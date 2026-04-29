import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../models/ar_filter_models.dart';

/// Custom painter that renders AR face filters (lip color, glasses, crown,
/// blush, freckles, etc.) on top of a camera preview using ML Kit face
/// landmark and contour data.
class FaceLandmarkPainter extends CustomPainter {
  final Face? face;
  final List<ARFilter> activeFilters;
  final Size previewSize;
  final Size imageSize;
  final bool isFrontCamera;

  FaceLandmarkPainter({
    required this.face,
    required this.activeFilters,
    required this.previewSize,
    required this.imageSize,
    this.isFrontCamera = true,
  });

  // ── coordinate mapping ──────────────────────────────────────────────

  Offset _mapPoint(math.Point<int> point) {
    Size effectiveImageSize = imageSize;
    bool swapped = false;

    // Camera sensor is typically landscape while preview is portrait.
    if ((imageSize.width > imageSize.height) !=
        (previewSize.width > previewSize.height)) {
      effectiveImageSize = Size(imageSize.height, imageSize.width);
      swapped = true;
    }

    final scale = math.max(
      previewSize.width / effectiveImageSize.width,
      previewSize.height / effectiveImageSize.height,
    );

    final dx = (previewSize.width - effectiveImageSize.width * scale) / 2;
    final dy = (previewSize.height - effectiveImageSize.height * scale) / 2;

    double x, y;
    if (swapped) {
      x = point.y.toDouble() * scale + dx;
      y = point.x.toDouble() * scale + dy;
    } else {
      x = point.x.toDouble() * scale + dx;
      y = point.y.toDouble() * scale + dy;
    }

    if (isFrontCamera) {
      x = previewSize.width - x;
    }

    return Offset(x, y);
  }

  List<Offset> _mapContour(FaceContourType type) {
    final contour = face?.contours[type];
    if (contour == null) return [];
    return contour.points.map(_mapPoint).toList();
  }

  Offset? _mapLandmark(FaceLandmarkType type) {
    final lm = face?.landmarks[type];
    if (lm == null) return null;
    return _mapPoint(lm.position);
  }

  // ── paint entry ─────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null || activeFilters.isEmpty) return;

