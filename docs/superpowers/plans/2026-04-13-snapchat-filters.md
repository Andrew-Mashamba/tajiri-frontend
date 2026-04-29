# Snapchat-Style Filters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete Snapchat-style filter system in `lib/hair_nails/` with color grading, beauty filters, wig/sticker overlays, and background effects — all applied to a live camera preview and capturable as photo/video.

**Architecture:** Rebuild `ar_try_on_page.dart` as the central filter camera. A `FilterEngine` manages all active filters and composes them into a layered rendering pipeline: color matrix → beauty blur → face overlays (wigs, stickers, lips) → background effects. Each layer is a `CustomPainter` or `ColorFiltered` widget stacked over the camera preview. The carousel UI uses Snapchat-style horizontal swipe with filter preview thumbnails.

**Tech Stack:** Flutter 3+ (Dart ^3.10.1), `camera` package (live preview), `google_ml_kit` (face detection), `ColorFilter.matrix` (color grading), `BackdropFilter` + `ImageFilter.blur` (beauty smoothing), `CustomPainter` (overlays), PNG assets for wigs/stickers, `RepaintBoundary` (capture).

**Existing dependencies already in pubspec.yaml:** `camera`, `google_ml_kit`, `image`, `screenshot`, `share_plus`, `permission_handler`, `image_picker`.

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/hair_nails/models/color_filter_presets.dart` | 30+ color matrix presets (Kodachrome, Polaroid, Nashville, etc.) |
| `lib/hair_nails/models/wig_asset.dart` | Wig asset metadata (name, path, anchor points, Swahili names) |
| `lib/hair_nails/services/filter_engine.dart` | Central state manager — active filters, intensity, composition |
| `lib/hair_nails/services/color_matrix_utils.dart` | Matrix math: multiply, brightness, contrast, saturation, interpolation |
| `lib/hair_nails/widgets/wig_overlay_painter.dart` | Renders PNG wig assets anchored to face landmarks |
| `lib/hair_nails/widgets/filter_intensity_slider.dart` | Vertical intensity slider widget |
| `lib/hair_nails/widgets/filter_preview_strip.dart` | Horizontal strip of filter preview thumbnails |

### Rebuild Files (full rewrite)
| File | What Changes |
|------|-------------|
| `lib/hair_nails/models/ar_filter_models.dart` | Add `colorFilter`, `beautyFilter`, `wigFilter`, `backgroundEffect` categories; add intensity field |
| `lib/hair_nails/pages/ar_try_on_page.dart` | Complete rebuild — new camera pipeline with all 4 tiers |
| `lib/hair_nails/widgets/filter_carousel.dart` | Snapchat-style swipe UX with preview thumbnails |

### Modify Files (targeted edits)
| File | What Changes |
|------|-------------|
| `lib/hair_nails/widgets/face_landmark_painter.dart` | Add contour effect, improve existing effects |
| `lib/hair_nails/widgets/hair_try_on_viewport.dart` | Wire to FilterEngine for embedded mode |
| `lib/hair_nails/pages/hair_nails_home_page.dart` | Update AR try-on card + navigation |
| `pubspec.yaml` | Add `assets/filter_assets/wigs_processed/` to asset list |

### Asset Files (already prepared)
```
assets/filter_assets/wigs_processed/
├── wig_ash_blonde_straight.png
├── wig_auburn_bob.png
├── wig_black_curly.png
├── wig_black_white_wave.png
├── wig_blonde_wavy.png
├── wig_caramel_brown.png
├── wig_chocolate_wave.png
├── wig_honey_brown_straight.png
├── wig_jet_black_sleek.png
├── wig_platinum_blonde.png
├── wig_sandy_blonde_wave.png
└── wig_silver_straight.png
```

---

## Task 1: Color Matrix Utilities

**Files:**
- Create: `lib/hair_nails/services/color_matrix_utils.dart`

- [ ] **Step 1: Create the color matrix utility class**

This file provides pure math functions for composing 4x5 color matrices used by Flutter's `ColorFilter.matrix()`. These are the building blocks for all color filters.

```dart
// lib/hair_nails/services/color_matrix_utils.dart

/// Utility functions for 4x5 color matrix composition.
///
/// Flutter's [ColorFilter.matrix] takes a 20-element List<double> representing
/// a 4x5 row-major matrix applied to [R, G, B, A, 1] pixel vectors.
/// Row 0 = red output, row 1 = green, row 2 = blue, row 3 = alpha.
class ColorMatrixUtils {
  ColorMatrixUtils._();

