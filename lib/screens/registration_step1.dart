import 'package:flutter/material.dart';

class RegistrationStep1 extends StatefulWidget {
  const RegistrationStep1({super.key});

  @override
  State<RegistrationStep1> createState() => _RegistrationStep1State();
}

class _RegistrationStep1State extends State<RegistrationStep1> with TickerProviderStateMixin {
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
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
   //bottom rise to
    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bottomController, curve: Curves.easeOut));

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
      backgroundColor: const Color(0xFFF9F2D7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 130,
                      width: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 60,
                        color: Color(0xFF273E58),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "First, let's verify",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF273E58),
                      ),
                    ),
                    const Text(
                      "your identity",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF273E58),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Proceeding to next step...'),
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
                          fontWeight: FontWeight.w500,
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
