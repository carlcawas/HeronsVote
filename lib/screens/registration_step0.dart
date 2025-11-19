import 'package:flutter/material.dart';
import 'registration_step1.dart';
import './Privacy&Terms/privacyPolicy.dart';
import './Privacy&Terms/termsCondition.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';


class RegistrationStep0 extends StatefulWidget {
  final String uid;
  const RegistrationStep0({super.key, required this.uid});

  @override
  State<RegistrationStep0> createState() => _RegistrationStep0State();
}

class _RegistrationStep0State extends State<RegistrationStep0>
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


      appBar: AppBar( //appbar back button
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFF9F2D7),
        elevation: 0,
        leading: Hero(
          tag: 'appBarBackButton',
          child: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF404040),
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),


      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 104),
            SlideTransition(
              position: _contentSlide,
              child: Column(
                children: [
                  Container(
                    height: 221,
                    width: 221,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: SizedBox(
                      width: 0, //maintext gap between icon
                      child: SvgPicture.asset(
                        'assets/verify.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Complete ",
                            style: TextStyle(
                              color: const Color(0xFF414141),
                              fontSize: 24,
                              fontFamily: 'Geist',
                            ),
                          ),
                          TextSpan(
                            text: "Student\n",
                            style: TextStyle(
                              color: const Color(0xFF414141),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Geist',
                            ),
                          ),
                          TextSpan(
                            text: "Registration",
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
                          bottom: 47,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Verify Identity button
                            Opacity(
                              opacity: _isBoxChecked ? 1.0 : 0.5,
                              child: Material(
                                color: _isBoxChecked
                                      ? const Color(0xFF5C6AA0)
                                      : const Color(
                                          0xFF5C6AA0,
                                        ).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(100),

                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(100),
                                    onTap: _isBoxChecked
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RegistrationStep1(
                                              uid: widget.uid,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                    child: Container(
                                      height: 60,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                        child: const Text(
                                          'Get Started',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFFF8F8F8),
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Geist',
                                          ),
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
                                  horizontal: 35,
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
                                            ? const Color(0xFF858FB8)
                                            : const Color(0xFFF8F8F8),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: _isBoxChecked
                                              ? const Color(0xFF5C6AA0)
                                              : Colors.white,
                                          width: 1, 
                                        ),
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
                                              text: 'Terms & Conditions',
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
