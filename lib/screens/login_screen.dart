import 'package:flutter/material.dart';
import 'registration_step1.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<Offset> _logoSlide;

  late final AnimationController _textController;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;

  late final AnimationController _bottomController;
  late final Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();

    //slide
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoController.forward();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 300), () {
      _textController.forward();
    });

    // Bottom slide
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bottomController, curve: Curves.easeOut),
        );
    Future.delayed(const Duration(milliseconds: 500), () {
      _bottomController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F2D7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _logoSlide,
                      child: Hero(
                        tag: 'logoHero',
                        child: SizedBox(
                          width: 230,
                          child: Image.asset(
                            alignment: Alignment.bottomCenter,
                            'assets/HeronVoteLogo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Center(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "H",
                                  style: TextStyle(
                                    color: const Color(0xFF414141),
                                    fontSize: 32,
                                    fontFamily: 'Geist',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: "erons",
                                  style: TextStyle(
                                    color: const Color(0xFF414141),
                                    fontSize: 32,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                                TextSpan(
                                  text: "Vote",
                                  style: TextStyle(
                                    color: const Color(0xFF414141),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SlideTransition(
              position: _bottomSlide,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF354372),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 50
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 700),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const RegistrationStep1(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              final offsetAnimation =
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                              final fadeAnimation = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              );

                              return FadeTransition(
                                opacity: fadeAnimation,
                                child: SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                ),
                              );
                            },
                      ),
                    );
                  },
                  child: Container(
                    height: 61,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6AA0),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Geist',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
