const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { randomUUID } = require('crypto');

function sanitizarEndpoint(endpoint) {
  return (endpoint || '')
    .trim()
    .replace(/^https?:\/\//, '')
    .replace(/\/+$/, '');
}

const client = new S3Client({
  region: 'auto',
  endpoint: `https://${sanitizarEndpoint(process.env.R2_ENDPOINT)}`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  },
});

const PASTAS_PERMITIDAS = ['workouts', 'exercises', 'avatars'];

module.exports.config = {
  api: { bodyParser: { sizeLimit: '8mb' } },
};

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Método não permitido' });
    return;
  }

  try {
    const { pasta, nomeOriginal, contentType, base64 } = req.body || {};

    if (!pasta || !nomeOriginal || !base64) {
      res.status(400).json({ error: 'pasta, nomeOriginal e base64 são obrigatórios' });
      return;
    }
    if (!PASTAS_PERMITIDAS.includes(pasta)) {
      res.status(400).json({ error: `pasta inválida. Use uma de: ${PASTAS_PERMITIDAS.join(', ')}` });
      return;
    }
    if (!process.env.R2_ENDPOINT || !process.env.R2_ACCESS_KEY_ID || !process.env.R2_SECRET_ACCESS_KEY || !process.env.R2_BUCKET || !process.env.R2_PUBLIC_URL) {
      res.status(500).json({ error: 'Variáveis de ambiente do R2 incompletas na Vercel (confira R2_ENDPOINT, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET, R2_PUBLIC_URL).' });
      return;
    }

    const extensao = nomeOriginal.includes('.') ? nomeOriginal.split('.').pop().toLowerCase() : 'bin';
    const chave = `${pasta}/${randomUUID()}.${extensao}`;
    const buffer = Buffer.from(base64, 'base64');

    await client.send(new PutObjectCommand({
      Bucket: process.env.R2_BUCKET,
      Key: chave,
      Body: buffer,
      ContentType: contentType || 'application/octet-stream',
    }));

    const publicUrl = `${process.env.R2_PUBLIC_URL}/${chave}`;
    res.status(200).json({ publicUrl });
  } catch (err) {
    console.error('Erro ao enviar pro R2:', err);
    // Devolve a mensagem real do erro (não sensível — não inclui a chave
    // secreta) para diagnosticar sem precisar ficar adivinhando.
    res.status(500).json({ error: 'Erro ao enviar arquivo', detalhe: err.message || String(err) });
  }
};