import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Renders a per-pixel hair color overlay based on a segmentation probability mask.
///
/// Each pixel in [hairMask] is a float in [0.0, 1.0] representing the probability
/// that the pixel belongs to hair. Pixels above [threshold] are painted with
/// [targetColor] using [BlendMode.multiply] for a natural tint effect.
///
/// The mask grid ([maskWidth] x [maskHeight]) is scaled to fill the canvas.
///
/// TODO(Phase 2): Wire face_detection_tflite selfieSegmentation here
/// to populate hairMask with per-pixel hair probabilities.
/// For now, hair color changes use the silhouette overlay approach.
class HairSegmentationPainter extends CustomPainter {
  HairSegmentationPainter({
    required this.hairMask,
    required this.maskWidth,
    required this.maskHeight,
    required this.targetColor,
    this.threshold = 0.5,
    this.opacity = 0.55,
  });

  final Float32List? hairMask;
  final int maskWidth;
  final int maskHeight;
  final Color targetColor;
  final double threshold;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (hairMask == null || hairMask!.isEmpty) return;

    final cellW = size.width / maskWidth;
    final cellH = size.height / maskHeight;

    for (int y = 0; y < maskHeight; y++) {
      for (int x = 0; x < maskWidth; x++) {
        final idx = y * maskWidth + x;
        if (idx >= hairMask!.length) return;
        final prob = hairMask![idx];
        if (prob < threshold) continue;
        final a = (prob * opacity * 255).round().clamp(0, 255);
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5),
          Paint()
            ..color = targetColor.withAlpha(a)
            ..blendMode = BlendMode.multiply,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HairSegmentationPainter old) =>
      old.hairMask != hairMask || old.targetColor != targetColor;
}
