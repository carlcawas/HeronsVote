import 'package:flutter/material.dart';
import 'registration_step3.dart';
import './Privacy&Terms/privacyPolicy.dart';
import './Privacy&Terms/termsCondition.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';


class RegistrationStep1 extends StatefulWidget {
  final String uid;
  const RegistrationStep1({super.key, required this.uid});

  @override
  State<RegistrationStep1> createState() => _RegistrationStep1State();
}

class _RegistrationStep1State extends State<RegistrationStep1>
    with TickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final AnimationController _bottomController;
  late final Animation<Offset> _bottomSlide;
  late TapGestureRecognizer _termsTapRecognizer;
  late TapGestureRecognizer _privacyTapRecognizer;

  bool _isBoxChecked = false;

  @override
  void initState() {
    super.initState();

    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TermsCondition()),
        );
      };

    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyPolicy()),
        );
      };

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );

    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bottomController, curve: Curves.easeOut),
        );

    _contentController.forward();
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _bottomController.forward(),
    );
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    _contentController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF9F2D7),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFF9F2D7),
        elevation: 0,
        leading: Hero(
          tag: 'appBarBackButton',
          child: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 65),
            SlideTransition(
              position: _contentSlide,
              child: Column(
                children: [
                  Container(
                    height: 238,
                    width: 238,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: SizedBox(
                      width: 0,
                      child: SvgPicture.asset(
                        'assets/verify.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 45),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "First, let's ",
                            style: TextStyle(
                              color: const Color(0xFF414141),
                              fontSize: 24,
                              fontFamily: 'Geist',
                            ),
                          ),
                          TextSpan(
                            text: "verify\n",
                            style: TextStyle(
                              color: const Color(0xFF414141),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          TextSpan(
                            text: "your identity",
                            style: TextStyle(
                              color: const Color(0xFF414141),
                              fontSize: 24,
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SlideTransition(
              position: _bottomSlide,
              child: Stack(
                children: [
                  // Hero for background panel only
                  Hero(
                    tag: 'bluePanel',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
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
                          top: 30,
                          bottom: 50,
                        ),
                        child: Column(
                          children: [
                            // Verify Identity button
                            GestureDetector(
                              onTap: _isBoxChecked
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RegistrationStep3(
                                            uid: widget.uid,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _isBoxChecked
                                      ? const Color(0xFF5C6AA0)
                                      : const Color(
                                          0xFF5C6AA0,
                                        ).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Center(
                                  child: Text(
                                    'Verify Identity',
                                    style: TextStyle(
                                      color: _isBoxChecked
                                          ? Colors.white
                                          : Colors.white60,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBoxChecked = !_isBoxChecked;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Checkbox
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      curve: Curves.easeInOut,
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _isBoxChecked
                                            ? const Color(0xFF74B6F9)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: _isBoxChecked
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    // Text with clickable parts
                                    Flexible(
                                      child: RichText(
                                        textAlign: TextAlign.left,
                                        text: TextSpan(
                                          style: const TextStyle(
                                            color: Color(0xFFECECEC),
                                            fontSize: 10,
                                            fontFamily: 'Geist',
                                            height: 16 / 10,
                                            letterSpacing: 10 * 0.02,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'By signing in to this app, you agree to our ',
                                            ),
                                            TextSpan(
                                              text: 'Terms \n& Conditions',
                                              style: const TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.white70,
                                              ),
                                              recognizer: _termsTapRecognizer,
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: const TextStyle(
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.white70,
                                              ),
                                              recognizer: _privacyTapRecognizer,
                                            ),
                                            const TextSpan(text: '.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
