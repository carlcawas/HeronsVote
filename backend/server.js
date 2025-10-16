const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Health check
app.get('/', (req, res) => res.send('✅ HeronsVote TOTP backend online'));

// Generate TOTP secret and QR code
app.get('/generate', async (req, res) => {
  try {
    // You can replace this with the actual user email or Firebase UID later
    const label = 'user@heronsvote';
    const issuer = 'HeronsVote';

    // Generate TOTP secret
    const secret = speakeasy.generateSecret({
      name: `${issuer}:${label}`,
      issuer: issuer,
      length: 20, // standard length for Google Auth
    });

    // Construct a fully compatible otpauth URL manually
    const otpauthUrl = `otpauth://totp/${encodeURIComponent(
      issuer
    )}:${encodeURIComponent(label)}?secret=${secret.base32}&issuer=${encodeURIComponent(
      issuer
    )}&algorithm=SHA1&digits=6&period=30`;

    // Generate QR code in base64
    const qr = await QRCode.toDataURL(otpauthUrl);

    console.log('Generated new TOTP secret for user:', label);
    console.log('Secret (base32):', secret.base32);
    console.log('OTPAuth URL:', otpauthUrl);

    // Send JSON back to Flutter app
    res.json({
      secret: secret.base32,
      otpauth_url: otpauthUrl,
      qr,
    });
  } catch (err) {
    console.error('Error generating TOTP:', err);
    res.status(500).json({ error: err.message });
  }
});

// Verify TOTP token
app.post('/verify', (req, res) => {
  try {
    const { token, secret } = req.body;

    if (!token || !secret) {
      return res
        .status(400)
        .json({ verified: false, error: 'Missing token or secret' });
    }

    // Use speakeasy verify function (base32 encoded secret)
    const verified = speakeasy.totp.verify({
      secret,
      encoding: 'base32',
      token,
      window: 2, // allow ±1 time step (60s total)
      step: 30,
      algorithm: 'sha1',
    });

    console.log(`🔍 Verify token=${token}, verified=${verified}`);

    res.json({ verified });
  } catch (err) {
    console.error('Verification error:', err);
    res.status(500).json({ verified: false, error: err.message });
  }
});

// Start server
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log(`TOTP server running on port ${PORT}`));
