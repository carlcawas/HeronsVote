import 'package:flutter/material.dart';
import 'reverify_step3.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:heronsvote/home/header.dart';

class RegistrationStep2 extends StatefulWidget {
  final String uid;
  final String name;
  final String college;
  final String collegeId;
  final String? yearLevel;
  final String? semester;
  final String section;
  const RegistrationStep2({
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
  State<RegistrationStep2> createState() => _RegistrationStep2State();
}

class _RegistrationStep2State extends State<RegistrationStep2>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;

  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  static const Color textFieldFillColor = Color(0xFFF7F7F7);
  static const Color labelTextColor = Color(0xFF747474);
  static const Color hintTextColor = Color(0xFF747474);

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
    // Save user's registration step
    _saveRegisterStep();

    // Auto fill information
    _nameController.text = widget.name;
    _yearLevelController.text = widget.yearLevel ?? '';
    _semesterController.text = widget.semester ?? '';
    _sectionController.text = widget.section;

    // college dropdown autofill string
    _selectedCollege = widget.collegeId; // e.g. "CCIS"
    _collegeController.text =
        collegeMap[widget.collegeId] ?? widget.college; // show full name

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
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                label,
                style: const TextStyle(
                  color: labelTextColor,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
            ),

            if (isEmpty)
              const Text(
                ' *Required',
                style: TextStyle(
                  color: Color(0xFFED6C6A),
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,

          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF404040),
              fontSize: 14,
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
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isEmpty ? Color(0xFFED6C6A) : Color(0xFFD9D9D9),
                  width: isEmpty ? 1.5 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isEmpty ? Color(0xFFED6C6A) : Color(0xFFD9D9D9),
                  width: isEmpty ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: isEmpty ? Color(0xFFED6C6A) : Color(0xFFD9D9D9),
                  width: isEmpty ? 1.5 : 1,
                ),
              ),

