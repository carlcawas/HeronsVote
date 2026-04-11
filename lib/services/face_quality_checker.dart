import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Comprehensive face quality assessment
class FaceQualityChecker {
  // Quality thresholds - relaxed for better real-world performance
  static const double minBrightness = 50.0;  // Lowered from 60
  static const double maxBrightness = 220.0; // Raised from 200
  static const double minSharpness = 30.0;   // Lowered from 80 for better real-world performance
  static const double maxFaceAngle = 20.0;   // Raised from 15 degrees
  static const double minFaceSizeRatio = 0.20; // Lowered from 0.25
  static const double maxOcclusionRatio = 0.20; // Raised from 0.15

  /// Checks all quality metrics and returns a detailed result
  static Future<FaceQualityResult> checkQuality({
    required img.Image image,
    required Face face,
    required List<FaceLandmark>? landmarks,
  }) async {
    final result = FaceQualityResult();

    // 1. Brightness check
    result.brightnessScore = _checkBrightness(image);
    result.isBrightnessOk = result.brightnessScore >= minBrightness &&
        result.brightnessScore <= maxBrightness;

    // 2. Sharpness/blur check
    result.sharpnessScore = _checkSharpness(image);
    result.isSharpnessOk = result.sharpnessScore >= minSharpness;

    // 3. Pose/angle check
    result.poseResult = _checkPose(face);
    result.isPoseOk = result.poseResult.isAcceptable;

    // 4. Face size check (distance from camera)
    result.faceSizeRatio = _checkFaceSize(image, face);
    result.isFaceSizeOk = result.faceSizeRatio >= minFaceSizeRatio;

    // 5. Face centering check
    result.centeringResult = _checkCentering(image, face);
    result.isCenteredOk = result.centeringResult.isAcceptable;

    // 6. Occlusion check (if landmarks available)
    if (landmarks != null) {
      result.occlusionResult = _checkOcclusion(landmarks, face);
      result.isOcclusionOk = result.occlusionResult.occlusionRatio <= maxOcclusionRatio;
    } else {
      result.isOcclusionOk = true; // Skip if no landmarks
    }

    // Overall quality assessment
    result.isOverallQualityOk = result.isBrightnessOk &&
        result.isSharpnessOk &&
        result.isPoseOk &&
        result.isFaceSizeOk &&
        result.isCenteredOk &&
        result.isOcclusionOk;

    result.qualityScore = _calculateOverallScore(result);

    return result;
  }

  /// Check image brightness by sampling pixels
  static double _checkBrightness(img.Image image) {
    double total = 0.0;
    int count = 0;

    final int strideX = max(1, image.width ~/ 30);
    final int strideY = max(1, image.height ~/ 30);

    for (int y = 0; y < image.height; y += strideY) {
      for (int x = 0; x < image.width; x += strideX) {
        final pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();
        // Calculate luminance
        total += (0.299 * r + 0.587 * g + 0.114 * b);
        count++;
      }
    }

    return count == 0 ? 0.0 : total / count;
  }

