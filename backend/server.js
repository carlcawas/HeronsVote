const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const totp = require('totp-generator');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Health check (Render uses this)
app.get('/', (req, res) => res.send('HeronsVote TOTP backend online'));

// Generate secret and QR
app.get('/generate', async (req, res) => {
  try {
    const secret = speakeasy.generateSecret({ name: 'HeronsVote App' });
    const qr = await QRCode.toDataURL(secret.otpauth_url);
    res.json({ secret: secret.base32, qr });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Verify token
app.post('/verify', (req, res) => {
  const { token, secret } = req.body;
  if (!token || !secret) {
    return res.status(400).json({ verified: false, error: 'Missing token or secret' });
  }

  const verified = speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token,
    window: 1
  });

  res.json({ verified });
});

// Render provides process.env.PORT
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`TOTP server running on port ${PORT}`));