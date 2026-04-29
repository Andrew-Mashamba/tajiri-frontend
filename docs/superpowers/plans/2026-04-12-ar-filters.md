# AR Filters & Virtual Try-On Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Hair & Nails virtual try-on from basic geometric blobs into production-quality AR filters with face landmark positioning, hair color segmentation, lip color, accessories, and a filter gallery UI.

**Architecture:** Three-phase approach. Phase 1 enables ML Kit's 133 face contour points + 10 landmarks (already available — just config flags) to position overlays precisely on face features. Phase 2 adds `face_detection_tflite` package for 468-point face mesh and per-pixel hair segmentation, enabling real hair color changes. Phase 3 builds a polished filter gallery UI with categories, carousel, before/after, and save/share.

**Tech Stack:** Flutter, google_ml_kit (face detection with contours/landmarks), face_detection_tflite (468-point mesh + hair segmentation), camera package, CustomPaint for rendering, RepaintBoundary for capture.

---

## File Structure

### New Files
- `lib/hair_nails/models/ar_filter_models.dart` — Filter types, presets, categories
- `lib/hair_nails/widgets/face_landmark_painter.dart` — Landmark-based overlay rendering (lip color, accessories)
- `lib/hair_nails/widgets/hair_segmentation_painter.dart` — Hair mask color overlay rendering
- `lib/hair_nails/widgets/filter_carousel.dart` — Bottom filter picker carousel UI
- `lib/hair_nails/pages/ar_try_on_page.dart` — New unified try-on page replacing virtual_hair_try_on_page.dart

### Modified Files
- `lib/hair_nails/widgets/hair_try_on_viewport.dart` — Enable landmarks/contours, expose face data for painters
- `lib/hair_nails/pages/hair_nails_home_page.dart` — Update try-on navigation to new page
- `pubspec.yaml` — Add face_detection_tflite dependency

---

## Phase 1: Face Landmarks & Contour-Based Filters

### Task 1: Enable ML Kit Face Landmarks and Contours

**Files:**
- Modify: `lib/hair_nails/widgets/hair_try_on_viewport.dart`

- [ ] **Step 1: Change FaceDetectorOptions flags**

In `_HairTryOnViewportState.initState()`, the `FaceDetectorOptions` currently has `enableLandmarks: false` and `enableContours: false`. Change both to `true`:

```dart
_faceDetector = GoogleMlKit.vision.faceDetector(
  FaceDetectorOptions(
    enableLandmarks: true,    // was false
    enableContours: true,     // was false
    enableClassification: true, // was false — enables smile + eye open detection
    performanceMode: FaceDetectorMode.fast,
    minFaceSize: 0.15, // slightly larger minimum for better landmark accuracy
  ),
);
```

- [ ] **Step 2: Store full Face object instead of just Rect**

Replace the `Rect? _faceInPreview` field with the full `Face` object so painters can access landmarks and contours:

```dart
// Replace this:
Rect? _faceInPreview;

// With these:
Face? _detectedFace;
Rect? _faceRectInPreview;
```

- [ ] **Step 3: Update _onCameraImage to store the full Face**

In the `_onCameraImage` method, after face detection succeeds, store the full `Face` object AND the mapped preview rect:

```dart
final face = faces.first;
final bbox = face.boundingBox;
final previewRect = _mapImageRectToPreview(
  bbox, _previewLayoutSize, _imageSize,
  ctrl.description.lensDirection == CameraLensDirection.front,
);
if (!mounted) return;
final wasNull = _faceRectInPreview == null;
if (_rectChanged(_faceRectInPreview, previewRect)) {
  setState(() {
    _detectedFace = face;
    _faceRectInPreview = previewRect;
  });
}
```

Update all references from `_faceInPreview` to `_faceRectInPreview` throughout the file (the null checks in `_buildCameraStack`, face guide visibility, face check animation).

- [ ] **Step 4: Pass face data to HairTryOnPainter**

Update the `HairTryOnPainter` constructor to also accept `Face?` for landmark access:

```dart
class HairTryOnPainter extends CustomPainter {
  HairTryOnPainter({
    required this.faceRect,
    required this.styleIndex,
    required this.tint,
    this.face,
    required this.previewSize,
    required this.imageSize,
    required this.isFrontCamera,
  });

  final Rect? faceRect;
  final int styleIndex;
  final Color tint;
  final Face? face;
  final Size previewSize;
  final Size imageSize;
  final bool isFrontCamera;
```

Update the `CustomPaint` call in `_buildCameraStack` to pass the new fields:

```dart
CustomPaint(
  painter: HairTryOnPainter(
    faceRect: _faceRectInPreview,
    styleIndex: _styleIndex,
    tint: _hairColorChoices[_colorIndex % _hairColorChoices.length],
    face: _detectedFace,
    previewSize: _previewLayoutSize,
    imageSize: _imageSize,
    isFrontCamera: _controller?.description.lensDirection == CameraLensDirection.front,
  ),
),
```

- [ ] **Step 5: Verify face detection still works**

Run: `flutter analyze lib/hair_nails/widgets/hair_try_on_viewport.dart`
Expected: 0 errors

Test: Build and run on device. Camera should open, face guide shows, face detection succeeds (check logs for `detectFacesImageByteArray.end()`). Hair overlays should still render as before.

- [ ] **Step 6: Commit**

```bash
git add lib/hair_nails/widgets/hair_try_on_viewport.dart
git commit -m "feat(hair): enable ML Kit face landmarks + contours for AR filters"
```

---

### Task 2: Create AR Filter Models

**Files:**
- Create: `lib/hair_nails/models/ar_filter_models.dart`

- [ ] **Step 1: Define filter type enums and preset data**

