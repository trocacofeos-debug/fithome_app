const { db } = require('../api-lib/firebaseAdmin');

const ASAAS_BASE_URL = 'https://sandbox.asaas.com/api/v3';

async function asaasFetch(path) {
  const res = await fetch(`${ASAAS_BASE_URL}${path}`, {
    headers: { 'access_token': process.env.ASAAS_API_KEY },
  });
  return res.json();
}

async function criarNotificacao(userId, titulo, mensagem, tipo) {
  if (!userId) return;
  await db.collection('notifications').add({
    userId,
    titulo,
    mensagem,
    tipo: tipo || 'geral',
    lida: false,
    createdAt: new Date(),
    rota: null,
  });
}

// Endpoint configurado no Dashboard do Asaas (Integrações → Webhooks).
// Segurança: o Asaas manda um "Token de acesso" no header
// `asaas-access-token` em toda chamada — validamos antes de processar.
module.exports = async (req, res) => {
  const tokenRecebido = req.headers['asaas-access-token'];
  if (tokenRecebido !== process.env.ASAAS_WEBHOOK_TOKEN) {
    console.warn('Webhook do Asaas recebido com token inválido.');
    res.status(401).send('unauthorized');
    return;
  }

  const { event, payment } = req.body || {};
  if (!payment || !payment.subscription) {
    res.status(200).json({ ignored: true });
    return;
  }

  try {
    const snap = await db
      .collection('subscriptions')
      .where('asaasSubscriptionId', '==', payment.subscription)
      .limit(1)
      .get();

    if (snap.empty) {
      console.warn('Nenhuma assinatura no Firestore para:', payment.subscription);
      res.status(200).json({ ignored: true });
      return;
    }
    const ref = snap.docs[0].ref;
    const subData = snap.docs[0].data();

    switch (event) {
      case 'PAYMENT_CONFIRMED':
      case 'PAYMENT_RECEIVED': {
        const assinaturaAsaas = await asaasFetch(`/subscriptions/${payment.subscription}`);
        await ref.set(
          { status: 'ativa', proximoVencimento: new Date(assinaturaAsaas.nextDueDate) },
          { merge: true },
        );
        await criarNotificacao(
          subData.alunoId,
          'Pagamento confirmado',
          `Sua assinatura do plano ${subData.planoNome} está ativa.`,
          'assinatura',
        );
        break;
      }

      case 'PAYMENT_OVERDUE': {
        await ref.set({ status: 'atrasada' }, { merge: true });
        await criarNotificacao(
          subData.alunoId,
          'Pagamento em atraso',
          `A cobrança do plano ${subData.planoNome} venceu. Regularize para continuar treinando.`,
          'assinatura',
        );
        break;
      }

      case 'PAYMENT_DELETED':
      case 'PAYMENT_REFUNDED': {
        await ref.set({ status: 'cancelada', canceladaEm: new Date() }, { merge: true });
        await criarNotificacao(
          subData.alunoId,
          'Assinatura cancelada',
          `Sua assinatura do plano ${subData.planoNome} foi cancelada.`,
          'assinatura',
        );
        break;
      }

      default:
        break;
    }

    res.status(200).json({ received: true });
  } catch (err) {
    console.error('Erro ao processar webhook do Asaas:', err);
    res.status(500).send('erro interno');
  }
};