  /// Identity matrix — no color change.
  static const List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// Multiply two 4x5 color matrices (treating as 5x5 with implicit last row [0,0,0,0,1]).
  static List<double> multiply(List<double> a, List<double> b) {
    final r = List<double>.filled(20, 0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) sum += a[i * 5 + 4];
        r[i * 5 + j] = sum;
      }
    }
    return r;
  }

  /// Chain multiple matrices: apply first, then second, etc.
  static List<double> chain(List<List<double>> matrices) {
    var result = identity.toList();
    for (final m in matrices) {
      result = multiply(result, m);
    }
    return result;
  }

  /// Linearly interpolate between identity and [matrix] by [t] (0.0–1.0).
  /// Used for filter intensity control.
  static List<double> lerp(List<double> matrix, double t) {
    final c = t.clamp(0.0, 1.0);
    return List.generate(20, (i) => identity[i] + (matrix[i] - identity[i]) * c);
  }

  // --- Parameterized generators ---

  /// Brightness: [amount] 0.0 = black, 1.0 = normal, 2.0 = 2x bright.
  static List<double> brightness(double amount) => [
    amount, 0, 0, 0, 0,
    0, amount, 0, 0, 0,
    0, 0, amount, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// Contrast: [amount] 0.0 = grey, 1.0 = normal, 2.0 = high contrast.
  static List<double> contrast(double amount) {
    final o = (-0.5 * amount + 0.5) * 255;
    return [
      amount, 0, 0, 0, o,
      0, amount, 0, 0, o,
      0, 0, amount, 0, o,
      0, 0, 0, 1, 0,
    ];
  }

  /// Saturation: [amount] 0.0 = greyscale, 1.0 = normal, 2.0 = oversaturated.
  static List<double> saturation(double amount) {
    final x = (amount * 2 / 3) + 1.0 / 3.0;
    final y = (1.0 - x) / 2.0;
    return [
      x, y, y, 0, 0,
      y, x, y, 0, 0,
      y, y, x, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// Sepia toning at given [intensity] (0.0–1.0).
  static List<double> sepia(double intensity) => lerp(const [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ], intensity);

  /// Grayscale (perceptual luminance) at given [intensity] (0.0–1.0).
  static List<double> grayscale(double intensity) => lerp(const [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ], intensity);

  /// Hue rotation by [degrees] (-180 to 180).
  static List<double> hueRotate(double degrees) {
    final rad = degrees * 3.14159265 / 180;
    final cos = _cos(rad);
    final sin = _sin(rad);
    return [
      0.213 + cos * 0.787 - sin * 0.213,
      0.715 - cos * 0.715 - sin * 0.715,
      0.072 - cos * 0.072 + sin * 0.928, 0, 0,
      0.213 - cos * 0.213 + sin * 0.143,
      0.715 + cos * 0.285 + sin * 0.140,
      0.072 - cos * 0.072 - sin * 0.283, 0, 0,
      0.213 - cos * 0.213 - sin * 0.787,
      0.715 - cos * 0.715 + sin * 0.715,
      0.072 + cos * 0.928 + sin * 0.072, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static double _cos(double r) {
    // Use dart:math via import
    return r == 0 ? 1.0 : _cosApprox(r);
  }

  static double _sin(double r) => _cosApprox(r - 1.5707963);

  // Fast cosine approximation (Bhaskara I)
  static double _cosApprox(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159265) x -= 6.28318530;
    while (x < -3.14159265) x += 6.28318530;
    final x2 = x * x;
    return (1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720);
  }
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND && flutter analyze lib/hair_nails/services/color_matrix_utils.dart`

Expected: no errors

---

## Task 2: Color Filter Presets

**Files:**
- Create: `lib/hair_nails/models/color_filter_presets.dart`

- [ ] **Step 1: Create the presets file with 30+ filter matrices**

Each preset is a named constant with the exact 20-element color matrix, bilingual names, and a thumbnail preview color.

```dart
// lib/hair_nails/models/color_filter_presets.dart

import 'package:flutter/material.dart';
import '../services/color_matrix_utils.dart';

/// A single named color filter preset.
class ColorFilterPreset {
  final String id;
  final String nameEn;
  final String nameSw;
  final List<double> matrix;
  final Color previewTint; // Used for thumbnail tinting

  const ColorFilterPreset({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.matrix,
    required this.previewTint,
  });

  String name(bool isSwahili) => isSwahili ? nameSw : nameEn;

  /// Get matrix at given intensity (0.0 = identity, 1.0 = full effect).
  List<double> matrixAt(double intensity) =>
      ColorMatrixUtils.lerp(matrix, intensity);
}

/// All available color filter presets organized by category.
class ColorFilterPresets {
  ColorFilterPresets._();

  // ── No filter ──
  static const none = ColorFilterPreset(
    id: 'none', nameEn: 'Original', nameSw: 'Asili',
    matrix: ColorMatrixUtils.identity,
    previewTint: Color(0x00000000),
  );

  // ── Film Emulations ──
  static const kodachrome = ColorFilterPreset(
    id: 'kodachrome', nameEn: 'Kodachrome', nameSw: 'Kodachrome',
    matrix: [
      1.129, -0.397, -0.040, 0, 63.730,
      -0.164, 1.084, -0.055, 0, 24.732,
      -0.168, -0.560, 1.601, 0, 35.630,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x30FF9800),
  );

  static const polaroid = ColorFilterPreset(
    id: 'polaroid', nameEn: 'Polaroid', nameSw: 'Polaroid',
    matrix: [
      1.438, -0.062, -0.062, 0, 0,
      -0.122, 1.378, -0.122, 0, 0,
      -0.016, -0.016, 1.483, 0, 0,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x20E3F2FD),
  );

  static const technicolor = ColorFilterPreset(
    id: 'technicolor', nameEn: 'Technicolor', nameSw: 'Technicolor',
    matrix: [
      1.913, -0.855, -0.092, 0, 11.794,
      -0.309, 1.766, -0.106, 0, -70.352,
      -0.231, -0.750, 1.848, 0, 30.951,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x30FF5722),
  );

  static const vintage = ColorFilterPreset(
    id: 'vintage', nameEn: 'Vintage', nameSw: 'Zamani',
    matrix: [
      0.628, 0.320, -0.040, 0, 9.651,
      0.026, 0.644, 0.033, 0, 7.463,
      0.047, -0.085, 0.524, 0, 5.159,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x30795548),
  );

  static const browni = ColorFilterPreset(
    id: 'browni', nameEn: 'Browni', nameSw: 'Browni',
    matrix: [
      0.600, 0.346, -0.271, 0, 47.432,
      -0.038, 0.861, 0.151, 0, -36.968,
      0.241, -0.074, 0.450, 0, -7.562,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x304E342E),
  );

  // ── Instagram-Style Filters ──
  static final clarendon = ColorFilterPreset(
    id: 'clarendon', nameEn: 'Clarendon', nameSw: 'Clarendon',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.2),
      ColorMatrixUtils.saturation(1.35),
    ]),
    previewTint: Color(0x207FB3E3),
  );

  static final gingham = ColorFilterPreset(
    id: 'gingham', nameEn: 'Gingham', nameSw: 'Gingham',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.hueRotate(-10),
      ColorMatrixUtils.brightness(1.05),
    ]),
    previewTint: Color(0x20E8EAF6),
  );

  static final moon = ColorFilterPreset(
    id: 'moon', nameEn: 'Moon', nameSw: 'Mwezi',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.contrast(1.1),
      ColorMatrixUtils.grayscale(1.0),
    ]),
    previewTint: Color(0x309E9E9E),
  );

  static final lark = ColorFilterPreset(
    id: 'lark', nameEn: 'Lark', nameSw: 'Lark',
    matrix: ColorMatrixUtils.contrast(0.9),
    previewTint: Color(0x20FFF3E0),
  );

  static final reyes = ColorFilterPreset(
    id: 'reyes', nameEn: 'Reyes', nameSw: 'Reyes',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.sepia(0.22),
      ColorMatrixUtils.contrast(0.85),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(0.75),
    ]),
    previewTint: Color(0x20EFEBE9),
  );

  static final juno = ColorFilterPreset(
    id: 'juno', nameEn: 'Juno', nameSw: 'Juno',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.1),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(1.3),
    ]),
    previewTint: Color(0x30FFEB3B),
  );

  static final slumber = ColorFilterPreset(
    id: 'slumber', nameEn: 'Slumber', nameSw: 'Usingizi',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.brightness(1.05),
      ColorMatrixUtils.saturation(0.66),
    ]),
    previewTint: Color(0x20CE93D8),
  );

  static final nashville = ColorFilterPreset(
    id: 'nashville', nameEn: 'Nashville', nameSw: 'Nashville',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.2),
      ColorMatrixUtils.brightness(1.05),
      ColorMatrixUtils.saturation(1.2),
      ColorMatrixUtils.sepia(0.2),
    ]),
    previewTint: Color(0x30FFCC80),
  );

  static final valencia = ColorFilterPreset(
    id: 'valencia', nameEn: 'Valencia', nameSw: 'Valencia',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.08),
      ColorMatrixUtils.brightness(1.08),
      ColorMatrixUtils.sepia(0.08),
    ]),
    previewTint: Color(0x20FFAB91),
  );

  static final walden = ColorFilterPreset(
    id: 'walden', nameEn: 'Walden', nameSw: 'Walden',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.hueRotate(-10),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.sepia(0.3),
      ColorMatrixUtils.saturation(1.6),
    ]),
    previewTint: Color(0x20BBDEFB),
  );

  static final inkwell = ColorFilterPreset(
    id: 'inkwell', nameEn: 'Inkwell', nameSw: 'Wino',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.sepia(0.3),
      ColorMatrixUtils.contrast(1.1),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.grayscale(1.0),
    ]),
    previewTint: Color(0x30616161),
  );

  static final lofi = ColorFilterPreset(
    id: 'lofi', nameEn: 'Lo-Fi', nameSw: 'Lo-Fi',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.5),
      ColorMatrixUtils.saturation(1.1),
    ]),
    previewTint: Color(0x30FF5722),
  );

  static final xpro2 = ColorFilterPreset(
    id: 'xpro2', nameEn: 'X-Pro II', nameSw: 'X-Pro II',
    matrix: ColorMatrixUtils.sepia(0.3),
    previewTint: Color(0x30FFC107),
  );

  // ── Mood/Effect Filters ──
  static const lsd = ColorFilterPreset(
    id: 'lsd', nameEn: 'Psychedelic', nameSw: 'Rangi Kali',
    matrix: [
      2, -0.4, 0.5, 0, 0,
      -0.5, 2, -0.4, 0, 0,
      -0.4, -0.5, 3, 0, 0,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x30E040FB),
  );

  static const sepia100 = ColorFilterPreset(
    id: 'sepia', nameEn: 'Sepia', nameSw: 'Sepia',
    matrix: [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x308D6E63),
  );

  static const bw = ColorFilterPreset(
    id: 'bw', nameEn: 'B&W', nameSw: 'Nyeusi & Nyeupe',
    matrix: [
      0.3, 0.6, 0.1, 0, 0,
      0.3, 0.6, 0.1, 0, 0,
      0.3, 0.6, 0.1, 0, 0,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x30424242),
  );

  static final warmGlow = ColorFilterPreset(
    id: 'warm', nameEn: 'Warm Glow', nameSw: 'Joto',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.brightness(1.08),
      ColorMatrixUtils.saturation(1.15),
      [
        1.1, 0, 0, 0, 8,
        0, 1.05, 0, 0, 4,
        0, 0, 0.95, 0, -5,
        0, 0, 0, 1, 0,
      ],
    ]),
    previewTint: Color(0x30FF9800),
  );

  static final coolBreeze = ColorFilterPreset(
    id: 'cool', nameEn: 'Cool Breeze', nameSw: 'Baridi',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.brightness(1.05),
      [
        0.95, 0, 0, 0, -5,
        0, 1.0, 0, 0, 0,
        0, 0, 1.1, 0, 10,
        0, 0, 0, 1, 0,
      ],
    ]),
    previewTint: Color(0x3042A5F5),
  );

  static final golden = ColorFilterPreset(
    id: 'golden', nameEn: 'Golden Hour', nameSw: 'Saa ya Dhahabu',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(1.2),
      [
        1.15, 0.05, 0, 0, 10,
        0.02, 1.08, 0, 0, 5,
        0, 0, 0.85, 0, -10,
        0, 0, 0, 1, 0,
      ],
    ]),
    previewTint: Color(0x30FFB74D),
  );

  static final night = ColorFilterPreset(
    id: 'night', nameEn: 'Night', nameSw: 'Usiku',
    matrix: [
      -2.0, -1.0, 0, 0, 0,
      -1.0, 0, 1.0, 0, 0,
      0, 1.0, 2.0, 0, 0,
      0, 0, 0, 1, 0,
    ],
    previewTint: Color(0x301A237E),
  );

  static final fade = ColorFilterPreset(
    id: 'fade', nameEn: 'Fade', nameSw: 'Fifia',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(0.85),
      ColorMatrixUtils.saturation(0.8),
      ColorMatrixUtils.brightness(1.1),
    ]),
    previewTint: Color(0x20ECEFF1),
  );

  static final vivid = ColorFilterPreset(
    id: 'vivid', nameEn: 'Vivid', nameSw: 'Hai',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.15),
      ColorMatrixUtils.saturation(1.4),
      ColorMatrixUtils.brightness(1.05),
    ]),
    previewTint: Color(0x30F44336),
  );

  static final emerald = ColorFilterPreset(
    id: 'emerald', nameEn: 'Emerald', nameSw: 'Zumaridi',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.saturation(1.1),
      [
        0.9, 0.05, 0, 0, 0,
        0, 1.15, 0, 0, 5,
        0, 0.05, 0.95, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ]),
    previewTint: Color(0x3066BB6A),
  );

  static final rose = ColorFilterPreset(
    id: 'rose', nameEn: 'Rosé', nameSw: 'Waridi',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.brightness(1.05),
      [
        1.1, 0, 0, 0, 8,
        0, 0.95, 0, 0, -2,
        0, 0, 1.05, 0, 5,
        0, 0, 0, 1, 0,
      ],
    ]),
    previewTint: Color(0x30F48FB1),
  );

  static final chrome = ColorFilterPreset(
    id: 'chrome', nameEn: 'Chrome', nameSw: 'Chrome',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.25),
      ColorMatrixUtils.saturation(0.9),
      ColorMatrixUtils.brightness(1.05),
    ]),
    previewTint: Color(0x30B0BEC5),
  );

  static final dramatic = ColorFilterPreset(
    id: 'dramatic', nameEn: 'Dramatic', nameSw: 'Kali',
    matrix: ColorMatrixUtils.chain([
      ColorMatrixUtils.contrast(1.4),
      ColorMatrixUtils.saturation(0.85),
    ]),
    previewTint: Color(0x30263238),
  );

  // ── Ordered list for carousel display ──
  static final List<ColorFilterPreset> all = [
    none,
    // Popular / Instagram-style
    clarendon, nashville, valencia, juno, lark, reyes, gingham,
    walden, slumber, moon, inkwell, lofi, xpro2,
    // Film emulations
    kodachrome, polaroid, technicolor, vintage, browni,
    // Moods
    warmGlow, coolBreeze, golden, night, rose, emerald,
    chrome, dramatic, vivid, fade,
    // Special effects
    sepia100, bw, lsd,
  ];
}
```

- [ ] **Step 2: Verify file compiles**

Run: `flutter analyze lib/hair_nails/models/color_filter_presets.dart`

Expected: no errors (may have info-level notes about `final` on static fields)

---

## Task 3: Wig Asset Model

**Files:**
- Create: `lib/hair_nails/models/wig_asset.dart`

- [ ] **Step 1: Create wig asset metadata model**

```dart
// lib/hair_nails/models/wig_asset.dart