```dart
// lib/hair_nails/models/ar_filter_models.dart

import 'package:flutter/material.dart';

enum FilterCategory {
  hairColor,
  hairStyle,
  lipColor,
  accessories,
  faceEffect,
}

enum FilterType {
  // Hair Color
  hairColorBlack,
  hairColorBrown,
  hairColorRed,
  hairColorBlonde,
  hairColorBlue,
  hairColorPink,
  hairColorBurgundy,
  hairColorGrey,

  // Lip Color
  lipRed,
  lipPink,
  lipNude,
  lipBerry,
  lipCoral,
  lipBrown,

  // Accessories
  accSunglasses,
  accRoundGlasses,
  accCrown,
  accFlowerCrown,
  accEarrings,
  accHeadband,

  // Hair Style (reuse existing 8)
  styleAfro,
  styleBraids,
  styleBob,
  styleBun,
  styleCornrows,
  styleLocs,
  styleBantuKnots,
  styleTwistOut,

  // Face Effects
  fxSmooth,
  fxBlush,
  fxFreckles,
  fxContour,
}

class ARFilter {
  final FilterType type;
  final FilterCategory category;
  final String nameEn;
  final String nameSw;
  final Color? color; // For hair color / lip color
  final int? styleIndex; // For hair styles (maps to existing kHairTryOnStyleCount)
  final IconData icon;

  const ARFilter({
    required this.type,
    required this.category,
    required this.nameEn,
    required this.nameSw,
    this.color,
    this.styleIndex,
    this.icon = Icons.auto_awesome_rounded,
  });

  String name(bool isSwahili) => isSwahili ? nameSw : nameEn;
}

/// All available filter presets grouped by category.
class ARFilterPresets {
  static const List<ARFilter> hairColors = [
    ARFilter(type: FilterType.hairColorBlack, category: FilterCategory.hairColor, nameEn: 'Jet Black', nameSw: 'Nyeusi', color: Color(0xFF0A0A0A), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBrown, category: FilterCategory.hairColor, nameEn: 'Brown', nameSw: 'Kahawia', color: Color(0xFF5D4037), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorRed, category: FilterCategory.hairColor, nameEn: 'Red', nameSw: 'Nyekundu', color: Color(0xFFB71C1C), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBlonde, category: FilterCategory.hairColor, nameEn: 'Blonde', nameSw: 'Blonde', color: Color(0xFFC8A951), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBlue, category: FilterCategory.hairColor, nameEn: 'Blue', nameSw: 'Bluu', color: Color(0xFF1565C0), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorPink, category: FilterCategory.hairColor, nameEn: 'Pink', nameSw: 'Waridi', color: Color(0xFFE91E63), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorBurgundy, category: FilterCategory.hairColor, nameEn: 'Burgundy', nameSw: 'Burgundy', color: Color(0xFF800020), icon: Icons.circle),
    ARFilter(type: FilterType.hairColorGrey, category: FilterCategory.hairColor, nameEn: 'Grey', nameSw: 'Kijivu', color: Color(0xFF9E9E9E), icon: Icons.circle),
  ];

  static const List<ARFilter> lipColors = [
    ARFilter(type: FilterType.lipRed, category: FilterCategory.lipColor, nameEn: 'Classic Red', nameSw: 'Nyekundu', color: Color(0xFFD32F2F), icon: Icons.circle),
    ARFilter(type: FilterType.lipPink, category: FilterCategory.lipColor, nameEn: 'Pink', nameSw: 'Waridi', color: Color(0xFFEC407A), icon: Icons.circle),
    ARFilter(type: FilterType.lipNude, category: FilterCategory.lipColor, nameEn: 'Nude', nameSw: 'Nude', color: Color(0xFFBCAAA4), icon: Icons.circle),
    ARFilter(type: FilterType.lipBerry, category: FilterCategory.lipColor, nameEn: 'Berry', nameSw: 'Berry', color: Color(0xFF880E4F), icon: Icons.circle),
    ARFilter(type: FilterType.lipCoral, category: FilterCategory.lipColor, nameEn: 'Coral', nameSw: 'Coral', color: Color(0xFFFF7043), icon: Icons.circle),
    ARFilter(type: FilterType.lipBrown, category: FilterCategory.lipColor, nameEn: 'Brown', nameSw: 'Kahawia', color: Color(0xFF6D4C41), icon: Icons.circle),
  ];

  static const List<ARFilter> accessories = [
    ARFilter(type: FilterType.accSunglasses, category: FilterCategory.accessories, nameEn: 'Sunglasses', nameSw: 'Miwani ya jua', icon: Icons.wb_sunny_rounded),
    ARFilter(type: FilterType.accRoundGlasses, category: FilterCategory.accessories, nameEn: 'Round Glasses', nameSw: 'Miwani', icon: Icons.visibility_rounded),
    ARFilter(type: FilterType.accCrown, category: FilterCategory.accessories, nameEn: 'Crown', nameSw: 'Taji', icon: Icons.star_rounded),
    ARFilter(type: FilterType.accFlowerCrown, category: FilterCategory.accessories, nameEn: 'Flower Crown', nameSw: 'Taji la Maua', icon: Icons.local_florist_rounded),
    ARFilter(type: FilterType.accHeadband, category: FilterCategory.accessories, nameEn: 'Headband', nameSw: 'Bendi ya kichwa', icon: Icons.horizontal_rule_rounded),
  ];

  static const List<ARFilter> hairStyles = [
    ARFilter(type: FilterType.styleAfro, category: FilterCategory.hairStyle, nameEn: 'Short Afro', nameSw: 'Afro Fupi', styleIndex: 0, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBraids, category: FilterCategory.hairStyle, nameEn: 'Long Braids', nameSw: 'Misuko Mirefu', styleIndex: 1, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBob, category: FilterCategory.hairStyle, nameEn: 'Bob Cut', nameSw: 'Bob', styleIndex: 2, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBun, category: FilterCategory.hairStyle, nameEn: 'High Bun', nameSw: 'Bun ya Juu', styleIndex: 3, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleCornrows, category: FilterCategory.hairStyle, nameEn: 'Cornrows', nameSw: 'Cornrows', styleIndex: 4, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleLocs, category: FilterCategory.hairStyle, nameEn: 'Locs', nameSw: 'Locs/Dread', styleIndex: 5, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleBantuKnots, category: FilterCategory.hairStyle, nameEn: 'Bantu Knots', nameSw: 'Bantu Knots', styleIndex: 6, icon: Icons.face_rounded),
    ARFilter(type: FilterType.styleTwistOut, category: FilterCategory.hairStyle, nameEn: 'Twist Out', nameSw: 'Twist Out', styleIndex: 7, icon: Icons.face_rounded),
  ];

  static const List<ARFilter> faceEffects = [
    ARFilter(type: FilterType.fxSmooth, category: FilterCategory.faceEffect, nameEn: 'Smooth Skin', nameSw: 'Ngozi Laini', icon: Icons.blur_on_rounded),
    ARFilter(type: FilterType.fxBlush, category: FilterCategory.faceEffect, nameEn: 'Blush', nameSw: 'Blush', color: Color(0xFFE57373), icon: Icons.favorite_rounded),
    ARFilter(type: FilterType.fxFreckles, category: FilterCategory.faceEffect, nameEn: 'Freckles', nameSw: 'Freckles', icon: Icons.scatter_plot_rounded),
    ARFilter(type: FilterType.fxContour, category: FilterCategory.faceEffect, nameEn: 'Contour', nameSw: 'Contour', icon: Icons.contrast_rounded),
  ];

  static List<ARFilter> byCategory(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.hairColor: return hairColors;
      case FilterCategory.hairStyle: return hairStyles;
      case FilterCategory.lipColor: return lipColors;
      case FilterCategory.accessories: return accessories;
      case FilterCategory.faceEffect: return faceEffects;
    }
  }

  static const List<FilterCategory> allCategories = FilterCategory.values;
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/models/ar_filter_models.dart`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add lib/hair_nails/models/ar_filter_models.dart
git commit -m "feat(hair): add AR filter models with presets for hair/lip/accessories"
```

---

### Task 3: Build Face Landmark Painter (Lip Color + Accessories)

**Files:**
- Create: `lib/hair_nails/widgets/face_landmark_painter.dart`

- [ ] **Step 1: Create the landmark-based painter**

This painter uses ML Kit's 133 contour points to render lip color and accessories precisely on face features.

```dart
// lib/hair_nails/widgets/face_landmark_painter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/ar_filter_models.dart';

