import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_step5.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationStep4 extends StatefulWidget {
  final String uid;
  final String name;
  final String college;
  final String? yearLevel;
  final String? semester;
  final String section;
  const RegistrationStep4({
    super.key,
    required this.uid,
    required this.name,
    required this.college,
    required this.yearLevel,
    required this.semester,
    required this.section,
    });

  @override
  State<RegistrationStep4> createState() => _RegistrationStep4State();
}

class _RegistrationStep4State extends State<RegistrationStep4> with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;

  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  static const Color textFieldFillColor = Color(0xFFDFE3F0,); //bg TF
  static const Color labelTextColor = Colors.white; //label
  static const Color hintTextColor = Color(0xFF797979,); 

  // Init TextField === similar to casting TextView
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _yearLevelController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Auto fill information :)
    _nameController.text = widget.name;
    _collegeController.text = widget.college;
    _yearLevelController.text = widget.yearLevel ?? '';
    _semesterController.text = widget.semester ?? '';
    _sectionController.text = widget.section;

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _panelSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.linear),
    );

    _panelController.forward();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _panelController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildStyledTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool showBottomSpacing = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: labelTextColor,
            fontSize: 12,
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontFamily: 'Geist',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: hintTextColor,
              fontSize: 12,
              fontFamily: 'Geist',
            ),

            filled: true,
            fillColor: textFieldFillColor,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0), 
              borderSide: BorderSide.none, 
            ),

            contentPadding: const EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 3.0,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (showBottomSpacing) const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      backgroundColor: const Color(0xFFF6EFD2),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(child: StepProgressIndicator(currentStep: 2)),
            const SizedBox(height: 10),
            Expanded(
              child: SlideTransition(
                position: _panelSlide,
                child: Container(
                  margin: const EdgeInsets.only(top: 35),
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
                    bottom:
                        50, 
                  ),
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "Verify Student ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "details",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
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
                          _buildStyledTextField(
                            controller: _nameController,
                            label: 'Name:',
                            hintText: 'Last name, First name, M.I.',
                          ),
                          const SizedBox(height: 10),

                          _buildStyledTextField(
                            controller: _collegeController,
                            label: 'College:',
                            hintText:
                                'e.g. College of Computing and Information Sciences',
                          ),

                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildStyledTextField(
                                  controller: _yearLevelController,
                                  label: 'Yr/Level:',
                                  hintText: 'e.g. Third Year',
                                  showBottomSpacing: false,
                                  keyboardType: TextInputType.text,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: _buildStyledTextField(
                                  controller: _sectionController,
                                  label: 'Section:',
                                  hintText: 'e.g. III-ACSAD',
                                  showBottomSpacing: false,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          _buildStyledTextField(
                            controller: _semesterController,
                            label: 'Semester & Academic Year:',
                            hintText: 'e.g. First Semester A.Y. 2025-2026',
                          ),

                          const Spacer(),
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                await _updateDetails(context);
                              },
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C6AA0),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Confirm',
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
                        ],
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

  Future<void> _updateDetails(BuildContext context)  async {
    // Checks passed uid if still authenticated by firebase
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Fluttertoast.showToast(
        msg: "User is not authenticated. Please log in again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    
    // Get new information input by user
    String nName = _nameController.text;
    String nCollege = _collegeController.text;
    String nYrLvl = _yearLevelController.text;
    String nSection = _sectionController.text;
    String nSemester = _semesterController.text;

    // Init database's users collection
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Validate inputs
    final hasCompletedInput =
        nName.isNotEmpty &&
        nCollege.isNotEmpty &&
        nYrLvl.isNotEmpty &&
        nSection.isNotEmpty &&
        nSemester.isNotEmpty;

      if (!hasCompletedInput) {
        // TODO: Replace Toast with UI update
        Fluttertoast.showToast(
          msg: "All fields must not be empty. Please re-enter your details or re-upload your COR.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        debugPrint('Invalid Inputs.');
        return;
      }

    // Update fields in firestore firebase
    await userRef.set({
      'name': nName,
      'college': nCollege,
      'year_level': nYrLvl,
      'section': nSection,
      'semester': nSemester,
      'lastUpdateCOR': DateTime.now(),
    }, SetOptions(merge: true));

    // TODO: Replace Toast with UI update
    Fluttertoast.showToast(
      msg: "Student information updated successfully.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );

    // Move to next page if all steps are successful
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 0),
        pageBuilder: (context, animation, secondaryAnimation) => const RegistrationStep5(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {return child;},
      ),
    );
  }
}

//steps
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
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 7,
                decoration: BoxDecoration(
                  color: index + 1 <= currentStep
                      ? lineActiveColor
                      : Colors.grey[300],
                  border: Border.all(color: Color(0xFFD9D9D9), width: 2),
                ),
              ),
          ],
        );
      }),
    );
  }
}
