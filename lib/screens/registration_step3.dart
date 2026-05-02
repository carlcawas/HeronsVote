import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:heronsvote/services/model_handler.dart';
import '../screens/registration_verified.dart';

const int MODEL_INPUT_SIZE = 160;

class _CapturedFaceFrame {
  final File file;
  final img.Image image;
  final Face face;
  final List<FaceLandmark> landmarks;
  final double score;

  _CapturedFaceFrame({
    required this.file,
    required this.image,
    required this.face,
    required this.landmarks,
    required this.score,
  });
}

class _BurstRegistrationResult {
  final _CapturedFaceFrame? frame;
  final RegistrationPipelineResult pipelineResult;

  _BurstRegistrationResult({
    required this.frame,
    required this.pipelineResult,
  });
}

class RegistrationStep3 extends StatefulWidget {
  final String? uid;
  const RegistrationStep3({super.key, required this.uid});

  @override
  State<RegistrationStep3> createState() => _RegistrationStep3State();
}

class _RegistrationStep3State extends State<RegistrationStep3>
    with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  // Pipeline components
  ModelHandler? _modelHandler;
  bool _modelsReady = false;
  
  // Camera
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _processing = false;
  late final FaceDetector _faceDetector;
  
  // Progress counter for burst processing
  int _framesCollected = 0;
  static const int minFramesForLiveness = 3;

  @override
  void initState() {
    super.initState();
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

    _panelController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentController.forward();
    });

    // Initialize face detector with landmarks
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableTracking: false,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);

    _initCameraAndPermission();
    _initializeModels();
  }

  @override
  void dispose() {
    _panelController.dispose();
    _contentController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    _modelHandler?.dispose();
    super.dispose();
  }

  Future<void> _initializeModels() async {
    _modelHandler = ModelHandler();
    await _modelHandler!.loadModels();
    if (!mounted) return;
    setState(() => _modelsReady = true);
    print('[Registration] Models loaded, ready for capture');
  }

  Future<void> _saveRegisterStep() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.set({'registration_step': 3}, SetOptions(merge: true));
  }

  Future<void> _initCameraAndPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        _showError("Camera permission is required to capture your face.");
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.high, // Higher resolution for better quality
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Better for processing
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);
      print('[Registration] Camera initialized');
    } catch (e) {
      _showError("Failed to initialize camera: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _toUserFriendlyError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('multiple face')) return 'Only one face should be in the view.';
    if (msg.contains('no face')) return 'No face found. Please face the camera directly.';
    if (msg.contains('cover') || msg.contains('occl')) return 'Captured face is partially covered.';
    if (msg.contains('angle') || msg.contains('yaw') || msg.contains('pitch')) return 'Please face the camera straight.';
    if (msg.contains('blur') || msg.contains('sharp')) return 'Image is blurry. Please be steady.';
    if (msg.contains('light') || msg.contains('dark') || msg.contains('exposure')) return 'Lighting is too low. Please move to a brighter place.';
    if (msg.contains('stability') || msg.contains('movement')) return 'Too much movement. Please hold your phone steady.';
    if (msg.contains('smile')) return 'Please smile and try again.';
    if (msg.contains('camera not ready')) return 'Camera is not ready yet.';
    if (msg.contains('user not logged')) return 'Please log in again.';
    if (msg.contains('loading validation models')) return 'Please wait a moment and try again.';
    if (msg.contains('failed to process face')) return 'Could not read your face. Try again.';
    return 'Face check failed. Please try again.';
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAcceptedFacePreview(File imageFile) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Registered Face Preview',
            style: TextStyle(color: Colors.white, fontFamily: 'Geist', fontSize: 16),
          ),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 220,
                height: 260,
                child: Center(
                  child: Text(
                    'Preview unavailable.',
                    style: TextStyle(color: Colors.white70, fontFamily: 'Geist'),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontFamily: 'Geist'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // MAIN CAPTURE AND PROCESSING FLOW
  // ============================================
  Future<void> _onCapturePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError(_toUserFriendlyError("camera not ready"));
      return;
    }

    if (_processing) {
      print('[Registration] Already processing, ignoring tap');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError(_toUserFriendlyError("user not logged in"));
      return;
    }

    if (!_modelsReady) {
      _showError(_toUserFriendlyError("loading validation models"));
      return;
    }

    setState(() => _processing = true);
    _framesCollected = 0;

    try {
      // Reset liveness state for this session.
      _modelHandler!.resetLiveness();

      // Fast check: capture 3 frames and require at least 2 successful analyses.
      final captureResult = await _captureAndAnalyzeBurst(
        attempts: 3,
        minSuccessRequired: 2,
      );
      if (captureResult == null || !captureResult.pipelineResult.success) {
        final msg = _toUserFriendlyError(
          captureResult?.pipelineResult.message ??
              "Face capture failed. Keep your face centered and try again.",
        );
        _showError(msg);
        return;
      }
      final result = captureResult.pipelineResult;
      final acceptedFile = captureResult.frame?.file;

      // Handle pipeline result
      if (!result.success) {
        _showError(_toUserFriendlyError(result.message));
        print('[Registration] Pipeline failed at ${result.stage}: ${result.message}');
        
        // Show detailed feedback if available
        if (result.qualityResult != null && !result.qualityResult!.isOverallQualityOk) {
          print('[Registration] Quality feedback: ${result.qualityResult!.getFeedback()}');
        }
        if (result.livenessResult != null) {
          print('[Registration] Liveness: ${result.livenessResult!.message}');
        }
        return;
      }

      // SUCCESS: Store encrypted embedding to Firebase
      print('[Registration] Storing encrypted embedding to Firebase...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'faceEmbeddingEncrypted': result.encryptedEmbedding,
        'faceEmbeddingVersion': 'facenet_512_v1',
        'faceEmbeddingEncryptedAt': FieldValue.serverTimestamp(),
        'registrationCompletedAt': FieldValue.serverTimestamp(),
      });

      print('[Registration] Registration completed successfully!');
      _showSuccess('Face registered successfully!');

      if (acceptedFile != null && await acceptedFile.exists()) {
        await _showAcceptedFacePreview(acceptedFile);
      }

      // Cleanup
      if (captureResult.frame != null) {
        try {
          await captureResult.frame!.file.delete();
        } catch (_) {}
      }

      // Navigate to success screen
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => RegistrationVerified(uid: user.uid),
        ),
      );

    } catch (e) {
      print('[Registration] ERROR: $e');
      _showError(_toUserFriendlyError("failed to process face"));
    } finally {
      if (mounted) setState(() => _processing = false);
      _framesCollected = 0;
    }
  }

  Future<_BurstRegistrationResult?> _captureAndAnalyzeBurst({
    int attempts = 5,
    int minSuccessRequired = 3,
  }) async {
    _BurstRegistrationResult? bestSuccess;
    RegistrationPipelineResult? lastFailure;
    int successCount = 0;
    final Map<String, int> failureCounts = {};
    Offset? previousCenter;
    int unstableTransitions = 0;
    int stableFrameCount = 0;

    for (int i = 0; i < attempts; i++) {
      final frame = await _captureFaceFrame();
      _framesCollected = i + 1;
      if (mounted) setState(() {});

      if (frame == null) {
        await Future.delayed(const Duration(milliseconds: 90));
        continue;
      }

      // Anti-shake: measure sudden center movement between captured frames.
      final bbox = frame.face.boundingBox;
      final center = Offset(
        bbox.left + (bbox.width / 2.0),
        bbox.top + (bbox.height / 2.0),
      );
      if (previousCenter != null) {
        final dx = center.dx - previousCenter!.dx;
        final dy = center.dy - previousCenter!.dy;
        final movement = math.sqrt((dx * dx) + (dy * dy));
        final diagonal = math.sqrt(
          (frame.image.width * frame.image.width) +
              (frame.image.height * frame.image.height),
        );
        final normalizedMovement = diagonal == 0 ? 0.0 : movement / diagonal;
        if (normalizedMovement > 0.16) {
          unstableTransitions++;
        } else {
          stableFrameCount++;
        }
      } else {
        stableFrameCount++;
      }
      previousCenter = center;

      final RegistrationPipelineResult result = await _modelHandler!.processRegistration(
        image: frame.image,
        face: frame.face,
        landmarks: frame.landmarks,
        skipLivenessCheck: true,
      );

      if (result.success) {
        successCount++;
        if (bestSuccess == null || frame.score > bestSuccess.frame!.score) {
          if (bestSuccess != null) {
            try {
              await bestSuccess.frame!.file.delete();
            } catch (_) {}
          }
          bestSuccess = _BurstRegistrationResult(
            frame: frame,
            pipelineResult: result,
          );
        } else {
          try {
            await frame.file.delete();
          } catch (_) {}
        }
      } else {
        lastFailure = result;
        failureCounts[result.message] = (failureCounts[result.message] ?? 0) + 1;
        try {
          await frame.file.delete();
        } catch (_) {}
      }

      await Future.delayed(const Duration(milliseconds: 90));
    }

    if (bestSuccess != null &&
        successCount >= minSuccessRequired) {
      if (unstableTransitions > 0 && stableFrameCount < minSuccessRequired) {
        return _BurstRegistrationResult(
          frame: null,
          pipelineResult: RegistrationPipelineResult(
            success: false,
            stage: 'stability_check',
            message: 'Camera movement is too high. Keep the phone steady and face the camera directly.',
          ),
        );
      }
      return bestSuccess;
    }

    if (unstableTransitions >= 2) {
      return _BurstRegistrationResult(
        frame: null,
        pipelineResult: RegistrationPipelineResult(
          success: false,
          stage: 'stability_check',
          message: 'Camera movement is too high. Keep the phone steady and face the camera directly.',
        ),
      );
    }

    if (failureCounts.isNotEmpty) {
      String topMessage = failureCounts.entries.first.key;
      int topCount = failureCounts.entries.first.value;
      for (final entry in failureCounts.entries) {
        if (entry.value > topCount) {
          topMessage = entry.key;
          topCount = entry.value;
        }
      }
      return _BurstRegistrationResult(
        frame: null,
        pipelineResult: RegistrationPipelineResult(
          success: false,
          stage: 'frame_validation',
          message: topMessage,
        ),
      );
    }

    if (lastFailure != null) {
      return _BurstRegistrationResult(frame: null, pipelineResult: lastFailure);
    }

    return _BurstRegistrationResult(
      frame: null,
      pipelineResult: RegistrationPipelineResult(
        success: false,
        stage: 'burst_capture',
        message: 'No valid face frame captured. Ensure your face is visible and directed to the camera.',
      ),
    );
  }

  Future<_CapturedFaceFrame?> _captureFaceFrame() async {
    try {
      final XFile raw = await _cameraController!.takePicture();
      final file = File(raw.path);
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }

      final inputImage = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.length != 1) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }

      final face = faces.first;
      final landmarks = face.landmarks.values.whereType<FaceLandmark>().toList();
      final score = _scoreFace(face, decoded);
      return _CapturedFaceFrame(
        file: file,
        image: decoded,
        face: face,
        landmarks: landmarks,
        score: score,
      );
    } catch (_) {
      return null;
    }
  }

  double _scoreFace(Face face, img.Image image) {
    final box = face.boundingBox;
    final imageArea = math.max(1, image.width * image.height).toDouble();
    final faceArea = math.max(1, box.width * box.height).toDouble();
    final areaRatio = (faceArea / imageArea).clamp(0.0, 1.0);

    final centerX = box.left + (box.width / 2.0);
    final centerY = box.top + (box.height / 2.0);
    final distToCenter = math.sqrt(
      math.pow(centerX - (image.width / 2.0), 2) +
          math.pow(centerY - (image.height / 2.0), 2),
    );
    final maxDist = math.sqrt(
      math.pow(image.width / 2.0, 2) + math.pow(image.height / 2.0, 2),
    );
    final centerScore = (1.0 - (distToCenter / maxDist)).clamp(0.0, 1.0);

    final yawPenalty = ((face.headEulerAngleY ?? 0.0).abs() / 45.0).clamp(0.0, 1.0);
    final pitchPenalty = ((face.headEulerAngleX ?? 0.0).abs() / 35.0).clamp(0.0, 1.0);
    final yawPitchScore = (1.0 - ((yawPenalty + pitchPenalty) / 2.0)).clamp(0.0, 1.0);

    final leftEye = (face.leftEyeOpenProbability ?? 0.6).clamp(0.0, 1.0);
    final rightEye = (face.rightEyeOpenProbability ?? 0.6).clamp(0.0, 1.0);
    final eyeScore = ((leftEye + rightEye) / 2.0).clamp(0.0, 1.0);

    return (areaRatio * 0.35) +
        (centerScore * 0.30) +
        (yawPitchScore * 0.25) +
        (eyeScore * 0.10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F2D7),

      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFF9F2D7),
        elevation: 0,
        leading: Hero(
          tag: 'appBarBackButton',
          child: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF404040),
                size: 24,
              ),
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
            const SizedBox(height: 0),

            const Center(
              child: Hero(
                tag: 'HeroStepProgressIndicator',
                child: Material(
                  type: MaterialType.transparency,
                  child: StepProgressIndicator(currentStep: 3),
                ),
              ),
            ),

            const SizedBox(height: 0),
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
                      left: 25,
                      right: 25,
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
                                    TextSpan(
                                      text: "Verify student ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Face",
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
                            const SizedBox(height: 32),
                            Container(
                              height: 350,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6AA0),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFFFEB66),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: _cameraInitialized && _cameraController != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _cameraController!.value.previewSize?.height ?? 100,
                                              height: _cameraController!.value.previewSize?.width ?? 100,
                                              child: CameraPreview(_cameraController!),
                                            ),
                                          ),
                                          if (_processing)
                                            Positioned.fill(
                                              child: Container(
                                                color: Colors.black.withOpacity(0.4),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      _framesCollected >= minFramesForLiveness
                                                          ? 'Analyzing...'
                                                          : 'Collecting frames ($_framesCollected/$minFramesForLiveness)',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          // Face overlay guide
                                          if (!_processing)
                                            Center(
                                              child: Container(
                                                width: 200,
                                                height: 250,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.5),
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                              ),
                                            ),
                                        ],
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Material(
                                color: const Color(0xFF5C6AA0),
                                borderRadius: BorderRadius.circular(40),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(40),
                                  onTap: _processing ? null : _onCapturePressed,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: Center(
                                      child: Text(
                                        _processing
                                            ? 'Processing...'
                                            : 'Capture',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Geist',
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

// Progress step indicator widget
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

    int totalIntervals = totalSteps - 1;

    double progressValue;
    if (currentStep >= totalSteps) {
      progressValue = 1.0;
    } else {
      progressValue = ((currentStep - 1) + 0.5) / totalIntervals;
    }

    return SizedBox(
      width: 254,
      height: outerCircleSize,
      child: Stack(
        children: [
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: outerCircleSize / 2),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(activeColor),
                    minHeight: 2,
                  ),
                ),
              ),
            ),
          ),

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
                      color: (isActive || isCompleted) ? activeColor : inactiveColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: checkIconColor)
                          : Text(
                              '$stepNumber',
                              style: TextStyle(
                                color: isActive ? Colors.white : const Color(0xFF404040),
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