/// Renders lip color, blush, and accessories using ML Kit face contour points.
class FaceLandmarkPainter extends CustomPainter {
  FaceLandmarkPainter({
    required this.face,
    required this.activeFilters,
    required this.previewSize,
    required this.imageSize,
    required this.isFrontCamera,
  });

  final Face? face;
  final List<ARFilter> activeFilters;
  final Size previewSize;
  final Size imageSize;
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;
    for (final filter in activeFilters) {
      switch (filter.category) {
        case FilterCategory.lipColor:
          _paintLipColor(canvas, size, filter);
          break;
        case FilterCategory.accessories:
          _paintAccessory(canvas, size, filter);
          break;
        case FilterCategory.faceEffect:
          _paintFaceEffect(canvas, size, filter);
          break;
        default:
          break;
      }
    }
  }

  Offset _mapPoint(Point<int> point) {
    // Map from image coordinates to preview coordinates
    // Account for sensor rotation: image is landscape, preview is portrait
    Size effectiveImageSize = imageSize;
    bool swapped = false;
    if ((imageSize.width > imageSize.height) != (previewSize.width > previewSize.height)) {
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

  void _paintLipColor(Canvas canvas, Size size, ARFilter filter) {
    final color = filter.color ?? Colors.red;
    final f = face!;

    // Get lip contour points
    final upperTop = f.contours[FaceContourType.upperLipTop]?.points;
    final upperBottom = f.contours[FaceContourType.upperLipBottom]?.points;
    final lowerTop = f.contours[FaceContourType.lowerLipTop]?.points;
    final lowerBottom = f.contours[FaceContourType.lowerLipBottom]?.points;

    if (upperTop == null || lowerBottom == null) return;

    // Upper lip: outer edge (upperTop) + inner edge reversed (upperBottom)
    final upperPath = Path();
    final utPoints = upperTop.map(_mapPoint).toList();
    if (utPoints.isEmpty) return;
    upperPath.moveTo(utPoints.first.dx, utPoints.first.dy);
    for (int i = 1; i < utPoints.length; i++) {
      upperPath.lineTo(utPoints[i].dx, utPoints[i].dy);
    }
    if (upperBottom != null) {
      final ubPoints = upperBottom.map(_mapPoint).toList().reversed.toList();
      for (final p in ubPoints) {
        upperPath.lineTo(p.dx, p.dy);
      }
    }
    upperPath.close();

    // Lower lip: outer edge (lowerBottom) + inner edge reversed (lowerTop)
    final lowerPath = Path();
    final lbPoints = lowerBottom.map(_mapPoint).toList();
    if (lbPoints.isEmpty) return;
    lowerPath.moveTo(lbPoints.first.dx, lbPoints.first.dy);
    for (int i = 1; i < lbPoints.length; i++) {
      lowerPath.lineTo(lbPoints[i].dx, lbPoints[i].dy);
    }
    if (lowerTop != null) {
      final ltPoints = lowerTop.map(_mapPoint).toList().reversed.toList();
      for (final p in ltPoints) {
        lowerPath.lineTo(p.dx, p.dy);
      }
    }
    lowerPath.close();

    final paint = Paint()
      ..color = color.withOpacity(0.45)
      ..blendMode = BlendMode.multiply
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(upperPath, paint);
    canvas.drawPath(lowerPath, paint);
  }

  void _paintAccessory(Canvas canvas, Size size, ARFilter filter) {
    final f = face!;
    final leftEye = f.landmarks[FaceLandmarkType.leftEye];
    final rightEye = f.landmarks[FaceLandmarkType.rightEye];
    if (leftEye == null || rightEye == null) return;

    final le = _mapPoint(leftEye.position);
    final re = _mapPoint(rightEye.position);
    final eyeCenter = Offset((le.dx + re.dx) / 2, (le.dy + re.dy) / 2);
    final eyeDist = (re.dx - le.dx).abs();
    final angle = math.atan2(re.dy - le.dy, re.dx - le.dx);

    switch (filter.type) {
      case FilterType.accSunglasses:
        _drawSunglasses(canvas, eyeCenter, eyeDist, angle);
        break;
      case FilterType.accRoundGlasses:
        _drawRoundGlasses(canvas, eyeCenter, eyeDist, angle, le, re);
        break;
      case FilterType.accCrown:
        _drawCrown(canvas, eyeCenter, eyeDist, angle);
        break;
      case FilterType.accFlowerCrown:
        _drawFlowerCrown(canvas, eyeCenter, eyeDist, angle);
        break;
      case FilterType.accHeadband:
        _drawHeadband(canvas, eyeCenter, eyeDist, angle);
        break;
      default:
        break;
    }
  }

  void _drawSunglasses(Canvas canvas, Offset center, double eyeDist, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final w = eyeDist * 1.4;
    final h = eyeDist * 0.45;
    final lensW = w * 0.42;
    final lensH = h * 0.85;
    final gap = w * 0.08;

    // Frame
    final framePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    // Left lens
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-gap - lensW / 2, 0), width: lensW, height: lensH), Radius.circular(lensH * 0.3)),
      framePaint,
    );
    // Right lens
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(gap + lensW / 2, 0), width: lensW, height: lensH), Radius.circular(lensH * 0.3)),
      framePaint,
    );
    // Bridge
    canvas.drawLine(
      Offset(-gap, 0),
      Offset(gap, 0),
      Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = lensH * 0.12..strokeCap = StrokeCap.round,
    );
    // Arms
    final armPaint = Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = lensH * 0.1..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-gap - lensW, 0), Offset(-gap - lensW - eyeDist * 0.35, lensH * 0.15), armPaint);
    canvas.drawLine(Offset(gap + lensW, 0), Offset(gap + lensW + eyeDist * 0.35, lensH * 0.15), armPaint);

    // Lens tint
    final tintPaint = Paint()
      ..color = const Color(0xFF263238).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-gap - lensW / 2, 0), width: lensW * 0.92, height: lensH * 0.78), Radius.circular(lensH * 0.25)),
      tintPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(gap + lensW / 2, 0), width: lensW * 0.92, height: lensH * 0.78), Radius.circular(lensH * 0.25)),
      tintPaint,
    );

    canvas.restore();
  }

  void _drawRoundGlasses(Canvas canvas, Offset center, double eyeDist, double angle, Offset le, Offset re) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final r = eyeDist * 0.28;
    final gap = eyeDist * 0.08;
    final wire = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final lens = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.fill;

    // Left lens
    canvas.drawCircle(Offset(-gap - r, 0), r, lens);
    canvas.drawCircle(Offset(-gap - r, 0), r, wire);
    // Right lens
    canvas.drawCircle(Offset(gap + r, 0), r, lens);
    canvas.drawCircle(Offset(gap + r, 0), r, wire);
    // Bridge
    canvas.drawArc(Rect.fromCenter(center: Offset.zero, width: gap * 2, height: r * 0.6), math.pi, math.pi, false, wire);

    canvas.restore();
  }

  void _drawCrown(Canvas canvas, Offset center, double eyeDist, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy - eyeDist * 0.9);
    canvas.rotate(angle);

    final w = eyeDist * 1.2;
    final h = eyeDist * 0.5;
    final paint = Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill;
    final outline = Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 2;

    final path = Path();
    path.moveTo(-w / 2, h * 0.3);
    path.lineTo(-w / 2, -h * 0.1);
    path.lineTo(-w * 0.25, h * 0.15);
    path.lineTo(0, -h * 0.5);
    path.lineTo(w * 0.25, h * 0.15);
    path.lineTo(w / 2, -h * 0.1);
    path.lineTo(w / 2, h * 0.3);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outline);

    // Jewels
    final jewel = Paint()..color = Colors.red..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, -h * 0.3), h * 0.08, jewel);
    canvas.drawCircle(Offset(-w * 0.35, 0), h * 0.06, Paint()..color = Colors.blue..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.35, 0), h * 0.06, Paint()..color = Colors.green..style = PaintingStyle.fill);

    canvas.restore();
  }

  void _drawFlowerCrown(Canvas canvas, Offset center, double eyeDist, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy - eyeDist * 0.85);
    canvas.rotate(angle);

    final w = eyeDist * 1.3;
    final colors = [Colors.pink.shade300, Colors.yellow.shade300, Colors.purple.shade300, Colors.red.shade300, Colors.orange.shade300];
    final r = eyeDist * 0.1;

    for (int i = 0; i < 7; i++) {
      final x = -w / 2 + (w / 6) * i;
      final y = math.sin(i * 0.9) * eyeDist * 0.08;
      final c = colors[i % colors.length];
      // Petals
      for (int j = 0; j < 5; j++) {
        final a = (j / 5) * math.pi * 2;
        canvas.drawCircle(Offset(x + math.cos(a) * r * 0.5, y + math.sin(a) * r * 0.5), r * 0.4, Paint()..color = c);
      }
      // Center
      canvas.drawCircle(Offset(x, y), r * 0.3, Paint()..color = Colors.yellow.shade600);
    }

    // Vine
    final vine = Paint()..color = Colors.green.shade700..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final vinePath = Path();
    vinePath.moveTo(-w / 2, 0);
    for (int i = 0; i <= 6; i++) {
      final x = -w / 2 + (w / 6) * i;
      final y = math.sin(i * 0.9) * eyeDist * 0.08;
      if (i == 0) {
        vinePath.moveTo(x, y + r * 0.5);
      } else {
        vinePath.lineTo(x, y + r * 0.5);
      }
    }
    canvas.drawPath(vinePath, vine);

    canvas.restore();
  }

  void _drawHeadband(Canvas canvas, Offset center, double eyeDist, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy - eyeDist * 0.6);
    canvas.rotate(angle);

    final w = eyeDist * 1.5;
    final band = Paint()..color = const Color(0xFF1A1A1A)..strokeWidth = eyeDist * 0.06..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset.zero, width: w, height: eyeDist * 0.4), math.pi, math.pi, false, band);

    canvas.restore();
  }

  void _paintFaceEffect(Canvas canvas, Size size, ARFilter filter) {
    final f = face!;
    switch (filter.type) {
      case FilterType.fxBlush:
        final leftCheek = f.contours[FaceContourType.leftCheek]?.points;
        final rightCheek = f.contours[FaceContourType.rightCheek]?.points;
        if (leftCheek != null && leftCheek.isNotEmpty) {
          final lc = _mapPoint(leftCheek.first);
          _drawBlush(canvas, lc, filter.color ?? Colors.pink.shade200);
        }
        if (rightCheek != null && rightCheek.isNotEmpty) {
          final rc = _mapPoint(rightCheek.first);
          _drawBlush(canvas, rc, filter.color ?? Colors.pink.shade200);
        }
        break;
      case FilterType.fxFreckles:
        _drawFreckles(canvas);
        break;
      default:
        break;
    }
  }

  void _drawBlush(Canvas canvas, Offset center, Color color) {
    final r = (previewSize.width * 0.06).clamp(15.0, 40.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  void _drawFreckles(Canvas canvas) {
    final noseBase = face!.landmarks[FaceLandmarkType.noseBase];
    if (noseBase == null) return;
    final center = _mapPoint(noseBase.position);
    final spread = previewSize.width * 0.08;
    final rng = math.Random(42); // Deterministic seed for stable freckles
    final paint = Paint()..color = const Color(0xFF8D6E63).withOpacity(0.5);

    for (int i = 0; i < 20; i++) {
      final dx = (rng.nextDouble() - 0.5) * spread * 2;
      final dy = (rng.nextDouble() - 0.5) * spread;
      final r = 1.5 + rng.nextDouble() * 1.5;
      canvas.drawCircle(Offset(center.dx + dx, center.dy + dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceLandmarkPainter oldDelegate) =>
      oldDelegate.face != face ||
      oldDelegate.activeFilters != activeFilters;
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/widgets/face_landmark_painter.dart`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add lib/hair_nails/widgets/face_landmark_painter.dart
git commit -m "feat(hair): add face landmark painter for lip color, accessories, face effects"
```

---

### Task 4: Build Filter Carousel Widget

**Files:**
- Create: `lib/hair_nails/widgets/filter_carousel.dart`

- [ ] **Step 1: Create the filter category tabs + preset carousel**

```dart
// lib/hair_nails/widgets/filter_carousel.dart

import 'package:flutter/material.dart';
import '../models/ar_filter_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Bottom-pinned filter picker: category tabs on top, preset carousel below.
class FilterCarousel extends StatefulWidget {
  final FilterCategory selectedCategory;
  final List<ARFilter> activeFilters;
  final bool isSwahili;
  final ValueChanged<FilterCategory> onCategoryChanged;
  final ValueChanged<ARFilter> onFilterToggled; // Toggle on/off

  const FilterCarousel({
    super.key,
    required this.selectedCategory,
    required this.activeFilters,
    required this.isSwahili,
    required this.onCategoryChanged,
    required this.onFilterToggled,
  });

  @override
  State<FilterCarousel> createState() => _FilterCarouselState();
}

class _FilterCarouselState extends State<FilterCarousel> {
  static const _categoryIcons = {
    FilterCategory.hairColor: Icons.palette_rounded,
    FilterCategory.hairStyle: Icons.face_rounded,
    FilterCategory.lipColor: Icons.lipstick,
    FilterCategory.accessories: Icons.auto_awesome_rounded,
    FilterCategory.faceEffect: Icons.blur_on_rounded,
  };

  static const _categoryLabelsEn = {
    FilterCategory.hairColor: 'Hair',
    FilterCategory.hairStyle: 'Style',
    FilterCategory.lipColor: 'Lips',
    FilterCategory.accessories: 'Acc.',
    FilterCategory.faceEffect: 'Effects',
  };

  static const _categoryLabelsSw = {
    FilterCategory.hairColor: 'Nywele',
    FilterCategory.hairStyle: 'Mtindo',
    FilterCategory.lipColor: 'Midomo',
    FilterCategory.accessories: 'Mapambo',
    FilterCategory.faceEffect: 'Efekti',
  };

  @override
  Widget build(BuildContext context) {
    final presets = ARFilterPresets.byCategory(widget.selectedCategory);

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category tabs
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: FilterCategory.values.map((cat) {
                  final isSelected = cat == widget.selectedCategory;
                  final label = widget.isSwahili
                      ? (_categoryLabelsSw[cat] ?? cat.name)
                      : (_categoryLabelsEn[cat] ?? cat.name);
                  return GestureDetector(
                    onTap: () => widget.onCategoryChanged(cat),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _categoryIcons[cat] ?? Icons.auto_awesome_rounded,
                          size: 20,
                          color: isSelected ? Colors.white : Colors.white54,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.white54,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 20,
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Preset carousel
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: presets.length + 1, // +1 for "None" option
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  // First item = "None" (clear this category)
                  if (i == 0) {
                    final hasActive = widget.activeFilters.any((f) => f.category == widget.selectedCategory);
                    return _FilterChip(
                      label: widget.isSwahili ? 'Bila' : 'None',
                      color: null,
                      icon: Icons.block_rounded,
                      isSelected: !hasActive,
                      onTap: () {
                        // Remove all filters in this category
                        final inCat = widget.activeFilters.where((f) => f.category == widget.selectedCategory).toList();
                        for (final f in inCat) {
                          widget.onFilterToggled(f);
                        }
                      },
                    );
                  }

                  final filter = presets[i - 1];
                  final isActive = widget.activeFilters.contains(filter);

                  return _FilterChip(
                    label: filter.name(widget.isSwahili),
                    color: filter.color,
                    icon: filter.icon,
                    isSelected: isActive,
                    onTap: () => widget.onFilterToggled(filter),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color ?? Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white24,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: color == null
                ? Icon(icon, color: Colors.white70, size: 20)
                : null,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Fix lipstick icon (may not exist in Material Icons)**

Replace `Icons.lipstick` with `Icons.brush_rounded` since `lipstick` is not a standard Material icon:

```dart
FilterCategory.lipColor: Icons.brush_rounded,
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/hair_nails/widgets/filter_carousel.dart`
Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
git add lib/hair_nails/widgets/filter_carousel.dart
git commit -m "feat(hair): add filter carousel widget with category tabs and preset chips"
```

---

### Task 5: Build the Unified AR Try-On Page

**Files:**
- Create: `lib/hair_nails/pages/ar_try_on_page.dart`
- Modify: `lib/hair_nails/pages/hair_nails_home_page.dart`

- [ ] **Step 1: Create the new AR try-on page**

This page combines: camera preview + hair overlay (existing `HairTryOnPainter`) + face landmark overlay (`FaceLandmarkPainter`) + filter carousel + before/after toggle + capture/share.

```dart
// lib/hair_nails/pages/ar_try_on_page.dart

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/ar_filter_models.dart';
import '../widgets/face_landmark_painter.dart';
import '../widgets/filter_carousel.dart';
import '../widgets/hair_try_on_viewport.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class ARTryOnPage extends StatefulWidget {
  final int userId;
  const ARTryOnPage({super.key, required this.userId});

  @override
  State<ARTryOnPage> createState() => _ARTryOnPageState();
}

class _ARTryOnPageState extends State<ARTryOnPage>
    with SingleTickerProviderStateMixin {
  // Camera
  CameraController? _controller;
  FaceDetector? _faceDetector;
  Face? _detectedFace;
  Rect? _faceRect;
  Size _imageSize = Size.zero;
  Size _previewSize = Size.zero;
  bool _isInitializing = true;
  String? _initError;
  int _frameTick = 0;
  bool _processing = false;
  bool _isCapturing = false;

  // Filters
  FilterCategory _selectedCategory = FilterCategory.hairColor;
  final List<ARFilter> _activeFilters = [];
  int _hairColorIndex = 0;
  int _hairStyleIndex = 0;
  bool _showBeforeAfter = false;

  final GlobalKey _captureKey = GlobalKey();

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    _initCamera();
  }

  @override
  void dispose() {
    _disposeCamera();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() { _isInitializing = false; _initError = 'permission'; });
      return;
    }
    try {
      final cameras = await availableCameras();
      var front = cameras.first;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) { front = c; break; }
      }
      final ctrl = CameraController(front, ResolutionPreset.medium, enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _controller = ctrl; _isInitializing = false; });
      await ctrl.startImageStream(_onFrame);
    } catch (e) {
      if (mounted) setState(() { _isInitializing = false; _initError = e.toString(); });
    }
  }

  Future<void> _disposeCamera() async {
    final c = _controller;
    if (c != null) {
      if (c.value.isStreamingImages) await c.stopImageStream();
      await c.dispose();
    }
    _controller = null;
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_controller == null || _faceDetector == null || _processing) return;
    _frameTick++;
    if (_frameTick % 8 != 0) return; // ~4fps
    _processing = true;

    try {
      final input = _buildInput(image);
      if (input == null) return;
      final faces = await _faceDetector!.processImage(input);
      if (!mounted) return;

      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      if (faces.isEmpty) {
        if (_faceRect != null) setState(() { _detectedFace = null; _faceRect = null; });
        return;
      }

      final face = faces.first;
      final rect = _mapRect(face.boundingBox);
      setState(() { _detectedFace = face; _faceRect = rect; });
    } catch (e) {
      if (kDebugMode) debugPrint('[ARTryOn] $e');
    } finally {
      _processing = false;
    }
  }

  InputImage? _buildInput(CameraImage image) {
    final sensor = _controller!.description.sensorOrientation;
    final rotation = InputImageRotation.values.firstWhere(
      (r) => r.rawValue == sensor, orElse: () => InputImageRotation.rotation0deg);

    final Uint8List bytes;
    final int bpr;
    if (Platform.isIOS) {
      bytes = image.planes[0].bytes;
      bpr = image.planes[0].bytesPerRow;
      return InputImage.fromBytes(bytes: bytes, metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, format: InputImageFormat.bgra8888, bytesPerRow: bpr));
    }
    // Android NV21
    if (image.planes.length == 1) {
      bytes = image.planes[0].bytes;
      bpr = image.planes[0].bytesPerRow;
    } else if (image.planes.length == 2) {
      final wb = WriteBuffer();
      for (final p in image.planes) wb.putUint8List(p.bytes);
      bytes = wb.done().buffer.asUint8List();
      bpr = image.planes[0].bytesPerRow;
    } else {
      final y = image.planes[0]; final u = image.planes[1]; final v = image.planes[2];
      final nv21 = Uint8List(y.bytes.length + u.bytes.length + v.bytes.length);
      nv21.setRange(0, y.bytes.length, y.bytes);
      int off = y.bytes.length;
      final n = math.min(v.bytes.length, u.bytes.length);
      for (int i = 0; i < n; i++) { nv21[off++] = v.bytes[i]; nv21[off++] = u.bytes[i]; }
      bytes = nv21;
      bpr = y.bytesPerRow;
    }
    return InputImage.fromBytes(bytes: bytes, metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation, format: InputImageFormat.nv21, bytesPerRow: bpr));
  }

  Rect _mapRect(Rect r) {
    Size img = _imageSize;
    bool swapped = false;
    if ((img.width > img.height) != (_previewSize.width > _previewSize.height)) {
      img = Size(img.height, img.width); swapped = true;
    }
    final s = math.max(_previewSize.width / img.width, _previewSize.height / img.height);
    final dx = (_previewSize.width - img.width * s) / 2;
    final dy = (_previewSize.height - img.height * s) / 2;
    Rect m = swapped ? Rect.fromLTRB(r.top, r.left, r.bottom, r.right) : r;
    var l = m.left * s + dx; var t = m.top * s + dy;
    var ri = m.right * s + dx; var b = m.bottom * s + dy;
    if (_controller?.description.lensDirection == CameraLensDirection.front) {
      final w = ri - l; l = _previewSize.width - ri; ri = l + w;
    }
    return Rect.fromLTRB(l, t, ri, b);
  }

  void _toggleFilter(ARFilter filter) {
    setState(() {
      if (filter.category == FilterCategory.hairColor || filter.category == FilterCategory.lipColor || filter.category == FilterCategory.hairStyle) {
        // Single-select within category
        _activeFilters.removeWhere((f) => f.category == filter.category);
        if (!_activeFilters.contains(filter)) _activeFilters.add(filter);
      } else {
        // Toggle
        if (_activeFilters.contains(filter)) {
          _activeFilters.remove(filter);
        } else {
          _activeFilters.add(filter);
        }
      }
      // Track hair style/color index for the existing HairTryOnPainter
      if (filter.category == FilterCategory.hairStyle && filter.styleIndex != null) {
        _hairStyleIndex = filter.styleIndex!;
      }
      if (filter.category == FilterCategory.hairColor && filter.color != null) {
        _hairColorIndex = ARFilterPresets.hairColors.indexOf(filter);
      }
    });
  }

  Color get _activeHairColor {
    final hc = _activeFilters.where((f) => f.category == FilterCategory.hairColor).firstOrNull;
    return hc?.color ?? const Color(0xFF1A1A1A);
  }

  bool get _hasHairStyle => _activeFilters.any((f) => f.category == FilterCategory.hairStyle);

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final file = File('${Directory.systemTemp.path}/tajiri_ar_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'TAJIRI Hair Try-On'));
    } catch (e) {
      if (kDebugMode) debugPrint('[ARTryOn] capture: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(sw ? 'Jaribu Mtindo' : 'Try On', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
        actions: [
          // Before/after toggle
          IconButton(
            icon: Icon(_showBeforeAfter ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white),
            onPressed: () => setState(() => _showBeforeAfter = !_showBeforeAfter),
            tooltip: sw ? 'Kabla/Baada' : 'Before/After',
          ),
          // Capture
          IconButton(
            icon: _isCapturing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt_rounded, color: Colors.white),
            onPressed: _isCapturing ? null : _capture,
            tooltip: sw ? 'Piga picha' : 'Capture',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera + overlays
          Expanded(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : _initError != null
                    ? Center(child: Text(_initError!, style: const TextStyle(color: Colors.white70)))
                    : LayoutBuilder(builder: (ctx, constraints) {
                        _previewSize = constraints.biggest;
                        return RepaintBoundary(
                          key: _captureKey,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Camera preview (aspect-correct)
                              if (_controller != null)
                                SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    clipBehavior: Clip.hardEdge,
                                    child: SizedBox(
                                      width: _controller!.value.previewSize?.height ?? constraints.maxWidth,
                                      height: _controller!.value.previewSize?.width ?? constraints.maxHeight,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                ),

                              // Hair style overlay (existing painter — only when not showing before)
                              if (!_showBeforeAfter && _hasHairStyle)
                                CustomPaint(
                                  painter: HairTryOnPainter(
                                    faceRect: _faceRect,
                                    styleIndex: _hairStyleIndex,
                                    tint: _activeHairColor,
                                  ),
                                ),

                              // Lip color + accessories + face effects (landmark-based)
                              if (!_showBeforeAfter && _detectedFace != null)
                                CustomPaint(
                                  painter: FaceLandmarkPainter(
                                    face: _detectedFace,
                                    activeFilters: _activeFilters.where((f) =>
                                      f.category == FilterCategory.lipColor ||
                                      f.category == FilterCategory.accessories ||
                                      f.category == FilterCategory.faceEffect
                                    ).toList(),
                                    previewSize: _previewSize,
                                    imageSize: _imageSize,
                                    isFrontCamera: _controller?.description.lensDirection == CameraLensDirection.front,
                                  ),
                                ),

                              // Face guide when no face detected
                              if (_faceRect == null)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.face_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
                                      const SizedBox(height: 8),
                                      Text(
                                        sw ? 'Weka uso wako kwenye kamera' : 'Position your face in the camera',
                                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),

                              // Before/after label
                              if (_showBeforeAfter)
                                Positioned(
                                  top: 12, left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                    child: Text(sw ? 'KABLA' : 'BEFORE', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
          ),

          // Filter carousel at bottom
          FilterCarousel(
            selectedCategory: _selectedCategory,
            activeFilters: _activeFilters,
            isSwahili: sw,
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            onFilterToggled: _toggleFilter,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update home page navigation to use new page**

In `lib/hair_nails/pages/hair_nails_home_page.dart`, find where `VirtualHairTryOnPage` is imported/navigated and add `ARTryOnPage` as an additional option. Search for `VirtualHairTryOnPage` references and add the new page alongside:

```dart
import 'ar_try_on_page.dart';

// In the style gallery AppBar action or wherever try-on is launched:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ARTryOnPage(userId: widget.userId),
));
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/hair_nails/pages/ar_try_on_page.dart`
Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
git add lib/hair_nails/pages/ar_try_on_page.dart lib/hair_nails/pages/hair_nails_home_page.dart
git commit -m "feat(hair): add unified AR try-on page with filter carousel"
```

---

## Phase 2: Hair Segmentation (face_detection_tflite)

### Task 6: Add face_detection_tflite Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

```yaml
# In pubspec.yaml dependencies section, add:
  face_detection_tflite: ^0.1.6
```

- [ ] **Step 2: Run pub get**

Run: `flutter pub get`
Expected: Resolves successfully. May download opencv_dart and flutter_litert as transitive dependencies.

- [ ] **Step 3: Verify build still works**

Run: `flutter analyze`
Expected: No new errors from the dependency addition.

Note: `face_detection_tflite` requires native build changes. On Android, ensure `minSdkVersion` is >= 24 in `android/app/build.gradle`. On iOS, ensure deployment target is >= 12.0.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add face_detection_tflite for hair segmentation + 468-point mesh"
```

---

### Task 7: Build Hair Segmentation Painter

**Files:**
- Create: `lib/hair_nails/widgets/hair_segmentation_painter.dart`

- [ ] **Step 1: Create the hair mask color overlay painter**

This painter takes a per-pixel hair probability mask from `face_detection_tflite` and renders a color overlay with the desired hair color using multiply blend mode.

```dart
// lib/hair_nails/widgets/hair_segmentation_painter.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders a hair color overlay using a per-pixel segmentation mask.
/// The [hairMask] is a Float32List where each value (0.0-1.0) represents
/// the probability that the pixel is hair.
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

  ui.Image? _cachedImage;
  Float32List? _lastMask;

  @override
  void paint(Canvas canvas, Size size) {
    if (hairMask == null || hairMask!.isEmpty) return;

    // Build an RGBA image from the mask
    final pixels = Uint8List(maskWidth * maskHeight * 4);
    final r = targetColor.red;
    final g = targetColor.green;
    final b = targetColor.blue;

    for (int i = 0; i < maskWidth * maskHeight; i++) {
      final prob = hairMask![i];
      if (prob >= threshold) {
        final a = (prob * opacity * 255).round().clamp(0, 255);
        pixels[i * 4] = r;
        pixels[i * 4 + 1] = g;
        pixels[i * 4 + 2] = b;
        pixels[i * 4 + 3] = a;
      }
      // else: transparent (already 0)
    }

    // Draw the mask image scaled to fill the canvas
    final paint = Paint()
      ..blendMode = BlendMode.multiply
      ..filterQuality = FilterQuality.medium;

    // Use drawImageRect for scaling
    // We need to create the image from pixels — use Canvas.drawRawPoints or
    // paint each pixel as a rect for simplicity given the 256x256 mask size
    final cellW = size.width / maskWidth;
    final cellH = size.height / maskHeight;

    for (int y = 0; y < maskHeight; y++) {
      for (int x = 0; x < maskWidth; x++) {
        final idx = y * maskWidth + x;
        final prob = hairMask![idx];
        if (prob < threshold) continue;

        final a = (prob * opacity * 255).round().clamp(0, 255);
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5);
        canvas.drawRect(rect, Paint()
          ..color = targetColor.withAlpha(a)
          ..blendMode = BlendMode.multiply);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HairSegmentationPainter oldDelegate) =>
      oldDelegate.hairMask != hairMask ||
      oldDelegate.targetColor != targetColor ||
      oldDelegate.threshold != threshold;
}
```

Note: The pixel-by-pixel approach is simple but may be slow for 256x256 masks (65K iterations per frame). A more performant approach would convert the mask to a `ui.Image` using `decodeImageFromPixels` and draw it once. This can be optimized in a follow-up if performance is an issue.

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/widgets/hair_segmentation_painter.dart`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add lib/hair_nails/widgets/hair_segmentation_painter.dart
git commit -m "feat(hair): add hair segmentation painter for real hair color overlay"
```

---

### Task 8: Integrate Hair Segmentation into AR Try-On Page

**Files:**
- Modify: `lib/hair_nails/pages/ar_try_on_page.dart`

- [ ] **Step 1: Add face_detection_tflite import and hair segmentation pipeline**

Add to the imports:
```dart
import 'package:face_detection_tflite/face_detection_tflite.dart' as tflite;
```

Add fields to `_ARTryOnPageState`:
```dart
tflite.FaceDetector? _tfliteDetector;
Float32List? _hairMask;
int _maskWidth = 256;
int _maskHeight = 256;
bool _segProcessing = false;
int _segFrameTick = 0;
```

In `initState`, initialize the TFLite detector:
```dart
_tfliteDetector = tflite.FaceDetector();
_tfliteDetector!.initialize();
```

In `dispose`, clean up:
```dart
_tfliteDetector?.dispose();
```

- [ ] **Step 2: Run hair segmentation on camera frames**

Add a separate method called from `_onFrame` at a lower frequency (every 15th frame = ~2fps for segmentation):

```dart
Future<void> _runSegmentation(CameraImage image) async {
  _segFrameTick++;
  if (_segFrameTick % 15 != 0) return;
  if (_segProcessing || _tfliteDetector == null) return;
  // Only run if a hair color filter is active
  if (!_activeFilters.any((f) => f.category == FilterCategory.hairColor)) return;

  _segProcessing = true;
  try {
    final seg = await _tfliteDetector!.selfieSegmentation(
      /* pass camera image mat */
      mode: tflite.SelfieSegmentationMode.multiclass,
    );
    if (!mounted) return;
    setState(() {
      _hairMask = seg.hairMask;
      _maskWidth = seg.width;
      _maskHeight = seg.height;
    });
  } catch (e) {
    if (kDebugMode) debugPrint('[ARTryOn] segmentation: $e');
  } finally {
    _segProcessing = false;
  }
}
```

Note: The exact API for `face_detection_tflite` may differ. Check the package documentation for the correct method signatures. The key is to get a `Float32List` hair mask.

- [ ] **Step 3: Add HairSegmentationPainter to the render stack**

In the `build` method's `Stack`, add the segmentation painter when a hair color filter is active:

```dart
// Hair color via segmentation mask (Phase 2)
if (!_showBeforeAfter && _hairMask != null && _activeFilters.any((f) => f.category == FilterCategory.hairColor))
  CustomPaint(
    painter: HairSegmentationPainter(
      hairMask: _hairMask,
      maskWidth: _maskWidth,
      maskHeight: _maskHeight,
      targetColor: _activeHairColor,
    ),
  ),
```

- [ ] **Step 4: Verify compilation**

Run: `flutter analyze lib/hair_nails/pages/ar_try_on_page.dart`
Expected: 0 errors (may have warnings if face_detection_tflite API doesn't exactly match)

- [ ] **Step 5: Commit**

```bash
git add lib/hair_nails/pages/ar_try_on_page.dart
git commit -m "feat(hair): integrate hair segmentation for real hair color changes"
```

---

## Phase 3: Polish & UX

### Task 9: Before/After Comparison Toggle

Already implemented in Task 5 as `_showBeforeAfter` toggle. The `BEFORE` label shows when active, and all filter overlays are hidden, showing only the raw camera feed.

No additional work needed — this task is complete from Task 5.

---

### Task 10: Wire AR Try-On into the App

**Files:**
- Modify: `lib/hair_nails/pages/hair_nails_home_page.dart`
- Modify: `lib/hair_nails/pages/style_gallery_page.dart`

- [ ] **Step 1: Add AR Try-On button to home page**

In the home page, find the existing try-on/virtual section and add a prominent "AR Try-On" card:

```dart
import 'ar_try_on_page.dart';

// Add a card in the quick actions or hero area:
Material(
  color: _kPrimary,
  borderRadius: BorderRadius.circular(14),
  child: InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(
      builder: (_) => ARTryOnPage(userId: widget.userId),
    )),
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sw ? 'Jaribu Mtindo' : 'AR Try-On',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(sw ? 'Jaribu rangi ya nywele, midomo, na mapambo' : 'Try hair color, lip color & accessories',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
            ],
          )),
          Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.7)),
        ],
      ),
    ),
  ),
),
```

- [ ] **Step 2: Add AR Try-On button to style gallery AppBar**

In `style_gallery_page.dart`, add an AppBar action button:

```dart
import 'ar_try_on_page.dart';

