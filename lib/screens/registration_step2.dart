import 'dart:math';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'registration_step3.dart';
import 'package:ntp/ntp.dart';
import 'package:convert/convert.dart';

import 'package:totp_authenticator/totp_authenticator.dart';

class RegistrationStep2 extends StatefulWidget {
  final String uid;
  const RegistrationStep2({super.key, required this.uid});

  @override
  State<RegistrationStep2> createState() => _RegistrationStep2State();
}

class _RegistrationStep2State extends State<RegistrationStep2> with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;
  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  String? _totpSecret;
  String _otpauthUrl = '';
  bool _dialogShown = false;
  bool _isGenerating = false;

  bool _forceSecretReset = false;

  String _enteredCode = '';

  @override
  void initState() {
    super.initState();

    _panelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));

    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _contentController, curve: Curves.linear));

    _panelController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareTotpAndShowDialog());
  }

  @override
  void dispose() {
    _panelController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _normalizeSecret(String raw) {
    return raw.replaceAll(' ', '').replaceAll('=', '').toUpperCase();
  }

  Future<int> _utcMillis() async {
    try {
      final offset = await NTP.getNtpOffset(lookUpAddress: 'time.google.com');
      final nowUtcMilliseconds =
          DateTime.now().toUtc().millisecondsSinceEpoch + offset;
      return nowUtcMilliseconds;
    } catch (e) {
      debugPrint('NTP FAILED. Using device clock as fallback. Error: $e');
      return DateTime.now().toUtc().millisecondsSinceEpoch;
    }
  }

  Future<int> _verifyTotpAndGetWindow({
    required String secret,
    required String code,
    int interval = 30,
    int length = 6,
    int window = 1,
    int? lastVerifiedWindow,
  }) async {
    final normalized = _normalizeSecret(secret);
    final nowMillis = await _utcMillis();

    final timeStepCounter = (nowMillis ~/ 1000) ~/ interval;

    // For debugging
    final expected = OTP.generateTOTPCodeString(
      normalized,
      nowMillis,
      interval: interval,
      length: length,
      algorithm: Algorithm.SHA1,
    );
    debugPrint(
      'DEBUG: Secret=$normalized | nowMillis=$nowMillis | TimeCounter=$timeStepCounter | CorrectCode(T0)=$expected',
    );

    for (int drift = -window; drift <= window; drift++) {
      final candidateWindow = timeStepCounter + drift;

      if (lastVerifiedWindow != null && candidateWindow <= lastVerifiedWindow) {
        debugPrint('Skipping candidateWindow=$candidateWindow because lastVerifiedWindow=$lastVerifiedWindow');
        continue;
      }

      final tsMillis = candidateWindow * interval * 1000;
      final candidate = OTP.generateTOTPCodeString(
        normalized,
        tsMillis,
        interval: interval,
        length: length,
        algorithm: Algorithm.SHA1,
      );

      debugPrint('DEBUG drift=$drift candidateWindow=$candidateWindow tsMillis=$tsMillis candidate=$candidate input=$code');

      if (candidate == code) {
        return candidateWindow;
      }
    }

    return -1;
  }

  Future<void> _prepareTotpAndShowDialog() async {
    if (_isGenerating) return;
    _isGenerating = true;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);
      final doc = await userRef.get();

      String secret = '';
      bool mustGenerateNew = true;

      if (doc.exists && doc.data()?['totpSecret'] != null && !_forceSecretReset) {
        secret = doc.data()!['totpSecret'] as String;
        mustGenerateNew = false;
      }

      if (mustGenerateNew) {
        try {
          secret = TOTP.generateSecret();
        } catch (e) {
          final random = Random.secure();
          final bytes = List<int>.generate(20, (_) => random.nextInt(256));
          secret = base32.encode(Uint8List.fromList(bytes));
        }

        _forceSecretReset = false;
      }

      secret = _normalizeSecret(secret);
      await userRef.set({'totpSecret': secret}, SetOptions(merge: true));

      if (!mounted) return;

      final issuer = 'HeronsVote';
      final email = FirebaseAuth.instance.currentUser?.email ?? 'unknown';
      final label = '${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(email)}';

      String uriFromLib;
      try {
        final totpLib = TOTP();

        uriFromLib = totpLib.generateQRCodeUri(label, secret, issuer: issuer, interval: 30);
      } catch (e) {
        uriFromLib = 'otpauth://totp/$label'
            '?secret=$secret'
            '&issuer=${Uri.encodeComponent(issuer)}'
            '&algorithm=SHA1'
            '&digits=6'
            '&period=30';
      }

      setState(() {
        _totpSecret = secret;
        _otpauthUrl = uriFromLib;
      });

      debugPrint('SECRET FROM FIRESTORE: $secret');
      debugPrint('OTP URL = $uriFromLib');

      if (!_dialogShown) {
        _dialogShown = true;

        String decodedHex = 'N/A';
        List<Map<String, String>> debugCandidates = [];
        try {
          final decodedBytes = base32.decode(secret);
          decodedHex = hex.encode(decodedBytes);
        } catch (e) {
          decodedHex = 'failed to decode: $e';
        }

        final nowMillisForDebug = await _utcMillis();
        final intervalDebug = 30;
        final timeStepCounterDebug = (nowMillisForDebug ~/ 1000) ~/ intervalDebug;
        for (int drift = -1; drift <= 1; drift++) {
          final candidateWindow = timeStepCounterDebug + drift;
          final tsMillis = candidateWindow * intervalDebug * 1000;
          final candidate = OTP.generateTOTPCodeString(
            _normalizeSecret(secret),
            tsMillis,
            interval: intervalDebug,
            length: 6,
            algorithm: Algorithm.SHA1,
          );
          debugCandidates.add({
            'drift': drift.toString(),
            'window': candidateWindow.toString(),
            'tsMillis': tsMillis.toString(),
            'code': candidate,
          });
        }

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Authenticator Setup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Scan this QR code with Google Authenticator app:'),
                    const SizedBox(height: 12),
                    SizedBox(width: 180, height: 180, child: QrImageView(data: _otpauthUrl, version: QrVersions.auto)),
                    const SizedBox(height: 16),
                    const Text('Or manually enter this key:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    SelectableText(secret, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),

                    // DEBUG temporary
                    const Divider(),
                    const SizedBox(height: 6),
                    const Text('DEBUG INFO (temporary)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: Text('Decoded secret (hex):', style: TextStyle(fontSize: 11, color: Colors.black54))),
                    SelectableText(decodedHex, textAlign: TextAlign.left, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: Text('Server expected codes (drift -1,0,+1):', style: TextStyle(fontSize: 11, color: Colors.black54))),
                    const SizedBox(height: 6),

                    for (final c in debugCandidates)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'drift=${c['drift']} window=${c['window']} code=${c['code']}',
                          style: const TextStyle(fontSize: 13, fontFamily: 'Geist'),
                        ),
                      ),

                    const SizedBox(height: 6),
                    const Divider(),
                    const SizedBox(height: 6),
                    const Text('After scanning, compare the code shown on your phone with the three "code=..." lines above.', style: TextStyle(fontSize: 11)),
                    const SizedBox(height: 6),
                    const Text('If the phone value does NOT match any of the three, check: (1) you scanned the new QR, (2) the entry is TOTP/time-based (not HOTP), (3) phone clock is correct, (4) try a different authenticator app.', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
        if (mounted) setState(() => _dialogShown = false);
      }
    } catch (e, st) {
      debugPrint('Error preparing TOTP: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error preparing authenticator.')));
      }
    } finally {
      _isGenerating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF6EFD2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6EFD2),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black, size: 25), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(child: StepProgressIndicator(currentStep: 1)),
            const SizedBox(height: 10),
            Expanded(
              child: SlideTransition(
                position: _panelSlide,
                child: Container(
                  margin: const EdgeInsets.only(top: 35),
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Color(0xFF354372), borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 50),
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: "Enter the code from your\n", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Geist')),
                                  TextSpan(text: "Google Authenticator", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Geist')),
                                  TextSpan(text: " app", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Geist')),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 50),
                          PinCodeTextField(
                            appContext: context,
                            length: 6,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            cursorColor: const Color(0xFF515151),
                            autoFocus: true,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 64,
                              fieldWidth: 47,
                              inactiveColor: const Color(0xFFDFE3F0),
                              activeColor: const Color(0xFFDFE3F0),
                              selectedColor: const Color(0xFFDFE3F0),
                              activeFillColor: const Color(0xFFDFE3F0),
                              inactiveFillColor: const Color(0xFFDFE3F0),
                              selectedFillColor: const Color(0xFFDFE3F0),
                            ),
                            animationDuration: const Duration(milliseconds: 10),
                            backgroundColor: Colors.transparent,
                            enableActiveFill: true,
                            onCompleted: (v) => debugPrint("Completed: $v"),
                            onChanged: (value) => setState(() => _enteredCode = value),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16),
                            child: Text(
                              "Step 1: Open your Google Authenticator app.\n\nStep 2: Find the 6-digit code for your UMak account.\n\nStep 3: Enter the code below.",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Geist'),
                            ),
                          ),
                          const Spacer(),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                if (mounted && _dialogShown) {
                                  Navigator.of(context).pop();
                                }
                                setState(() {
                                  _forceSecretReset = true;
                                });
                                _prepareTotpAndShowDialog();
                              },
                              child: const Text(
                                'Code not working? Tap to reset and re-scan QR.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                if (_enteredCode.length != 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the 6-digit code.')));
                                  return;
                                }

                                String? secret = _totpSecret;
                                if (secret == null || secret.isEmpty) {
                                  final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
                                  secret = doc.data()?['totpSecret'] as String?;
                                }

                                if (secret == null || secret.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No TOTP setup found')));
                                  return;
                                }

                                debugPrint("SECRET FROM FIRESTORE: $secret");

                                final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
                                int? lastVerifiedWindow;
                                if (doc.exists && doc.data()?['lastVerifiedWindow'] != null) {
                                  final val = doc.data()!['lastVerifiedWindow'];
                                  if (val is int) lastVerifiedWindow = val;
                                  else if (val is double) lastVerifiedWindow = val.toInt();
                                }

                                final matchedWindow = await _verifyTotpAndGetWindow(
                                  secret: secret,
                                  code: _enteredCode,
                                  interval: 30,
                                  length: 6,
                                  window: 1,
                                  lastVerifiedWindow: lastVerifiedWindow,
                                );

                                if (matchedWindow >= 0) {
                                  await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
                                    'lastVerifiedWindow': matchedWindow,
                                    'lastVerified': FieldValue.serverTimestamp(),
                                  });

                                  if (!mounted) return;
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationStep3()));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired code. Please try again.')));
                                }
                              },
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(color: const Color(0xFF5C6AA0), borderRadius: BorderRadius.circular(40)),
                                child: const Center(child: Text('Authenticate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Geist'))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  const StepProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF354372);
    const inactiveColor = Color(0xFFD9D9D9);
    const lineActiveColor = Color(0xFF273E58);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index + 1 <= currentStep;
        final isLast = index == 3;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                border: Border.all(color: inactiveColor, width: 4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Geist'),
                ),
              ),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 7,
                decoration: BoxDecoration(
                  color: index + 1 <= currentStep ? lineActiveColor : Colors.grey[300],
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 2),
                ),
              ),
          ],
        );
      }),
    );
  }
}