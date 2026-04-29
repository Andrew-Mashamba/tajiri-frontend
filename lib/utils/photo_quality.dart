import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Result of a quick frontend image-quality check that runs BEFORE ML Kit
/// face detection. Cheap rejection of unusable images saves the user from
/// proceeding with a photo the server will eventually reject.
class PhotoQualityResult {
  final bool isValid;

  /// One of: too_small, blurry, corrupt.
  final String? errorKey;
  final int width;
  final int height;
  final double laplacianVariance;

  const PhotoQualityResult({
    required this.isValid,
    this.errorKey,
    required this.width,
    required this.height,
    required this.laplacianVariance,
  });
}

class PhotoQuality {
  /// Minimum dimension on either axis. Below this, ML Kit cannot reliably
  /// detect faces or landmarks.
  static const int minDimension = 480;

  /// Empirical Laplacian-variance threshold below which an image looks
  /// noticeably blurry. Tuned for 256-pixel-down-sampled grayscale.
  static const double minLaplacianVariance = 60.0;

  static Future<PhotoQualityResult> evaluate(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return const PhotoQualityResult(
          isValid: false,
          errorKey: 'corrupt',
          width: 0,
          height: 0,
          laplacianVariance: 0,
        );
      }
      final w = image.width;
      final h = image.height;
      if (w < minDimension || h < minDimension) {
        return PhotoQualityResult(
          isValid: false,
          errorKey: 'too_small',
          width: w,
          height: h,
          laplacianVariance: 0,
        );
      }
      final variance = _laplacianVariance(image);
      if (variance < minLaplacianVariance) {
        return PhotoQualityResult(
          isValid: false,
          errorKey: 'blurry',
          width: w,
          height: h,
          laplacianVariance: variance,
        );
      }
      return PhotoQualityResult(
        isValid: true,
        width: w,
        height: h,
        laplacianVariance: variance,
      );
    } catch (e) {
      debugPrint('[PhotoQuality] decode error: $e');
      return const PhotoQualityResult(
        isValid: false,
        errorKey: 'corrupt',
        width: 0,
        height: 0,
        laplacianVariance: 0,
      );
    }
  }

  static String errorSwahili(String? key) {
    switch (key) {
      case 'too_small':
        return 'Picha ni ndogo sana. Chukua picha mpya iliyo wazi.';
      case 'blurry':
        return 'Picha haionekani wazi. Jaribu tena na mwanga mzuri na mkono thabiti.';
      case 'corrupt':
        return 'Picha hii haisomi. Jaribu picha nyingine.';
      default:
        return 'Picha haifai. Jaribu tena.';
    }
  }

  /// Variance of the Laplacian — a standard sharpness proxy.
  /// Higher variance → more high-frequency content → sharper image.
  static double _laplacianVariance(img.Image src) {
    img.Image work = src;
    if (math.max(src.width, src.height) > 256) {
      final scale = 256 / math.max(src.width, src.height);
      work = img.copyResize(
        src,
        width: (src.width * scale).round(),
        height: (src.height * scale).round(),
      );
    }
    final gray = img.grayscale(work);
    final w = gray.width;
    final h = gray.height;
    if (w < 3 || h < 3) return 0;

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = gray.getPixel(x, y).r.toDouble();
        final n = gray.getPixel(x, y - 1).r.toDouble();
        final s = gray.getPixel(x, y + 1).r.toDouble();
        final e = gray.getPixel(x + 1, y).r.toDouble();
        final wp = gray.getPixel(x - 1, y).r.toDouble();
        final lap = n + s + e + wp - 4 * c;
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }
    if (count == 0) return 0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }
}
