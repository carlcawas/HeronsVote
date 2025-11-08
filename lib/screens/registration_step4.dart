import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_step5.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class RegistrationStep4 extends StatefulWidget {
  final String uid;
  final String name;
  final String college;
  final String collegeId;
  final String? yearLevel;
  final String? semester;
  final String section;
  const RegistrationStep4({
    super.key,
    required this.uid,
    required this.name,
    required this.college,
    required this.collegeId,
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

  String? _selectedCollege;
  
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

  // String map for colleges autofill and dropdown
  final Map<String, String> collegeMap = {
      'CBFS': 'College of Business and Financial Science',
      'CCIS': 'College of Computing and Information Sciences',
      'CCSE': 'College of Construction Science and Engineering',
      'CET': 'College of Engineering Technology',
      'CHK': 'College of Human Kinetics',
      'CITE': 'College of Innovative Teacher Education',
      'CGPP': 'College of Governance and Public Policy',
      'CTHM': 'College of Tourism and Hospitality Management',
      'IAD': 'Institute of Arts and Design',
      'IIHS': 'Institute of Imaging Health Sciences',
      'IOA': 'Institute of Accountancy',
      'ION': 'Institute of Nursing',
      'IOP': 'Institute of Pharmacy',
      'IOPSY': 'Institute of Psychology',
      'ISW': 'Institute of Social Work',
      'IDEM': 'Institute of Disaster and Emergency Management',
  };

  @override
  void initState() {
    super.initState();

    // Auto fill information
    _nameController.text = widget.name;
    _yearLevelController.text = widget.yearLevel ?? '';
    _semesterController.text = widget.semester ?? '';
    _sectionController.text = widget.section;

    // college dropdown autofill string
    _selectedCollege = widget.collegeId; // e.g. "CCIS"
    _collegeController.text = collegeMap[widget.collegeId] ?? widget.college; // show full name


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

                                      // College dropdown
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'College:',
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 12,
                                                  fontFamily: 'Geist',
                                                ),
                                              ),
                                              if (_isCollegeEmpty)
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
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDFE3F0),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                color: _isCollegeEmpty
                                                    ? Colors.red
                                                    : Colors.transparent,
                                                width: _isCollegeEmpty
                                                    ? 1.5
                                                    : 0,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),

                                            // Dropdown for college
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton2<String>(
                                                value: _selectedCollege,
                                                isExpanded: true,
                                                dropdownStyleData: DropdownStyleData(
                                                  maxHeight: 200, // limit dropdown height
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  offset: const Offset(0, 0), // starts below the college box field
                                                ),
                                                buttonStyleData: const ButtonStyleData(
                                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                                  height: 49,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFDFE3F0),
                                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                                  ),
                                                ),
                                                menuItemStyleData: const MenuItemStyleData(
                                                  height: 49,
                                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                                ),
                                                iconStyleData: const IconStyleData(
                                                  icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                                ),
                                                hint: const Text(
                                                  'e.g. College of Computing and Information Sciences',
                                                  style: TextStyle(
                                                    color: Color(0xFF797979),
                                                    fontSize: 12,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                                items: collegeMap.entries.map((entry) {
                                                  return DropdownMenuItem<String>(
                                                    value: entry.key,
                                                    child: Text(
                                                      entry.value,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 12,
                                                        fontFamily: 'Geist',
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCollege = value;
                                                    _collegeController.text = collegeMap[value] ?? '';
                                                    _validateFields();
                                                  });
                                                },
                                              ),
                                            ),

                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),

                                      const SizedBox(height: 0),

                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                      'Yr/Level:',
                                                      style: TextStyle(
                                                        color: Color(0xFFFFFFFF),
                                                        fontSize: 12,
                                                        fontFamily: 'Geist',
                                                      ),
                                                    ),
                                                    if (_isYearLevelEmpty)
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
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDFE3F0),
                                                    borderRadius: BorderRadius.circular(10.0),
                                                    border: Border.all(
                                                      color: _isYearLevelEmpty ? Colors.red : Colors.transparent,
                                                      width: _isYearLevelEmpty ? 1.5 : 0,
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton2<String>(
                                                      value: _yearLevelController.text.isNotEmpty
                                                          ? _yearLevelController.text
                                                          : null,
                                                      isExpanded: true,
                                                      dropdownStyleData: DropdownStyleData(
                                                        maxHeight: 200,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      buttonStyleData: const ButtonStyleData(
                                                        height: 49,
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFFDFE3F0),
                                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                                        ),
                                                      ),
                                                      iconStyleData: const IconStyleData(
                                                        icon: Icon(Icons.arrow_drop_down, color: Colors.black54),
                                                      ),
                                                      hint: const Text(
                                                        'e.g. Third Year',
                                                        style: TextStyle(
                                                          color: Color(0xFF797979),
                                                          fontSize: 12,
                                                          fontFamily: 'Geist',
                                                        ),
                                                      ),
                                                      items: const [
                                                        'First Year',
                                                        'Second Year',
                                                        'Third Year',
                                                        'Fourth Year',
                                                      ].map((year) {
                                                        return DropdownMenuItem<String>(
                                                          value: year,
                                                          child: Text(
                                                            year,
                                                            style: const TextStyle(
                                                              color: Colors.black,
                                                              fontSize: 12,
                                                              fontFamily: 'Geist',
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _yearLevelController.text = value ?? '';
                                                          _validateFields();
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 18),
                                          Expanded(
                                            flex: 3,
                                            child: _buildStyledTextField(
                                              controller: _sectionController,
                                              label: 'Section:',
                                              hintText: 'e.g. ACSAD',
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
        msg: "All fields must not be empty. Please re-enter your details or re-upload your COR.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      debugPrint('Invalid Inputs.');
      return;
    }

    // get college id to insert in db
    final collegeId = _selectedCollege ?? "UNKNOWN";
    final collegeName = collegeMap[collegeId] ?? nCollege;

    // Update fields in db
    await userRef.set({
      'name': nName,
      'college': collegeName,
      'college_id': collegeId,
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
