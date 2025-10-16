const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const QRCode = require('qrcode');
const speakeasy = require('speakeasy');

const PORT = process.env.PORT || 3000;
const ISSUER_NAME = process.env.TOTP_ISSUER || 'HeronsVote App';


const app = express();
app.use(cors());
app.use(bodyParser.json());

// Health check
app.get('/', (req, res) => res.send('HeronsVote TOTP backend online'));

app.get('/generate', async (req, res) => {
  try {

    const label = req.query.email || 'guest@heronsvote.local'; 

    const secret = speakeasy.generateSecret({
      length: 20,
      name: `${ISSUER_NAME}:${label}`,
      issuer: ISSUER_NAME,
  
    });

    
    const otpauthUrl = speakeasy.otpauthURL({
      secret: secret.base32,
      label: `${ISSUER_NAME}:${label}`,
      issuer: ISSUER_NAME,
      encoding: 'base32', 
      algorithm: 'sha1',
      digits: 6,
      period: 30, 
    });

    const qr = await QRCode.toDataURL(otpauthUrl, { width: 300 });

    console.log('Generated Secret (base32):', secret.base32);
    console.log('OTPAuth URL:', otpauthUrl);

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
    window: 2, 
  });

  console.log(`🔍 Verifying token=${token} | verified=${verified}`);
  res.json({ verified });
});

app.listen(PORT, () => console.log(`OTP server running on port ${PORT}`));