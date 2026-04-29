import 'package:flutter/material.dart';
import '../services/color_matrix_utils.dart';

/// A named colour-filter preset backed by a 4x5 colour matrix.
class ColorFilterPreset {
  const ColorFilterPreset({
    required this.id,
    required this.nameEn,
    required this.nameSw,
    required this.matrix,
    required this.previewTint,
  });

  /// Unique identifier.
  final String id;

  /// Display name in English.
  final String nameEn;

  /// Display name in Swahili.
  final String nameSw;

  /// The 20-element 4x5 colour matrix for this preset at full intensity.
  final List<double> matrix;

  /// A solid colour used as a quick thumbnail preview tint.
  final Color previewTint;

  /// Returns the matrix blended between [ColorMatrixUtils.identity] and
  /// [matrix] by [intensity] (0.0–1.0).
  List<double> matrixAt(double intensity) =>
      ColorMatrixUtils.lerp(matrix, intensity);
}

/// Catalogue of all built-in colour-filter presets.
///
/// Film presets use exact matrices sourced from PixiJS colour-matrix filter.
/// Instagram-style presets compose primitives via [ColorMatrixUtils.chain].
class ColorFilterPresets {
  ColorFilterPresets._();

  // --------------------------------------------------------------------------
  // Identity
  // --------------------------------------------------------------------------

  static const ColorFilterPreset none = ColorFilterPreset(
    id: 'none',
    nameEn: 'Original',
    nameSw: 'Asili',
    matrix: ColorMatrixUtils.identity,
    previewTint: Color(0xFFFFFFFF),
  );

  // --------------------------------------------------------------------------
  // Film presets (hardcoded matrices from PixiJS)
  // --------------------------------------------------------------------------

  static const ColorFilterPreset kodachrome = ColorFilterPreset(
    id: 'kodachrome',
    nameEn: 'Kodachrome',
    nameSw: 'Kodachrome',
    matrix: <double>[
      1.129, -0.397, -0.040, 0, 63.730,
     -0.164,  1.084, -0.055, 0, 24.732,
     -0.168, -0.560,  1.601, 0, 35.630,
      0,      0,      0,     1,  0,
    ],
    previewTint: Color(0xFFD4A574),
  );

  static const ColorFilterPreset polaroid = ColorFilterPreset(
    id: 'polaroid',
    nameEn: 'Polaroid',
    nameSw: 'Polaroid',
    matrix: <double>[
      1.438, -0.062, -0.062, 0, 0,
     -0.122,  1.378, -0.122, 0, 0,
     -0.016, -0.016,  1.483, 0, 0,
      0,      0,      0,     1, 0,
    ],
    previewTint: Color(0xFFF0E6D3),
  );

  static const ColorFilterPreset technicolor = ColorFilterPreset(
    id: 'technicolor',
    nameEn: 'Technicolor',
    nameSw: 'Technicolor',
    matrix: <double>[
      1.913, -0.855, -0.092, 0,   11.794,
     -0.309,  1.766, -0.106, 0,  -70.352,
     -0.231, -0.750,  1.848, 0,   30.951,
      0,      0,      0,     1,    0,
    ],
    previewTint: Color(0xFFFF6B35),
  );

  static const ColorFilterPreset vintage = ColorFilterPreset(
    id: 'vintage',
    nameEn: 'Vintage',
    nameSw: 'Zamani',
    matrix: <double>[
      0.628,  0.320, -0.040, 0,  9.651,
      0.026,  0.644,  0.033, 0,  7.463,
      0.047, -0.085,  0.524, 0,  5.159,
      0,      0,      0,     1,  0,
    ],
    previewTint: Color(0xFFC8A97A),
  );

  static const ColorFilterPreset browni = ColorFilterPreset(
    id: 'browni',
    nameEn: 'Browni',
    nameSw: 'Kahawia',
    matrix: <double>[
      0.600,  0.346, -0.271, 0,  47.432,
     -0.038,  0.861,  0.151, 0, -36.968,
      0.241, -0.074,  0.450, 0,  -7.562,
      0,      0,      0,     1,   0,
    ],
    previewTint: Color(0xFF8B5A2B),
  );

  // --------------------------------------------------------------------------
  // Instagram-style presets (composed via ColorMatrixUtils.chain)
  // --------------------------------------------------------------------------

