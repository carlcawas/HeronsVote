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
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height:0),
            const SizedBox(height: 72),

            const Center(
              child: Hero(
                tag: 'HeroStepProgressIndicator', 
                child: Material(
                  type: MaterialType.transparency,
                  child: StepProgressIndicator(currentStep: 4)),  
              )
            ),

            const SizedBox(height: 0),
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
                          'assets/reverified.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Center(
                      
                      child: Text.rich(
                        TextSpan(
                          children: [

                            TextSpan(
                              text: "COR Succesfully Updated",
                              style: TextStyle(
                                color: Color(0xFF404040),
                                fontSize: 24,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w600,
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
                  color: Color(0xFFFFFFFF),
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
                    /*Center(
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
                    const SizedBox(height: 0),*/
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
                            'Go Back',
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

//progress step indicator
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    // SIZES
    const double innerCircleSize = 32.0;
    const double gapSize = 4.0; 
    const double outerCircleSize = innerCircleSize + (gapSize * 2); // 40.0 px

    const Color activeColor = Color(0xFF354372);
    const Color inactiveColor = Color(0xFFD6DAE5);
    const Color checkIconColor = Colors.white;

    // Calculate the total number of gaps (e.g., 4 steps = 3 gaps)
    int totalIntervals = totalSteps - 1;
    
    // Calculate current progress
    double progressValue;
    if (currentStep >= totalSteps) {
      // If last step, fill line completely
      progressValue = 1.0; 
    } else {
      // Otherwise, fill to current step PLUS half of the next gap (+ 0.5)
      progressValue = ((currentStep - 1) + 0.5) / totalIntervals;
    }

    return SizedBox(
      width: 254,
      height: outerCircleSize, 
      child: Stack(
        children: [
          // LAYER 1: The Outer Containers (Bottom)
          // These sit BEHIND the line.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
               return Container(
                 width: outerCircleSize,
                 height: outerCircleSize,
                 decoration: const BoxDecoration(
                   color: inactiveColor, // outer circle color
                   shape: BoxShape.circle,
                 ),
               );
            }),
          ),

          // LAYER 2: The Continuous Line (Middle)
          // This sits ON TOP of Layer 1, so it is not erased.
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: outerCircleSize / 2),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: Container( // <-- Add Container for the border
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: inactiveColor, //border color
                      width: 2.0,
                    ),
                  ),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: inactiveColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: 2,
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: The Inner Circles (Top)
          // This sits ON TOP of the Line.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              int stepNumber = index + 1;
              bool isCompleted = stepNumber < currentStep;
              bool isActive = stepNumber == currentStep;

              return SizedBox(
                width: outerCircleSize,
                height: outerCircleSize,
                child: Center(
                  child: Container(
                    width: innerCircleSize,
                    height: innerCircleSize,
                    decoration: BoxDecoration(
                      color: (isActive || isCompleted) ? activeColor : inactiveColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: checkIconColor)
                          : Text(
                              '$stepNumber',
                              style: TextStyle(
                                color: (isActive) ? Colors.white : const Color(0xFF404040),
                                fontWeight: FontWeight.w100,
                                fontSize: 14,
                                fontFamily: 'Geist',
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
