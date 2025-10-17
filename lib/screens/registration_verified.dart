import 'package:flutter/material.dart';
import 'package:heronsvote/home/home.dart';

class RegistrationVerified extends StatefulWidget {
  const RegistrationVerified({super.key});

  @override
  State<RegistrationVerified> createState() => _RegistrationVerifiedState();
}

class _RegistrationVerifiedState extends State<RegistrationVerified>
    with TickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final AnimationController _bottomController;
  late final Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();

    //top slide
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );
    //bottom rise to
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _bottomController, curve: Curves.easeOut),
        );

    _contentController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _bottomController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
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
            const SizedBox(height: 50),
            Expanded(
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        child: Image.asset(
                          height: 300,
                          'assets/verified.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Verified",
                              style: TextStyle(
                                color: const Color(0xFF414141),
                                fontSize: 25,
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
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 30,
                  bottom: 50,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Registration ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontFamily: 'Geist',
                              ),
                            ),
                            TextSpan(
                              text: "successful.",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                fontFamily: 'Geist',
                              ),
                            ),
                            TextSpan(
                              text: "\nYou may now log in.",
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
                    const SizedBox(height: 40),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 0),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const HomeScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return child;
                                },
                          ),
                        );
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C6AA0),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text(
                            'Continue',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
