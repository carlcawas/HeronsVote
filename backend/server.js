const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');

// --- Configuration ---
// Use environment variables for sensitive/configurable data
const PORT = process.env.PORT || 3000;
const ISSUER_NAME = process.env.TOTP_ISSUER || 'HeronsVote App';
// DEFAULT_LABEL is removed as the label will now be fetched from the request

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Health check
app.get('/', (req, res) => res.send('HeronsVote TOTP backend online'));

app.get('/generate', async (req, res) => {
  try {

    const label = req.query.email || 'guest@heronsvote.local'; 

    // Generate secret - speakeasy returns both ascii and base32
    const secret = speakeasy.generateSecret({
      length: 20,
      name: `${ISSUER_NAME}:${label}`,
      issuer: ISSUER_NAME,
      // Use 'base32' here to ensure the secret itself is base32 encoded
    });

    // CRITICAL: Use base32 encoding for the secret in the otpauthURL
    // TOTP apps expect base32-encoded secrets
    const otpauthUrl = speakeasy.otpauthURL({
      secret: secret.base32,
      label: `${ISSUER_NAME}:${label}`,
      issuer: ISSUER_NAME,
      encoding: 'base32', // Must match the secret encoding
      algorithm: 'sha1',
      digits: 6,
      period: 30, // 30 seconds is standard
    });

    const qr = await QRCode.toDataURL(otpauthUrl, { width: 300 });

    console.log('Generated Secret (base32):', secret.base32);
    console.log('OTPAuth URL:', otpauthUrl);

    // IMPORTANT: The secret must be stored on the server (e.g., database)
    // and associated with the user's account for verification later.
    res.json({
      secret: secret.base32,
      otpauth_url: otpauthUrl,
      qr,
    });
  } catch (err) {
    console.error('Error generating TOTP:', err);
    res.status(500).json({ error: 'Failed to generate TOTP configuration' });
  }
});

/**
 * 🔒 Verify endpoint
 * In a real application, the 'secret' should be retrieved from the database
 * using a userId passed in the request, not sent by the client.
 */
app.post('/verify', (req, res) => {
  // Client sends the one-time 'token' and the 'secret' (for this example only)
  const { token, secret } = req.body;

  if (!token || !secret) {
    return res
      .status(400)
      .json({ verified: false, error: 'Missing token or secret' });
  }

  // Use speakeasy.totp.verify to check the token against the secret
  const verified = speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token,
    window: 1, // Allows tokens one time step before or after (30 sec tolerance)
  });

  console.log(`🔍 Verifying token=${token} | verified=${verified}`);
  res.json({ verified });
});

app.listen(PORT, () => console.log(`OTP server running on port ${PORT}`));