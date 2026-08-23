const { db } = require('../api-lib/firebaseAdmin');

// Configurado em vercel.json (seção "crons") para rodar 1x por dia.
// A Vercel manda automaticamente o header Authorization com o CRON_SECRET
// quando o gatilho é o cron dela — isso impede qualquer outra pessoa de
// chamar esse endpoint manualmente.
module.exports = async (req, res) => {
  const authHeader = req.headers.authorization || '';
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  try {
    const agora = new Date();
    const snap = await db
      .collection('subscriptions')
      .where('status', '==', 'ativa')
      .where('proximoVencimento', '<', agora)
      .get();

    if (snap.empty) {
      res.status(200).json({ atualizadas: 0 });
      return;
    }

    const batch = db.batch();
    snap.docs.forEach((doc) => batch.update(doc.ref, { status: 'atrasada' }));
    await batch.commit();

    res.status(200).json({ atualizadas: snap.size });
  } catch (err) {
    console.error('Erro ao verificar assinaturas atrasadas:', err);
    res.status(500).json({ error: 'Erro ao verificar assinaturas atrasadas.' });
  }
};