  static final ColorFilterPreset clarendon = ColorFilterPreset(
    id: 'clarendon',
    nameEn: 'Clarendon',
    nameSw: 'Clarendon',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.2),
      ColorMatrixUtils.saturation(1.35),
    ]),
    previewTint: const Color(0xFF6ECBF5),
  );

  static final ColorFilterPreset gingham = ColorFilterPreset(
    id: 'gingham',
    nameEn: 'Gingham',
    nameSw: 'Gingham',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.hueRotate(-10),
      ColorMatrixUtils.brightness(1.05),
    ]),
    previewTint: const Color(0xFFE8DDD0),
  );

  static final ColorFilterPreset moon = ColorFilterPreset(
    id: 'moon',
    nameEn: 'Moon',
    nameSw: 'Mwezi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.contrast(1.1),
      ColorMatrixUtils.grayscale(1.0),
    ]),
    previewTint: const Color(0xFFB0B0B0),
  );

  static final ColorFilterPreset lark = ColorFilterPreset(
    id: 'lark',
    nameEn: 'Lark',
    nameSw: 'Lark',
    matrix: ColorMatrixUtils.contrast(0.9),
    previewTint: const Color(0xFFF5E6D3),
  );

  static final ColorFilterPreset reyes = ColorFilterPreset(
    id: 'reyes',
    nameEn: 'Reyes',
    nameSw: 'Reyes',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.sepia(0.22),
      ColorMatrixUtils.contrast(0.85),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(0.75),
    ]),
    previewTint: const Color(0xFFD4B896),
  );

  static final ColorFilterPreset juno = ColorFilterPreset(
    id: 'juno',
    nameEn: 'Juno',
    nameSw: 'Juno',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.1),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(1.3),
    ]),
    previewTint: const Color(0xFF7AC8A0),
  );

  static final ColorFilterPreset slumber = ColorFilterPreset(
    id: 'slumber',
    nameEn: 'Slumber',
    nameSw: 'Usingizi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.brightness(1.05),
      ColorMatrixUtils.saturation(0.66),
    ]),
    previewTint: const Color(0xFF9B8EA8),
  );

  static final ColorFilterPreset nashville = ColorFilterPreset(
    id: 'nashville',
    nameEn: 'Nashville',
    nameSw: 'Nashville',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.2),
      ColorMatrixUtils.brightness(1.05),
      ColorMatrixUtils.saturation(1.2),
      ColorMatrixUtils.sepia(0.2),
    ]),
    previewTint: const Color(0xFFD4956A),
  );

  static final ColorFilterPreset valencia = ColorFilterPreset(
    id: 'valencia',
    nameEn: 'Valencia',
    nameSw: 'Valencia',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.08),
      ColorMatrixUtils.brightness(1.08),
      ColorMatrixUtils.sepia(0.08),
    ]),
    previewTint: const Color(0xFFF09060),
  );

  static final ColorFilterPreset walden = ColorFilterPreset(
    id: 'walden',
    nameEn: 'Walden',
    nameSw: 'Walden',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.hueRotate(-10),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.sepia(0.3),
      ColorMatrixUtils.saturation(1.6),
    ]),
    previewTint: const Color(0xFF7AB8A0),
  );

  static final ColorFilterPreset inkwell = ColorFilterPreset(
    id: 'inkwell',
    nameEn: 'Inkwell',
    nameSw: 'Wino',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.sepia(0.3),
      ColorMatrixUtils.contrast(1.1),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.grayscale(1.0),
    ]),
    previewTint: const Color(0xFF707070),
  );

  static final ColorFilterPreset lofi = ColorFilterPreset(
    id: 'lofi',
    nameEn: 'Lo-Fi',
    nameSw: 'Lo-Fi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.5),
      ColorMatrixUtils.saturation(1.1),
    ]),
    previewTint: const Color(0xFF8B6090),
  );

  static final ColorFilterPreset xpro2 = ColorFilterPreset(
    id: 'xpro2',
    nameEn: 'X-Pro II',
    nameSw: 'X-Pro II',
    matrix: ColorMatrixUtils.sepia(0.3),
    previewTint: const Color(0xFF704214),
  );

  // --------------------------------------------------------------------------
  // Mood presets
  // --------------------------------------------------------------------------

  static final ColorFilterPreset warmGlow = ColorFilterPreset(
    id: 'warm_glow',
    nameEn: 'Warm Glow',
    nameSw: 'Mwanga wa Joto',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(1.2),
      ColorMatrixUtils.hueRotate(10),
    ]),
    previewTint: const Color(0xFFFFAA44),
  );

  static final ColorFilterPreset coolBreeze = ColorFilterPreset(
    id: 'cool_breeze',
    nameEn: 'Cool Breeze',
    nameSw: 'Upepo Baridi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.brightness(1.05),
      ColorMatrixUtils.saturation(0.9),
      ColorMatrixUtils.hueRotate(-20),
    ]),
    previewTint: const Color(0xFF44AAFF),
  );

  static final ColorFilterPreset golden = ColorFilterPreset(
    id: 'golden',
    nameEn: 'Golden',
    nameSw: 'Dhahabu',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.sepia(0.4),
      ColorMatrixUtils.brightness(1.15),
      ColorMatrixUtils.saturation(1.1),
    ]),
    previewTint: const Color(0xFFFFCC00),
  );

  static final ColorFilterPreset night = ColorFilterPreset(
    id: 'night',
    nameEn: 'Night',
    nameSw: 'Usiku',
    matrix: <double>[
      -2.0, -1.0, 0, 0, 0,
      -1.0,  0,   1.0, 0, 0,
       0,    1.0, 2.0, 0, 0,
       0,    0,   0,   1, 0,
    ],
    previewTint: const Color(0xFF001030),
  );

  static final ColorFilterPreset fade = ColorFilterPreset(
    id: 'fade',
    nameEn: 'Fade',
    nameSw: 'Fifia',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(0.8),
      ColorMatrixUtils.brightness(1.1),
      ColorMatrixUtils.saturation(0.7),
    ]),
    previewTint: const Color(0xFFCCBBAA),
  );

  static final ColorFilterPreset vivid = ColorFilterPreset(
    id: 'vivid',
    nameEn: 'Vivid',
    nameSw: 'Kung\'aa',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.3),
      ColorMatrixUtils.saturation(1.6),
      ColorMatrixUtils.brightness(1.05),
    ]),
    previewTint: const Color(0xFFFF4499),
  );

  static final ColorFilterPreset emerald = ColorFilterPreset(
    id: 'emerald',
    nameEn: 'Emerald',
    nameSw: 'Zumaridi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.hueRotate(120),
      ColorMatrixUtils.saturation(1.3),
      ColorMatrixUtils.brightness(1.05),
    ]),
    previewTint: const Color(0xFF00CC66),
  );

  static final ColorFilterPreset rose = ColorFilterPreset(
    id: 'rose',
    nameEn: 'Rose',
    nameSw: 'Waridi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.hueRotate(-20),
      ColorMatrixUtils.saturation(1.2),
      ColorMatrixUtils.brightness(1.08),
    ]),
    previewTint: const Color(0xFFFF8080),
  );

  static final ColorFilterPreset chrome = ColorFilterPreset(
    id: 'chrome',
    nameEn: 'Chrome',
    nameSw: 'Kromi',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.4),
      ColorMatrixUtils.saturation(0.5),
      ColorMatrixUtils.brightness(1.2),
    ]),
    previewTint: const Color(0xFFDDDDDD),
  );

  static final ColorFilterPreset dramatic = ColorFilterPreset(
    id: 'dramatic',
    nameEn: 'Dramatic',
    nameSw: 'Hisia Kali',
    matrix: ColorMatrixUtils.chain(<List<double>>[
      ColorMatrixUtils.contrast(1.6),
      ColorMatrixUtils.saturation(1.4),
      ColorMatrixUtils.brightness(0.9),
    ]),
    previewTint: const Color(0xFF220044),
  );

  // --------------------------------------------------------------------------
  // Special presets
  // --------------------------------------------------------------------------

  static const ColorFilterPreset sepia100 = ColorFilterPreset(
    id: 'sepia100',
    nameEn: 'Sepia',
    nameSw: 'Sepia',
    matrix: <double>[
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0,     0,     0,     1, 0,
    ],
    previewTint: Color(0xFFB8864E),
  );

  static const ColorFilterPreset bw = ColorFilterPreset(
    id: 'bw',
    nameEn: 'Black & White',
    nameSw: 'Nyeusi na Nyeupe',
    matrix: <double>[
      0.3, 0.6, 0.1, 0, 0,
      0.3, 0.6, 0.1, 0, 0,
      0.3, 0.6, 0.1, 0, 0,
      0,   0,   0,   1, 0,
    ],
    previewTint: Color(0xFF888888),
  );

  static const ColorFilterPreset lsd = ColorFilterPreset(
    id: 'lsd',
    nameEn: 'LSD',
    nameSw: 'Rangi Nyingi',
    matrix: <double>[
      2,    -0.4,  0.5, 0, 0,
     -0.5,   2,   -0.4, 0, 0,
     -0.4,  -0.5,  3,   0, 0,
      0,     0,    0,   1, 0,
    ],
    previewTint: Color(0xFFAA00FF),
  );

  // --------------------------------------------------------------------------
  // Master list (carousel order)
  // --------------------------------------------------------------------------

  /// All presets in display order for the filter carousel.
  static List<ColorFilterPreset> get all => <ColorFilterPreset>[
        none,
        // Film
        kodachrome,
        polaroid,
        technicolor,
        vintage,
        browni,
        // Instagram-style
        clarendon,
        gingham,
        moon,
        lark,
        reyes,
        juno,
        slumber,
        nashville,
        valencia,
        walden,
        inkwell,
        lofi,
        xpro2,
        // Mood
        warmGlow,
        coolBreeze,
        golden,
        night,
        fade,
        vivid,
        emerald,
        rose,
        chrome,
        dramatic,
        // Special
        sepia100,
        bw,
        lsd,
      ];
}
