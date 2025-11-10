import 'package:flutter/material.dart';
import 'package:heronsvote/home/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RegistrationVerified extends StatefulWidget {
  final String uid;
  const RegistrationVerified({super.key, required this.uid});

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
    // Save user's registration step 
    _saveRegisterStep();

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

  Future<void> _saveRegisterStep() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({
        'registration_step' : 4,
        'registerComplete': true,
        'isVerified' : true,
      }, SetOptions(merge: true));
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
            const SizedBox(height: 50),
            const StepProgressIndicator(currentStep: 4), 
            const SizedBox(height: 20),
            Expanded(
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        child: SvgPicture.asset(
                          height: 220,
                          'assets/verified.svg',
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
                                fontSize: 24,
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
                    const SizedBox(height: 0),
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
                              text: "\nYou are now logged in.",
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 0),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    HomeScreen(uid: widget.uid),
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
                          (route) => false,
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

// Steps
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
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
            if (!isLast)
              SizedBox(
                width: 40, // Keep the original line width for spacing
                height: 7 + (2 * 2), // Total height including potential border
                child: Stack(
                  alignment: Alignment.centerLeft, // Align active line to the left
                  children: [
                    // --- Background (Inactive Line) ---
                    Container(
                      width: 40,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Inactive fill color
                        border: Border.all(color: Color(0xFFD9D9D9), width: 2),
                        // Optional: Add border radius if you want rounded ends
                        // borderRadius: BorderRadius.circular(3.5), 
                      ),
                    ),
                    // --- Foreground (Active Line - Animated Width) ---
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (index + 1 == currentStep) 
                             ? 40 / 2 // Half width if this is the *current* step
                             : (index + 1 < currentStep) 
                               ? 40 // Full width if this step is *already passed*
                               : 0, // Zero width if it's a future step
                      height: 7,
                      decoration: BoxDecoration(
                        color: lineActiveColor, // Active fill color
                        border: Border.all(color: Color(0xFFD9D9D9), width: 2), // Keep border consistent
                         // Optional: Add border radius if you want rounded ends
                        // borderRadius: BorderRadius.circular(3.5), 
                      ),
                    ),
                  ],
                ),
              ), // End of Line SizedBox/Stack

          ], // End of inner Row children
        ); // End of inner Row
      }), // End of List.generate
    ); // End of outer Row
  }
}
