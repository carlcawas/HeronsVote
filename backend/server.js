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

// 🧩 Generate TOTP secret and QR code
app.get('/generate', async (req, res) => {
  try {
    // In a real app, you might include a user's email or ID for uniqueness
    const label = 'user@heronsvote'; // can be dynamic
    const issuer = 'HeronsVote App';

    const secret = speakeasy.generateSecret({
      name: label,
      issuer: issuer,
    });

    // Manually construct a proper otpauth URL (for Google Authenticator compatibility)
    const otpauthUrl = `otpauth://totp/${encodeURIComponent(
      issuer
    )}:${encodeURIComponent(label)}?secret=${secret.base32}&issuer=${encodeURIComponent(
      issuer
    )}&algorithm=SHA1&digits=6&period=30`;

    // Generate the QR code image as base64
    const qr = await QRCode.toDataURL(otpauthUrl, { width: 300 });

    console.log('✅ Generated new TOTP secret:');
    console.log('Secret:', secret.base32);
    console.log('OTPAuth URL:', otpauthUrl);

    // Send to Flutter
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

// 🔒 Verify TOTP token
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
    step: 30, // allow ±30s drift
  });

  console.log(`🔍 Verify token=${token}, verified=${verified}`);

  res.json({ verified });
});

// 🚀 Start server
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => console.log(`TOTP server running on port ${PORT}`));