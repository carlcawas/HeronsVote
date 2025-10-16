const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// 🩺 Health check
app.get('/', (req, res) => res.send('✅ HeronsVote TOTP backend online'));

// 🧩 Generate TOTP secret + QR
app.get('/generate', async (req, res) => {
  try {
    const label = 'user@heronsvote'; // You can make this dynamic per user
    const issuer = 'HeronsVote App';

    // ✅ Explicitly set encoding and secret length for Authenticator compatibility
    const secret = speakeasy.generateSecret({
      name: `${issuer}:${label}`,
      issuer: issuer,
      length: 20, // standard RFC length
    });

    // ✅ Construct proper otpauth URL
    const otpauthUrl = speakeasy.otpauthURL({
      secret: secret.ascii,
      label: `${issuer}:${label}`,
      issuer: issuer,
      encoding: 'ascii',
      algorithm: 'sha1',
      digits: 6,
      period: 30,
    });

    // ✅ Generate QR code
    const qr = await QRCode.toDataURL(otpauthUrl, { width: 300 });

    console.log('✅ Generated TOTP Secret:', secret.base32);
    console.log('OTPAuth URL:', otpauthUrl);

    res.json({
      secret: secret.base32,
      otpauth_url: otpauthUrl,
      qr,
    });
  } catch (err) {
    console.error('❌ Error generating TOTP:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔒 Verify endpoint (optional)
app.post('/verify', (req, res) => {
  const { token, secret } = req.body;

  if (!token || !secret) {
    return res
      .status(400)
      .json({ verified: false, error: 'Missing token or secret' });
  }

  const verified = speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token,
    window: 1,
  });

  console.log(`🔍 Verifying token=${token} | verified=${verified}`);
  res.json({ verified });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 TOTP server running on port ${PORT}`));
