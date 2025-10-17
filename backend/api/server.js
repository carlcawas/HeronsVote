// api/index.js
import QRCode from "qrcode";
import speakeasy from "speakeasy";

export default async function handler(req, res) {
  if (req.method === "GET") {
    // ✅ Generate TOTP secret and QR
    try {
      const label = "user@heronsvote";
      const issuer = "HeronsVote App";

      const secret = speakeasy.generateSecret({
        name: `${issuer}:${label}`,
        issuer,
      });

      const qr = await QRCode.toDataURL(secret.otpauth_url);

      res.status(200).json({
        secret: secret.base32,
        otpauth_url: secret.otpauth_url,
        qr,
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  } else if (req.method === "POST") {
    // ✅ Verify a user’s TOTP
    try {
      const { token, secret } = req.body;

      if (!token || !secret)
        return res.status(400).json({ verified: false, error: "Missing fields" });

      const verified = speakeasy.totp.verify({
        secret,
        encoding: "base32",
        token,
        window: 1, // ±30s drift
      });

      res.status(200).json({ verified });
    } catch (err) {
      res.status(500).json({ verified: false, error: err.message });
    }
  } else {
    res.status(405).json({ error: "Method not allowed" });
  }
}
