const { db, auth } = require('./_lib/firebaseAdmin');

// Troque para "https://api.asaas.com/v3" quando for para produção.
const ASAAS_BASE_URL = 'https://sandbox.asaas.com/api/v3';

async function asaasFetch(path, options = {}) {
  const res = await fetch(`${ASAAS_BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'access_token': process.env.ASAAS_API_KEY,
      ...(options.headers || {}),
    },
  });
  const data = await res.json();
  if (!res.ok) {
    console.error('Erro na API do Asaas:', res.status, JSON.stringify(data));
    throw new Error(data?.errors?.[0]?.description || 'Erro ao comunicar com o Asaas.');
  }
  return data;
}

function cicloAsaas(duracaoDias) {
  if (duracaoDias <= 10) return 'WEEKLY';
  if (duracaoDias <= 45) return 'MONTHLY';
  if (duracaoDias <= 100) return 'QUARTERLY';
  if (duracaoDias <= 200) return 'SEMIANNUALLY';
  return 'YEARLY';
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Método não permitido' });
    return;
  }

  try {
    // Confere quem está chamando através do token de login do Firebase
    // (mandado pelo app no header Authorization).
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) {
      res.status(401).json({ error: 'Faça login para assinar.' });
      return;
    }
    const decoded = await auth.verifyIdToken(token);
    const uid = decoded.uid;

    const { planId, cpf } = req.body || {};
    if (!planId) {
      res.status(400).json({ error: 'planId é obrigatório.' });
      return;
    }

    const [userSnap, planSnap] = await Promise.all([
      db.collection('users').doc(uid).get(),
      db.collection('plans').doc(planId).get(),
    ]);
    if (!planSnap.exists) {
      res.status(404).json({ error: 'Plano não encontrado.' });
      return;
    }

    const user = userSnap.data() || {};
    const plan = planSnap.data();

    const cpfFinal = (cpf || user.cpf || '').replace(/\D/g, '');
    if (cpfFinal.length !== 11) {
      res.status(400).json({ error: 'Informe um CPF válido para continuar com a assinatura.' });
      return;
    }
    if (!user.cpf) {
      await db.collection('users').doc(uid).set({ cpf: cpfFinal }, { merge: true });
    }

    // 1) Cria (ou reaproveita) o cliente no Asaas
    let asaasCustomerId = user.asaasCustomerId;
    if (!asaasCustomerId) {
      const cliente = await asaasFetch('/customers', {
        method: 'POST',
        body: JSON.stringify({ name: user.nome || 'Aluno', email: user.email, cpfCnpj: cpfFinal }),
      });
      asaasCustomerId = cliente.id;
      await db.collection('users').doc(uid).set({ asaasCustomerId }, { merge: true });
    }

    // 2) Cria a assinatura recorrente
    const nextDueDate = new Date().toISOString().slice(0, 10);
    const assinatura = await asaasFetch('/subscriptions', {
      method: 'POST',
      body: JSON.stringify({
        customer: asaasCustomerId,
        billingType: 'UNDEFINED', // aluno escolhe PIX, boleto ou cartão na página
        value: plan.valor,
        nextDueDate,
        cycle: cicloAsaas(plan.duracaoDias),
        description: plan.nome,
      }),
    });

    // 3) Busca a primeira cobrança gerada, para pegar o link de pagamento
    const pagamentos = await asaasFetch(`/payments?subscription=${assinatura.id}&limit=1`);
    const primeiraCobranca = pagamentos.data && pagamentos.data[0];
    if (!primeiraCobranca) {
      res.status(500).json({ error: 'Assinatura criada, mas não foi possível gerar o link de pagamento.' });
      return;
    }

    // Salva a assinatura no Firestore já como "pendente" — o webhook
    // confirma e muda para "ativa" assim que o pagamento cair.
    await db.collection('subscriptions').add({
      alunoId: uid,
      alunoNome: user.nome || '',
      planoId: planId,
      planoNome: plan.nome || '',
      valor: plan.valor,
      status: 'pendente',
      inicio: new Date(),
      proximoVencimento: new Date(nextDueDate),
      asaasCustomerId,
      asaasSubscriptionId: assinatura.id,
    });

    res.status(200).json({ url: primeiraCobranca.invoiceUrl });
  } catch (err) {
    console.error('Erro no checkout do Asaas:', err);
    res.status(500).json({ error: err.message || 'Erro ao criar checkout de assinatura.' });
  }
};