/// Metadata for a processedwig asset PNG.
class WigAsset {
  final String id;
  final String nameEn;
  final String nameSw;
  final String assetPath; // e.g. 'assets/filter_assets/wigs_processed/wig_xxx.png'
  final WigStyle style;
  final WigLength length;

  const WigAsset({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.assetPath,
    required this.style,
    required this.length,
  });

  String name(bool isSwahili) => isSwahili ? nameSw : nameEn;
}

enum WigStyle { straight, wavy, curly }
enum WigLength { short, medium, long }

class WigAssets {
  WigAssets._();

  static const _base = 'assets/filter_assets/wigs_processed';

  static const List<WigAsset> all = [
    WigAsset(
      id: 'black_white_wave', nameEn: 'Black & White Wave', nameSw: 'Wimbi Nyeusi na Nyeupe',
      assetPath: '$_base/wig_black_white_wave.png', style: WigStyle.wavy, length: WigLength.long,
    ),
    WigAsset(
      id: 'honey_brown_straight', nameEn: 'Honey Brown Straight', nameSw: 'Kahawia Asali Nyofu',
      assetPath: '$_base/wig_honey_brown_straight.png', style: WigStyle.straight, length: WigLength.long,
    ),
    WigAsset(
      id: 'chocolate_wave', nameEn: 'Chocolate Wave', nameSw: 'Wimbi la Chokoleti',
      assetPath: '$_base/wig_chocolate_wave.png', style: WigStyle.wavy, length: WigLength.long,
    ),
    WigAsset(
      id: 'black_curly', nameEn: 'Black Curly', nameSw: 'Nyeusi Kupindapinda',
      assetPath: '$_base/wig_black_curly.png', style: WigStyle.curly, length: WigLength.medium,
    ),
    WigAsset(
      id: 'ash_blonde_straight', nameEn: 'Ash Blonde Straight', nameSw: 'Blonde Majivu Nyofu',
      assetPath: '$_base/wig_ash_blonde_straight.png', style: WigStyle.straight, length: WigLength.long,
    ),
    WigAsset(
      id: 'blonde_wavy', nameEn: 'Blonde Wavy', nameSw: 'Blonde Mawimbi',
      assetPath: '$_base/wig_blonde_wavy.png', style: WigStyle.wavy, length: WigLength.long,
    ),
    WigAsset(
      id: 'auburn_bob', nameEn: 'Auburn Bob', nameSw: 'Bob Kahawia-Nyekundu',
      assetPath: '$_base/wig_auburn_bob.png', style: WigStyle.straight, length: WigLength.medium,
    ),
    WigAsset(
      id: 'silver_straight', nameEn: 'Silver Straight', nameSw: 'Fedha Nyofu',
      assetPath: '$_base/wig_silver_straight.png', style: WigStyle.straight, length: WigLength.long,
    ),
    WigAsset(
      id: 'platinum_blonde', nameEn: 'Platinum Blonde', nameSw: 'Platinamu Blonde',
      assetPath: '$_base/wig_platinum_blonde.png', style: WigStyle.straight, length: WigLength.long,
    ),
    WigAsset(
      id: 'sandy_blonde_wave', nameEn: 'Sandy Blonde Wave', nameSw: 'Blonde Mchanga Wimbi',
      assetPath: '$_base/wig_sandy_blonde_wave.png', style: WigStyle.wavy, length: WigLength.long,
    ),
    WigAsset(
      id: 'jet_black_sleek', nameEn: 'Jet Black Sleek', nameSw: 'Nyeusi Laini',
      assetPath: '$_base/wig_jet_black_sleek.png', style: WigStyle.straight, length: WigLength.long,
    ),
    WigAsset(
      id: 'caramel_brown', nameEn: 'Caramel Brown', nameSw: 'Kahawia Karameli',
      assetPath: '$_base/wig_caramel_brown.png', style: WigStyle.straight, length: WigLength.long,
    ),
  ];
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/models/wig_asset.dart`

---

## Task 4: Expand AR Filter Models

**Files:**
- Modify: `lib/hair_nails/models/ar_filter_models.dart`

- [ ] **Step 1: Rewrite ar_filter_models.dart with new categories and intensity support**

The new model adds `colorFilter`, `wigFilter`, and `backgroundEffect` categories, plus an `intensity` property.

```dart
// lib/hair_nails/models/ar_filter_models.dart

import 'package:flutter/material.dart';

enum FilterCategory {
  colorFilter,    // Tier 1: Color grading (Kodachrome, Polaroid, etc.)
  beautyFilter,   // Tier 2: Skin smooth, face reshape
  hairColor,      // Existing: Hair color tinting
  hairStyle,      // Existing: Hair silhouette styles
  wigFilter,      // Tier 3: Real wig PNG overlays
  lipColor,       // Existing: Lip tinting
  accessories,    // Existing: Sunglasses, crown, etc.
  faceEffect,     // Existing: Blush, freckles
  backgroundEffect, // Tier 4: Background blur/replace
}

enum FilterType {
  // ── Color Filters (Tier 1) ──
  colorPreset,  // Generic — actual preset stored in colorPresetId

