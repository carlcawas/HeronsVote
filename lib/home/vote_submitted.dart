import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home.dart'; 

class VoteSubmittedPage extends StatelessWidget {
  final String uid;

  const VoteSubmittedPage({
    super.key, 
    required this.uid, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            //Header Title
          const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 24),
              child: Center(
                child: Text(
                  'Vote confirmation',
                  style: TextStyle(
                    color: Color(0xFF404040),
                    fontFamily: 'Geist',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Hero(
                  tag: 'HeroStepProgressIndicator',
                  child: Material(
                    type: MaterialType.transparency,
                    child: StepProgressIndicator(
                      currentStep: 3,
                      totalSteps: 3,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),

            //ICON MIDDLE
           Center(
              child: Container(
                width: 260, 
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/vote_verified.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // TExt
            const Text(
              'Vote submitted',
              style: TextStyle(
                color: Color(0xFF404040),
                fontSize: 24,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            const Spacer(flex: 2),

            // done
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(
                      builder: (context) => HomeScreen(uid: uid),),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFFF8F8F8),
                    fontSize: 14,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w700,
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

//Step indicator
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
    const double innerCircleSize = 32.0;
    const double gapSize = 4.0;
    const double outerCircleSize = innerCircleSize + (gapSize * 2);

    const Color activeColor = Color(0xFF354372);
    const Color inactiveColor = Color(0xFFD6DAE5);
    const Color checkIconColor = Colors.white;

    // Calculate the total number of gaps
    int totalIntervals = totalSteps - 1;

    // Calculate current progress
    double progressValue;
    if (currentStep >= totalSteps) {
      progressValue = 1.0;
    } else {
      // Logic: Fill to current step PLUS half of the next gap
      progressValue = ((currentStep - 1) + 0.5) / totalIntervals;
    }

    // Safety check to prevent division by zero if totalSteps is 1
    if (totalIntervals <= 0) progressValue = 0;

    return SizedBox(
      width: 200,
      height: outerCircleSize,
      child: Stack(
        children: [
          // LAYER 1: The Outer Containers (Bottom)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              return Container(
                width: outerCircleSize,
                height: outerCircleSize,
                decoration: const BoxDecoration(
                  color: inactiveColor,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),

          // LAYER 2: The Continuous Line (Middle)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: outerCircleSize / 2),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: inactiveColor,
                      width: 2.0,
                    ),
                  ),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: inactiveColor,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: 2,
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: The Inner Circles (Top)
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
                      color: (isActive || isCompleted)
                          ? activeColor
                          : inactiveColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 12, color: checkIconColor)
                          : Text(
                              '$stepNumber',
                              style: TextStyle(
                                color: (isActive)
                                    ? Colors.white
                                    : const Color(0xFF404040),
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