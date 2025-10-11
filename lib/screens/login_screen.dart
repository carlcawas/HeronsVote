import 'package:flutter/material.dart';
import 'registration_step1.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
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
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bottomController, curve: Curves.easeOut));
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
      backgroundColor: const Color(0xFFF9F2D7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 90),
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
                            'assets/HeronVoteLogo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textFade,
                        child: const Text(
                          'HeronsVote',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF273E58),
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
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrationStep1(),
                      ),
                    );
                  },
                  child: Container(
                    height: 60,
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
                            fontWeight: FontWeight.w500,
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