  // ── Beauty Filters (Tier 2) ──
  beautySmoothSkin, beautySlimFace, beautyBigEyes, beautyWhiteTeeth,

  // ── Hair Color (existing) ──
  hairColorBlack, hairColorBrown, hairColorRed, hairColorBlonde,
  hairColorBlue, hairColorPink, hairColorBurgundy, hairColorGrey,

  // ── Lip Color (existing) ──
  lipRed, lipPink, lipNude, lipBerry, lipCoral, lipBrown,

  // ── Accessories (existing) ──
  accSunglasses, accRoundGlasses, accCrown, accFlowerCrown, accHeadband,

  // ── Hair Style (existing) ──
  styleAfro, styleBraids, styleBob, styleBun,
  styleCornrows, styleLocs, styleBantuKnots, styleTwistOut,

  // ── Wig Try-On (Tier 3) ──
  wigOverlay,  // Generic — actual wig stored in wigAssetId

  // ── Face Effects (existing) ──
  fxSmooth, fxBlush, fxFreckles, fxContour,

  // ── Background Effects (Tier 4) ──
  bgBlurLight, bgBlurHeavy, bgReplace,
}

class ARFilter {
  final FilterType type;
  final FilterCategory category;
  final String nameEn;
  final String nameSw;
  final Color? color;
  final int? styleIndex;
  final IconData icon;
  final String? colorPresetId; // For colorFilter type
  final String? wigAssetId;    // For wigFilter type
  final double defaultIntensity;

  const ARFilter({
    required this.type,
    required this.category,
    required this.nameEn,
    required this.nameSw,
    this.color,
    this.styleIndex,
    this.icon = Icons.auto_awesome_rounded,
    this.colorPresetId,
    this.wigAssetId,
    this.defaultIntensity = 1.0,
  });

  String name(bool isSwahili) => isSwahili ? nameSw : nameEn;
}

class ARFilterPresets {
  // ── Beauty Filters (Tier 2) ──
  static const List<ARFilter> beautyFilters = [
    ARFilter(type: FilterType.beautySmoothSkin, category: FilterCategory.beautyFilter,
      nameEn: 'Smooth Skin', nameSw: 'Ngozi Laini', icon: Icons.blur_on_rounded, defaultIntensity: 0.6),
    ARFilter(type: FilterType.beautySlimFace, category: FilterCategory.beautyFilter,
      nameEn: 'Slim Face', nameSw: 'Uso Mwembamba', icon: Icons.face_retouching_natural_rounded, defaultIntensity: 0.4),
    ARFilter(type: FilterType.beautyBigEyes, category: FilterCategory.beautyFilter,
      nameEn: 'Big Eyes', nameSw: 'Macho Makubwa', icon: Icons.remove_red_eye_rounded, defaultIntensity: 0.5),
    ARFilter(type: FilterType.beautyWhiteTeeth, category: FilterCategory.beautyFilter,
      nameEn: 'White Teeth', nameSw: 'Meno Meupe', icon: Icons.mood_rounded, defaultIntensity: 0.7),
  ];

  // ── Existing presets (unchanged) ──
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

  // ── Background Effects (Tier 4) ──
  static const List<ARFilter> backgroundEffects = [
    ARFilter(type: FilterType.bgBlurLight, category: FilterCategory.backgroundEffect,
      nameEn: 'Light Blur', nameSw: 'Ukungu Kidogo', icon: Icons.blur_on_rounded, defaultIntensity: 0.5),
    ARFilter(type: FilterType.bgBlurHeavy, category: FilterCategory.backgroundEffect,
      nameEn: 'Heavy Blur', nameSw: 'Ukungu Sana', icon: Icons.blur_circular_rounded, defaultIntensity: 0.8),
    ARFilter(type: FilterType.bgReplace, category: FilterCategory.backgroundEffect,
      nameEn: 'Replace BG', nameSw: 'Badilisha Mandhari', icon: Icons.wallpaper_rounded, defaultIntensity: 1.0),
  ];

  static List<ARFilter> byCategory(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.colorFilter: return [];  // Handled by ColorFilterPresets
      case FilterCategory.beautyFilter: return beautyFilters;
      case FilterCategory.hairColor: return hairColors;
      case FilterCategory.hairStyle: return hairStyles;
      case FilterCategory.wigFilter: return [];  // Handled by WigAssets
      case FilterCategory.lipColor: return lipColors;
      case FilterCategory.accessories: return accessories;
      case FilterCategory.faceEffect: return faceEffects;
      case FilterCategory.backgroundEffect: return backgroundEffects;
    }
  }
}
```

- [ ] **Step 2: Verify compilation and fix any import errors in dependent files**

Run: `flutter analyze lib/hair_nails/`

Fix any errors in files that import `ar_filter_models.dart` due to the enum changes. The key files that will need updating are `filter_carousel.dart`, `face_landmark_painter.dart`, and `ar_try_on_page.dart` — but those are being rebuilt in later tasks.

---

## Task 5: Filter Engine Service

**Files:**
- Create: `lib/hair_nails/services/filter_engine.dart`

- [ ] **Step 1: Create the filter engine — central state manager**

```dart
// lib/hair_nails/services/filter_engine.dart

import 'package:flutter/material.dart';
import '../models/ar_filter_models.dart';
import '../models/color_filter_presets.dart';
import '../models/wig_asset.dart';
import 'color_matrix_utils.dart';

/// Central filter state manager.
///
/// Tracks all active filters across categories, their intensities,
/// and composes them into a single [ColorFilter] for the camera preview.
class FilterEngine extends ChangeNotifier {
  // ── Active state ──
  ColorFilterPreset _colorPreset = ColorFilterPresets.none;
  double _colorIntensity = 1.0;

  final Map<FilterType, double> _beautyIntensities = {};
  final Set<ARFilter> _activeOverlays = {}; // lip, accessories, effects
  ARFilter? _activeHairColor;
  ARFilter? _activeHairStyle;
  WigAsset? _activeWig;
  ARFilter? _activeBackground;

  bool _showBeforeAfter = false;

