import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_step5.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

class _RegistrationStep4State extends State<RegistrationStep4>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;

  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  static const Color textFieldFillColor = Color(0xFFDFE3F0);
  static const Color labelTextColor = Colors.white;
  static const Color hintTextColor = Color(0xFF797979);

  // Init TextField controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _yearLevelController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  bool _isNameEmpty = false;
  bool _isCollegeEmpty = false;
  bool _isYearLevelEmpty = false;
  bool _isSectionEmpty = false;
  bool _isSemesterEmpty = false;
  bool _isFormValid = true;

  void _validateFields() {
    setState(() {
      _isNameEmpty = _nameController.text.trim().isEmpty;
      _isCollegeEmpty = _collegeController.text.trim().isEmpty;
      _isYearLevelEmpty = _yearLevelController.text.trim().isEmpty;
      _isSectionEmpty = _sectionController.text.trim().isEmpty;
      _isSemesterEmpty = _semesterController.text.trim().isEmpty;

      _isFormValid =
          !(_isNameEmpty ||
              _isCollegeEmpty ||
              _isYearLevelEmpty ||
              _isSectionEmpty ||
              _isSemesterEmpty);
    });
  }

  @override
  void initState() {
    super.initState();

    // Auto fill information
    _nameController.text = widget.name;
    _collegeController.text = widget.college;
    _yearLevelController.text = widget.yearLevel ?? '';
    _semesterController.text = widget.semester ?? '';
    _sectionController.text = widget.section;

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    required bool isEmpty,
    bool showBottomSpacing = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: labelTextColor,
                fontSize: 12,
                fontFamily: 'Geist',
              ),
            ),
            if (isEmpty)
              const Text(
                ' *Required',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
          ],
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
          onChanged: (_) => _validateFields(),
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
              borderSide: BorderSide(
                color: isEmpty ? Colors.red : Colors.transparent,
                width: isEmpty ? 1.5 : 0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: isEmpty ? Colors.red : Colors.transparent,
                width: isEmpty ? 1.5 : 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: isEmpty ? Colors.red : Colors.transparent,
                width: isEmpty ? 1.5 : 0,
              ),
            ),

            suffixIcon: isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                      top: 12,
                      bottom: 12,
                    ),
                    child: SvgPicture.asset(
                      'assets/error.svg',
                      width: 20,
                      height: 20,
                    ),
                  )
                : null,

            contentPadding: const EdgeInsets.symmetric(
              vertical: 5.0,
              horizontal: 8.0,
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
      resizeToAvoidBottomInset: true,
      extendBody: true,
      backgroundColor: const Color(0xFFF9F2D7),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFF9F2D7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Hero(
          tag: 'appBarBackButton',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(child: StepProgressIndicator(currentStep: 2)),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'bluePanel',
                    child: Material(
                      type: MaterialType.transparency,
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
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 30,
                    ),
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 43),
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
                            const SizedBox(height: 24),

                            Expanded(
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: const <Color>[
                                      Colors
                                          .transparent,
                                      Colors.white,
                                    ],
                                    stops: const <double>[
                                      0.0, 
                                      0.05,
                                    ],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                    top:
                                        20,                                    bottom:
                                        50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildStyledTextField(
                                        controller: _nameController,
                                        label: 'Name:',
                                        hintText: 'Last name, First name, M.I.',
                                        isEmpty: _isNameEmpty,
                                      ),
                                      const SizedBox(height: 0),
                                      _buildStyledTextField(
                                        controller: _collegeController,
                                        label: 'College:',
                                        hintText:
                                            'e.g. College of Computing and Information Sciences',
                                        isEmpty: _isCollegeEmpty,
                                      ),
                                      const SizedBox(height: 0),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _buildStyledTextField(
                                              controller: _yearLevelController,
                                              label: 'Yr/Level:',
                                              hintText: 'e.g. Third Year',
                                              isEmpty: _isYearLevelEmpty,
                                              showBottomSpacing: false,
                                              keyboardType: TextInputType.text,
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          Expanded(
                                            flex: 3,
                                            child: _buildStyledTextField(
                                              controller: _sectionController,
                                              label: 'Section:',
                                              hintText: 'e.g. III-ACSAD',
                                              isEmpty: _isSectionEmpty,
                                              showBottomSpacing: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _buildStyledTextField(
                                        controller: _semesterController,
                                        label: 'Semester & Academic Year:',
                                        hintText:
                                            'e.g. First Semester A.Y. 2025-2026',
                                        isEmpty: _isSemesterEmpty,
                                      ),

                                      const SizedBox(
                                        height: 40,
                                      ),
                                      Center(
                                        child: AbsorbPointer(
                                          absorbing: !_isFormValid,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5C6AA0),
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(
                                                        _isFormValid
                                                            ? 0.25
                                                            : 0.15,
                                                      ),
                                                  offset: const Offset(0, 3),
                                                  blurRadius: _isFormValid
                                                      ? 6
                                                      : 3,
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                                onTap: () async {
                                                  _validateFields();
                                                  if (_isFormValid) {
                                                    await _updateDetails(
                                                      context,
                                                    );
                                                  }
                                                },
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: Center(
                                                    child:
                                                        AnimatedDefaultTextStyle(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    200,
                                                              ),
                                                          style: TextStyle(
                                                            color: _isFormValid
                                                                ? Colors.white
                                                                : Colors
                                                                      .white60,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily: 'Geist',
                                                          ),
                                                          child: const Text(
                                                            'Confirm',
                                                          ),
                                                        ),
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
                              ),
                            ),
                          ],
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

  Future<void> _updateDetails(BuildContext context) async {
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
      Fluttertoast.showToast(
        msg:
            "All fields must not be empty. Please re-enter your details or re-upload your COR.",
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
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegistrationStep5(uid: widget.uid),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
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
                width: 40,
                height: 7 + (2 * 2),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      width: 40,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border.all(color: Color(0xFFD9D9D9), width: 2),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (index + 1 == currentStep)
                          ? 40 / 2
                          : (index + 1 < currentStep)
                          ? 40
                          : 0,
                      height: 7,
                      decoration: BoxDecoration(
                        color: lineActiveColor,
                        border: Border.all(color: Color(0xFFD9D9D9), width: 2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}
