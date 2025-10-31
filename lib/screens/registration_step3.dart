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
  String? _uploadErrorMessage;

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
      _selectedFilePath = null;
    });
  }

  // --- Core File Upload and Processing Method ---
  Future<void> _handleCORUpload(BuildContext context) async {
    if (_isUploading) return; // Prevent multiple taps

    // Clear previous error and reset visible file state before starting
    setState(() {
      _uploadErrorMessage = null;
      _selectedFileName = '';
      _selectedFilePath = null;
      _uploadProgress = 0;
      _uploadComplete = false;
    });

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

    if (result == null || result.files.single.path == null) {
      return; // user cancelled
    }

    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;
    final fileSize = File(filePath).lengthSync();

    // File size validation
    if (fileSize > 5 * 1024 * 1024) {
      setState(() {
        _uploadErrorMessage = "Max file size reached.";
        _selectedFilePath = null;
      });
      return;
    }

    // Save selected file and start upload UI
    setState(() {
      _isUploading = true;
      _selectedFilePath = filePath;
      _selectedFileName = fileName;
      _uploadProgress = 0;
      _uploadComplete = false;
      _uploadErrorMessage = null;
    });

    final progressFuture = _simulateProgress();

    try {
      final text = await ReadPdfText.getPDFtext(filePath);
      final pdfText = text.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

      // --- COR validation fields ---
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

      // --- Academic Year Validation ---
      final currentYear = DateTime.now().year;
      final ayMatch = RegExp(r'(20\d{2})\s*-\s*(20\d{2})').firstMatch(pdfText);
      bool hasValidAY = false;
      if (ayMatch != null) {
        final startYear = int.tryParse(ayMatch.group(1) ?? '');
        final endYear = int.tryParse(ayMatch.group(2) ?? '');
        if (startYear != null && endYear != null) {
          hasValidAY =
              (startYear == currentYear || startYear == currentYear + 1);
        }
      }

      if (!hasStudentNo ||
          !hasUmakEmail ||
          !hasCollege ||
          !hasProgram ||
          !hasYearLevel ||
          !hasSemester) {
        _cancelUpload();
        setState(() {
          _uploadErrorMessage = "This is not a University COR";
        });
        return;
      }

      if (!hasValidAY) {
        _cancelUpload();
        setState(() {
          _uploadErrorMessage = "This is an outdated COR";
        });
        return;
      }

      // --- Extract student info ---
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

      // --- Formatting helpers ---
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

      // --- Final Data Validation ---
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
        setState(() {
          _uploadErrorMessage =
              "Invalid COR details. Please upload a valid University COR.";
        });
        return;
      }

      // Wait for progress simulation to finish
      await progressFuture;
      if (!_isUploading) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _cancelUpload();
        setState(() {
          _uploadErrorMessage =
              "An error has occurred. Please try uploading again.";
        });
        return;
      }

      // Save extracted info to Firestore
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
        'registerComplete': false,
      }, SetOptions(merge: true));

      // Enable button
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

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
      setState(() {
        _uploadErrorMessage =
            "An error has occurred while reading your COR. Please try again.";
      });
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
            const Center(child: StepProgressIndicator(currentStep: 1)),
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
                          GestureDetector(
                            onTap: isButtonActive
                                ? () => _handleCORUpload(context)
                                : null,
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
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.file_present_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Tap here to upload your COR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Max file size 5mb.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_isUploading ||
                              _uploadComplete ||
                              _uploadErrorMessage != null)
                            AnimatedOpacity(
                              opacity:
                                  (_selectedFilePath != null ||
                                      _uploadErrorMessage != null)
                                  ? 1.0
                                  : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 24,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 25,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF44558F),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // left: file icon
                                    const Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),

                                    // center: message + error icon grouped tightly
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _uploadErrorMessage != null
                                            ? Row(
                                                mainAxisSize: MainAxisSize
                                                    .min, // <-- group only as wide as needed
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // message (flexible, will ellipsize/wrap)
                                                  Flexible(
                                                    child: Text(
                                                      _uploadErrorMessage!,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Geist',
                                                        fontSize: 14,
                                                        height: 1.2,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      softWrap: true,
                                                    ),
                                                  ),

                                                  // tiny gap, icon directly beside message
                                                  const SizedBox(width: 4),

                                                  Image.asset(
                                                    'assets/error_icon.png',
                                                    width: 18,
                                                    height: 18,
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          _selectedFileName,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Geist',
                                                                fontSize: 12,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${(_uploadProgress * 100).toInt()}%',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontFamily: 'Geist',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: LinearProgressIndicator(
                                                      value: _uploadProgress,
                                                      minHeight: 6,
                                                      backgroundColor:
                                                          Colors.white24,
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFilePath = null;
                                          _uploadErrorMessage = null;
                                          _isUploading = false;
                                          _uploadProgress = 0;
                                          _uploadComplete = false;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Color(0xFFF3C8C8),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const Spacer(),
                          Center(
                            child: GestureDetector(
                              onTap: _uploadComplete
                                  ? () {
                                      if (_nameCap != null &&
                                          _collegeCap != null &&
                                          _yearLevel != null &&
                                          _semester != null &&
                                          _sectionCap != null) {
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
                                    }
                                  : null,
                              child: Container(
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF5C6AA0,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Center(
                                  child: Text(
                                    'Proceed',
                                    style: TextStyle(
                                      color: _uploadComplete
                                          ? Colors.white
                                          : Colors.white60,
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