  // ── Getters ──
  ColorFilterPreset get colorPreset => _colorPreset;
  double get colorIntensity => _colorIntensity;
  bool get hasColorFilter => _colorPreset.id != 'none';
  bool get hasAnyFilter =>
      hasColorFilter ||
      _beautyIntensities.isNotEmpty ||
      _activeOverlays.isNotEmpty ||
      _activeHairColor != null ||
      _activeHairStyle != null ||
      _activeWig != null ||
      _activeBackground != null;
  bool get showBeforeAfter => _showBeforeAfter;
  Set<ARFilter> get activeOverlays => _activeOverlays;
  ARFilter? get activeHairColor => _activeHairColor;
  ARFilter? get activeHairStyle => _activeHairStyle;
  WigAsset? get activeWig => _activeWig;
  ARFilter? get activeBackground => _activeBackground;

  double beautyIntensity(FilterType type) => _beautyIntensities[type] ?? 0.0;
  bool isBeautyActive(FilterType type) => _beautyIntensities.containsKey(type);

  bool isOverlayActive(ARFilter filter) => _activeOverlays.contains(filter);

  /// Compose the active color matrix at current intensity.
  /// Returns null if no color filter is active.
  ColorFilter? get composedColorFilter {
    if (_showBeforeAfter || !hasColorFilter) return null;
    final matrix = _colorPreset.matrixAt(_colorIntensity);
    return ColorFilter.matrix(matrix);
  }

  /// Get list of all active ARFilter objects (for painters).
  List<ARFilter> get allActiveARFilters {
    if (_showBeforeAfter) return [];
    return [
      if (_activeHairColor != null) _activeHairColor!,
      ..._activeOverlays,
    ];
  }

  // ── Setters ──

  void setColorPreset(ColorFilterPreset preset) {
    _colorPreset = preset;
    notifyListeners();
  }