              suffixIcon: isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(
                        right: 6,
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
                vertical: 0,
                horizontal: 14,
              ),
            ),
          ),
        ),

        if (showBottomSpacing) const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBody: true,
      backgroundColor: const Color(0xFFFFFFFF),


      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             CustomHeader(
              title: "Verify Details", 
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 22),
            const Center(
              child: Hero(
                tag: 'HeroStepProgressIndicator',
                child: Material(
                  type: MaterialType.transparency,
                  child: StepProgressIndicator(currentStep: 2),
                ),
              ),
            ),

            const SizedBox(height: 0),
            Expanded(
              child: Stack(
                children: [
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
                            Expanded(
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: const <Color>[
                                      Colors.transparent,
                                      Colors.white,
                                    ],
                                    stops: const <double>[0.0, 0.05],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                    top: 18,
                                    bottom: 12,
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
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: const Text(
                                                  'College:',
                                                  style: TextStyle(
                                                    color: labelTextColor,
                                                    fontSize: 12,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                              ),

                                              if (_isCollegeEmpty)
                                                const Text(
                                                  ' *Required',
                                                  style: TextStyle(
                                                    color: Color(0xFFED6C6A),
                                                    fontSize: 12,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            /*decoration: BoxDecoration(
                                              color: const Color(0xFFDFE3F0),
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                color: _isCollegeEmpty
                                                    ? Color (0xFFED6C6A)
                                                    : Color (0xFFD9D9D9),
                                                width: _isCollegeEmpty
                                                    ? 1.5
                                                    : 1,
                                              ),
                                            ),*/
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                            ),

                                            // Dropdown for college
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton2<String>(
                                                value: _selectedCollege,
                                                isExpanded: true,
                                                dropdownStyleData: DropdownStyleData(
                                                  maxHeight:
                                                      200, // limit dropdown height

                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFF7F7F7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    border: Border.all(
                                                      color: _isCollegeEmpty
                                                          ? const Color(
                                                              0xFFED6C6A,
                                                            )
                                                          : const Color(
                                                              0xFFD9D9D9,
                                                            ),
                                                      width: _isCollegeEmpty
                                                          ? 1.5
                                                          : 1.0,
                                                    ),
                                                  ),
                                                  offset: const Offset(
                                                    0,
                                                    -4,
                                                  ), // starts below the college box field
                                                ),

                                                buttonStyleData:
                                                    ButtonStyleData(
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          0xFFF7F7F7,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                              Radius.circular(
                                                                15,
                                                              ),
                                                            ),

                                                        border: Border.all(
                                                          color: _isCollegeEmpty
                                                              ? Color(
                                                                  0xFFED6C6A,
                                                                )
                                                              : const Color(
                                                                  0xFFD9D9D9,
                                                                ),
                                                          width: _isCollegeEmpty
                                                              ? 1.5
                                                              : 1.0,
                                                        ),
                                                      ),

                                                      //dito
                                                    ),
                                                menuItemStyleData:
                                                    const MenuItemStyleData(
                                                      height: 44,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                          ),
                                                    ),
                                                iconStyleData: const IconStyleData(
                                                  icon: Padding(
                                                    padding:
                                                        EdgeInsetsGeometry.only(
                                                          right: 14,
                                                        ),
                                                    child: Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Color(0xFF747474),
                                                    ),
                                                  ),
                                                ),
                                                hint: const Text(
                                                  'e.g. College of Computing and Information Sciences',
                                                  style: TextStyle(
                                                    color: Color(0xFF747474),
                                                    fontSize: 12,
                                                    fontFamily: 'Geist',
                                                  ),
                                                ),
                                                items: collegeMap.entries.map((
                                                  entry,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: entry.key,
                                                    child: Text(
                                                      entry.value,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF404040,
                                                        ),
                                                        fontSize: 14,
                                                        fontFamily: 'Geist',
                                                        fontWeight:
                                                            FontWeight.w100,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCollege = value;
                                                    _collegeController.text =
                                                        collegeMap[value] ?? '';
                                                    _validateFields();
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 0),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 4,
                                                      ),
                                                      child: const Text(
                                                        'Yr/Level:',
                                                        style: TextStyle(
                                                          color: labelTextColor,
                                                          fontSize: 12,
                                                          fontFamily: 'Geist',
                                                        ),
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
                                                const SizedBox(height: 4),
                                                Container(
                                                  /*decoration: BoxDecoration(
                                                    color: const Color(0xFFDFE3F0),
                                                    borderRadius: BorderRadius.circular(15),
                                                    border: Border.all(
                                                      color: _isYearLevelEmpty ? Colors.red : Colors.transparent,
                                                      width: _isYearLevelEmpty ? 1.5 : 0,
                                                    ),
                                                  ),*/
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 0,
                                                      ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton2<String>(
                                                      value:
                                                          _yearLevelController
                                                              .text
                                                              .isNotEmpty
                                                          ? _yearLevelController
                                                                .text
                                                          : null,
                                                      isExpanded: true,
                                                      dropdownStyleData:
                                                          DropdownStyleData(
                                                            maxHeight: 200,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        15,
                                                                      ),
                                                                ),
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  -4,
                                                                ),
                                                          ),

                                                      buttonStyleData: ButtonStyleData(
                                                        height: 48,
                                                        decoration: BoxDecoration(
                                                          color: Color(
                                                            0xFFF7F7F7,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.circular(
                                                                  15,
                                                                ),
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                _isCollegeEmpty
                                                                ? Color(
                                                                    0xFFED6C6A,
                                                                  )
                                                                : const Color(
                                                                    0xFFD9D9D9,
                                                                  ),
                                                            width:
                                                                _isCollegeEmpty
                                                                ? 1.5
                                                                : 1.0,
                                                          ),
                                                        ),
                                                      ),

                                                      iconStyleData:
                                                          const IconStyleData(
                                                            icon: Padding(
                                                              padding:
                                                                  EdgeInsetsGeometry.only(
                                                                    right: 14,
                                                                  ),
                                                              child: Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                color: Color(
                                                                  0xFF747474,
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                      hint: const Text(
                                                        'e.g. Third Year',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF747474,
                                                          ),
                                                          fontSize: 12,
                                                          fontFamily: 'Geist',
                                                        ),
                                                      ),
                                                      items:
                                                          const [
                                                            'First Year',
                                                            'Second Year',
                                                            'Third Year',
                                                            'Fourth Year',
                                                          ].map((year) {
                                                            return DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: year,
                                                              child: Text(
                                                                year,
                                                                style: const TextStyle(
                                                                  color: Color(
                                                                    0xFF404040,
                                                                  ),
                                                                  fontSize: 14,
                                                                  fontFamily:
                                                                      'Geist',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w100,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _yearLevelController
                                                                  .text =
                                                              value ?? '';
                                                          _validateFields();
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
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
                                        height: 75, //button gap height distance
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
                                                            'Proceed',
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

  Future<void> _saveRegisterStep() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({'registration_step': 2}, SetOptions(merge: true));
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
            RegistrationStep3(uid: widget.uid),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
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
    const double innerCircleSize = 32.0;
    const double gapSize = 4.0;
    const double outerCircleSize = innerCircleSize + (gapSize * 2);

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
