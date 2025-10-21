import 'package:flutter/material.dart';
import 'registration_step3.dart';

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

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _bottomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bottomController, curve: Curves.easeOut));

    _contentController.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _bottomController.forward());
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
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFF9F2D7),
        elevation: 0,
        leading: Hero( // <--- 1. ADD HERO WIDGET
          tag: 'appBarBackButton', // <--- 2. GIVE IT A UNIQUE TAG
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
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                    child: SizedBox(width: 0, child: Image.asset('assets/verified.png', fit: BoxFit.contain)),
                  ),
                  const SizedBox(height: 45),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "First, let's ",
                            style: TextStyle(color: const Color(0xFF414141), fontSize: 24, fontFamily: 'Geist'),
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
                      type: MaterialType.transparency, // <-- prevents text flash
                      child: Container(
                        width: double.infinity,
                        height: 146, // height of the panel you want to animate
                        decoration: const BoxDecoration(
                          color: Color(0xFF354372),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Panel content (button, padding, etc.)
                  Container(
                    padding: const EdgeInsets.only(left: 25, right: 25, top: 30, bottom: 46),
                    child: Material(
                      color: const Color(0xFF5C6AA0),
                      borderRadius: BorderRadius.circular(40),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RegistrationStep3(uid: widget.uid)),
                          );
                        },
                        child: SizedBox(
                          height: 56,
                          child: const Center(
                            child: Text(
                              'Verify Identity',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ), 
    );
  }
}