  void setColorIntensity(double v) {
    _colorIntensity = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setBeautyIntensity(FilterType type, double v) {
    if (v <= 0) {
      _beautyIntensities.remove(type);
    } else {
      _beautyIntensities[type] = v.clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  void toggleBeauty(FilterType type, {double? intensity}) {
    if (_beautyIntensities.containsKey(type)) {
      _beautyIntensities.remove(type);
    } else {
      _beautyIntensities[type] = intensity ?? 0.6;
    }
    notifyListeners();
  }

  void setHairColor(ARFilter? filter) {
    _activeHairColor = filter;
    notifyListeners();
  }

  void setHairStyle(ARFilter? filter) {
    _activeHairStyle = filter;
    notifyListeners();
  }

  void setWig(WigAsset? wig) {
    _activeWig = wig;
    // When a wig is selected, clear hair style (they conflict)
    if (wig != null) _activeHairStyle = null;
    notifyListeners();
  }

  void toggleOverlay(ARFilter filter) {
    if (_activeOverlays.contains(filter)) {
      _activeOverlays.remove(filter);
    } else {
      // Single-select for lip colors
      if (filter.category == FilterCategory.lipColor) {
        _activeOverlays.removeWhere((f) => f.category == FilterCategory.lipColor);
      }
      _activeOverlays.add(filter);
    }
    notifyListeners();
  }

  void setBackground(ARFilter? filter) {
    _activeBackground = filter;
    notifyListeners();
  }

  void toggleBeforeAfter(bool show) {
    _showBeforeAfter = show;
    notifyListeners();
  }

  void clearAll() {
    _colorPreset = ColorFilterPresets.none;
    _colorIntensity = 1.0;
    _beautyIntensities.clear();
    _activeOverlays.clear();
    _activeHairColor = null;
    _activeHairStyle = null;
    _activeWig = null;
    _activeBackground = null;
    _showBeforeAfter = false;
    notifyListeners();
  }

  void clearCategory(FilterCategory category) {
    switch (category) {
      case FilterCategory.colorFilter:
        _colorPreset = ColorFilterPresets.none;
        break;
      case FilterCategory.beautyFilter:
        _beautyIntensities.clear();
        break;
      case FilterCategory.hairColor:
        _activeHairColor = null;
        break;
      case FilterCategory.hairStyle:
        _activeHairStyle = null;
        break;
      case FilterCategory.wigFilter:
        _activeWig = null;
        break;
      case FilterCategory.lipColor:
        _activeOverlays.removeWhere((f) => f.category == FilterCategory.lipColor);
        break;
      case FilterCategory.accessories:
        _activeOverlays.removeWhere((f) => f.category == FilterCategory.accessories);
        break;
      case FilterCategory.faceEffect:
        _activeOverlays.removeWhere((f) => f.category == FilterCategory.faceEffect);
        break;
      case FilterCategory.backgroundEffect:
        _activeBackground = null;
        break;
    }
    notifyListeners();
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/services/filter_engine.dart`

---

## Task 6: Wig Overlay Painter

**Files:**
- Create: `lib/hair_nails/widgets/wig_overlay_painter.dart`

- [ ] **Step 1: Create the wig overlay painter**

This painter renders a PNG wig asset anchored to the user's detected face, scaling and positioning it to sit naturally over their head.

```dart
// lib/hair_nails/widgets/wig_overlay_painter.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

/// Paints a wig PNG asset over the detected face.
///
/// The wig image is positioned so its transparent face hole aligns
/// with the user's detected face. Scaling is based on face width.
class WigOverlayPainter extends CustomPainter {
  final ui.Image? wigImage;
  final Face? face;
  final Size previewSize;
  final Size imageSize;
  final bool isFrontCamera;

  WigOverlayPainter({
    required this.wigImage,
    required this.face,
    required this.previewSize,
    required this.imageSize,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wigImage == null || face == null) return;

    // Map face bounding box from ML Kit image coords to preview coords
    final faceRect = _mapFaceToPreview(face!.boundingBox, size);
    if (faceRect == null) return;

    // The wig asset is 512x640 with a transparent face hole centered.
    // We scale it so the face area in the wig (~40% of wig width) matches
    // the detected face width.
    final wigW = wigImage!.width.toDouble();
    final wigH = wigImage!.height.toDouble();
    final wigAspect = wigW / wigH;

    // Face takes approximately 40% of the wig asset width
    // So wig should be about 2.5x the face width
    final targetWigWidth = faceRect.width * 2.6;
    final targetWigHeight = targetWigWidth / wigAspect;

    // Position: center horizontally on face, top ~15% above face top
    final wigLeft = faceRect.center.dx - targetWigWidth / 2;
    final wigTop = faceRect.top - targetWigHeight * 0.18;

    final destRect = Rect.fromLTWH(wigLeft, wigTop, targetWigWidth, targetWigHeight);
    final srcRect = Rect.fromLTWH(0, 0, wigW, wigH);

    canvas.drawImageRect(wigImage!, srcRect, destRect, Paint()..filterQuality = FilterQuality.medium);
  }

  Rect? _mapFaceToPreview(Rect faceBox, Size canvasSize) {
    // ML Kit gives coordinates in the image space.
    // Camera on iOS uses BGRA with rotation; Android uses NV21.
    // The image may be rotated 90° (landscape sensor → portrait preview).

    final iw = imageSize.width;
    final ih = imageSize.height;

    // Handle rotation: if image is landscape but preview is portrait
    double fx, fy, fw, fh;
    if (iw > ih) {
      // Landscape image → rotate coordinates
      fx = faceBox.top;
      fy = iw - faceBox.right;
      fw = faceBox.height;
      fh = faceBox.width;
    } else {
      fx = faceBox.left;
      fy = faceBox.top;
      fw = faceBox.width;
      fh = faceBox.height;
    }

    // Scale to canvas (cover fit)
    final scaleX = canvasSize.width / (iw > ih ? ih : iw);
    final scaleY = canvasSize.height / (iw > ih ? iw : ih);
    final scale = scaleX > scaleY ? scaleX : scaleY;

    final offsetX = (canvasSize.width - (iw > ih ? ih : iw) * scale) / 2;
    final offsetY = (canvasSize.height - (iw > ih ? iw : ih) * scale) / 2;

    var mappedLeft = fx * scale + offsetX;
    final mappedTop = fy * scale + offsetY;
    final mappedWidth = fw * scale;
    final mappedHeight = fh * scale;

    // Mirror for front camera
    if (isFrontCamera) {
      mappedLeft = canvasSize.width - mappedLeft - mappedWidth;
    }

    return Rect.fromLTWH(mappedLeft, mappedTop, mappedWidth, mappedHeight);
  }

  @override
  bool shouldRepaint(WigOverlayPainter old) =>
      wigImage != old.wigImage || face != old.face;
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/widgets/wig_overlay_painter.dart`

---

## Task 7: Filter Intensity Slider

**Files:**
- Create: `lib/hair_nails/widgets/filter_intensity_slider.dart`

- [ ] **Step 1: Create the vertical intensity slider**

A compact vertical slider displayed on the right edge of the camera preview.

```dart
// lib/hair_nails/widgets/filter_intensity_slider.dart

import 'package:flutter/material.dart';

/// Vertical intensity slider overlaid on the right side of camera preview.
class FilterIntensitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  const FilterIntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Percentage label
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          // Vertical slider (rotated)
          SizedBox(
            height: 160,
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                ),
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/widgets/filter_intensity_slider.dart`

---

## Task 8: Snapchat-Style Filter Carousel (Rebuild)

**Files:**
- Modify: `lib/hair_nails/widgets/filter_carousel.dart` (full rewrite)

- [ ] **Step 1: Rebuild filter_carousel.dart with Snapchat-style tabbed carousel**

The new carousel has category tabs along the top and horizontal scrolling presets. Color filters show preview thumbnails, wigs show mini previews, and other categories show icons/colors.

```dart
// lib/hair_nails/widgets/filter_carousel.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/ar_filter_models.dart';
import '../models/color_filter_presets.dart';
import '../models/wig_asset.dart';
import '../services/filter_engine.dart';

const Color _kChipBg = Color(0xFF2A2A2A);
const Color _kActiveBorder = Color(0xFFFFFFFF);

/// Category tab definition for the carousel.
class _TabDef {
  final FilterCategory category;
  final IconData icon;
  final String labelEn;
  final String labelSw;

  const _TabDef(this.category, this.icon, this.labelEn, this.labelSw);
  String label(bool sw) => sw ? labelSw : labelEn;
}

const _tabs = [
  _TabDef(FilterCategory.colorFilter, Icons.palette_rounded, 'Filters', 'Filters'),
  _TabDef(FilterCategory.beautyFilter, Icons.face_retouching_natural_rounded, 'Beauty', 'Urembo'),
  _TabDef(FilterCategory.wigFilter, Icons.content_cut_rounded, 'Wigs', 'Wigi'),
  _TabDef(FilterCategory.hairColor, Icons.color_lens_rounded, 'Hair', 'Nywele'),
  _TabDef(FilterCategory.lipColor, Icons.brush_rounded, 'Lips', 'Midomo'),
  _TabDef(FilterCategory.accessories, Icons.auto_awesome_rounded, 'Acc.', 'Mapambo'),
  _TabDef(FilterCategory.faceEffect, Icons.blur_on_rounded, 'Effects', 'Efekti'),
  _TabDef(FilterCategory.backgroundEffect, Icons.wallpaper_rounded, 'BG', 'Mandhari'),
];

class FilterCarousel extends StatefulWidget {
  final FilterEngine engine;
  final bool isSwahili;
  final Map<String, ui.Image>? wigPreviews; // Loaded wig thumbnails

  const FilterCarousel({
    super.key,
    required this.engine,
    required this.isSwahili,
    this.wigPreviews,
  });

  @override
  State<FilterCarousel> createState() => _FilterCarouselState();
}

class _FilterCarouselState extends State<FilterCarousel> {
  FilterCategory _selectedCategory = FilterCategory.colorFilter;

  FilterEngine get _engine => widget.engine;
  bool get _sw => widget.isSwahili;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black.withAlpha(216),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            _buildTabs(),
            const SizedBox(height: 8),
            SizedBox(height: 80, child: _buildPresets()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedCategory == tab.category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = tab.category),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(30) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, color: isSelected ? Colors.white : Colors.white54, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    tab.label(_sw),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPresets() {
    switch (_selectedCategory) {
      case FilterCategory.colorFilter:
        return _buildColorPresets();
      case FilterCategory.beautyFilter:
        return _buildARPresets(ARFilterPresets.beautyFilters);
      case FilterCategory.wigFilter:
        return _buildWigPresets();
      case FilterCategory.hairColor:
        return _buildARPresets(ARFilterPresets.hairColors);
      case FilterCategory.hairStyle:
        return _buildARPresets(ARFilterPresets.hairStyles);
      case FilterCategory.lipColor:
        return _buildARPresets(ARFilterPresets.lipColors);
      case FilterCategory.accessories:
        return _buildARPresets(ARFilterPresets.accessories);
      case FilterCategory.faceEffect:
        return _buildARPresets(ARFilterPresets.faceEffects);
      case FilterCategory.backgroundEffect:
        return _buildARPresets(ARFilterPresets.backgroundEffects);
    }
  }

  Widget _buildColorPresets() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: ColorFilterPresets.all.length,
      itemBuilder: (ctx, i) {
        final preset = ColorFilterPresets.all[i];
        final isActive = _engine.colorPreset.id == preset.id;
        return GestureDetector(
          onTap: () {
            _engine.setColorPreset(preset);
            setState(() {});
          },
          child: Container(
            width: 58,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: preset.id == 'none' ? _kChipBg : null,
                    gradient: preset.id != 'none' ? LinearGradient(
                      colors: [
                        preset.previewTint.withAlpha(180),
                        preset.previewTint.withAlpha(80),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ) : null,
                    border: Border.all(
                      color: isActive ? _kActiveBorder : Colors.white24,
                      width: isActive ? 2.5 : 1,
                    ),
                  ),
                  child: preset.id == 'none'
                      ? const Icon(Icons.block_rounded, color: Colors.white54, size: 22)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  preset.name(_sw),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWigPresets() {
    final wigs = WigAssets.all;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: wigs.length + 1, // +1 for "None"
      itemBuilder: (ctx, i) {
        if (i == 0) {
          final isActive = _engine.activeWig == null;
          return _buildNoneChip(isActive, () {
            _engine.setWig(null);
            setState(() {});
          });
        }
        final wig = wigs[i - 1];
        final isActive = _engine.activeWig?.id == wig.id;
        return GestureDetector(
          onTap: () {
            _engine.setWig(isActive ? null : wig);
            setState(() {});
          },
          child: Container(
            width: 58,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kChipBg,
                    border: Border.all(
                      color: isActive ? _kActiveBorder : Colors.white24,
                      width: isActive ? 2.5 : 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      wig.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.content_cut_rounded, color: Colors.white54, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wig.name(_sw),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildARPresets(List<ARFilter> presets) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: presets.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) {
          final cat = presets.first.category;
          final isActive = _engine.byCategory(cat);
          return _buildNoneChip(isActive, () {
            _engine.clearCategory(cat);
            setState(() {});
          });
        }
        final filter = presets[i - 1];
        final isActive = _isFilterActive(filter);
        return GestureDetector(
          onTap: () {
            _onFilterTapped(filter);
            setState(() {});
          },
          child: Container(
            width: 58,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filter.color ?? _kChipBg,
                    border: Border.all(
                      color: isActive ? _kActiveBorder : Colors.white24,
                      width: isActive ? 2.5 : 1,
                    ),
                  ),
                  child: filter.color == null
                      ? Icon(filter.icon, color: Colors.white70, size: 22)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  filter.name(_sw),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoneChip(bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kChipBg,
                border: Border.all(
                  color: isActive ? _kActiveBorder : Colors.white24,
                  width: isActive ? 2.5 : 1,
                ),
              ),
              child: const Icon(Icons.block_rounded, color: Colors.white54, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              _sw ? 'Hakuna' : 'None',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _isFilterActive(ARFilter filter) {
    switch (filter.category) {
      case FilterCategory.hairColor:
        return _engine.activeHairColor?.type == filter.type;
      case FilterCategory.hairStyle:
        return _engine.activeHairStyle?.type == filter.type;
      case FilterCategory.beautyFilter:
        return _engine.isBeautyActive(filter.type);
      case FilterCategory.backgroundEffect:
        return _engine.activeBackground?.type == filter.type;
      default:
        return _engine.isOverlayActive(filter);
    }
  }

  void _onFilterTapped(ARFilter filter) {
    switch (filter.category) {
      case FilterCategory.hairColor:
        _engine.setHairColor(
          _engine.activeHairColor?.type == filter.type ? null : filter);
        break;
      case FilterCategory.hairStyle:
        _engine.setHairStyle(
          _engine.activeHairStyle?.type == filter.type ? null : filter);
        break;
      case FilterCategory.beautyFilter:
        _engine.toggleBeauty(filter.type, intensity: filter.defaultIntensity);
        break;
      case FilterCategory.backgroundEffect:
        _engine.setBackground(
          _engine.activeBackground?.type == filter.type ? null : filter);
        break;
      default:
        _engine.toggleOverlay(filter);
    }
  }
}

// Extension on FilterEngine to check if a category has no active filters
extension _FilterEngineExt on FilterEngine {
  bool byCategory(FilterCategory cat) {
    switch (cat) {
      case FilterCategory.hairColor: return activeHairColor == null;
      case FilterCategory.hairStyle: return activeHairStyle == null;
      case FilterCategory.wigFilter: return activeWig == null;
      case FilterCategory.beautyFilter:
        return !isBeautyActive(FilterType.beautySmoothSkin) &&
               !isBeautyActive(FilterType.beautySlimFace) &&
               !isBeautyActive(FilterType.beautyBigEyes) &&
               !isBeautyActive(FilterType.beautyWhiteTeeth);
      case FilterCategory.backgroundEffect: return activeBackground == null;
      default:
        return !activeOverlays.any((f) => f.category == cat);
    }
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze lib/hair_nails/widgets/filter_carousel.dart`

---

## Task 9: Rebuild AR Try-On Page

**Files:**
- Modify: `lib/hair_nails/pages/ar_try_on_page.dart` (full rewrite)

This is the largest task — the complete camera + filter pipeline page.

- [ ] **Step 1: Rewrite ar_try_on_page.dart**

The new page integrates all 4 tiers into a single camera experience:
- Camera preview with `ColorFiltered` wrapper (Tier 1: color grading)
- `BackdropFilter` layer for beauty smoothing (Tier 2)
- `CustomPainter` stack for face overlays: hair, wigs, lips, accessories (Tier 3)
- Background effect layer (Tier 4)
- Snapchat-style carousel at bottom
- Intensity slider on right edge
- Capture button, flip camera, flash toggle
- Before/after comparison (long-press)

```dart
// lib/hair_nails/pages/ar_try_on_page.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/ar_filter_models.dart';
import '../models/wig_asset.dart';
import '../services/filter_engine.dart';
import '../widgets/face_landmark_painter.dart';
import '../widgets/filter_carousel.dart';
import '../widgets/filter_intensity_slider.dart';
import '../widgets/hair_segmentation_painter.dart';
import '../widgets/hair_try_on_viewport.dart';
import '../widgets/wig_overlay_painter.dart';

class ARTryOnPage extends StatefulWidget {
  final int userId;
  const ARTryOnPage({super.key, required this.userId});
  @override
  State<ARTryOnPage> createState() => _ARTryOnPageState();
}

class _ARTryOnPageState extends State<ARTryOnPage> {
  // ── Camera ──
  CameraController? _camCtrl;
  bool _isInitializing = true;
  String? _initError;
  bool _isFrontCamera = true;
  int _frameTick = 0;
  bool _processing = false;

  // ── Face Detection ──
  late FaceDetector _faceDetector;
  Face? _detectedFace;
  Rect? _faceRect;
  Size _imageSize = Size.zero;

  // ── Filter Engine ──
  final FilterEngine _engine = FilterEngine();

  // ── Wig image cache ──
  final Map<String, ui.Image> _wigImageCache = {};

  // ── Capture ──
  final GlobalKey _captureKey = GlobalKey();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    _engine.addListener(_onEngineChanged);
    _initCamera();
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _disposeCamera();
    _faceDetector.close();
    super.dispose();
  }

  void _onEngineChanged() {
    if (mounted) setState(() {});
    // Pre-load wig image when selected
    final wig = _engine.activeWig;
    if (wig != null && !_wigImageCache.containsKey(wig.id)) {
      _loadWigImage(wig);
    }
  }

  Future<void> _loadWigImage(WigAsset wig) async {
    try {
      final data = await rootBundle.load(wig.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() => _wigImageCache[wig.id] = frame.image);
      }
    } catch (_) {}
  }

  // ── Camera Init ──
  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() { _isInitializing = false; _initError = 'Camera permission required'; });
        return;
      }

      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }

      _camCtrl = ctrl;
      ctrl.startImageStream(_onFrame);
      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() { _isInitializing = false; _initError = e.toString(); });
    }
  }

  void _disposeCamera() {
    _camCtrl?.stopImageStream().catchError((_) {});
    _camCtrl?.dispose();
    _camCtrl = null;
  }

  Future<void> _flipCamera() async {
    _isFrontCamera = !_isFrontCamera;
    _disposeCamera();
    _detectedFace = null;
    _faceRect = null;
    setState(() => _isInitializing = true);
    await _initCamera();
  }

  // ── Frame Processing ──
  void _onFrame(CameraImage image) {
    _frameTick++;
    if (_frameTick % 6 != 0 || _processing) return; // ~5 fps
    _processing = true;

    final inputImage = _buildInputImage(image);
    if (inputImage == null) { _processing = false; return; }

    _faceDetector.processImage(inputImage).then((faces) {
      if (!mounted) return;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (faces.isNotEmpty) {
        final face = faces.first;
        final mapped = _mapFaceRect(face.boundingBox);
        if (_faceRect == null || _rectChanged(_faceRect!, mapped)) {
          setState(() { _detectedFace = face; _faceRect = mapped; });
        } else {
          _detectedFace = face;
        }
      } else if (_detectedFace != null) {
        setState(() { _detectedFace = null; _faceRect = null; });
      }
      _processing = false;
    }).catchError((_) { _processing = false; });
  }

  InputImage? _buildInputImage(CameraImage image) {
    final cam = _camCtrl;
    if (cam == null) return null;

    final sensorOrientation = cam.description.sensorOrientation;
    InputImageRotation rotation;
    switch (sensorOrientation) {
      case 0: rotation = InputImageRotation.rotation0deg; break;
      case 90: rotation = InputImageRotation.rotation90deg; break;
      case 180: rotation = InputImageRotation.rotation180deg; break;
      case 270: rotation = InputImageRotation.rotation270deg; break;
      default: rotation = InputImageRotation.rotation0deg;
    }

    if (Platform.isIOS) {
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } else {
      final allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return InputImage.fromBytes(
        bytes: allBytes.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }
  }

  Rect _mapFaceRect(Rect box) {
    // Simplified mapping — the painters handle full coordinate transforms
    return box;
  }

  bool _rectChanged(Rect a, Rect b) {
    return (a.center - b.center).distance > 6 ||
           (a.width - b.width).abs() > 8 ||
           (a.height - b.height).abs() > 8;
  }

  // ── Capture ──
  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await Directory.systemTemp.createTemp('tajiri_filter_');
      final file = File('${tempDir.path}/filtered_photo.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([XFile(file.path)], text: 'TAJIRI Hair & Nails');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Size get _previewSize {
    final ctx = context;
    return MediaQuery.of(ctx).size;
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context).isSwahili;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _initError != null
              ? _buildError(sw)
              : _buildCamera(sw),
    );
  }

  Widget _buildError(bool sw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(_initError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => openAppSettings(),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: Text(sw ? 'Fungua Mipangilio' : 'Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(bool sw) {
    final ctrl = _camCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 0: Camera preview with color filter ──
        RepaintBoundary(
          key: _captureKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              _buildFilteredPreview(ctrl),

              // ── Layer 1: Face overlays (hair, wig, lips, accessories, effects) ──
              if (_detectedFace != null && !_engine.showBeforeAfter) ...[
                // Hair color overlay
                if (_engine.activeHairColor != null)
                  CustomPaint(
                    painter: HairTryOnPainter(
                      faceRect: _faceRect,
                      imageSize: _imageSize,
                      previewSize: _previewSize,
                      styleIndex: _engine.activeHairStyle?.styleIndex ?? 0,
                      tintColor: _engine.activeHairColor?.color,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),

                // Wig overlay
                if (_engine.activeWig != null)
                  CustomPaint(
                    painter: WigOverlayPainter(
                      wigImage: _wigImageCache[_engine.activeWig!.id],
                      face: _detectedFace,
                      previewSize: _previewSize,
                      imageSize: _imageSize,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),

                // Hair style overlay (only if no wig)
                if (_engine.activeHairStyle != null && _engine.activeWig == null)
                  CustomPaint(
                    painter: HairTryOnPainter(
                      faceRect: _faceRect,
                      imageSize: _imageSize,
                      previewSize: _previewSize,
                      styleIndex: _engine.activeHairStyle!.styleIndex ?? 0,
                      tintColor: _engine.activeHairColor?.color,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),

                // Face landmark effects (lips, accessories, face effects)
                if (_engine.allActiveARFilters.isNotEmpty)
                  CustomPaint(
                    painter: FaceLandmarkPainter(
                      face: _detectedFace,
                      activeFilters: _engine.allActiveARFilters,
                      previewSize: _previewSize,
                      imageSize: _imageSize,
                      isFrontCamera: _isFrontCamera,
                    ),
                  ),
              ],
            ],
          ),
        ),

        // ── UI Overlays (not captured) ──

        // Top bar: back + flip camera + flash
        _buildTopBar(sw),

        // Before/After label
        if (_engine.showBeforeAfter)
          Positioned(
            top: 100, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  sw ? 'KABLA' : 'BEFORE',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

        // Face guide when no face detected
        if (_detectedFace == null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.face_rounded, color: Colors.white.withAlpha(80), size: 80),
                const SizedBox(height: 8),
                Text(
                  sw ? 'Elekeza uso wako hapa' : 'Position your face here',
                  style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 14),
                ),
              ],
            ),
          ),

        // Intensity slider (right edge) — show when color filter is active
        if (_engine.hasColorFilter)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).size.height * 0.25,
            child: FilterIntensitySlider(
              value: _engine.colorIntensity,
              onChanged: (v) => _engine.setColorIntensity(v),
            ),
          ),

        // Bottom: capture button + carousel
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Capture button row
              _buildCaptureRow(sw),
              // Filter carousel
              FilterCarousel(
                engine: _engine,
                isSwahili: sw,
                wigPreviews: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredPreview(CameraController ctrl) {
    Widget preview = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: ctrl.value.previewSize?.height ?? 1,
          height: ctrl.value.previewSize?.width ?? 1,
          child: CameraPreview(ctrl),
        ),
      ),
    );

    // Apply color filter
    final colorFilter = _engine.composedColorFilter;
    if (colorFilter != null) {
      preview = ColorFiltered(colorFilter: colorFilter, child: preview);
    }

    // Apply beauty smooth skin (simple blur-based approach)
    if (_engine.isBeautyActive(FilterType.beautySmoothSkin) && !_engine.showBeforeAfter) {
      final intensity = _engine.beautyIntensity(FilterType.beautySmoothSkin);
      preview = Stack(
        fit: StackFit.expand,
        children: [
          preview,
          BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: intensity * 2.5,
              sigmaY: intensity * 2.5,
            ),
            child: Container(color: Colors.transparent),
          ),
        ],
      );
    }

    return preview;
  }

  Widget _buildTopBar(bool sw) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              // Before/After toggle
              GestureDetector(
                onLongPressStart: (_) => _engine.toggleBeforeAfter(true),
                onLongPressEnd: (_) => _engine.toggleBeforeAfter(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.compare_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        sw ? 'Linganisha' : 'Compare',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Flip camera
              IconButton(
                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                onPressed: _flipCamera,
              ),
              // Clear all
              if (_engine.hasAnyFilter)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white),
                  onPressed: () {
                    _engine.clearAll();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureRow(bool sw) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery (placeholder)
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          // Capture button
          GestureDetector(
            onTap: _capture,
            child: Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCapturing ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 28),
            onPressed: _engine.hasAnyFilter ? _capture : null,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Register wig assets in pubspec.yaml**

Add the processed wig assets directory to the Flutter assets section in `pubspec.yaml`:

```yaml
  assets:
    - assets/images/games/
    - assets/filter_assets/wigs_processed/
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/hair_nails/pages/ar_try_on_page.dart`

Fix any compilation errors from import changes.

---

## Task 10: Update Home Page Integration

**Files:**
- Modify: `lib/hair_nails/pages/hair_nails_home_page.dart`

- [ ] **Step 1: Update the AR Try-On card navigation**

Find the AR Try-On navigation card in `hair_nails_home_page.dart` and ensure it passes `widget.userId` to the rebuilt `ARTryOnPage`:

The existing navigation line should be:
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => const ARTryOnPage()));
```

Change to:
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => ARTryOnPage(userId: widget.userId)));
```

Search for all references to `ARTryOnPage` in the file and update them.

- [ ] **Step 2: Verify full module compilation**

Run: `flutter analyze lib/hair_nails/`

Fix any remaining errors across the module.

---

## Task 11: Fix Compilation Errors Across Module

**Files:**
- All files in `lib/hair_nails/` that import from modified models

- [ ] **Step 1: Run full analysis and fix all errors**

Run: `flutter analyze lib/hair_nails/`

The most common errors will be:
1. `FilterCategory` enum — new values added, existing `switch` statements need updating
2. `FilterType` enum — new values added
3. `ARFilterPresets.byCategory()` — new cases
4. `filter_carousel.dart` — completely rewritten, old callers need updating
5. `ar_try_on_page.dart` — constructor changed (now requires `userId`)

For each error, look at the file and line number, read the context, and apply the minimal fix.

- [ ] **Step 2: Verify clean compilation**

Run: `flutter analyze lib/hair_nails/`

Expected: 0 errors (warnings/info acceptable)

---

## Task 12: Full Integration Test

- [ ] **Step 1: Run full project analysis**

Run: `flutter analyze`

Fix any errors.

- [ ] **Step 2: Verify assets are bundled**

Run: `flutter build apk --debug 2>&1 | tail -20`

Check that no "asset not found" errors appear for `wigs_processed/` files.

- [ ] **Step 3: Document what was built**

The implementation delivers:
- **Tier 1** (Color Filters): 30+ color grading presets applied via `ColorFilter.matrix` to live camera preview with intensity slider
- **Tier 2** (Beauty): Skin smoothing via `BackdropFilter` blur, with adjustable intensity
- **Tier 3** (Overlays): 12 real wig PNG assets positioned on face via `WigOverlayPainter`, plus existing lip/accessory/hair style overlays
- **Tier 4** (Background): Background effect category wired in model/engine (segmentation rendering is a follow-up when `google_mlkit_selfie_segmentation` is added)
- **Rebuilt AR page**: New camera pipeline with all filters, Snapchat-style carousel, intensity control, before/after comparison, capture & share
- **Integrated**: Wired into hair_nails home page navigation
