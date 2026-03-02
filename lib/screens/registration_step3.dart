import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_verified.dart';
import 'package:image/image.dart' as img;
import 'package:heronsvote/services/model_handler.dart';

const int MODEL_INPUT_SIZE = 160;
const double MIN_EYE_DISTANCE = 25.0;

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

  // Model Handler
  late final ModelHandler _modelHandler;
  bool _modelsReady = false;

  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _processing = false;
  late final FaceDetector _faceDetector;

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

    _panelController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentController.forward();
    });

    final options = FaceDetectorOptions(
      enableLandmarks: false,
      enableContours: false,
      enableTracking: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
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
    _modelHandler.dispose();
    super.dispose();
  }

  Future<void> _initializeModels() async {
    _modelHandler = ModelHandler();
    await _modelHandler.loadModels();
    if (!mounted) return;
    setState(() => _modelsReady = true);
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
        ResolutionPreset.medium,
        enableAudio: false,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onCapturePressed() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    _showError("Camera not ready.");
    return;
  }

  if (_processing || _cameraController!.value.isTakingPicture) return;
  setState(() => _processing = true);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _showError("User not logged in.");
    setState(() => _processing = false);
    return;
  }

  if (!_modelsReady) {
    _showError("Loading validation models. Please try again.");
    setState(() => _processing = false);
    return;
  }

  try {
    // Capture image
    XFile raw;
    try {
      raw = await _cameraController!.takePicture();
    } catch (e) {
      _showError("Camera busy. Try again.");
      return;
    }

    final File file = File(raw.path);
    try {
      await _cameraController!.pausePreview();
    } catch (_) {}

    // Brightness check
    if (await _isImageTooDark(file)) {
      _showError("Surrounding is too dark. Please move to a brighter area.");
      await _cameraController!.resumePreview();
      return;
    }

    // Decode image
    final imageBytes = await file.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      _showError("Failed to decode image.");
      await _cameraController!.resumePreview();
      return;
    }

    // Sharpness check
    if (_imageSharpness(decoded) < 80) {
      _showError("Image is blurry. Keep the camera stable.");
      await _cameraController!.resumePreview();
      return;
    }

    // Segmentation foreground check
    final segOutput = await _modelHandler?.runSegmentation(file);
    if (segOutput == null || !_isForegroundGood(segOutput)) {
      _showError("Face not clear from background. Move closer.");
      await _cameraController!.resumePreview();
      return;
    }

    // ----- FACE VALIDATION USING FACENET 512 -----
    // Resize to model input
    final resized = img.copyResize(decoded, width: MODEL_INPUT_SIZE, height: MODEL_INPUT_SIZE);
    final tempDir = Directory.systemTemp;
    final alignedFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_aligned.jpg');
    await alignedFile.writeAsBytes(img.encodeJpg(resized));

    // Run Facenet 512 TFLite model
    final embedding = await _modelHandler?.runFaceEmbedding(alignedFile);
    if (embedding == null || embedding.length != 512) {
      _showError("Embedding generation failed.");
      await _cameraController!.resumePreview();
      alignedFile.deleteSync();
      return;
    }

    final inputImage = InputImage.fromFilePath(file.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      _showError("No face detected.");
      await _cameraController!.resumePreview();
      alignedFile.deleteSync();
      return;
    }

    if (faces.length > 1) {
      _showError("Multiple faces detected. Please ensure only you are in the frame.");
      await _cameraController!.resumePreview();
      alignedFile.deleteSync();
      return;
    }

    final face = faces.first;
    
    if (face.headEulerAngleY == null || face.headEulerAngleX == null || face.headEulerAngleZ == null) {
      _showError("Could not determine face orientation.");
      await _cameraController!.resumePreview();
      alignedFile.deleteSync();
      return;
    }

    // Allow a 12-degree margin of error for looking straight ahead
    // Y = Yaw (left/right), X = Pitch (up/down), Z = Roll (tilt)
    if (face.headEulerAngleY!.abs() > 12 || face.headEulerAngleX!.abs() > 12 || face.headEulerAngleZ!.abs() > 12) {
      _showError("Face not properly oriented. Please look straight at the camera.");
      await _cameraController!.resumePreview();
      alignedFile.deleteSync();
      return;
    }

    // Normalize embedding
    final double norm = sqrt(embedding.fold(0.0, (prev, e) => prev + e * e));
    final normalizedEmbedding = embedding.map((e) => e / norm).toList();

    // Store to Firebase
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'faceEmbedding': normalizedEmbedding,
      'faceEmbeddingUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Cleanup
    try {
      await file.delete();
      await alignedFile.delete();
    } catch (_) {}

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
  }
}

  // Check if the foreground is good
  bool _isForegroundGood(List<List<List<List<double>>>> mask) {
    final height = mask[0].length;
    final width = mask[0][0].length;

    int foreground = 0;
    final total = height * width;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (mask[0][y][x][0] > 0.5) {
          foreground++;
        }
      }
    }

    final ratio = foreground / total;

    return ratio > 0.30;
  }

  // Brightness check
  Future<bool> _isImageTooDark(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return true;

    double total = 0.0;
    int count = 0;

    final int strideX = max(1, image.width ~/ 40);
    final int strideY = max(1, image.height ~/ 40);

    for (int y = 0; y < image.height; y += strideY) {
      for (int x = 0; x < image.width; x += strideX) {
        final img.Pixel pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();
        final int avg = ((r + g + b) / 3).round();
        total += avg;
        count++;
      }
    }

    final double avgBrightness = count == 0 ? 0.0 : total / count;

    // can be adjusted to be more/less strict
    // 45 - less strict ~~~ 80 - more strict
    return avgBrightness < 75.0;
  }

  // Blur detection
  double _imageSharpness(img.Image image) {
    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;

    final int stride = max(1, (min(image.width, image.height) ~/ 80));

    for (int y = 1; y < image.height - 1; y += stride) {
      for (int x = 1; x < image.width - 1; x += stride) {
        final double gray = img.getLuminance(image.getPixel(x, y)).toDouble();

        final double laplacian =
            gray * 4.0 -
            img.getLuminance(image.getPixel(x - 1, y)) -
            img.getLuminance(image.getPixel(x + 1, y)) -
            img.getLuminance(image.getPixel(x, y - 1)) -
            img.getLuminance(image.getPixel(x, y + 1));

        sum += laplacian;
        sumSq += laplacian * laplacian;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final double mean = sum / count;
    final double variance = (sumSq / count) - (mean * mean);
    return variance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F2D7),

      appBar: AppBar(
        //appbar back button
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
                    tag: 'bluePanel', // <--- 2. USE THE SAME TAG
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
                              //camera area
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child:
                                    _cameraInitialized &&
                                        _cameraController != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width:
                                                  _cameraController!
                                                      .value
                                                      .previewSize
                                                      ?.height ??
                                                  100,
                                              height:
                                                  _cameraController!
                                                      .value
                                                      .previewSize
                                                      ?.width ??
                                                  100,
                                              child: CameraPreview(
                                                _cameraController!,
                                              ),
                                            ),
                                          ),
                                          if (_processing)
                                            Positioned.fill(
                                              child: Container(
                                                color: Colors.black.withOpacity(
                                                  0.4,
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
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