  /// Check image sharpness using Laplacian variance
  static double _checkSharpness(img.Image image) {
    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;

    final int stride = max(1, (min(image.width, image.height) ~/ 60));

    for (int y = 1; y < image.height - 1; y += stride) {
      for (int x = 1; x < image.width - 1; x += stride) {
        final double gray = img.getLuminance(image.getPixel(x, y)).toDouble();

        // Laplacian approximation
        final double laplacian = gray * 4.0 -
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
    return (sumSq / count) - (mean * mean); // Variance
  }

  /// Check face pose/orientation
  static PoseResult _checkPose(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    final isAcceptable = yaw.abs() <= maxFaceAngle &&
        pitch.abs() <= maxFaceAngle &&
        roll.abs() <= maxFaceAngle;

    return PoseResult(
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      isAcceptable: isAcceptable,
    );
  }

  /// Check face size relative to image (distance indicator)
  static double _checkFaceSize(img.Image image, Face face) {
    final rect = face.boundingBox;
    return rect.width / image.width;
  }

  /// Check if face is centered in the frame
  static CenteringResult _checkCentering(img.Image image, Face face) {
    final rect = face.boundingBox;
    final imageCenterX = image.width / 2.0;
    final imageCenterY = image.height / 2.0;

    final faceCenterX = rect.left + (rect.width / 2);
    final faceCenterY = rect.top + (rect.height / 2);

    final offsetX = (faceCenterX - imageCenterX).abs() / imageCenterX;
    final offsetY = (faceCenterY - imageCenterY).abs() / imageCenterY;

    // Acceptable if within 30% of center (relaxed from 20%)
    final isAcceptable = offsetX <= 0.30 && offsetY <= 0.30;

    return CenteringResult(
      offsetX: offsetX,
      offsetY: offsetY,
      isAcceptable: isAcceptable,
    );
  }

  /// Check for occlusion using facial landmarks
  static OcclusionResult _checkOcclusion(
    List<FaceLandmark> landmarks,
    Face face,
  ) {
    // Count visible landmarks vs expected
    // FaceMesh has 468 landmarks, but ML Kit returns fewer key points
    final expectedLandmarks = 5; // Minimum: nose, eyes, mouth corners
    final visibleLandmarks = landmarks.length;

    final occlusionRatio = 1.0 - (visibleLandmarks / expectedLandmarks);
    final isAcceptable = occlusionRatio <= maxOcclusionRatio;

    return OcclusionResult(
      visibleLandmarks: visibleLandmarks,
      expectedLandmarks: expectedLandmarks,
      occlusionRatio: max(0.0, occlusionRatio),
      isAcceptable: isAcceptable,
    );
  }

  /// Calculate overall quality score (0-100)
  static double _calculateOverallScore(FaceQualityResult result) {
    double score = 100.0;

    // Brightness penalty (max -25)
    if (!result.isBrightnessOk) {
      final brightnessDeviation = result.brightnessScore < minBrightness
          ? minBrightness - result.brightnessScore
          : result.brightnessScore - maxBrightness;
      score -= min(25.0, brightnessDeviation / 2);
    }

    // Sharpness penalty (max -25)
    if (!result.isSharpnessOk) {
      final sharpnessDeficit = minSharpness - result.sharpnessScore;
      score -= min(25.0, sharpnessDeficit / 10);
    }

    // Pose penalty (max -20)
    if (!result.isPoseOk) {
      final maxAngleDeviation = max(
        result.poseResult.yaw.abs() - maxFaceAngle,
        max(
          result.poseResult.pitch.abs() - maxFaceAngle,
          result.poseResult.roll.abs() - maxFaceAngle,
        ),
      );
      score -= min(20.0, maxAngleDeviation * 2);
    }

    // Face size penalty (max -15)
    if (!result.isFaceSizeOk) {
      final sizeDeficit = minFaceSizeRatio - result.faceSizeRatio;
      score -= min(15.0, sizeDeficit * 50);
    }

    // Centering penalty (max -15)
    if (!result.isCenteredOk) {
      final maxOffset = max(
        result.centeringResult.offsetX,
        result.centeringResult.offsetY,
      );
      score -= min(15.0, (maxOffset - 0.20) * 75);
    }

    return max(0.0, score);
  }
}

/// Result of face quality assessment
class FaceQualityResult {
  // Brightness
  double brightnessScore = 0.0;
  bool isBrightnessOk = false;

  // Sharpness
  double sharpnessScore = 0.0;
  bool isSharpnessOk = false;

  // Pose
  PoseResult poseResult = PoseResult(yaw: 0, pitch: 0, roll: 0, isAcceptable: false);
  bool isPoseOk = false;

  // Face size
  double faceSizeRatio = 0.0;
  bool isFaceSizeOk = false;

  // Centering
  CenteringResult centeringResult = CenteringResult(
    offsetX: 0,
    offsetY: 0,
    isAcceptable: false,
  );
  bool isCenteredOk = false;

  // Occlusion
  OcclusionResult occlusionResult = OcclusionResult(
    visibleLandmarks: 0,
    expectedLandmarks: 0,
    occlusionRatio: 0,
    isAcceptable: true,
  );
  bool isOcclusionOk = false;

  // Overall
  bool isOverallQualityOk = false;
  double qualityScore = 0.0;

  /// Get human-readable feedback
  String getFeedback() {
    final issues = <String>[];

    if (!isBrightnessOk) {
      if (brightnessScore < FaceQualityChecker.minBrightness) {
        issues.add('Image too dark. Please move to a brighter area.');
      } else {
        issues.add('Image too bright. Please reduce lighting.');
      }
    }

    if (!isSharpnessOk) {
      issues.add('Image is blurry. Keep the camera steady.');
    }

    if (!isPoseOk) {
      issues.add('Please face the camera directly.');
    }

    if (!isFaceSizeOk) {
      issues.add('Please move closer to the camera.');
    }

    if (!isCenteredOk) {
      issues.add('Please center your face in the frame.');
    }

    if (!isOcclusionOk) {
      issues.add('Please remove face coverings or move hair away from face.');
    }

    if (issues.isEmpty) {
      return 'Quality check passed!';
    }

    return issues.join(' ');
  }
}

class PoseResult {
  final double yaw;
  final double pitch;
  final double roll;
  final bool isAcceptable;

  PoseResult({
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.isAcceptable,
  });
}

class CenteringResult {
  final double offsetX;
  final double offsetY;
  final bool isAcceptable;

  CenteringResult({
    required this.offsetX,
    required this.offsetY,
    required this.isAcceptable,
  });
}

class OcclusionResult {
  final int visibleLandmarks;
  final int expectedLandmarks;
  final double occlusionRatio;
  final bool isAcceptable;

  OcclusionResult({
    required this.visibleLandmarks,
    required this.expectedLandmarks,
    required this.occlusionRatio,
    required this.isAcceptable,
  });
}
