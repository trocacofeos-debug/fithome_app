const { db, auth } = require('../api-lib/firebaseAdmin');

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
  if (res.status === 204) return null;
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    console.error('Erro na API do Asaas:', res.status, JSON.stringify(data));
    throw new Error(data?.errors?.[0]?.description || 'Erro ao comunicar com o Asaas.');
  }
  return data;
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
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) {
      res.status(401).json({ error: 'Faça login.' });
      return;
    }
    const decoded = await auth.verifyIdToken(token);
    const uid = decoded.uid;

    const { subscriptionId } = req.body || {};
    if (!subscriptionId) {
      res.status(400).json({ error: 'subscriptionId é obrigatório.' });
      return;
    }

    const subRef = db.collection('subscriptions').doc(subscriptionId);
    const subSnap = await subRef.get();
    if (!subSnap.exists) {
      res.status(404).json({ error: 'Assinatura não encontrada.' });
      return;
    }
    const sub = subSnap.data();

    // Só o próprio dono da assinatura ou um admin pode cancelar.
    const userSnap = await db.collection('users').doc(uid).get();
    const role = userSnap.data()?.role;
    if (sub.alunoId !== uid && role !== 'admin') {
      res.status(403).json({ error: 'Sem permissão para cancelar essa assinatura.' });
      return;
    }

    if (sub.asaasSubscriptionId) {
      await asaasFetch(`/subscriptions/${sub.asaasSubscriptionId}`, { method: 'DELETE' });
    }

    await subRef.set({ status: 'cancelada', canceladaEm: new Date() }, { merge: true });
    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Erro ao cancelar assinatura:', err);
    res.status(500).json({ error: err.message || 'Erro ao cancelar assinatura.' });
  }
};