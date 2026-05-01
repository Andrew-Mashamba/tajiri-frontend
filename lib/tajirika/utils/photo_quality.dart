import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Spec F1 #7 — Soft-block obviously bad photos before they hit the upload.
///
/// Three cheap checks, all running in-process via the existing `image`
/// package (no extra deps):
/// - **Dimension** — reject if either side < [minSidePx] (default 480 px).
/// - **Blur** — reject if Laplacian variance < [minLaplacianVariance]
///   (default 60.0 on a 256-px-downsampled grayscale).
/// - **Brightness** — reject if mean luminance is way too dark (< [minMean])
///   or blown out (> [maxMean]).
///
/// Returns a [PhotoQualityResult]. Caller decides whether to soft-block UX
/// (preferred — show a "are you sure?" dialog) or hard-block.
enum PhotoQualityIssue { tooSmall, blurry, tooDark, tooBright, corrupt }

class PhotoQualityResult {
  final bool ok;
  final PhotoQualityIssue? issue;
  final int width;
  final int height;
  final double laplacianVariance;
  final double meanLuminance;

  const PhotoQualityResult({
    required this.ok,
    this.issue,
    required this.width,
    required this.height,
    required this.laplacianVariance,
    required this.meanLuminance,
  });

  String messageSwOrEn({bool isSwahili = false}) {
    switch (issue) {
      case PhotoQualityIssue.tooSmall:
        return isSwahili
            ? 'Picha ni ndogo sana. Tumia picha kubwa zaidi.'
            : 'Photo too small. Use a higher-resolution picture.';
      case PhotoQualityIssue.blurry:
        return isSwahili
            ? 'Picha hii ina ukungu — jaribu tena.'
            : 'This photo looks blurry — try again?';
      case PhotoQualityIssue.tooDark:
        return isSwahili
            ? 'Picha ni nyeusi sana. Tumia mwanga zaidi.'
            : 'Photo is too dark. Try again with more light.';
      case PhotoQualityIssue.tooBright:
        return isSwahili
            ? 'Picha imeangaza sana. Punguza mwanga.'
            : 'Photo is over-exposed. Reduce light.';
      case PhotoQualityIssue.corrupt:
        return isSwahili
            ? 'Hatuwezi kusoma picha hii.'
            : "Couldn't read this photo.";
      case null:
        return '';
    }
  }
}

class PhotoQuality {
  static const int minSidePx = 480;
  static const double minLaplacianVariance = 60.0;
  static const double minMean = 28.0;
  static const double maxMean = 235.0;

  static Future<PhotoQualityResult> evaluate(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return const PhotoQualityResult(
          ok: false,
          issue: PhotoQualityIssue.corrupt,
          width: 0,
          height: 0,
          laplacianVariance: 0,
          meanLuminance: 0,
        );
      }
      if (image.width < minSidePx || image.height < minSidePx) {
        return PhotoQualityResult(
          ok: false,
          issue: PhotoQualityIssue.tooSmall,
          width: image.width,
          height: image.height,
          laplacianVariance: 0,
          meanLuminance: 0,
        );
      }
      final scaled = img.copyResize(image, width: 256, maintainAspect: true);
      final gray = img.grayscale(scaled);
      final mean = _meanLuminance(gray);
      if (mean < minMean) {
        return PhotoQualityResult(
          ok: false,
          issue: PhotoQualityIssue.tooDark,
          width: image.width,
          height: image.height,
          laplacianVariance: 0,
          meanLuminance: mean,
        );
      }
      if (mean > maxMean) {
        return PhotoQualityResult(
          ok: false,
          issue: PhotoQualityIssue.tooBright,
          width: image.width,
          height: image.height,
          laplacianVariance: 0,
          meanLuminance: mean,
        );
      }
      final variance = _laplacianVariance(gray);
      if (variance < minLaplacianVariance) {
        return PhotoQualityResult(
          ok: false,
          issue: PhotoQualityIssue.blurry,
          width: image.width,
          height: image.height,
          laplacianVariance: variance,
          meanLuminance: mean,
        );
      }
      return PhotoQualityResult(
        ok: true,
        width: image.width,
        height: image.height,
        laplacianVariance: variance,
        meanLuminance: mean,
      );
    } catch (e) {
      debugPrint('[PhotoQuality] error: $e');
      return PhotoQualityResult(
        ok: false,
        issue: PhotoQualityIssue.corrupt,
        width: 0,
        height: 0,
        laplacianVariance: 0,
        meanLuminance: 0,
      );
    }
  }

  static double _meanLuminance(img.Image gray) {
    double sum = 0;
    final count = gray.width * gray.height;
    for (final p in gray) {
      sum += p.r;
    }
    return sum / count;
  }

  static double _laplacianVariance(img.Image gray) {
    final w = gray.width, h = gray.height;
    if (w < 3 || h < 3) return 0;
    final values = <double>[];
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c = gray.getPixel(x, y).r.toDouble();
        final n = gray.getPixel(x, y - 1).r.toDouble();
        final s = gray.getPixel(x, y + 1).r.toDouble();
        final e = gray.getPixel(x + 1, y).r.toDouble();
        final wp = gray.getPixel(x - 1, y).r.toDouble();
        values.add(n + s + e + wp - 4 * c);
      }
    }
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    double sq = 0;
    for (final v in values) {
      final d = v - mean;
      sq += d * d;
    }
    return math.sqrt(sq / values.length);
  }
}
