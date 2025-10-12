import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_step2.dart';

class RegistrationStep1 extends StatefulWidget {
  const RegistrationStep1({super.key});

  @override
  State<RegistrationStep1> createState() => _RegistrationStep1State();
}

class _RegistrationStep1State extends State<RegistrationStep1>
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
          children: [
            const SizedBox(height: 150),
              SlideTransition(
                position: _contentSlide,
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: SizedBox(
                        width: 300,
                        child: Image.asset(
                          'assets/verify.png',
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
                                fontWeight: FontWeight.w700,
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 700),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const RegistrationStep2(),
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
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6AA0),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: Text(
                        'Verify Identity',
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
            ),
          ],
        ),
      ),
    );
  }
}
