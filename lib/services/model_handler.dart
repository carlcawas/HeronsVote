import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'encryption_service.dart';
import 'face_quality_checker.dart';
import 'liveness_detector.dart';

/// Complete face verification pipeline handler
/// Handles: Face detection, quality check, liveness, embedding extraction, encryption
class ModelHandler {
  Interpreter? _faceNetInterpreter;
  bool _isLoaded = false;
  
  final LivenessDetector _livenessDetector = LivenessDetector();
  final EncryptionService _encryptionService = EncryptionService();

  /// Load all required ML models
  Future<void> loadModels() async {
    if (_isLoaded) return;

    try {
      // Load FaceNet 512 for embedding extraction
      _faceNetInterpreter = await Interpreter.fromAsset(
        'assets/models/facenet_512.tflite',
        options: InterpreterOptions()..threads = 4,
      );
      print('[ModelHandler] FaceNet model loaded successfully');
    } catch (e) {
      print('[ModelHandler] ERROR: Failed to load FaceNet model: $e');
      throw Exception('Failed to load FaceNet model: $e');
    }

    _isLoaded = true;
    print('[ModelHandler] All models loaded successfully');
  }

  /// Dispose resources
  void dispose() {
    _faceNetInterpreter?.close();
    _livenessDetector.reset();
    _encryptionService.clearCache();
  }

  /// Check if models are ready
  bool get isReady => _isLoaded && _faceNetInterpreter != null;

  // ============================================
  /// COMPLETE REGISTRATION PIPELINE
  /// Returns: Encrypted embedding ready for Firebase storage
  // ============================================
  Future<RegistrationPipelineResult> processRegistration({
    required img.Image image,
    required Face face,
    required List<FaceLandmark>? landmarks,
    bool skipLivenessCheck = false,
  }) async {
    print('[ModelHandler] Starting registration pipeline...');
    final stopwatch = Stopwatch()..start();

    try {
      // STEP 1: Quality Check
      print('[ModelHandler] Step 1/3: Quality check...');
      final qualityResult = await FaceQualityChecker.checkQuality(
        image: image,
        face: face,
        landmarks: landmarks,
      );

      print('[ModelHandler] Quality Score: ${qualityResult.qualityScore.toStringAsFixed(1)}/100');
      print('[ModelHandler] Quality OK: ${qualityResult.isOverallQualityOk}');
      
      if (!qualityResult.isOverallQualityOk) {
        return RegistrationPipelineResult(
          success: false,
          stage: 'quality_check',
          message: qualityResult.getFeedback(),
          qualityResult: qualityResult,
        );
      }

      LivenessFrameResult? livenessResult;
      if (!skipLivenessCheck) {
        // STEP 2: Liveness Check
        print('[ModelHandler] Step 2/3: Liveness check...');
        livenessResult = await _livenessDetector.processFrame(
          image: image,
          face: face,
          landmarks: landmarks,
        );

        print('[ModelHandler] Liveness Confidence: ${(livenessResult.confidence * 100).toStringAsFixed(1)}%');
        print('[ModelHandler] Liveness OK: ${livenessResult.isLive}');

        if (!livenessResult.isReadyForAnalysis) {
          return RegistrationPipelineResult(
            success: false,
            stage: 'liveness_check',
            message: 'Please hold steady.',
            livenessResult: livenessResult,
            qualityResult: qualityResult,
          );
        }

        if (!livenessResult.isLive) {
          return RegistrationPipelineResult(
            success: false,
            stage: 'liveness_check',
            message: livenessResult.message,
            livenessResult: livenessResult,
            qualityResult: qualityResult,
          );
        }
      }

      // STEP 3: Extract Embedding
      print('[ModelHandler] Step 3/3: Extracting embedding...');
      final embedding = await extractEmbedding(image);
      
      if (embedding.length != 512) {
        return RegistrationPipelineResult(
          success: false,
          stage: 'embedding_extraction',
          message: 'Failed to generate face embedding',
          qualityResult: qualityResult,
          livenessResult: livenessResult,
        );
      }

      // Normalize embedding
      final normalizedEmbedding = _normalize(embedding);
      print('[ModelHandler] Embedding extracted: ${normalizedEmbedding.length} dimensions');

      // STEP 4: Encrypt Embedding
      print('[ModelHandler] Encrypting embedding...');
      final encryptedEmbedding = await _encryptionService.encryptEmbedding(normalizedEmbedding);
      print('[ModelHandler] Embedding encrypted successfully');

      stopwatch.stop();
      print('[ModelHandler] Registration pipeline completed in ${stopwatch.elapsedMilliseconds}ms');

      return RegistrationPipelineResult(
        success: true,
        stage: 'complete',
        message: 'Registration successful',
        encryptedEmbedding: encryptedEmbedding,
        qualityResult: qualityResult,
        livenessResult: livenessResult,
      );
    } catch (e) {
      print('[ModelHandler] ERROR in registration pipeline: $e');
      return RegistrationPipelineResult(
        success: false,
        stage: 'error',
        message: 'Pipeline error: $e',
      );
    }
  }

