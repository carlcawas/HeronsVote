import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:heronsvote/services/model_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'reverify_step4.dart';
import 'package:image/image.dart' as img;

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
  
  // Liveness frames
  int _framesCollected = 0;
  static const int minFramesForLiveness = 2;

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
    print('[Reverify] Models loaded');
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);
    } catch (e) {
      _showError("Failed to initialize camera: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onCapturePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError("Camera not ready.");
      return;
    }
    if (_processing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("User not logged in.");
      return;
    }

    if (!_modelsReady) {
      _showError("Loading models. Please wait...");
      return;
    }

    setState(() => _processing = true);
    _framesCollected = 0;

    try {
      _modelHandler!.resetLiveness();
      _showSuccess('Please hold steady for 2 seconds...');
      await _collectFramesForLiveness();

      print('[Reverify] Capturing final image...');
      final XFile raw = await _cameraController!.takePicture();
      final File file = File(raw.path);

      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      
      if (decoded == null) {
        _showError("Failed to decode image.");
        return;
      }

      final inputImage = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showError("No face detected. Please face the camera directly.");
        return;
      }

      if (faces.length > 1) {
        _showError("Multiple faces detected. Please ensure only you are in the frame.");
        return;
      }

      final face = faces.first;
      final landmarks = face.landmarks.values.whereType<FaceLandmark>().toList();

      print('[Reverify] Running verification pipeline...');
      final result = await _modelHandler!.processRegistration(
        image: decoded,
        face: face,
        landmarks: landmarks,
      );

      if (!result.success) {
        _showError(result.message);
        print('[Reverify] Pipeline failed at ${result.stage}: ${result.message}');
        return;
      }

      print('[Reverify] Storing encrypted embedding...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'faceEmbeddingEncrypted': result.encryptedEmbedding,
        'faceEmbeddingVersion': 'facenet_512_v1',
        'faceEmbeddingEncryptedAt': FieldValue.serverTimestamp(),
        'reverifiedAt': FieldValue.serverTimestamp(),
      });

      try {
        await file.delete();
      } catch (_) {}

      _showSuccess('Face re-verified successfully!');

      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => RegistrationVerified(uid: user.uid),
        ),
      );
    } catch (e) {
      _showError("Failed to capture and process face: $e");
      try {
        await _cameraController?.resumePreview();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _processing = false);
      _framesCollected = 0;
    }
  }

  Future<void> _collectFramesForLiveness() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final stopwatch = Stopwatch()..start();
    const collectionDuration = Duration(milliseconds: 1000); // Reduced from 2000ms

    while (stopwatch.elapsed < collectionDuration) {
      try {
        final XFile raw = await _cameraController!.takePicture();
        final File file = File(raw.path);
        final imageBytes = await file.readAsBytes();
        final decoded = img.decodeImage(imageBytes);

        if (decoded == null) continue;

        final inputImage = InputImage.fromFile(file);
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final face = faces.first;
          final landmarks = face.landmarks.values.whereType<FaceLandmark>().toList();
          
          final livenessResult = await _modelHandler!.processFrameForLiveness(
            image: decoded,
            face: face,
            landmarks: landmarks,
          );

          _framesCollected = livenessResult.framesCollected ?? 0;
          
          if (livenessResult.isReadyForAnalysis && livenessResult.isLive) {
            break;
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('[Liveness] Frame collection error: $e');
      }
    }

    stopwatch.stop();
    print('[Liveness] Collection completed in ${stopwatch.elapsedMilliseconds}ms');
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
                                      text: "Re-verify ",
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
                                        _processing ? 'Processing...' : 'Capture',
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

// Step progress indicator widget (unchanged)
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
