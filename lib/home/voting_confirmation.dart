import 'package:flutter/material.dart';
import 'sample_data.dart';
import 'face_verification.dart';
import 'header.dart';

class VoteConfirmationPage extends StatelessWidget {
  final Map<String, Candidate?> selectedCandidates;

  const VoteConfirmationPage({super.key, required this.selectedCandidates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Vote confirmation',
              onBack: () => Navigator.pop(context),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Hero(
                  tag: 'HeroStepProgressIndicator',
                  child: Material(
                    type: MaterialType.transparency,
                    child: StepProgressIndicator(currentStep: 1, totalSteps: 3),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedCandidates.entries.map((entry) {
                    return _buildReadOnlyField(
                      label: entry.key,
                      value: entry.value?.name ?? 'No Selection',
                    );
                  }).toList(),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceVerificationPage(
                        selectedCandidates: selectedCandidates,
                      ),
                    ),
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
                  'Proceed to Face Verification',
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

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 12,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF404040),
                fontSize: 16,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(
              horizontal: outerCircleSize / 2,
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: inactiveColor, width: 2.0),
                  ),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: inactiveColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      activeColor,
                    ),
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
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: checkIconColor,
                            )
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
