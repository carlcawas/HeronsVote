import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_verified.dart';
import 'package:image/image.dart' as img;

class RegistrationStep5 extends StatefulWidget {
  final String? uid;
  const RegistrationStep5({super.key, required this.uid});

  @override
  State<RegistrationStep5> createState() => _RegistrationStep5State();
}

class _RegistrationStep5State extends State<RegistrationStep5> with TickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;
  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _processing = false;
  late final FaceMeshDetector _meshDetector;

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
      if (mounted) _contentController.forward();
    });

    _meshDetector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
    _initCameraAndPermission();
  }

  @override
  void dispose() {
    _panelController.dispose();
    _contentController.dispose();
    _cameraController?.dispose();
    _meshDetector.close();
    super.dispose();
  }

  Future<void> _initCameraAndPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted)
        _showError("Camera permission is required to capture your face.");
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
    if (_processing) return;

  setState(() => _processing = true);
    try {
      final XFile raw = await _cameraController!.takePicture();
      await _cameraController!.pausePreview();
      final File file = File(raw.path);

      // Check if too captured img is dark
      if (await _isImageTooDark(file)) {
        _showError("Too dark — please move to a brighter area.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      // Check if image is blurred (Still strict at 80)
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);

      // if < 30 --- less strict 
      // if < 80 --- more strict
      if (decoded != null && _imageSharpness(decoded) < 80) {
        _showError("Image is blurry. Please refocus and try again.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      final inputImage = InputImage.fromFile(file);
      final meshes = await _meshDetector.processImage(inputImage);

      if (meshes.isEmpty) {
        _showError("No face detected — please face the camera directly.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      final mesh = meshes.first;
      final points = mesh.points;

      // can be adjusted up to 468
      if (points.length < 300) {
        _showError("Face mesh incomplete. Try again.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      // geometry-based checks
      final leftEye = points[33];
      final rightEye = points[263];
      
      if (leftEye.x.isNaN || rightEye.x.isNaN) {
        _showError("Invalid mesh data. Try again.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      final double eyeDist = sqrt(
        pow(rightEye.x - leftEye.x, 2) +
            pow(rightEye.y - leftEye.y, 2) +
            pow(rightEye.z - leftEye.z, 2),
      );

      // can be adjusted
      // if < 7 --- less strict
      // if < 15 --- more strict 
      if (eyeDist < 15) {
        _showError("Face too small or partially covered — move closer.",);
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      // Glasses check 
      final eyesBrightness = await _regionBrightness(file, leftEye, rightEye);
      
      // can be adjusted to adjust eye strictness
      // if < 40 --- less strict
      // if < 60 --- more strict
      if (eyesBrightness < 55) {
        _showError("Remove glasses for clearer face detection.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      if (decoded == null) {
        _showError("Failed to decode image for pose checks.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }
      final double imageWidth = decoded.width.toDouble();
      final double imageHeight = decoded.height.toDouble();
      final double imageCenterX = imageWidth / 2.0;
      final double imageCenterY = imageHeight / 2.0;
      
      final double cx = (leftEye.x + rightEye.x) / 2.0;
      final double cy = (leftEye.y + rightEye.y) / 2.0;
      final double cz = (leftEye.z + rightEye.z) / 2.0;

      // tolerance 0.20 = 20% can be adjusted to be more/less strict
      final double allowedHorizontalOffset = imageWidth * 0.15; 
      final double allowedVerticalOffset = imageHeight * 0.15;

      if ((cx - imageCenterX).abs() > allowedHorizontalOffset ||
          (cy - imageCenterY).abs() > allowedVerticalOffset) {
        _showError("Please center your face in the frame.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      final double eyeTilt = (leftEye.y - rightEye.y).abs();
      // 0.17 = ~10 deg, 0.25 = ~15 deg. Lower is stricter.
      const double maxTiltThreshold = 0.17;
      if ((eyeTilt / eyeDist) > maxTiltThreshold) {
        _showError("Please keep your head level and upright.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      final noseTip = points[1];
      final double distLeft = (noseTip.x - leftEye.x).abs();
      final double distRight = (noseTip.x - rightEye.x).abs();
      final double yawRatio = min(distLeft, distRight) / max(distLeft, distRight);
      
      // 0.70 = 30% turn
      // can be adjusted to 0.80+ for stricter.
      const double minYawThreshold = 0.80;
      if (yawRatio < minYawThreshold) {
        _showError("Please face the camera directly.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      // Mouth Open Check
      final lipTop = points[13];
      final lipBottom = points[14];
      final double lipDist = (lipBottom.y - lipTop.y).abs();

      // Can be adjusted, mouth open < 40% of eye distance
      const double maxMouthOpenRatio = 0.4; 
      if ((lipDist / eyeDist) > maxMouthOpenRatio) {
        _showError("Please close your mouth for a neutral expression.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      // Eye Closed Check
      final leftEyeTop = points[159];
      final leftEyeBottom = points[145];
      final double leftEyeOpenness = (leftEyeBottom.y - leftEyeTop.y).abs();

      final rightEyeTop = points[386];
      final rightEyeBottom = points[374];
      final double rightEyeOpenness = (rightEyeBottom.y - rightEyeTop.y).abs();

      // can be adjusted eye openness 0.05 - less strict 0.10 - more strict
      const double minEyeOpenRatio = 0.07; 
      if ((leftEyeOpenness / eyeDist) < minEyeOpenRatio || 
          (rightEyeOpenness / eyeDist) < minEyeOpenRatio) {
        _showError("Please keep both eyes open.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      final List<double> embedding = [];
      for (final p in points) {
        final double nx = (p.x - cx) / eyeDist;
        final double ny = (p.y - cy) / eyeDist;
        final double nz = (p.z - cz) / eyeDist;
        embedding.addAll([nx, ny, nz]);
      }

      final double norm = sqrt(embedding.fold(0.0, (s, v) => s + v * v));
      final List<double> normalized = norm == 0
          ? embedding
          : embedding.map((e) => e / norm).toList();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("Unable to find current user.");
        await _cameraController!.resumePreview();
        setState(() => _processing = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'faceEmbedding': normalized,
            'faceEmbeddingUpdatedAt': FieldValue.serverTimestamp(),
          });

      try {
        await file.delete();
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
      _showError("Failed to capture/process face: $e");
      await _cameraController!.resumePreview();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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

        final double laplacian = gray * 4.0
            - img.getLuminance(image.getPixel(x - 1, y))
            - img.getLuminance(image.getPixel(x + 1, y))
            - img.getLuminance(image.getPixel(x, y - 1))
            - img.getLuminance(image.getPixel(x, y + 1));

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

  // for glasses detection
  Future<double> _regionBrightness(File file, FaceMeshPoint left, FaceMeshPoint right) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return 0.0;

    final int midX = ((left.x + right.x) / 2).round();
    final int midY = ((left.y + right.y) / 2).round();

    double total = 0.0;
    int count = 0;

    const int dx = 40;
    const int dy = 20;
    final int step = 5;

    for (int y = midY - dy; y <= midY + dy; y += step) {
      for (int x = midX - dx; x <= midX + dx; x += step) {
        if (x >= 0 && y >= 0 && x < image.width && y < image.height) {
          final img.Pixel pixel = image.getPixel(x, y);
          final int r = pixel.r.toInt();
          final int g = pixel.g.toInt();
          final int b = pixel.b.toInt();
          final int avg = ((r + g + b) / 3).round();
          total += avg;
          count++;
        }
      }
    }

    return count == 0 ? 0.0 : total / count;
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
            const Center(child: StepProgressIndicator(currentStep: 3)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          const Center(
                            child: Text(
                              "Verify student Face",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            height: 480,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5C6AA0),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.yellowAccent,
                                width: 1,
                              ),
                            ),
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
                                            width: _cameraController!
                                                .value
                                                .previewSize!
                                                .height,
                                            height: _cameraController!
                                                .value
                                                .previewSize!
                                                .width,
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
                            child: GestureDetector(
                              onTap: _processing ? null : _onCapturePressed,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5C6AA0),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Center(
                                  child: Text(
                                    _processing ? 'Processing...' : 'Capture',
                                    style: const TextStyle(
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
