const admin = require('firebase-admin');

// Inicializa uma única vez (Vercel reaproveita a mesma instância entre
// chamadas quando a função "esquenta"). A chave de serviço vem em base64
// pra evitar problemas com quebras de linha/aspas dentro da variável de
// ambiente da Vercel.
if (!admin.apps.length) {
  const json = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf-8');
  const serviceAccount = JSON.parse(json);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

module.exports = {
  admin,
  db: admin.firestore(),
  auth: admin.auth(),
};