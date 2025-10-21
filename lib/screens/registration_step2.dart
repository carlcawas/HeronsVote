import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'registration_step3.dart';

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

  String _enteredCode = '';
  bool _isCodeInvalid = false;

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

  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _getOtpAuthUrl({
    required String secret,
    required String accountName,
    String issuer = 'HeronsVote App',
  }) {
    return 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer&algorithm=SHA1&digits=6&period=30';
  }


  bool _verifyCode({required String secret, required String code}) {
  try {
    final now = DateTime.now().millisecondsSinceEpoch;
    final current = OTP.generateTOTPCodeString(secret, now, interval: 30);
    final previous = OTP.generateTOTPCodeString(secret, now - 30000, interval: 30);
    final next = OTP.generateTOTPCodeString(secret, now + 30000, interval: 30);

    debugPrint('Current=$current | Prev=$previous | Next=$next | Input=$code');

    return code == current || code == previous || code == next;
  } catch (e) {
    debugPrint('Error verifying TOTP: $e');
    return false;
  }
}


  // Get current code (for testing)
  String _getCurrentCode(String secret) {
  try {
    return OTP.generateTOTPCodeString(
      secret,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30,
      length: 6,
    );
  } catch (e) {
    debugPrint('Error getting current code: $e');
    return '000000';
  }
}


  Future<void> _prepareTotpAndShowDialog() async {
    if (_isGenerating) return;
    _isGenerating = true;

    try {
      final secret = _generateSecret();
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'user@umak.edu.ph';
      final otpauthUrl = _getOtpAuthUrl(
        secret: secret,
        accountName: userEmail,
      );
      
      debugPrint('Generated secret: $secret');
      debugPrint('OTPAuth URL: $otpauthUrl');

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'totpSecret': secret,
        'totpEnabled': false,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _totpSecret = secret;
        _otpauthUrl = otpauthUrl;
      });

      // Show the QR dialog
      if (!_dialogShown) {
        _dialogShown = true;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Authenticator Setup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan this QR code with Google Authenticator:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: 220,
                      height: 220,
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      child: QrImageView(
                        data: otpauthUrl,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Or manually enter this key:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        secret,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        final testCode = _getCurrentCode(secret);
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Expected Code'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Your Google Authenticator should show:',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 15),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue, width: 3),
                                  ),
                                  child: Text(
                                    testCode,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 10,
                                      color: Colors.blue,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  'If it doesn\'t match, make sure you:\n• Deleted old entries\n• Scanned the correct QR code\n• Synced time in Authenticator settings',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user, size: 18),
                      label: const Text('Show Expected Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      _isGenerating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                                children: const [
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
                            autoFocus: false,
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
                              errorBorderColor: _isCodeInvalid
                                  ? Colors.redAccent
                                  : const Color(0xFFDFE3F0),
                            ),
                            animationDuration: const Duration(milliseconds: 10),
                            backgroundColor: Colors.transparent,
                            enableActiveFill: true,
                            onCompleted: (v) => debugPrint("Completed: $v"),
                            onChanged: (value) => setState(() {
                              _enteredCode = value;
                              _isCodeInvalid = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          if (_isCodeInvalid)
                            const Center(
                              child: Text(
                                'Invalid code. Please try again or sync time in Authenticator.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontFamily: 'Geist',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.only(left: 16, top: 16),
                            child: Text(
                              "Step 1: Open Google Authenticator\n\nStep 2: Tap menu ⋮ → Settings → Time correction → Sync now\n\nStep 3: Find HeronsVote App entry\n\nStep 4: Enter the 6-digit code",
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
                                setState(() => _isCodeInvalid = false);
                                _prepareTotpAndShowDialog();
                              },
                              child: const Text(
                                'Need to re-scan QR code? Tap here',
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
                                      content: Text('Please enter the 6-digit code.'),
                                    ),
                                  );
                                  return;
                                }

                                // Get secret from Firestore if not in memory
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
                                      content: Text('No TOTP setup found. Please re-scan QR code.'),
                                    ),
                                  );
                                  return;
                                }

                                // Verify code
                                final isValid = _verifyCode(
                                  secret: secret,
                                  code: _enteredCode,
                                );

                                if (isValid) {
                                  // SUCCESS
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.uid)
                                      .update({
                                    'totpEnabled': true,
                                    'lastVerified': FieldValue.serverTimestamp(),
                                  });

                                  if (mounted) {
                                    setState(() => _isCodeInvalid = false);
                                  }

                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegistrationStep3(),
                                    ),
                                  );
                                } else {
                                  // FAILURE
                                  if (mounted) {
                                    setState(() => _isCodeInvalid = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid code. Please try again.'),
                                      ),
                                    );
                                  }
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