// In AppBar actions:
IconButton(
  icon: const Icon(Icons.auto_awesome_rounded),
  onPressed: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => ARTryOnPage(userId: widget.userId),
  )),
  tooltip: 'AR Try-On',
),
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/hair_nails/`
Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
git add lib/hair_nails/pages/hair_nails_home_page.dart lib/hair_nails/pages/style_gallery_page.dart
git commit -m "feat(hair): wire AR try-on page into home and style gallery"
```

---

## Summary

| Task | Phase | What It Does |
|------|-------|-------------|
| 1 | P1 | Enable ML Kit 133 contour points + 10 landmarks |
| 2 | P1 | Define filter models (hair/lip/accessories/effects presets) |
| 3 | P1 | Build face landmark painter (lip color, sunglasses, crown, blush, freckles) |
| 4 | P1 | Build filter carousel UI (category tabs + preset chips) |
| 5 | P1 | Build unified AR try-on page (camera + overlays + carousel + capture) |
| 6 | P2 | Add face_detection_tflite dependency |
| 7 | P2 | Build hair segmentation painter (per-pixel color overlay) |
| 8 | P2 | Integrate segmentation into AR page |
| 9 | P3 | Before/after toggle (already done in Task 5) |
| 10 | P3 | Wire AR page into home + style gallery |
