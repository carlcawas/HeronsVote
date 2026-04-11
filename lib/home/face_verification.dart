import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:heronsvote/services/model_handler.dart';
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
  late final FaceDetector _faceDetector;
  late final ModelHandler _modelHandler;
  bool _modelsReady = false;
  
  // Verification state
  int _verificationAttempts = 0;
  static const int maxVerificationAttempts = 10;
  int _framesCollected = 0;
  static const int minFramesForLiveness = 2;

  @override
  void initState() {
    super.initState();
    
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

  Future<void> _initializeModels() async {
    _modelHandler = ModelHandler();
    await _modelHandler.loadModels();
    if (!mounted) return;
    setState(() => _modelsReady = true);
    print('[Verification] Models loaded, ready for verification');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _modelHandler.dispose();
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);
      print('[Verification] Camera initialized');
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

  // ============================================
  // MAIN VERIFICATION FLOW
  // ============================================
  Future<void> _onCapturePressed() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_processing) return;
    if (!_modelsReady) {
      _showError("Loading models. Please wait...");
      return;
    }

    setState(() => _processing = true);
    _framesCollected = 0;

    try {
      // Reset liveness detector for new session
      _modelHandler.resetLiveness();

      // Check if user has registered face
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "User not logged in.";
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!doc.exists || !doc.data()!.containsKey('faceEmbeddingEncrypted')) {
        throw "No registered face found. Please complete registration first.";
      }
      
      final String encryptedStoredEmbedding = doc.data()!['faceEmbeddingEncrypted'];

      // Collect frames for liveness detection
      _showSuccess('Please hold steady for 2 seconds...');
      await _collectFramesForLiveness();

      // Capture final image
      print('[Verification] Capturing final image...');
      
      // Give camera a moment to focus after liveness frames
      await Future.delayed(const Duration(milliseconds: 500));
      
      final XFile raw = await _cameraController!.takePicture();
      await _cameraController!.pausePreview();
      final File file = File(raw.path);

      // Decode image
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      
      if (decoded == null) {
        throw "Failed to decode image.";
      }

      print('[Verification] Image decoded: ${decoded.width}x${decoded.height}');

      // Detect face
      final inputImage = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw "No face detected. Please face the camera directly.";
      }

      if (faces.length > 1) {
        throw "Multiple faces detected. Please ensure only you are in the frame.";
      }

      final face = faces.first;
      final landmarks = face.landmarks.values.whereType<FaceLandmark>().toList();

      print('[Verification] Face detected with ${landmarks.length} landmarks');

      // Run verification pipeline
      print('[Verification] Running verification pipeline...');
      final result = await _modelHandler.processVerification(
        image: decoded,
        face: face,
        landmarks: landmarks,
        encryptedStoredEmbedding: encryptedStoredEmbedding,
      );

      // Handle result
      if (!result.success) {
        print('[Verification] Pipeline failed at ${result.stage}: ${result.message}');
        print('[Verification] Similarity Score: ${result.similarityScore?.toStringAsFixed(4)}');
        print('[Verification] Distance Score: ${result.distanceScore?.toStringAsFixed(4)}');
        print('[Verification] Quality Score: ${result.qualityResult?.qualityScore.toStringAsFixed(1)}');
        print('[Verification] Liveness Confidence: ${result.livenessResult?.confidence.toStringAsFixed(2)}');

        if (result.stage == 'quality_check') {
          _verificationAttempts++;
          if (_verificationAttempts >= maxVerificationAttempts) {
            throw "Verification failed after $maxVerificationAttempts attempts. Please try again later or contact support.";
          }
          throw "${result.message} (Attempt $_verificationAttempts/$maxVerificationAttempts)";
        }

        if (result.stage == 'liveness_check') {
          _verificationAttempts++;
          if (_verificationAttempts >= maxVerificationAttempts) {
            throw "Verification failed after $maxVerificationAttempts attempts. Please try again later or contact support.";
          }
          throw "${result.message} (Attempt $_verificationAttempts/$maxVerificationAttempts)";
        }

        if (result.stage == 'embedding_extraction') {
          throw result.message;
        }

        // Comparison stage - show actual scores for debugging
        if (result.stage == 'complete') {
          final similarityPct = (result.similarityScore! * 100).toStringAsFixed(1);
          throw "Face does not match (Similarity: $similarityPct%). Please try again or contact support.";
        }

        throw result.message;
      }

      // SUCCESS
      print('[Verification] VERIFICATION SUCCESSFUL');
      print('[Verification] Similarity: ${(result.similarityScore! * 100).toStringAsFixed(2)}%');
      print('[Verification] Distance: ${result.distanceScore!.toStringAsFixed(4)}');
      
      _showSuccess('Face verified! Submitting vote...');
      
      // Cleanup
      try {
        await file.delete();
      } catch (_) {}

      // Submit vote
      await _submitFinalVote();

    } catch (e) {
      print('[Verification] ERROR: $e');
      _showError(e.toString().replaceAll("Exception: ", ""));
      try {
        await _cameraController!.resumePreview();
      } catch (_) {}
      
      /*if (!e.toString().contains("already voted")) {
        _verificationAttempts++;
      }*/
    } finally {
      if (mounted) setState(() => _processing = false);
      _framesCollected = 0;
    }
  }

  // ============================================
  // COLLECT FRAMES FOR LIVENESS
  // ============================================
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
          
          final livenessResult = await _modelHandler.processFrameForLiveness(
            image: decoded,
            face: face,
            landmarks: landmarks,
          );

          _framesCollected = livenessResult.framesCollected ?? 0;
          
          print('[Liveness] Frames: $_framesCollected, Ready: ${livenessResult.isReadyForAnalysis}');

          if (livenessResult.isReadyForAnalysis && livenessResult.isLive) {
            print('[Liveness] Liveness verified!');
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

  // ============================================
  // SUBMIT VOTE AFTER VERIFICATION
  // ============================================
  Future<void> _submitFinalVote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final bool isProposal = widget.electionType == 'proposal';
      final String collectionPath = isProposal ? 'proposals' : 'elections';

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw "User profile not found.";

      final userData = userDoc.data()!;
      final String userYear = userData['year_level'] ?? 'Unknown';
      final String userCollege = userData['college_id'] ?? 'Unknown';

      await firestore.runTransaction((transaction) async {
        final ballotRef = firestore
            .collection(collectionPath)
            .doc(widget.electionId)
            .collection('votes')
            .doc(user.uid);

        final ballotSnapshot = await transaction.get(ballotRef);
        if (ballotSnapshot.exists) {
          throw "You have already voted in this election.";
        }

        Map<String, dynamic> selectionsMap = {};
        widget.selectedCandidates.forEach((pos, candidate) {
          if (candidate != null) {
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

        final generalStatsRef = firestore
            .collection(collectionPath)
            .doc(widget.electionId)
            .collection('stats')
            .doc('general');

        transaction.set(generalStatsRef, {
          'total_votes_cast': FieldValue.increment(1),
          'by_year_level': {userYear: FieldValue.increment(1)},
        }, SetOptions(merge: true));

        if (isProposal) {
          final proposalRef = firestore.collection('proposals').doc(widget.electionId);
          transaction.update(proposalRef, {
            'vote_count': FieldValue.increment(1),
          });
        }

        widget.selectedCandidates.forEach((position, candidate) {
          if (candidate != null) {
            DocumentReference statsRef;
            String name;
            bool isAbstain = candidate.isAbstain;

            String docId;
            if (isAbstain) {
              final String safePos = position.replaceAll(RegExp(r'\s+'), '_');
              docId = 'abstain_$safePos';
              name = "Abstain";
            } else if (isProposal) {
              docId = candidate.name;
              name = candidate.name;
            } else if (candidate.id != null) {
              docId = candidate.id!;
              name = candidate.name;
            } else {
              return;
            }

            statsRef = firestore
                .collection(collectionPath)
                .doc(widget.electionId)
                .collection('stats')
                .doc(docId);

            transaction.set(statsRef, {
              'name': name,
              'position': position,
              'is_abstain': isAbstain,
              'total_votes': FieldValue.increment(1),
              'by_year_level': {userYear: FieldValue.increment(1)},
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
      if (msg.contains("FirebaseException"))
        msg = "Network error. Please try again.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Hero(
              tag: 'header_vote',
              child: Material(
                type: MaterialType.transparency,
                child: CustomHeader(
                  title: 'Vote confirmation',
                  onBack: () => Navigator.pop(context),
                ),
              ),
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

            // Camera Preview
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
                    if (_processing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 16),
                              Text(
                                _framesCollected >= minFramesForLiveness
                                    ? 'Analyzing...'
                                    : 'Collecting frames ($_framesCollected/$minFramesForLiveness)',
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Button
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25, bottom: 25),
              child: ElevatedButton(
                onPressed: _processing ? null : _onCapturePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6AA0),
                  disabledBackgroundColor: const Color(0xFF5C6AA0).withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _processing ? 'Processing' : 'Capture',
                  style: const TextStyle(
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
