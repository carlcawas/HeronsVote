import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heronsvote/screens/registration_verified.dart';

class RegistrationStep5 extends StatefulWidget {
  const RegistrationStep5({super.key});

  @override
  State<RegistrationStep5> createState() => _RegistrationStep5State();
}

class _RegistrationStep5State extends State<RegistrationStep5>
    with TickerProviderStateMixin {
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
      if (mounted) {
        _contentController.forward();
      }
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
      if (mounted) {
        _showError("Camera permission is required to capture your face.");
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      CameraDescription? front;
      for (var cam in cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          front = cam;
          break;
        }
      }
      final cameraToUse = front ?? (cameras.isNotEmpty ? cameras.first : null);
      if (cameraToUse == null) {
        _showError("No camera found on this device.");
        return;
      }

      _cameraController = CameraController(
        cameraToUse,
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

      final File file = File(raw.path);

      final inputImage = InputImage.fromFile(file);
      final List<FaceMesh> meshes = await _meshDetector.processImage(
        inputImage,
      );

      if (meshes.isEmpty) {
        _showError(
          "No face detected — please try again with your face centered.",
        );
        setState(() => _processing = false);
        return;
      }

      final FaceMesh mesh = meshes.first;
      final List<FaceMeshPoint> points = mesh.points;

      final leftEye = points[33];
      final rightEye = points[263];

      final double eyeDist = sqrt(
        pow(rightEye.x - leftEye.x, 2) +
            pow(rightEye.y - leftEye.y, 2) +
            pow(rightEye.z - leftEye.z, 2),
      );

      if (eyeDist == 0) {
        _showError("Invalid mesh detected. Try again.");
        return;
      }

      final double cx = (leftEye.x + rightEye.x) / 2.0;
      final double cy = (leftEye.y + rightEye.y) / 2.0;
      final double cz = (leftEye.z + rightEye.z) / 2.0;

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
        _showError("Unable to find current user");
        setState(() => _processing = false);
        return;
      }

      final uid = user.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await docRef.update({
        'faceEmbedding': normalized,
        'faceEmbeddingUpdatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await file.delete();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 0),
          pageBuilder: (_, __, ___) => const RegistrationVerified(),
        ),
      );
    } catch (e) {
      _showError("Failed to capture/process face: $e");
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
