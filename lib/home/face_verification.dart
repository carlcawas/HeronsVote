import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'voting_models.dart';
import 'vote_submitted.dart';
import 'header.dart';

class FaceVerificationPage extends StatefulWidget {
  final Map<String, VotingCandidate?> selectedCandidates;
  final String electionId;
  final String electionType;

  const FaceVerificationPage({
    super.key, 
    required this.selectedCandidates, 
    required this.electionId,
    required this.electionType,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _processing = false;
  late final FaceMeshDetector _meshDetector;

  @override
  void initState() {
    super.initState();
    _meshDetector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
    _initCameraAndPermission();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _meshDetector.close();
    super.dispose();
  }

  Future<void> _initCameraAndPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        _showError("Camera permission is required.");
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // CAPTURE AND PROCESS FACE
  Future<void> _onCapturePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_processing) return;

    setState(() => _processing = true);

    try {
      final XFile raw = await _cameraController!.takePicture();
      await _cameraController!.pausePreview();
      final File file = File(raw.path);

      // Quality Checks
      if (await _isImageTooDark(file)) {
        throw "Surrounding is too dark. Please move to a brighter area.";
      }

      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);

      if (decoded != null && _imageSharpness(decoded) < 80) {
        throw "Image is blurry. Please keep the camera stable.";
      }

      // Detect Face Mesh
      final inputImage = InputImage.fromFile(file);
      final meshes = await _meshDetector.processImage(inputImage);

      if (meshes.isEmpty) throw "No face detected.";

      final mesh = meshes.first;
      final points = mesh.points;

      if (points.length < 300) throw "Face mesh incomplete.";

      // Geometric Checks
      final leftEye = points[33];
      final rightEye = points[263];

      final double eyeDist = sqrt(
        pow(rightEye.x - leftEye.x, 2) +
            pow(rightEye.y - leftEye.y, 2) +
            pow(rightEye.z - leftEye.z, 2),
      );

      if (eyeDist < 15) throw "Face is too far. Please move closer.";

      final eyesBrightness = await _regionBrightness(file, leftEye, rightEye);
      if (eyesBrightness < 55) throw "Remove obstructions (mask/sunglasses).";

      final double imageWidth = decoded!.width.toDouble();
      final double imageHeight = decoded.height.toDouble();
      final double cx = (leftEye.x + rightEye.x) / 2.0;
      final double cy = (leftEye.y + rightEye.y) / 2.0;
      final double cz = (leftEye.z + rightEye.z) / 2.0;

      if ((cx - imageWidth / 2).abs() > imageWidth * 0.15 ||
          (cy - imageHeight / 2).abs() > imageHeight * 0.15) {
        throw "Please center your face.";
      }

      final noseTip = points[1];
      final double distLeft = (noseTip.x - leftEye.x).abs();
      final double distRight = (noseTip.x - rightEye.x).abs();
      final double yawRatio =
          min(distLeft, distRight) / max(distLeft, distRight);
      if (yawRatio < 0.80) throw "Please face the camera straight.";

      // Generate Embedding
      final List<double> currentEmbedding = [];
      for (final p in points) {
        final double nx = (p.x - cx) / eyeDist;
        final double ny = (p.y - cy) / eyeDist;
        final double nz = (p.z - cz) / eyeDist;
        currentEmbedding.addAll([nx, ny, nz]);
      }

      final double norm = sqrt(currentEmbedding.fold(0.0, (s, v) => s + v * v));
      final List<double> normalizedCurrent = norm == 0
          ? currentEmbedding
          : currentEmbedding.map((e) => e / norm).toList();

      // Verify
      await _verifyUser(normalizedCurrent);

      // Cleanup
      try { await file.delete(); } catch (_) {}

    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
      await _cameraController!.resumePreview();
      setState(() => _processing = false);
    }
  }

  // VERIFY WITH STORED IN FIRESTORE 
  Future<void> _verifyUser(List<double> currentEmbedding) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw "User not logged in.";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
        
    if (!doc.exists || !doc.data()!.containsKey('faceEmbedding')) {
      throw "No registered face found. Please contact admin.";
    }

    final List<dynamic> storedRaw = doc.data()!['faceEmbedding'];
    final List<double> storedEmbedding = storedRaw.cast<double>();

    double distance = 0.0;
    for (int i = 0; i < currentEmbedding.length; i++) {
      double diff = currentEmbedding[i] - storedEmbedding[i];
      distance += diff * diff;
    }
    distance = sqrt(distance);

    const double verificationThreshold = 0.8;

    if (distance <= verificationThreshold) {
      if (!mounted) return;
      await _submitFinalVote();
    } else {
      throw "Face does not match our records. Verification failed.";
    }
  }

  // SUBMIT VOTE AFTER VERIFICATION
  Future<void> _submitFinalVote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Determine if elections or proposals
      final bool isProposal = widget.electionType == 'proposal';
      final String collectionPath = isProposal ? 'proposals' : 'elections';

      // Get User Profile
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw "User profile not found.";
      
      final userData = userDoc.data()!;
      final String userYear = userData['year_level'] ?? 'Unknown'; 
      final String userCollege = userData['college_id'] ?? 'Unknown';

      // Run Transaction
      await firestore.runTransaction((transaction) async {
        
        // ONE-VOTE ENFORCEMENT CHECK
        final ballotRef = firestore
            .collection(collectionPath) // Dynamic Path
            .doc(widget.electionId)
            .collection('votes')
            .doc(user.uid);
            
        final ballotSnapshot = await transaction.get(ballotRef);
        if (ballotSnapshot.exists) {
          throw "You have already voted in this election.";
        }

        // WRITE VOTE/BALLOT
        Map<String, dynamic> selectionsMap = {};
        widget.selectedCandidates.forEach((pos, candidate) {
          if (candidate != null) {
             // For proposals, candidate.id might be null if created on the fly, fallback to name
             String id = candidate.id ?? candidate.name; 
             if (candidate.isAbstain) id = "ABSTAIN";
             selectionsMap[pos] = id;
          }
        });

        transaction.set(ballotRef, {
          'votedAt': FieldValue.serverTimestamp(),
          'user_year_level': userYear,
          'user_college_id': userCollege,
          'selections': selectionsMap,
        });

        // UPDATE GENERAL STATS
        final generalStatsRef = firestore
            .collection(collectionPath)
            .doc(widget.electionId)
            .collection('stats')
            .doc('general');

        transaction.set(generalStatsRef, {
          'total_votes_cast': FieldValue.increment(1),
          'by_year_level': { userYear: FieldValue.increment(1) }
        }, SetOptions(merge: true));

        // UPDATE PROPOSAL MAIN VOTE COUNT
        if (isProposal) {
          final proposalRef = firestore.collection('proposals').doc(widget.electionId);
          transaction.update(proposalRef, {
            'vote_count': FieldValue.increment(1)
          });
        }

        // UPDATE CANDIDATE/OPTION STATS
        widget.selectedCandidates.forEach((position, candidate) {
          if (candidate != null) {
             DocumentReference statsRef;
             String name;
             bool isAbstain = candidate.isAbstain;

             // Logic for ID generation
             String docId;
             if (isAbstain) {
                 final String safePos = position.replaceAll(RegExp(r'\s+'), '_');
                 docId = 'abstain_$safePos';
                 name = "Abstain";
             } else if (isProposal) {
                 // For proposals, use "Yes" or "No" as ID
                 docId = candidate.name; 
                 name = candidate.name;
             } else if (candidate.id != null) {
                 docId = candidate.id!;
                 name = candidate.name;
             } else {
                 return; // Skip invalid
             }

             statsRef = firestore
                 .collection(collectionPath)
                 .doc(widget.electionId)
                 .collection('stats')
                 .doc(docId);

             // Atomic Increment
             transaction.set(statsRef, {
               'name': name,
               'position': position,
               'is_abstain': isAbstain,
               'total_votes': FieldValue.increment(1),
               'by_year_level': { userYear: FieldValue.increment(1) }
             }, SetOptions(merge: true));
          }
        });
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VoteSubmittedPage(uid: user.uid),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains("FirebaseException")) msg = "Network error. Please try again.";
      if (msg.contains("already voted")) msg = "Vote already recorded.";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission Failed: $msg"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() => _processing = false);
    }
  }

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
    return (count == 0 ? 0.0 : total / count) < 75.0;
  }

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
    return (sumSq / count) - (mean * mean);
  }

  Future<double> _regionBrightness(
    File file,
    FaceMeshPoint left,
    FaceMeshPoint right,
  ) async {
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
          total += ((r + g + b) / 3).round();
          count++;
        }
      }
    }
    return count == 0 ? 0.0 : total / count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Vote confirmation',
              onBack: () => Navigator.pop(context),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Hero(
                tag: 'HeroStepProgressIndicator',
                child: Material(
                  type: MaterialType.transparency,
                  child: StepProgressIndicator(currentStep: 2, totalSteps: 3),
                ),
              ),
            ),

            const SizedBox(height: 20),

            //Camera Preview
            Container(
              height: 424,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 27),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF858FB8), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraInitialized && _cameraController != null)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize!.height,
                          height: _cameraController!.value.previewSize!.width,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    else
                      Container(
                        color: Colors.black,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // button
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
              child: ElevatedButton(
                onPressed: _processing ? null : _onCapturePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  disabledBackgroundColor: const Color(
                    0xFF5C6AA0,
                  ).withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _processing ? 'Processing' : 'Capture',
                  style: TextStyle(
                    color: Color(0xFFF8F8F8),
                    fontSize: 14,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w700,
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