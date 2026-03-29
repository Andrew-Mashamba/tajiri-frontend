import 'dart:io';
import 'dart:ui';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceValidationResult {
  final bool isValid;
  final String? errorKey; // 'no_face' or 'multiple_faces'
  final Rect? faceBounds;
  final int faceCount;

  const FaceValidationResult({
    required this.isValid,
    this.errorKey,
    this.faceBounds,
    required this.faceCount,
  });
}

class FaceValidator {
  /// Strict validation for registration — exactly 1 face required.
  static Future<FaceValidationResult> validate(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableLandmarks: false,
          enableContours: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        return const FaceValidationResult(
          isValid: false,
          errorKey: 'no_face',
          faceCount: 0,
        );
      }

      if (faces.length > 1) {
        return FaceValidationResult(
          isValid: false,
          errorKey: 'multiple_faces',
          faceCount: faces.length,
        );
      }

      final face = faces.first;
      return FaceValidationResult(
        isValid: true,
        faceBounds: face.boundingBox,
        faceCount: 1,
      );
    } catch (e) {
      // ML Kit unavailable — allow upload without face data
      return const FaceValidationResult(
        isValid: true,
        errorKey: null,
        faceCount: 0,
      );
    }
  }

  /// Lenient detection for profile updates — returns largest face bbox or null.
  static Future<Rect?> detectLargestFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableLandmarks: false,
          enableContours: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) return null;

      // Find largest face by bounding box area
      Face largest = faces.first;
      double maxArea = largest.boundingBox.width * largest.boundingBox.height;
      for (final face in faces.skip(1)) {
        final area = face.boundingBox.width * face.boundingBox.height;
        if (area > maxArea) {
          maxArea = area;
          largest = face;
        }
      }

      return largest.boundingBox;
    } catch (e) {
      return null;
    }
  }
}