    for (final filter in activeFilters) {
      switch (filter.type) {
        // Lip colors
        case FilterType.lipRed:
        case FilterType.lipPink:
        case FilterType.lipNude:
        case FilterType.lipBerry:
        case FilterType.lipCoral:
        case FilterType.lipBrown:
          _drawLipColor(canvas, filter.color ?? const Color(0xFFD32F2F));
          break;

        // Accessories
        case FilterType.accSunglasses:
          _drawSunglasses(canvas);
          break;
        case FilterType.accRoundGlasses:
          _drawRoundGlasses(canvas);
          break;
        case FilterType.accCrown:
          _drawCrown(canvas);
          break;
        case FilterType.accFlowerCrown:
          _drawFlowerCrown(canvas);
          break;
        case FilterType.accHeadband:
          _drawHeadband(canvas);
          break;

        // Face effects
        case FilterType.fxBlush:
          _drawBlush(canvas, filter.color ?? const Color(0xFFE57373));
          break;
        case FilterType.fxFreckles:
          _drawFreckles(canvas);
          break;

        // Hair and other types are handled elsewhere.
        default:
          break;
      }
    }
  }

  // ── lip color ───────────────────────────────────────────────────────

  void _drawLipColor(Canvas canvas, Color color) {
    final upperTop = _mapContour(FaceContourType.upperLipTop);
    final upperBottom = _mapContour(FaceContourType.upperLipBottom);
    final lowerTop = _mapContour(FaceContourType.lowerLipTop);
    final lowerBottom = _mapContour(FaceContourType.lowerLipBottom);

    if (upperTop.isEmpty ||
        upperBottom.isEmpty ||
        lowerTop.isEmpty ||
        lowerBottom.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.multiply;

    // Upper lip: upperLipTop forward + upperLipBottom reversed.
    final upperPath = Path()..moveTo(upperTop.first.dx, upperTop.first.dy);
    for (final p in upperTop.skip(1)) {
      upperPath.lineTo(p.dx, p.dy);
    }
    for (final p in upperBottom.reversed) {
      upperPath.lineTo(p.dx, p.dy);
    }
    upperPath.close();

    // Lower lip: lowerLipTop forward + lowerLipBottom reversed.
    final lowerPath = Path()..moveTo(lowerTop.first.dx, lowerTop.first.dy);
    for (final p in lowerTop.skip(1)) {
      lowerPath.lineTo(p.dx, p.dy);
    }
    for (final p in lowerBottom.reversed) {
      lowerPath.lineTo(p.dx, p.dy);
    }
    lowerPath.close();

    canvas.drawPath(upperPath, paint);
    canvas.drawPath(lowerPath, paint);
  }

  // ── helpers for eye-based accessories ───────────────────────────────

  /// Returns (leftEye, rightEye, center, distance, angle) or null.
  _EyeMetrics? _eyeMetrics() {
    final left = _mapLandmark(FaceLandmarkType.leftEye);
    final right = _mapLandmark(FaceLandmarkType.rightEye);
    if (left == null || right == null) return null;

    final center = Offset((left.dx + right.dx) / 2, (left.dy + right.dy) / 2);
    final dist = (right - left).distance;
    final angle = math.atan2(right.dy - left.dy, right.dx - left.dx);

    return _EyeMetrics(
      left: left,
      right: right,
      center: center,
      distance: dist,
      angle: angle,
    );
  }

  // ── sunglasses ──────────────────────────────────────────────────────

  void _drawSunglasses(Canvas canvas) {
    final em = _eyeMetrics();
    if (em == null) return;

    final lensW = em.distance * 0.48;
    final lensH = em.distance * 0.36;

    canvas.save();
    canvas.translate(em.center.dx, em.center.dy);
    canvas.rotate(em.angle);

    final framePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.04;

    final tintPaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Lens rectangles relative to center.
    final halfDist = em.distance / 2;
    final leftLens = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-halfDist * 0.5, 0),
        width: lensW,
        height: lensH,
      ),
      Radius.circular(lensH * 0.2),
    );
    final rightLens = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(halfDist * 0.5, 0),
        width: lensW,
        height: lensH,
      ),
      Radius.circular(lensH * 0.2),
    );

    // Tint fill.
    canvas.drawRRect(leftLens, tintPaint);
    canvas.drawRRect(rightLens, tintPaint);

    // Frame stroke.
    canvas.drawRRect(leftLens, framePaint);
    canvas.drawRRect(rightLens, framePaint);

    // Bridge line.
    canvas.drawLine(
      Offset(-halfDist * 0.5 + lensW / 2, 0),
      Offset(halfDist * 0.5 - lensW / 2, 0),
      framePaint,
    );

    // Arms (temple bars).
    final armPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.035
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-halfDist * 0.5 - lensW / 2, 0),
      Offset(-em.distance * 0.85, lensH * 0.1),
      armPaint,
    );
    canvas.drawLine(
      Offset(halfDist * 0.5 + lensW / 2, 0),
      Offset(em.distance * 0.85, lensH * 0.1),
      armPaint,
    );

    canvas.restore();
  }

  // ── round glasses ───────────────────────────────────────────────────

  void _drawRoundGlasses(Canvas canvas) {
    final em = _eyeMetrics();
    if (em == null) return;

    final radius = em.distance * 0.22;

    canvas.save();
    canvas.translate(em.center.dx, em.center.dy);
    canvas.rotate(em.angle);

    final wirePaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.025;

    final halfDist = em.distance / 2;

    // Left circle.
    canvas.drawCircle(Offset(-halfDist * 0.5, 0), radius, wirePaint);
    // Right circle.
    canvas.drawCircle(Offset(halfDist * 0.5, 0), radius, wirePaint);

    // Bridge.
    canvas.drawLine(
      Offset(-halfDist * 0.5 + radius, 0),
      Offset(halfDist * 0.5 - radius, 0),
      wirePaint,
    );

    // Arms.
    canvas.drawLine(
      Offset(-halfDist * 0.5 - radius, 0),
      Offset(-em.distance * 0.82, radius * 0.3),
      wirePaint,
    );
    canvas.drawLine(
      Offset(halfDist * 0.5 + radius, 0),
      Offset(em.distance * 0.82, radius * 0.3),
      wirePaint,
    );

    // Subtle lens tint.
    final lensTint = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-halfDist * 0.5, 0), radius, lensTint);
    canvas.drawCircle(Offset(halfDist * 0.5, 0), radius, lensTint);

    canvas.restore();
  }

  // ── crown ───────────────────────────────────────────────────────────

  void _drawCrown(Canvas canvas) {
    final em = _eyeMetrics();
    if (em == null) return;

    canvas.save();
    canvas.translate(em.center.dx, em.center.dy);
    canvas.rotate(em.angle);

    final crownWidth = em.distance * 1.3;
    final crownHeight = em.distance * 0.55;
    final topY = -em.distance * 0.9;

    final goldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.02;

    // Zigzag crown path.
    final path = Path();
    final left = -crownWidth / 2;
    final right = crownWidth / 2;
    final bottom = topY + crownHeight;

    path.moveTo(left, bottom);
    path.lineTo(left, topY + crownHeight * 0.35);
    path.lineTo(left + crownWidth * 0.15, topY + crownHeight * 0.6);
    path.lineTo(left + crownWidth * 0.3, topY);
    path.lineTo(left + crownWidth * 0.45, topY + crownHeight * 0.5);
    path.lineTo(left + crownWidth * 0.5, topY - crownHeight * 0.1);
    path.lineTo(left + crownWidth * 0.55, topY + crownHeight * 0.5);
    path.lineTo(left + crownWidth * 0.7, topY);
    path.lineTo(left + crownWidth * 0.85, topY + crownHeight * 0.6);
    path.lineTo(right, topY + crownHeight * 0.35);
    path.lineTo(right, bottom);
    path.close();

    canvas.drawPath(path, goldPaint);
    canvas.drawPath(path, outlinePaint);

    // Jewels at the peaks.
    final jewelPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    final jewelRadius = em.distance * 0.035;

    canvas.drawCircle(Offset(left + crownWidth * 0.3, topY + jewelRadius), jewelRadius, jewelPaint);
    canvas.drawCircle(
      Offset(left + crownWidth * 0.5, topY - crownHeight * 0.1 + jewelRadius),
      jewelRadius,
      jewelPaint..color = const Color(0xFF1565C0),
    );
    canvas.drawCircle(
      Offset(left + crownWidth * 0.7, topY + jewelRadius),
      jewelRadius,
      jewelPaint..color = const Color(0xFF2E7D32),
    );

    canvas.restore();
  }

  // ── flower crown ────────────────────────────────────────────────────

  void _drawFlowerCrown(Canvas canvas) {
    final em = _eyeMetrics();
    if (em == null) return;

    canvas.save();
    canvas.translate(em.center.dx, em.center.dy);
    canvas.rotate(em.angle);

    final crownWidth = em.distance * 1.4;
    final baseY = -em.distance * 0.85;
    const flowerCount = 7;
    final flowerRadius = em.distance * 0.07;
    final petalRadius = flowerRadius * 1.1;

    // Vine line.
    final vinePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.02
      ..strokeCap = StrokeCap.round;

    final vinePath = Path();
    vinePath.moveTo(-crownWidth / 2, baseY);
    for (int i = 0; i <= 20; i++) {
      final t = i / 20.0;
      final x = -crownWidth / 2 + crownWidth * t;
      final y = baseY + math.sin(t * math.pi * 3) * em.distance * 0.03;
      if (i == 0) {
        vinePath.moveTo(x, y);
      } else {
        vinePath.lineTo(x, y);
      }
    }
    canvas.drawPath(vinePath, vinePaint);

    // Flower colors.
    const flowerColors = [
      Color(0xFFE91E63),
      Color(0xFFFF9800),
      Color(0xFFFDD835),
      Color(0xFFAB47BC),
      Color(0xFFEF5350),
      Color(0xFFFF7043),
      Color(0xFFEC407A),
    ];

    final centerPaint = Paint()
      ..color = const Color(0xFFFDD835)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < flowerCount; i++) {
      final t = (i + 0.5) / flowerCount;
      final x = -crownWidth / 2 + crownWidth * t;
      final y = baseY + math.sin(t * math.pi * 3) * em.distance * 0.03;

      final petalPaint = Paint()
        ..color = flowerColors[i % flowerColors.length]
        ..style = PaintingStyle.fill;

      // Draw 5 petals around center.
      for (int p = 0; p < 5; p++) {
        final angle = p * math.pi * 2 / 5;
        final px = x + math.cos(angle) * petalRadius;
        final py = y + math.sin(angle) * petalRadius;
        canvas.drawCircle(Offset(px, py), flowerRadius * 0.6, petalPaint);
      }

      // Center dot.
      canvas.drawCircle(Offset(x, y), flowerRadius * 0.4, centerPaint);
    }

    // Small leaves.
    final leafPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < flowerCount - 1; i++) {
      final t = (i + 1.0) / flowerCount;
      final x = -crownWidth / 2 + crownWidth * t;
      final y = baseY + em.distance * 0.04;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: flowerRadius * 0.8,
          height: flowerRadius * 0.4,
        ),
        leafPaint,
      );
    }

    canvas.restore();
  }

  // ── headband ────────────────────────────────────────────────────────

  void _drawHeadband(Canvas canvas) {
    final em = _eyeMetrics();
    if (em == null) return;

    canvas.save();
    canvas.translate(em.center.dx, em.center.dy);
    canvas.rotate(em.angle);

    final bandWidth = em.distance * 1.5;
    final bandY = -em.distance * 0.7;

    final bandPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.07
      ..strokeCap = StrokeCap.round;

    // Arc across forehead.
    final path = Path();
    path.moveTo(-bandWidth / 2, bandY + em.distance * 0.1);
    path.quadraticBezierTo(0, bandY - em.distance * 0.15, bandWidth / 2,
        bandY + em.distance * 0.1);

    canvas.drawPath(path, bandPaint);

    // Subtle highlight stripe.
    final highlightPaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = em.distance * 0.015;

    canvas.drawPath(path, highlightPaint);

    canvas.restore();
  }

  // ── blush ───────────────────────────────────────────────────────────

  void _drawBlush(Canvas canvas, Color color) {
    final leftCheek = _mapLandmark(FaceLandmarkType.leftCheek);
    final rightCheek = _mapLandmark(FaceLandmarkType.rightCheek);

    if (leftCheek == null && rightCheek == null) return;

    // Estimate radius from eye distance, fallback to bounding box.
    final em = _eyeMetrics();
    final radius = em != null ? em.distance * 0.22 : 20.0;

    void drawCheekBlush(Offset center) {
      final blushPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      canvas.drawCircle(center, radius, blushPaint);
    }

    if (leftCheek != null) drawCheekBlush(leftCheek);
    if (rightCheek != null) drawCheekBlush(rightCheek);
  }

  // ── freckles ────────────────────────────────────────────────────────

  void _drawFreckles(Canvas canvas) {
    final noseBase = _mapLandmark(FaceLandmarkType.noseBase);
    if (noseBase == null) return;

    final em = _eyeMetrics();
    final spread = em != null ? em.distance * 0.35 : 30.0;
    final dotRadius = em != null ? em.distance * 0.012 : 1.5;

    final frecklePaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    // Deterministic placement so freckles don't jump between frames.
    final rng = math.Random(42);

    for (int i = 0; i < 20; i++) {
      final dx = (rng.nextDouble() - 0.5) * 2 * spread;
      final dy = (rng.nextDouble() - 0.5) * spread * 0.8;
      final r = dotRadius * (0.6 + rng.nextDouble() * 0.8);
      canvas.drawCircle(
        Offset(noseBase.dx + dx, noseBase.dy + dy),
        r,
        frecklePaint,
      );
    }
  }

  // ── repaint ─────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(covariant FaceLandmarkPainter oldDelegate) {
    return oldDelegate.face != face ||
        oldDelegate.activeFilters != activeFilters ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}

// ── private helper ──────────────────────────────────────────────────────

class _EyeMetrics {
  final Offset left;
  final Offset right;
  final Offset center;
  final double distance;
  final double angle;

  const _EyeMetrics({
    required this.left,
    required this.right,
    required this.center,
    required this.distance,
    required this.angle,
  });
}