  // ============================================
  /// COMPLETE VERIFICATION PIPELINE (Voting/Reverification)
  /// Returns: Verification result with similarity score
  // ============================================
  Future<VerificationPipelineResult> processVerification({
    required img.Image image,
    required Face face,
    required List<FaceLandmark>? landmarks,
    required String encryptedStoredEmbedding,
  }) async {
    print('[ModelHandler] Starting verification pipeline...');
    final stopwatch = Stopwatch()..start();

    try {
      // STEP 1: Quality Check
      print('[ModelHandler] Step 1/4: Quality check...');
      final qualityResult = await FaceQualityChecker.checkQuality(
        image: image,
        face: face,
        landmarks: landmarks,
      );

      print('[ModelHandler] Quality Score: ${qualityResult.qualityScore.toStringAsFixed(1)}/100');
      
      if (!qualityResult.isOverallQualityOk) {
        return VerificationPipelineResult(
          success: false,
          stage: 'quality_check',
          message: qualityResult.getFeedback(),
          qualityResult: qualityResult,
        );
      }

      // STEP 2: Liveness Check
      print('[ModelHandler] Step 2/4: Liveness check...');
      final livenessResult = await _livenessDetector.processFrame(
        image: image,
        face: face,
        landmarks: landmarks,
      );

      print('[ModelHandler] Liveness Confidence: ${(livenessResult.confidence * 100).toStringAsFixed(1)}%');

      if (!livenessResult.isReadyForAnalysis) {
        return VerificationPipelineResult(
          success: false,
          stage: 'liveness_check',
          message: 'Please hold steady.',
          livenessResult: livenessResult,
          qualityResult: qualityResult,
        );
      }

      if (!livenessResult.isLive) {
        return VerificationPipelineResult(
          success: false,
          stage: 'liveness_check',
          message: livenessResult.message,
          livenessResult: livenessResult,
          qualityResult: qualityResult,
        );
      }

      // STEP 3: Extract Live Embedding
      print('[ModelHandler] Step 3/4: Extracting live embedding...');
      final liveEmbedding = await extractEmbedding(image);
      
      if (liveEmbedding.length != 512) {
        return VerificationPipelineResult(
          success: false,
          stage: 'embedding_extraction',
          message: 'Failed to generate face embedding',
          qualityResult: qualityResult,
          livenessResult: livenessResult,
        );
      }

      final normalizedLive = _normalize(liveEmbedding);
      print('[ModelHandler] Live embedding extracted');

      // STEP 4: Decrypt Stored Embedding & Compare
      print('[ModelHandler] Step 4/4: Decrypting and comparing...');
      final storedEmbedding = await _encryptionService.decryptEmbedding(encryptedStoredEmbedding);
      print('[ModelHandler] Stored embedding decrypted: ${storedEmbedding.length} dimensions');
      print('[ModelHandler] Stored embedding sample: [${storedEmbedding.take(5).map((e) => e.toStringAsFixed(4)).join(", ")}...]');

      final similarity = _cosineSimilarity(normalizedLive, storedEmbedding);
      final distance = _euclideanDistance(normalizedLive, storedEmbedding);

      print('[ModelHandler] Live embedding sample: [${normalizedLive.take(5).map((e) => e.toStringAsFixed(4)).join(", ")}...]');
      print('[ModelHandler] Cosine Similarity: ${similarity.toStringAsFixed(4)}');
      print('[ModelHandler] Euclidean Distance: ${distance.toStringAsFixed(4)}');

      // Threshold check - optimized for FaceNet 512 with proper normalization
      // Cosine similarity: 0.60 allows for variations in lighting, angle, expression
      // Euclidean distance: 1.5 is standard for FaceNet512 with normalized input
      const double similarityThreshold = 0.60;
      const double distanceThreshold = 1.5;

      print('[ModelHandler] Thresholds: similarity >= $similarityThreshold, distance <= $distanceThreshold');
      print('[ModelHandler] Similarity check: ${similarity >= similarityThreshold} ($similarity >= $similarityThreshold)');
      print('[ModelHandler] Distance check: ${distance <= distanceThreshold} ($distance <= $distanceThreshold)');

      final isMatch = similarity >= similarityThreshold && distance <= distanceThreshold;

      stopwatch.stop();
      print('[ModelHandler] Verification completed in ${stopwatch.elapsedMilliseconds}ms');
      print('[ModelHandler] Result: ${isMatch ? "MATCH" : "NO MATCH"}');

      return VerificationPipelineResult(
        success: isMatch,
        stage: 'complete',
        message: isMatch ? 'Verification successful' : 'Face does not match',
        similarityScore: similarity,
        distanceScore: distance,
        qualityResult: qualityResult,
        livenessResult: livenessResult,
      );
    } catch (e) {
      print('[ModelHandler] ERROR in verification pipeline: $e');
      return VerificationPipelineResult(
        success: false,
        stage: 'error',
        message: 'Pipeline error: $e',
      );
    }
  }

  // ============================================
  /// EMBEDDING EXTRACTION (FaceNet 512)
  // ============================================
  Future<List<double>> extractEmbedding(img.Image image) async {
    if (_faceNetInterpreter == null) {
      throw Exception('FaceNet interpreter not loaded');
    }

    // Get model input dimensions
    var inputShape = _faceNetInterpreter!.getInputTensor(0).shape;
    int height = inputShape[1];
    int width = inputShape[2];

    // Preprocess image
    final input = _preprocessImageToList(image, width, height);

    // Allocate output buffer
    var outputShape = _faceNetInterpreter!.getOutputTensor(0).shape;
    var output = _allocateBuffer(outputShape);

    // Run inference
    _faceNetInterpreter!.run(input, output);

    // Extract and return embedding
    List<double> embedding = _flatten(output);
    return embedding;
  }

  // Reset liveness detector (call when starting new verification session)
  void resetLiveness() {
    _livenessDetector.reset();
  }

  // Process frame for liveness detection (used during frame collection)
  Future<LivenessFrameResult> processFrameForLiveness({
    required img.Image image,
    required Face face,
    required List<FaceLandmark>? landmarks,
  }) async {
    return await _livenessDetector.processFrame(
      image: image,
      face: face,
      landmarks: landmarks,
    );
  }

  // ============================================
  /// HELPER METHODS
  // ============================================

  List<double> _normalize(List<double> vector) {
    double sum = vector.fold(0.0, (p, v) => p + v * v);
    double norm = sum == 0 ? 1.0 : sqrt(sum);
    return vector.map((v) => v / norm).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      double diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  dynamic _allocateBuffer(List<int> shape) {
    if (shape.length == 1) return List.filled(shape[0], 0.0);
    if (shape.length == 2) return List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
    if (shape.length == 3) return List.generate(shape[0], (_) => List.generate(shape[1], (_) => List.filled(shape[2], 0.0)));
    if (shape.length == 4) return List.generate(shape[0], (_) => List.generate(shape[1], (_) => List.generate(shape[2], (_) => List.filled(shape[3], 0.0))));
    throw Exception('Unsupported shape dimension: ${shape.length}');
  }

  List<double> _flatten(dynamic list) {
    List<double> result = [];
    for (var item in list) {
      if (item is List) result.addAll(_flatten(item));
      else result.add((item as num).toDouble());
    }
    return result;
  }

  List<List<List<List<double>>>> _preprocessImageToList(img.Image image, int width, int height) {
    // Resize image to model input size
    img.Image resized = img.copyResize(image, width: width, height: height);
    
    // Flip horizontally to normalize front-camera images
    // Front cameras capture mirrored images, this ensures consistency
    img.Image flipped = img.flipHorizontal(resized);

    var input = List.generate(
      1,
      (_) => List.generate(
        height,
        (_) => List.generate(width, (_) => List.filled(3, 0.0)),
      ),
    );

    // FaceNet expects input normalized with mean=0.5 and std=1.0
    // Formula: (pixel / 255.0 - 0.5) * 2.0 = pixel / 127.5 - 1.0
    // This maps [0, 255] to [-1, 1]
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = flipped.getPixel(x, y);
        input[0][y][x][0] = (pixel.r / 127.5) - 1.0;  // R channel
        input[0][y][x][1] = (pixel.g / 127.5) - 1.0;  // G channel
        input[0][y][x][2] = (pixel.b / 127.5) - 1.0;  // B channel
      }
    }

    return input;
  }
}

// ============================================
/// RESULT CLASSES
// ============================================

class RegistrationPipelineResult {
  final bool success;
  final String stage;
  final String message;
  final String? encryptedEmbedding;
  final FaceQualityResult? qualityResult;
  final LivenessFrameResult? livenessResult;

  RegistrationPipelineResult({
    required this.success,
    required this.stage,
    required this.message,
    this.encryptedEmbedding,
    this.qualityResult,
    this.livenessResult,
  });
}

class VerificationPipelineResult {
  final bool success;
  final String stage;
  final String message;
  final double? similarityScore;
  final double? distanceScore;
  final FaceQualityResult? qualityResult;
  final LivenessFrameResult? livenessResult;

  VerificationPipelineResult({
    required this.success,
    required this.stage,
    required this.message,
    this.similarityScore,
    this.distanceScore,
    this.qualityResult,
    this.livenessResult,
  });
}
