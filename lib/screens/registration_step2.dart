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
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationStep2 extends StatefulWidget {
  final String uid;
  const RegistrationStep2({super.key, required this.uid});

  @override
  State<RegistrationStep2> createState() => _RegistrationStep2State();
}

class _RegistrationStep2State extends State<RegistrationStep2>
    with TickerProviderStateMixin {
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

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.linear),
    );

    _panelController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _prepareTotpAndShowDialog(),
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _normalizeSecret(String raw) {
    return raw.replaceAll(' ', '').toUpperCase(); // ✅ keep '='
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
    // Ensure the secret is properly formatted for Base32
    final normalized = _normalizeSecret(secret);

    // Use NTP (fallback to device clock)
    final nowMillis = await _utcMillis();
    final nowSeconds = (nowMillis / 1000).floor(); // ✅ convert ms → seconds

    final currentCounter = nowSeconds ~/ interval;

    // Optional: print one example expected code for debugging
    final expectedCode = OTP.generateTOTPCodeString(
      normalized,
      currentCounter * interval,
      interval: interval,
      length: length,
      algorithm: Algorithm.SHA1,
    );
    debugPrint(
      'DEBUG: currentCounter=$currentCounter | expectedCode=$expectedCode | input=$code',
    );

    // Try the current, previous, and next window for drift tolerance
    for (int drift = -window; drift <= window; drift++) {
      final candidateCounter = currentCounter + drift;

      // Skip already verified windows to prevent code reuse
      if (lastVerifiedWindow != null &&
          candidateCounter <= lastVerifiedWindow) {
        continue;
      }

      final candidateCode = OTP.generateTOTPCodeString(
        normalized,
        candidateCounter * interval,
        interval: interval,
        length: length,
        algorithm: Algorithm.SHA1,
      );

      debugPrint(
        'DEBUG drift=$drift | candidateCounter=$candidateCounter | candidateCode=$candidateCode',
      );

      if (candidateCode == code) {
        // ✅ Success
        return candidateCounter;
      }
    }

    // ❌ No match
    return -1;
  }

  Future<void> _prepareTotpAndShowDialog() async {
    if (_isGenerating) return;
    _isGenerating = true;

    try {
      // Call your backend to get a unique secret and QR per user
      final res = await http.get(
        Uri.parse('http://192.168.254.103:3000/generate'),
      ); // replace with your local IP
      if (res.statusCode != 200) throw Exception('Backend error');
      final data = jsonDecode(res.body);
      final secret = data['secret'] as String;
      final qrDataUrl = data['qr'] as String;

      // Save to Firestore for this specific user
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'totpSecret': secret,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _totpSecret = secret;
        _otpauthUrl = qrDataUrl; // we’ll use this for displaying the QR
      });

      // Show the QR dialog
      if (!_dialogShown) {
        _dialogShown = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Authenticator Setup'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Scan this QR code using Google Authenticator:'),
                  const SizedBox(height: 10),
                  Image.memory(
                    base64Decode(qrDataUrl.split(',').last),
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 10),
                  const Text('Or manually enter this key:'),
                  SelectableText(secret),
                ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error preparing authenticator.')),
        );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF354372),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 40,
                    bottom: 50,
                  ),
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
                                  TextSpan(
                                    text: "Enter the code from your\n",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Google Authenticator",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  TextSpan(
                                    text: " app",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
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
                            onChanged: (value) =>
                                setState(() => _enteredCode = value),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16),
                            child: Text(
                              "Step 1: Open your Google Authenticator app.\n\nStep 2: Find the 6-digit code for your UMak account.\n\nStep 3: Enter the code below.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Geist',
                              ),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter the 6-digit code.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                String? secret = _totpSecret;
                                if (secret == null || secret.isEmpty) {
                                  final doc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.uid)
                                      .get();
                                  secret = doc.data()?['totpSecret'] as String?;
                                }

                                if (secret == null || secret.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No TOTP setup found'),
                                    ),
                                  );
                                  return;
                                }

                                debugPrint("SECRET FROM FIRESTORE: $secret");

                                final doc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.uid)
                                    .get();
                                int? lastVerifiedWindow;
                                if (doc.exists &&
                                    doc.data()?['lastVerifiedWindow'] != null) {
                                  final val = doc.data()!['lastVerifiedWindow'];
                                  if (val is int)
                                    lastVerifiedWindow = val;
                                  else if (val is double)
                                    lastVerifiedWindow = val.toInt();
                                }

                                final matchedWindow =
                                    await _verifyTotpAndGetWindow(
                                      secret: secret,
                                      code: _enteredCode,
                                      interval: 30,
                                      length: 6,
                                      window: 1,
                                      lastVerifiedWindow: lastVerifiedWindow,
                                    );

                                if (matchedWindow >= 0) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.uid)
                                      .update({
                                        'lastVerifiedWindow': matchedWindow,
                                        'lastVerified':
                                            FieldValue.serverTimestamp(),
                                      });

                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegistrationStep3(),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Invalid or expired code. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C6AA0),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Authenticate',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ),
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
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 7,
                decoration: BoxDecoration(
                  color: index + 1 <= currentStep
                      ? lineActiveColor
                      : Colors.grey[300],
                  border: Border.all(color: const Color(0xFFD9D9D9), width: 2),
                ),
              ),
          ],
        );
      }),
    );
  }
}
