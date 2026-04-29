import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

/// CustomPainter that renders a PNG wig asset over the user's detected face.
class WigOverlayPainter extends CustomPainter {
  final ui.Image? wigImage;
  final Face? face;
  final Size previewSize;
  final Size imageSize;
  final bool isFrontCamera;

  const WigOverlayPainter({
    required this.wigImage,
    required this.face,
    required this.previewSize,
    required this.imageSize,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wigImage == null || face == null) return;

    final Rect mappedFaceRect = _mapFaceToPreview(face!.boundingBox, size);

    // Scale wig so it's wide enough: target wig width = faceRect.width * 2.6
    final double targetWigWidth = mappedFaceRect.width * 2.6;
    final double wigAspect = wigImage!.width / wigImage!.height;
    final double targetWigHeight = targetWigWidth / wigAspect;

    // Center horizontally on face; top is faceRect.top - targetWigHeight * 0.18
    final double left =
        mappedFaceRect.center.dx - targetWigWidth / 2;
    final double top = mappedFaceRect.top - targetWigHeight * 0.18;

    final Rect destRect = Rect.fromLTWH(left, top, targetWigWidth, targetWigHeight);
    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      wigImage!.width.toDouble(),
      wigImage!.height.toDouble(),
    );

    final Paint paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(wigImage!, srcRect, destRect, paint);
  }

  /// Maps a face bounding box from ML Kit image coordinates to canvas (preview)
  /// coordinates.
  ///
  /// Handles landscape→portrait rotation (if imageWidth > imageHeight, swap
  /// x/y coords), applies cover-fit scaling, and mirrors for the front camera.
  Rect _mapFaceToPreview(Rect faceBox, Size canvasSize) {
    double imgW = imageSize.width;
    double imgH = imageSize.height;

    double left = faceBox.left;
    double top = faceBox.top;
    double right = faceBox.right;
    double bottom = faceBox.bottom;

    // Handle landscape→portrait rotation: ML Kit returns landscape coords
    // when the sensor image is wider than it is tall.
    if (imgW > imgH) {
      // Rotate 90° clockwise: new (x, y) = (oldY, imgW - oldX)
      final double newLeft = top;
      final double newTop = imgW - right;
      final double newRight = bottom;
      final double newBottom = imgW - left;

      left = newLeft;
      top = newTop;
      right = newRight;
      bottom = newBottom;

      // Swap image dimensions to reflect the rotation
      final double temp = imgW;
      imgW = imgH;
      imgH = temp;
    }

    // Cover-fit: scale the image so it fills the canvas, cropping edges
    final double scaleX = canvasSize.width / imgW;
    final double scaleY = canvasSize.height / imgH;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    // Offset to center the scaled image within the canvas
    final double offsetX = (canvasSize.width - imgW * scale) / 2;
    final double offsetY = (canvasSize.height - imgH * scale) / 2;

    double mappedLeft = left * scale + offsetX;
    double mappedTop = top * scale + offsetY;
    double mappedRight = right * scale + offsetX;
    double mappedBottom = bottom * scale + offsetY;

    // Mirror horizontally for front camera
    if (isFrontCamera) {
      final double mirroredLeft = canvasSize.width - mappedRight;
      final double mirroredRight = canvasSize.width - mappedLeft;
      mappedLeft = mirroredLeft;
      mappedRight = mirroredRight;
    }

    return Rect.fromLTRB(mappedLeft, mappedTop, mappedRight, mappedBottom);
  }

  @override
  bool shouldRepaint(WigOverlayPainter oldDelegate) {
    return oldDelegate.wigImage != wigImage || oldDelegate.face != face;
  }
}
