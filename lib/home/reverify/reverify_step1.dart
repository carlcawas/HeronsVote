import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'reverify_step2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:heronsvote/home/header.dart';
import 'package:heronsvote/services/cor_ocr_parser.dart';

class RegistrationStep1 extends StatefulWidget {
  final String uid;
  const RegistrationStep1({super.key, required this.uid});

  @override
  State<RegistrationStep1> createState() => _RegistrationStep1State();
}

class _RegistrationStep1State extends State<RegistrationStep1>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;

  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  bool _isUploading = false;
  double _uploadProgress = 0;
  String _selectedFileName = "";
  bool _uploadComplete = false;
  String? _nameCap;
  String? _collegeCap;
  String? _collegeId;
  String? _yearLevel;
  String? _semester;
  String? _sectionCap;

  // Store the path of the selected PDF file
  String? _selectedFilePath;
  String? _uploadErrorMessage;

  // colors
  final Color _dashedBorderColor = const Color(0xFF5C6AA0);
  // --- Animation and Progress Methods ---
  @override
  void initState() {
    super.initState();
    // Save user's registration step
    _saveRegisterStep();

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

  Future<void> _saveRegisterStep() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({'registration_step': 1}, SetOptions(merge: true));
  }

  Future<void> _simulateProgress() async {
    setState(() {
      _uploadProgress = 0;
    });

    for (int i = 0; i <= 100; i++) {
      if (!_isUploading) return;
      await Future.delayed(const Duration(milliseconds: 10));
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
      _uploadErrorMessage = null;
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
      if (await Permission.manageExternalStorage.status.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.manageExternalStorage.request();
      }
      
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }
    
    // checks if permission is not granted
    if (!status.isGranted) {
      if (!mounted) return; 

      // SnackBar with a button to open settings manually
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "File access is required to upload your COR.",
            style: TextStyle(fontFamily: 'Geist'),
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
      
      // Reset uploading state
      setState(() {
        _isUploading = false;
      });
      return;
    }

    // Select PDF file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      setState(() { _isUploading = false; });
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
      CorOcrParseResult parsed;
      try {
        parsed = CorOcrParser.parse(
          text,
          currentYear: DateTime.now().year,
        );
      } on CorOcrParseException catch (e) {
        _cancelUpload();
        setState(() {
          if (e.type == CorOcrParseError.notUniversityCor) {
            _uploadErrorMessage = "This is not a University COR";
          } else if (e.type == CorOcrParseError.outdatedCor) {
            _uploadErrorMessage = "This is an outdated COR";
          } else {
            _uploadErrorMessage =
                "Invalid COR details. Please upload a valid University COR.";
          }
        });
        return;
      }

      final nameCap = parsed.name;
      final studentNoCap = parsed.studentNo;
      final email = parsed.email;
      final programCap = parsed.program;
      final collegeCap = parsed.college;
      final collegeId = findCollegeIdFromOCR(collegeCap);
      final yearLevel = parsed.yearLevel;
      final semester = parsed.semester;
      final genderCap = parsed.gender;
      final sectionCap = parsed.section;

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
        'college_id': collegeId,
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
        _collegeId = collegeId;
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

  // College mapping
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

  // Abbreviate college as id
  String? findCollegeIdFromOCR(String? collegeText) {
    if (collegeText == null || collegeText.isEmpty) return null;

    String normalized = collegeText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();

    // contains match
    for (final entry in collegeMap.entries) {
      final fullName = entry.value.toLowerCase();
      if (normalized.contains(fullName) || fullName.contains(normalized)) {
        return entry.key;
      }
    }

    // Partial word match (>=60% match)
    for (final entry in collegeMap.entries) {
      final parts = entry.value.toLowerCase().split(' ');
      int matches = parts.where((p) => normalized.contains(p)).length;
      if (matches >= (parts.length * 0.6)) return entry.key;
    }

    // Fuzzy match (Levenshtein)
    String? bestMatchId;
    double bestScore = double.infinity;

    for (final entry in collegeMap.entries) {
      final distance = levenshtein(normalized, entry.value.toLowerCase());
      if (distance < bestScore) {
        bestScore = distance.toDouble();
        bestMatchId = entry.key;
      }
    }

    // Accept fuzzy match if distance is small enough relative to string length
    if (bestScore <= (normalized.length * 0.3)) {
      return bestMatchId;
    }

    return null;
  }

  // for easier college to abbreviation matching
  int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[t.length];
  }

  @override
  Widget build(BuildContext context) {
    final isButtonActive = !_isUploading && !_uploadComplete;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFFFF),

      
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(
              title: "COR Verification", 
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 22),
            const Center(
              child: Hero(
                tag: 'HeroStepProgressIndicator',
                child: Material(
                  type: MaterialType.transparency,
                  child: StepProgressIndicator(currentStep: 1),
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
                      bottom: 47,
                    ),
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 22),
                            // File selection box
                            Material(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: isButtonActive
                                    ? () => _handleCORUpload(context)
                                    : null,

                                child: CustomPaint(
                                  painter: _DashedBorderPainter(
                                    color: _dashedBorderColor,
                                    strokeWidth: 2.0,
                                    radius: 28.0,
                                    dashPattern: [6, 4],
                                  ),

                                  child: Container(
                                    height: 240,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      /*border: Border.all(
                                        color: const Color(0xFFFFEB66),
                                        width: 2,
                                      ),*/
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 74,
                                          left: 0,
                                          right: 0,
                                          child: const Icon(
                                            Icons.file_present_rounded,
                                            color: Color(0xFF404040),
                                            size: 26,
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 74,
                                          child: Column(
                                            children: [
                                              Text(
                                                'Tap here to upload your COR',
                                                style: TextStyle(
                                                  color: Color(0xFF404040),
                                                  fontSize: 14,
                                                  fontFamily: 'Geist',
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Max file size 5mb.',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF747474,
                                                  ),
                                                  fontSize: 12,
                                                  fontFamily: 'Geist',
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Upload status container
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
                                    vertical: 20,
                                    horizontal: 22,
                                  ),
                                  //padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        color: Color(0xFF404040),
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _uploadErrorMessage != null
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        _uploadErrorMessage!,
                                                        style: const TextStyle(
                                                         color: Color(0xFF404040),
                                                          fontFamily: 'Geist',
                                                          fontSize: 12,
                                                          //height: 1.2,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        softWrap: true,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    SvgPicture.asset(
                                                      'assets/error.svg',
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Expanded(
                                                          child: Transform.translate(
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  -1,
                                                                ),
                                                            child: Text(
                                                              _selectedFileName,
                                                              style:
                                                                  const TextStyle(
                                                                   color: Color(0xFF404040),
                                                                    fontFamily:
                                                                        'Geist',
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),

                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Transform.translate(
                                                          offset: const Offset(
                                                            0,
                                                            -1,
                                                          ),
                                                          child: Text(
                                                            '${(_uploadProgress * 100).toInt()}%',
                                                            style:
                                                                const TextStyle(
                                                                  color: Color(0xFF404040),
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  fontFamily:
                                                                      'Geist',
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 0),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFAAB3D0,
                                                          ),
                                                          width: 3.0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                        child: LinearProgressIndicator(
                                                          value:
                                                              _uploadProgress,
                                                          minHeight: 3,
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFFFFFFF,
                                                              ),
                                                          valueColor:
                                                              const AlwaysStoppedAnimation<
                                                                Color
                                                              >(const Color(
                                                                0xFF5C6AA0,
                                                              ),),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: _cancelUpload,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFAAB3D0),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Color(0xFF404040),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const Spacer(),
                            Center(
                              child: Opacity(
                                opacity: _uploadComplete ? 1.0 : 0.5,

                                child: Material(
                                  color: const Color(0xFF5C6AA0),
                                  borderRadius: BorderRadius.circular(40),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: _uploadComplete
                                        ? () {
                                            if (_nameCap != null &&
                                                _collegeCap != null &&
                                                _collegeId != null &&
                                                _yearLevel != null &&
                                                _semester != null &&
                                                _sectionCap != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      RegistrationStep2(
                                                        uid: widget.uid,
                                                        name: _nameCap!,
                                                        college: _collegeCap!,
                                                        collegeId: _collegeId!,
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
            padding: const EdgeInsets.symmetric(
              horizontal: outerCircleSize / 2,
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: Container(
                  // <-- Add Container for the border
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: inactiveColor, //border color
                      width: 2.0,
                    ),
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

//dashed line
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final List<double> dashPattern;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.radius = 0.0,
    this.dashPattern = const [5, 3],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    // Logic to draw dashed path
    final Path dashedPath = Path();
    double distance = 0.0;
    final PathMetrics pathMetrics = path.computeMetrics();

    for (final PathMetric pathMetric in pathMetrics) {
      while (distance < pathMetric.length) {
        final double length = dashPattern[0];
        final double gap = dashPattern.length > 1 ? dashPattern[1] : length;

        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        radius != oldDelegate.radius;
  }
}
