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

  bool _isUploading = false;
  double _uploadProgress = 0;
  String _selectedFileName = "";
  bool _uploadComplete = false;
  String? _nameCap;
  String? _collegeCap;
  String? _yearLevel;
  String? _semester;
  String? _sectionCap;
  // Store the path of the selected PDF file
  String? _selectedFilePath;

  // --- Animation and Progress Methods ---

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

    //_panelController.forward();

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

  Future<void> _simulateProgress() async {
    setState(() {
      _uploadProgress = 0;
    });

    for (int i = 0; i <= 100; i++) {
      if (!_isUploading) return;
      await Future.delayed(const Duration(milliseconds: 25));
      if (mounted) {
        setState(() {
          _uploadProgress = i / 100;
        });
      }
    }

    if (mounted) {
      setState(() {
        _uploadComplete = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _cancelUpload() {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
      _uploadComplete = false;
      _selectedFileName = "";
      _selectedFilePath = null; // Clear the selected file path
    });
  }

  // --- Core File Upload and Processing Method ---

  Future<void> _handleCORUpload(BuildContext context) async {
    if (_isUploading) return; // Prevent multiple taps

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
      Fluttertoast.showToast(
        msg: "Please select your COR in PDF format",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;

    setState(() {
      _isUploading = true;
      _selectedFilePath = filePath;
      _selectedFileName = fileName;
      _uploadProgress = 1.0;
      _uploadComplete = false;
    });

    // Start UI progress simulation
    final progressFuture = _simulateProgress();

    // Start actual PDF reading and processing
    try {
      final text = await ReadPdfText.getPDFtext(filePath);
      final pdfText = text.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

      // Check for mandatory fields/data to validate COR
      final hasStudentNo = RegExp(
        r'\b[ka]\d{8}\b',
        caseSensitive: false,
      ).hasMatch(pdfText);
      final hasUmakEmail = RegExp(
        r'\b[\w\.\-]+@umak\.edu\.ph\b',
      ).hasMatch(pdfText);
      final hasCollege =
          pdfText.contains('college of') || pdfText.contains('college');
      final hasProgram =
          pdfText.contains('program') || pdfText.contains('major');
      final hasYearLevel = pdfText.contains('year level');
      final hasSemester = pdfText.contains('semester');
      final currentYear = DateTime.now().year;
      final ayMatch = RegExp(r'(20\d{2})\s*-\s*(20\d{2})').firstMatch(pdfText);

      bool hasValidAY = false;
      if (ayMatch != null) {
        final startYear = int.tryParse(ayMatch.group(1) ?? '');
        final endYear = int.tryParse(ayMatch.group(2) ?? '');
        if (startYear != null && endYear != null) {
          hasValidAY = (startYear == currentYear && endYear == currentYear + 1);
        }
      }

      if (!hasStudentNo ||
          !hasUmakEmail ||
          !hasCollege ||
          !hasProgram ||
          !hasYearLevel ||
          !hasSemester ||
          !hasValidAY) {
        // Validation failed, cancel upload status
        _cancelUpload();
        Fluttertoast.showToast(
          msg:
              "Please upload an official UMak COR for A.Y. $currentYear-${currentYear + 1}.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        debugPrint('Rejected invalid COR: missing or invalid fields.');
        return;
      }

      // Extract NEEDED data
      final name = RegExp(
        r'name\s*:? ([a-z\s\.\-]+) student no',
      ).firstMatch(pdfText)?.group(1)?.trim();
      final studentNo = RegExp(
        r'student no\.?\s*:? ([a-z0-9\-]+)',
      ).firstMatch(pdfText)?.group(1)?.trim();
      final email = RegExp(
        r'email\s*:? ([\w\.\@]+)',
      ).firstMatch(pdfText)?.group(1)?.trim();
      final program = RegExp(
        r'program/?major\s*:? ([a-z\s\.\-]+) year level',
      ).firstMatch(pdfText)?.group(1)?.trim();
      var yearLevel = RegExp(
        r'year level\s*:? ([a-z0-9\s]+)',
      ).firstMatch(pdfText)?.group(1)?.trim();
      final college = RegExp(
        r'college\s*:? ([a-z\s]+) semester',
      ).firstMatch(pdfText)?.group(1)?.trim();
      var semester = RegExp(
        r'semester\s*&?\s*academic year\s*:? ([a-z0-9\s\.\-]+)',
      ).firstMatch(pdfText)?.group(1)?.trim();
      final gender = RegExp(
        r'gender\s*:? ([a-z]+)',
      ).firstMatch(pdfText)?.group(1)?.trim();
      final section = RegExp(
        r'\b([ivx]{1,4}-[a-z]+)\b',
        caseSensitive: false,
      ).firstMatch(pdfText)?.group(1)?.toUpperCase().trim();

      // Format extracted information
      String capitalizeWords(String? input) {
        if (input == null || input.isEmpty) return '';
        return input
            .split(' ')
            .map(
              (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ')
            .trim();
      }

      String cleanSection(String? input) {
        if (input == null || input.isEmpty) return '';
        return input.replaceAll(RegExp(r'\s*-\s*'), '-').toUpperCase().trim();
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
        semester = semester.replaceAll(
          RegExp(r'a\.?y\.?', caseSensitive: false),
          'A.Y.',
        );
        semester = capitalizeWords(semester);
      }

      // Final Data Validation
      final studentNoValid = RegExp(
        r'^[KA]\d{8}$',
        caseSensitive: false,
      ).hasMatch(studentNoCap);
      final emailValid =
          email != null && email.toLowerCase().endsWith('@umak.edu.ph');
      final hasEssentialData =
          nameCap.isNotEmpty &&
          programCap.isNotEmpty &&
          collegeCap.isNotEmpty &&
          yearLevel != null &&
          semester != null;

      if (!studentNoValid || !emailValid || !hasEssentialData) {
        _cancelUpload();
        Fluttertoast.showToast(
          msg: "Invalid COR file. Please upload your official UMak COR.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        debugPrint('Invalid COR detected.');
        return;
      }

      // Wait for progress simulation matapos
      await progressFuture;
      if (!_isUploading) return; // Check if cancelled during waiting

      // Database Update
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _cancelUpload();
        Fluttertoast.showToast(
          msg: "User is not authenticated. Please log in again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

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
        'registerComplete': false, // complete step 4
      }, SetOptions(merge: true));

      Fluttertoast.showToast(
        msg: "COR information processed successfully. Proceeding to next step.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );

      // Successfully processed, now navigate

      // Reset upload state after successful navigation/completion
      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _uploadComplete = true;
        _nameCap = nameCap;
        _collegeCap = collegeCap;
        _yearLevel = yearLevel;
        _semester = semester;
        _sectionCap = sectionCap;
      });
    } catch (e) {
      debugPrint('Error handling COR: $e');
      _cancelUpload();
      Fluttertoast.showToast(
        msg: "Failed to read or process COR PDF.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //is active colors
    final isButtonActive = !_isUploading && !_uploadComplete;
    final buttonColor = isButtonActive
        ? const Color(0xFF5C6AA0)
        : const Color(0xFF5C6AA0);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Center(child: StepProgressIndicator(currentStep: 1)),
            const SizedBox(height: 10),

            Expanded(
              child: Stack(
                children: [
                  Hero( // <--- 1. ADD THE HERO WIDGET
                    tag: 'bluePanel', // <--- 2. USE THE SAME TAG
                    child: Material (
                      type: MaterialType.transparency, // avoids text flash
                      child: Container( // <--- Container is the child of Hero
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
                      bottom: 50,
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

                            // File selection box
                            // File selection box
                          Material(
                            color: const Color(0xFF5C6AA0),      // <--- Keep color here
                            borderRadius: BorderRadius.circular(30), // <--- Keep radius here
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30), // Match radius for ripple
                              onTap: isButtonActive
                                  ? () => _handleCORUpload(context)
                                  : null,
                              child: Container(
                                height: 238,
                                // 👇 Add decoration back to Container, but ONLY for the border
                                decoration: BoxDecoration(
                                  // Color is handled by Material now
                                  borderRadius: BorderRadius.circular(30), // Keep radius for shape
                                  border: Border.all( // Add border back here
                                    color: const Color(0xFFFFEB66),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.file_present_rounded,
                                    color: Color(0xFFF9F2D7),
                                    size: 26,
                                  ),
                                ),
                              ), // <-- Container ends
                            ), // <-- InkWell ends
                          ), // <-- Material ends

                            if (_isUploading || _uploadComplete)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF354372),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //file icon
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: Color(0xFFF9F2D7),
                                      size: 30,
                                    ),
                                    const SizedBox(width: 21),
                                    // Middle column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          //top row
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedFileName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Geist',
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${(_uploadProgress * 100).toInt()}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontFamily: 'Geist',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Progress bar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: _uploadProgress,
                                              minHeight: 6,
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 26),
                                    if (_selectedFilePath != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 5,
                                        ), 
                                        child: GestureDetector(
                                          onTap: _cancelUpload,
                                          child: const Icon(
                                            Icons.close,
                                            color: Color(0xFFF3C8C8),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                            const Spacer(),
                            Center(
                              child: Opacity(
                                opacity: (_uploadComplete || isButtonActive) ? 1.0 : 0.5,
                                child: Material(
                                  color: (_uploadComplete || isButtonActive) ? const Color(0xFF5C6AA0) : Colors.grey,
                                  borderRadius: BorderRadius.circular(40),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(40),
                                    onTap: _uploadComplete
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => RegistrationStep4(
                                                  uid: widget.uid,
                                                  name: _nameCap!,
                                                  college: _collegeCap!,
                                                  yearLevel: _yearLevel!,
                                                  semester: _semester!,
                                                  section: _sectionCap!,
                                                ),
                                              ),
                                            );
                                          }
                                        : isButtonActive
                                        ? () => _handleCORUpload(context)
                                        : null,
                                    child: SizedBox(
                                      height: 56,
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          _uploadComplete ? 'Proceed' : 'Upload COR',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      )
                                    )
                                  )
                                ),
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ]
              )
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
