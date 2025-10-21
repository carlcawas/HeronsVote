import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_step4.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationStep3 extends StatefulWidget {
  final String uid;
  const RegistrationStep3({super.key, required this.uid});

  @override
  State<RegistrationStep3> createState() => _RegistrationStep3State();
}

class _RegistrationStep3State extends State<RegistrationStep3>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;

  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    bottom: 50,
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
                                  TextSpan(
                                    text: "Upload your ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Geist',
                                    ),
                                  ),
                                  TextSpan(
                                    text: "COR",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
                          
                          // When box with icon is clicked
                          GestureDetector(
                            onTap: () async {
                              await _openCOR(context);
                            },
                            child: Container(
                              height: 250,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6AA0),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.yellowAccent,
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.file_present_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          //

                          const Spacer(),
                          Center(
                            child: GestureDetector(
                              // TODO: REMOVE NATO SINCE AFTER MAGSELECT NG FILE AUTO READ NA SIYA
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C6AA0),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Upload',
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

  // Opens PDF file and read PDF to extract information
  Future<void> _openCOR(BuildContext context) async {
    // Init and check storage permission
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = await Permission.manageExternalStorage.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      Fluttertoast.showToast(
        msg: "Please enable the storage permission.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      openAppSettings();
      return;
    }

    // Select PDF file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    // If no PDF file is selected
    if (result == null || result.files.single.path == null) {
      // TODO: Replace Toast with UI update
      Fluttertoast.showToast(
        msg: "Please select your COR in PDF format",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      return;
    }

    // If PDF file is selected, get path
    final filePath = result.files.single.path!;
    debugPrint('Selected PDF: $filePath');

    // TODO: Replace Toast with UI update
    Fluttertoast.showToast(
      msg: "Reading your COR...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    //

    // Read PDF Process
    try {
      final text = await ReadPdfText.getPDFtext(filePath);
      final pdfText = text.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

      // Checks if COR is valid
      final hasStudentNo = RegExp(r'\b[ka]\d{8}\b', caseSensitive: false).hasMatch(pdfText);
      final hasUmakEmail = RegExp(r'\b[\w\.\-]+@umak\.edu\.ph\b').hasMatch(pdfText);
      final hasCollege = pdfText.contains('college of') ||  pdfText.contains('college');
      final hasProgram = pdfText.contains('program') || pdfText.contains('major');
      final hasYearLevel = pdfText.contains('year level');
      final hasSemester = pdfText.contains('semester');
      final currentYear = DateTime.now().year;
      final ayMatch = RegExp(r'(20\d{2})\s*-\s*(20\d{2})').firstMatch(pdfText);
      
      bool hasValidAY = false;
      // Checks if acad year is valid
      if (ayMatch != null) {
        final startYear = int.tryParse(ayMatch.group(1) ?? '');
        final endYear = int.tryParse(ayMatch.group(2) ?? '');
        if (startYear != null && endYear != null) {
          hasValidAY = (startYear == currentYear && endYear == currentYear + 1);
        }
      }

      if (!hasStudentNo || !hasUmakEmail || !hasCollege || !hasProgram || !hasYearLevel || !hasSemester || !hasValidAY) {
        Fluttertoast.showToast(
          msg: "Please upload an official UMak COR for A.Y. $currentYear-${currentYear + 1}.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        debugPrint('Rejected invalid COR: missing or invalid fields.');
        return;
      }

      // For terminal debugging
      debugPrint('--- Raw Extracted PDF Text ---');
      debugPrint(pdfText.substring(0, pdfText.length > 2000 ? 2000 : pdfText.length));

      // Extract NEEDED data === DON'T TOUCH PLZ ===
      final name = RegExp(r'name\s*:? ([a-z\s\.\-]+) student no').firstMatch(pdfText)?.group(1)?.trim();
      final studentNo = RegExp(r'student no\.?\s*:? ([a-z0-9\-]+)').firstMatch(pdfText)?.group(1)?.trim();
      final email = RegExp(r'email\s*:? ([\w\.\@]+)').firstMatch(pdfText)?.group(1)?.trim();
      final program = RegExp(r'program/?major\s*:? ([a-z\s\.\-]+) year level').firstMatch(pdfText)?.group(1)?.trim();
      var yearLevel = RegExp(r'year level\s*:? ([a-z0-9\s]+)').firstMatch(pdfText)?.group(1)?.trim();
      final college = RegExp(r'college\s*:? ([a-z\s]+) semester').firstMatch(pdfText)?.group(1)?.trim();
      var semester = RegExp(r'semester\s*&?\s*academic year\s*:? ([a-z0-9\s\.\-]+)').firstMatch(pdfText)?.group(1)?.trim();    
      final gender = RegExp(r'gender\s*:? ([a-z]+)').firstMatch(pdfText)?.group(1)?.trim();
      final section = RegExp(r'\b([ivx]{1,4}-[a-z]+)\b', caseSensitive: false).firstMatch(pdfText)?.group(1)?.toUpperCase().trim();


      // Format extracted information
      String capitalizeWords(String? input) {
        if (input == null || input.isEmpty) return '';
        return input
            .split(' ')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ')
            .trim();
      }

      String cleanSection(String? input) {
        if (input == null || input.isEmpty) return '';
        return input
            .replaceAll(RegExp(r'\s*-\s*'), '-')
            .toUpperCase()
            .trim();
      }

      final nameCap = capitalizeWords(name);
      final studentNoCap = studentNo?.toUpperCase() ?? '';
      final programCap = capitalizeWords(program);
      final collegeCap = capitalizeWords(college);
      final genderCap = capitalizeWords(gender);
      final sectionCap = cleanSection(section);

      if (yearLevel != null && yearLevel.contains('year')) {
        final idx = yearLevel.indexOf('year');
        yearLevel = yearLevel.substring(0, idx + 4).trim();
        yearLevel = capitalizeWords(yearLevel);
      }

      
      if (semester != null) {
        final match = RegExp(r'(20\d{2}-20\d{2})').firstMatch(semester);
        if (match != null) semester = semester.substring(0, match.end).trim();
        semester = semester.replaceAll(RegExp(r'a\.?y\.?', caseSensitive: false), 'A.Y.');
        semester = capitalizeWords(semester);
      }

      // Checks the information if legit
      // Checks if student no is A12345678 or K12345678
      final studentNoValid = RegExp(r'^[KA]\d{8}$', caseSensitive: false).hasMatch(studentNoCap);
      // Checks if email ends with @umak.edu.ph
      final emailValid = email != null && email.toLowerCase().endsWith('@umak.edu.ph');
      // Generic checking for other fields
      final hasEssentialData = nameCap.isNotEmpty && programCap.isNotEmpty && collegeCap.isNotEmpty && yearLevel != null && semester != null;

      if (!studentNoValid || !emailValid || !hasEssentialData) {
        // TODO: Replace Toast with UI update
        Fluttertoast.showToast(
          msg: "Invalid COR file. Please upload your official UMak COR.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        debugPrint('Invalid COR detected.');
        return;
      }

      // For terminal debugging
      debugPrint('--- Parsed COR Data ---');
      debugPrint('Name: $nameCap');
      debugPrint('Student No: $studentNoCap');
      debugPrint('Email: $email');
      debugPrint('Program: $programCap');
      debugPrint('College: $collegeCap');
      debugPrint('Year Level: $yearLevel');
      debugPrint('Section: $sectionCap');
      debugPrint('Semester: $semester');
      debugPrint('Gender: $genderCap');

      // Checks passed uid from registration_step2, step1, and login
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        Fluttertoast.showToast(
          msg: "User is not authenticated. Please log in again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      // Init database's users collection
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // Update fields in firestore firebase
      await userRef.set({
        'name': nameCap,
        'student_number': studentNoCap,
        'email': email,
        'program': programCap,
        'college': collegeCap,
        'year_level': yearLevel,
        'section': sectionCap,
        'semester': semester,
        'gender': genderCap,
        'lastUpdateCOR': DateTime.now(),
        'registerComplete': true,
      }, SetOptions(merge: true));

      // TODO: Replace Toast with UI update
      Fluttertoast.showToast(
        msg: "COR information updated successfully.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      
      // Move to next step, pass ONLY NEEDED information in next window and auto fill the fields on step4 :)))
      Navigator.pushReplacement(context,
        MaterialPageRoute(
          builder: (_) => RegistrationStep4(
            name: nameCap,
            college: collegeCap,
            yearLevel: yearLevel,
            semester: semester,
            section: sectionCap,
          ),
        ),
      );

    } catch (e) {
      debugPrint('Error reading COR: $e');
      // TODO: Replace Toast with UI update
      Fluttertoast.showToast(
        msg: "Failed to read COR PDF.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }