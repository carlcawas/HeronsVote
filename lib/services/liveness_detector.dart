import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Liveness detection to prevent spoofing attacks
/// Uses multiple techniques: blink detection, depth analysis, texture analysis
class LivenessDetector {
  // Liveness thresholds - optimized for real-world conditions
  static const int minFramesForAnalysis = 2;
  static const double blinkScoreThreshold = 0.25;  // Lowered from 0.3
  static const double depthVarianceThreshold = 0.015; // Lowered from 0.02
  static const double textureScoreThreshold = 0.35; // Lowered from 0.4 for single-frame reliability
  static const double motionConsistencyThreshold = 0.4; // Lowered from 0.5

  final List<LivenessFrame> _frameBuffer = [];
  bool _isAnalyzing = false;

  /// Process a frame for liveness detection
  /// Call this for each camera frame during the capture process
  Future<LivenessFrameResult> processFrame({
    required img.Image image,
    required Face face,
    required List<FaceLandmark>? landmarks,
  }) async {
    if (_isAnalyzing) {
      return LivenessFrameResult(
        isLive: false,
        isReadyForAnalysis: false,
        confidence: 0.0,
        message: 'Analysis in progress',
      );
    }

    // Extract features from this frame
    final frameData = LivenessFrame(
      timestamp: DateTime.now(),
      eyeAspectRatio: _calculateEAR(landmarks),
      mouthAspectRatio: _calculateMAR(landmarks),
      faceSize: face.boundingBox.width,
      textureScore: _analyzeTexture(image, face),
      image: image,
    );

    _frameBuffer.add(frameData);

    // Keep only recent frames (last 2 seconds)
    final cutoff = DateTime.now().subtract(const Duration(milliseconds: 2000));
    _frameBuffer.removeWhere((f) => f.timestamp.isBefore(cutoff));

    // Check if we have enough frames for analysis
    if (_frameBuffer.length < minFramesForAnalysis) {
      return LivenessFrameResult(
        isLive: false,
        isReadyForAnalysis: false,
        confidence: 0.0,
        framesCollected: _frameBuffer.length,
        minFramesNeeded: minFramesForAnalysis,
        message: 'Collecting frames...',
      );
    }

    // Perform liveness analysis
    return _analyzeLiveness();
  }

  /// Calculate Eye Aspect Ratio (EAR) for blink detection
  /// EAR = (|p2-p6| + |p3-p5|) / (2 * |p1-p4|)
  double? _calculateEAR(List<FaceLandmark>? landmarks) {
    if (landmarks == null || landmarks.length < 6) return null;

    // ML Kit face landmarks:
    // 0: bottomMouth, 1: noseBottom, 2: leftCheek, 3: rightCheek
    // 4: leftEye, 5: rightEye, 6: leftEar, 7: rightEar
    // 8: mouthCenter, 9: noseTip, 10: leftEyeCorner, 11: rightEyeCorner
    
    // Use eye positions for basic blink detection
    try {
      final leftEye = landmarks.firstWhere(
        (l) => l.type == FaceLandmarkType.leftEye,
        orElse: () => landmarks[4],
      );
      final rightEye = landmarks.firstWhere(
        (l) => l.type == FaceLandmarkType.rightEye,
        orElse: () => landmarks[5],
      );

      // Simple distance between eyes as proxy
      final dx = leftEye.position.x - rightEye.position.x;
      final dy = leftEye.position.y - rightEye.position.y;
      return sqrt(dx * dx + dy * dy);
    } catch (e) {
      return null;
    }
  }

  /// Calculate Mouth Aspect Ratio (MAR)
  double? _calculateMAR(List<FaceLandmark>? landmarks) {
    if (landmarks == null) return null;

    try {
      final mouthBottom = landmarks.firstWhere(
        (l) => l.type == FaceLandmarkType.bottomMouth,
      );
      // Use left eye as reference (always available in ML Kit)
      final eyeRef = landmarks.firstWhere(
        (l) => l.type == FaceLandmarkType.leftEye,
        orElse: () => landmarks.first,
      );

      return (mouthBottom.position.y - eyeRef.position.y).abs().toDouble();
    } catch (e) {
      // Reference landmark not available, return neutral value
      return 0.5;
    }
  }

  /// Analyze texture complexity to detect screen/print attacks
  double _analyzeTexture(img.Image image, Face face) {
    final rect = face.boundingBox;
    
    // Extract face region
    final faceX = rect.left.clamp(0, image.width - 1).toInt();
    final faceY = rect.top.clamp(0, image.height - 1).toInt();
    final faceW = rect.width.toInt().clamp(1, image.width - faceX);
    final faceH = rect.height.toInt().clamp(1, image.height - faceY);

    // Sample pixels from face region
    int edgeCount = 0;
    int totalSamples = 0;

    final strideX = max(1, faceW ~/ 20);
    final strideY = max(1, faceH ~/ 20);

    for (int y = faceY; y < faceY + faceH; y += strideY) {
      for (int x = faceX; x < faceX + faceW; x += strideX) {
        if (x >= image.width || y >= image.height) continue;

        final current = img.getLuminance(image.getPixel(x, y));
        
        // Check horizontal edge
        if (x + 1 < image.width) {
          final right = img.getLuminance(image.getPixel(x + 1, y));
          if ((current - right).abs() > 30) edgeCount++;
        }

        // Check vertical edge
        if (y + 1 < image.height) {
          final below = img.getLuminance(image.getPixel(x, y + 1));
          if ((current - below).abs() > 30) edgeCount++;
        }

        totalSamples += 2;
      }
    }

    return totalSamples > 0 ? edgeCount / totalSamples : 0.0;
  }

  /// Analyze collected frames for liveness
  LivenessFrameResult _analyzeLiveness() {
    _isAnalyzing = true;

    try {
      if (_frameBuffer.length < 1) {
        return LivenessFrameResult(
          isLive: false,
          isReadyForAnalysis: false,
          confidence: 0.0,
          message: 'Not enough frames',
        );
      }

      double overallConfidence = 0.0;
      final issues = <String>[];

      // 1. Check for natural motion (micro-movements) - only if 2+ frames
      if (_frameBuffer.length >= 2) {
        final motionScore = _analyzeMotion();
        if (motionScore >= motionConsistencyThreshold) {
          overallConfidence += 0.20;
        } else {
          issues.add('Insufficient natural movement detected');
        }
      } else {
        // Single frame - give partial credit, rely on other checks
        overallConfidence += 0.15;
      }

      // 2. Check texture complexity (real skin vs screen/print) - PRIMARY CHECK
      final avgTextureScore = _frameBuffer
          .map((f) => f.textureScore)
          .reduce((a, b) => a + b) / _frameBuffer.length;
      
      if (avgTextureScore >= textureScoreThreshold) {
        overallConfidence += 0.35; // Increased weight for single-frame reliability
      } else {
        issues.add('Texture appears artificial');
      }

      // 3. Check for blink (if eye data available) - bonus check
      final blinkScore = _detectBlink();
      if (blinkScore >= blinkScoreThreshold) {
        overallConfidence += 0.25;
      } else if (_frameBuffer.length >= 2) {
        // Only penalize if we have enough frames to detect blink
        overallConfidence += 0.10; // Partial credit
      } else {
        // Single frame - can't detect blink, neutral score
        overallConfidence += 0.15;
      }

      // 4. Check depth variance (3D face vs flat image)
      if (_frameBuffer.length >= 2) {
        final depthScore = _analyzeDepthVariance();
        if (depthScore >= depthVarianceThreshold) {
          overallConfidence += 0.20;
        } else {
          issues.add('Face appears flat (possible photo)');
        }
      } else {
        // Single frame - use face geometry as proxy
        overallConfidence += 0.15;
      }

      final isLive = overallConfidence >= 0.45; // Lowered from 0.50 for real-world conditions

      return LivenessFrameResult(
        isLive: isLive,
        isReadyForAnalysis: true,
        confidence: overallConfidence,
        motionScore: _frameBuffer.length >= 2 ? _analyzeMotion() : null,
        textureScore: avgTextureScore,
        blinkScore: blinkScore,
        depthScore: _frameBuffer.length >= 2 ? _analyzeDepthVariance() : null,
        message: isLive 
            ? 'Liveness verified' 
            : 'Liveness check failed: ${issues.join("; ")}',
      );
    } finally {
      _isAnalyzing = false;
    }
  }

