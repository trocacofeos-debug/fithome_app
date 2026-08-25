const { db } = require('./_lib/firebaseAdmin');

const ASAAS_BASE_URL = 'https://sandbox.asaas.com/api/v3';

// Sistema de indicação: plano cuja mensalidade paga comissão ao instrutor
// que indicou o aluno, e o valor dessa comissão.
const VALOR_PLANO_COMISSIONAVEL = 29.99;
const VALOR_COMISSAO_INDICACAO = 10;

async function asaasFetch(path) {
  const res = await fetch(`${ASAAS_BASE_URL}${path}`, {
    headers: { 'access_token': process.env.ASAAS_API_KEY },
  });
  return res.json();
}

// Credita a comissão de indicação ao instrutor, se o aluno tiver sido
// indicado por alguém e o plano pago for o comissionável. Um documento por
// (instrutor, aluno, mês) em `referral_commissions`, com ID determinístico
// — `.create()` falha com ALREADY_EXISTS se já existir, o que garante que
// reenvios do mesmo evento pelo Asaas nunca dupliquem a comissão.
async function creditarComissaoIndicacao(subData, subscriptionRef) {
  if (Math.abs(subData.valor - VALOR_PLANO_COMISSIONAVEL) > 0.01) return;

  const alunoDoc = await db.collection('users').doc(subData.alunoId).get();
  if (!alunoDoc.exists) return;
  const indicadoPor = alunoDoc.data().indicadoPor;
  if (!indicadoPor || indicadoPor === subData.alunoId) return;

  const agora = new Date();
  const periodo = `${agora.getFullYear()}-${String(agora.getMonth() + 1).padStart(2, '0')}`;
  const commissionId = `${indicadoPor}_${subData.alunoId}_${periodo}`;

  try {
    await db.collection('referral_commissions').doc(commissionId).create({
      instrutorId: indicadoPor,
      alunoId: subData.alunoId,
      alunoNome: subData.alunoNome,
      subscriptionId: subscriptionRef.id,
      valor: VALOR_COMISSAO_INDICACAO,
      periodo,
      criadoEm: agora,
    });
  } catch (err) {
    if (err.code === 6 || /already exists/i.test(err.message || '')) return; // já creditado neste período
    throw err;
  }

  await criarNotificacao(
    indicadoPor,
    'Nova comissão de indicação',
    `Você ganhou R$${VALOR_COMISSAO_INDICACAO.toFixed(2)} pela mensalidade de ${subData.alunoNome} este mês.`,
    'comissao',
  );
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
        await creditarComissaoIndicacao(subData, ref);
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