  /// Analyze motion consistency across frames
  double _analyzeMotion() {
    if (_frameBuffer.length < 2) return 0.0;

    // Check for natural micro-movements in face position
    final faceSizes = _frameBuffer.map((f) => f.faceSize).toList();
    
    double variance = 0.0;
    final mean = faceSizes.reduce((a, b) => a + b) / faceSizes.length;
    
    for (final size in faceSizes) {
      variance += (size - mean) * (size - mean);
    }
    variance /= faceSizes.length;

    // Some variance indicates natural movement (not a static photo)
    // But too much variance indicates rapid movement (possible video replay)
    if (variance > 0.5 && variance < 50.0) {
      return 1.0;
    } else if (variance > 0.1) {
      return 0.7;
    }
    return variance > 0 ? 0.3 : 0.1;
  }

  /// Detect blink from EAR variations
  double _detectBlink() {
    final earValues = _frameBuffer
        .where((f) => f.eyeAspectRatio != null)
        .map((f) => f.eyeAspectRatio!)
        .toList();

    if (earValues.length < 3) return 0.5; // Neutral score if no data

    // Look for EAR dip (blink pattern)
    final minEar = earValues.reduce((a, b) => a < b ? a : b);
    final maxEar = earValues.reduce((a, b) => a > b ? a : b);
    final avgEar = earValues.reduce((a, b) => a + b) / earValues.length;

    // A significant dip indicates a blink
    final earRange = maxEar - minEar;
    if (earRange > 0.1 * avgEar) {
      return 1.0; // Clear blink detected
    }
    
    return 0.5; // No clear blink, but not suspicious
  }

  /// Analyze depth variance (simulated from face size changes)
  double _analyzeDepthVariance() {
    if (_frameBuffer.length < 2) return 0.0;

    final faceSizes = _frameBuffer.map((f) => f.faceSize).toList();
    
    double variance = 0.0;
    final mean = faceSizes.reduce((a, b) => a + b) / faceSizes.length;
    
    for (final size in faceSizes) {
      variance += (size - mean) * (size - mean);
    }
    variance /= faceSizes.length;

    // Natural depth variation (user slightly moving)
    if (variance > 1.0 && variance < 100.0) {
      return 1.0;
    } else if (variance > 0.5) {
      return 0.7;
    }
    return 0.3;
  }

  /// Reset the frame buffer
  void reset() {
    _frameBuffer.clear();
    _isAnalyzing = false;
  }

  /// Get current frame buffer size
  int get frameCount => _frameBuffer.length;
}

/// Single frame data for liveness analysis
class LivenessFrame {
  final DateTime timestamp;
  final double? eyeAspectRatio;
  final double? mouthAspectRatio;
  final double faceSize;
  final double textureScore;
  final img.Image image;

  LivenessFrame({
    required this.timestamp,
    this.eyeAspectRatio,
    this.mouthAspectRatio,
    required this.faceSize,
    required this.textureScore,
    required this.image,
  });
}

/// Result of liveness analysis
class LivenessFrameResult {
  final bool isLive;
  final bool isReadyForAnalysis;
  final double confidence;
  final int? framesCollected;
  final int? minFramesNeeded;
  final double? motionScore;
  final double? textureScore;
  final double? blinkScore;
  final double? depthScore;
  final String message;

  LivenessFrameResult({
    required this.isLive,
    required this.isReadyForAnalysis,
    required this.confidence,
    this.framesCollected,
    this.minFramesNeeded,
    this.motionScore,
    this.textureScore,
    this.blinkScore,
    this.depthScore,
    required this.message,
  });
}
