import 'package:flutter/material.dart';

/// Instagram-style image filters using ColorFilter matrices
/// Based on research from https://retroportalstudio.medium.com/image-filters-in-flutter-no-package-required
class ImageFilters {
  ImageFilters._();

  /// All available filters
  static List<ImageFilterPreset> get presets => [
        normal,
        clarendon,
        gingham,
        moon,
        lark,
        reyes,
        juno,
        slumber,
        crema,
        ludwig,
        aden,
        perpetua,
        amaro,
        mayfair,
        rise,
        hudson,
        valencia,
        xpro2,
        sierra,
        willow,
        lofi,
        inkwell,
        nashville,
      ];

  // No filter - original image
  static final ImageFilterPreset normal = ImageFilterPreset(
    name: 'Asili',
    nameEn: 'Normal',
    matrix: null,
  );

  // Clarendon - Adds light to lighter areas and dark to darker areas
  static final ImageFilterPreset clarendon = ImageFilterPreset(
    name: 'Clarendon',
    nameEn: 'Clarendon',
    matrix: [
      1.2, 0, 0, 0, 0,
      0, 1.2, 0, 0, 0,
      0, 0, 1.2, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Gingham - Vintage-washed, yellowish
  static final ImageFilterPreset gingham = ImageFilterPreset(
    name: 'Gingham',
    nameEn: 'Gingham',
    matrix: [
      1.0, 0.1, 0.1, 0, 0,
      0.1, 1.0, 0.1, 0, 0,
      0.1, 0.1, 0.8, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Moon - Black and white with subtle blue
  static final ImageFilterPreset moon = ImageFilterPreset(
    name: 'Moon',
    nameEn: 'Moon',
    matrix: [
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.33, 0, 0,
      0.33, 0.33, 0.45, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Lark - Brightens and intensifies
  static final ImageFilterPreset lark = ImageFilterPreset(
    name: 'Lark',
    nameEn: 'Lark',
    matrix: [
      1.2, 0, 0, 0, 20,
      0, 1.05, 0, 0, 20,
      0, 0, 0.9, 0, 20,
      0, 0, 0, 1, 0,
    ],
  );

  // Reyes - Vintage with faded look
  static final ImageFilterPreset reyes = ImageFilterPreset(
    name: 'Reyes',
    nameEn: 'Reyes',
    matrix: [
      0.9, 0.1, 0, 0, 30,
      0.1, 0.9, 0, 0, 30,
      0, 0.1, 0.8, 0, 30,
      0, 0, 0, 1, 0,
    ],
  );

  // Juno - Teal and orange
  static final ImageFilterPreset juno = ImageFilterPreset(
    name: 'Juno',
    nameEn: 'Juno',
    matrix: [
      1.2, 0, 0, 0, 0,
      0, 1.0, 0.1, 0, 0,
      0, 0, 0.8, 0, 20,
      0, 0, 0, 1, 0,
    ],
  );

  // Slumber - Desaturated with yellow tint
  static final ImageFilterPreset slumber = ImageFilterPreset(
    name: 'Slumber',
    nameEn: 'Slumber',
    matrix: [
      0.9, 0.1, 0, 0, 10,
      0.1, 0.85, 0.05, 0, 10,
      0, 0.1, 0.7, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  // Crema - Creamy vintage
  static final ImageFilterPreset crema = ImageFilterPreset(
    name: 'Crema',
    nameEn: 'Crema',
    matrix: [
      1.1, 0.1, 0, 0, 15,
      0, 1.0, 0.1, 0, 15,
      0, 0, 0.9, 0, 15,
      0, 0, 0, 1, 0,
    ],
  );

  // Ludwig - Slightly desaturated
  static final ImageFilterPreset ludwig = ImageFilterPreset(
    name: 'Ludwig',
    nameEn: 'Ludwig',
    matrix: [
      1.05, 0.05, 0, 0, 0,
      0.05, 1.0, 0.05, 0, 0,
      0, 0.05, 0.95, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Aden - Soft, pastel look
  static final ImageFilterPreset aden = ImageFilterPreset(
    name: 'Aden',
    nameEn: 'Aden',
    matrix: [
      0.9, 0.1, 0, 0, 20,
      0.1, 0.85, 0.1, 0, 20,
      0.1, 0.1, 0.7, 0, 20,
      0, 0, 0, 1, 0,
    ],
  );

  // Perpetua - Soft, slightly blue
  static final ImageFilterPreset perpetua = ImageFilterPreset(
    name: 'Perpetua',
    nameEn: 'Perpetua',
    matrix: [
      0.95, 0, 0.1, 0, 0,
      0, 1.0, 0.1, 0, 0,
      0.1, 0.1, 1.1, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Amaro - Adds light to center
  static final ImageFilterPreset amaro = ImageFilterPreset(
    name: 'Amaro',
    nameEn: 'Amaro',
    matrix: [
      1.1, 0, 0, 0, 10,
      0, 1.1, 0, 0, 10,
      0, 0, 0.9, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  // Mayfair - Warm vintage
  static final ImageFilterPreset mayfair = ImageFilterPreset(
    name: 'Mayfair',
    nameEn: 'Mayfair',
    matrix: [
      1.1, 0.1, 0, 0, 10,
      0, 1.0, 0, 0, 10,
      0, 0.1, 0.8, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  // Rise - Soft, warm glow
  static final ImageFilterPreset rise = ImageFilterPreset(
    name: 'Rise',
    nameEn: 'Rise',
    matrix: [
      1.1, 0, 0, 0, 25,
      0, 1.05, 0, 0, 20,
      0, 0, 0.9, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  // Hudson - Cool blue tint
  static final ImageFilterPreset hudson = ImageFilterPreset(
    name: 'Hudson',
    nameEn: 'Hudson',
    matrix: [
      0.9, 0, 0.1, 0, 0,
      0, 0.9, 0.15, 0, 0,
      0.1, 0.1, 1.2, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Valencia - Warm vintage
  static final ImageFilterPreset valencia = ImageFilterPreset(
    name: 'Valencia',
    nameEn: 'Valencia',
    matrix: [
      1.1, 0.1, 0, 0, 10,
      0, 1.0, 0.1, 0, 5,
      0, 0, 0.85, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // X-Pro II - High contrast with vignette feel
  static final ImageFilterPreset xpro2 = ImageFilterPreset(
    name: 'X-Pro II',
    nameEn: 'X-Pro II',
    matrix: [
      1.3, 0, 0, 0, -20,
      0, 1.2, 0, 0, -10,
      0, 0, 1.4, 0, -30,
      0, 0, 0, 1, 0,
    ],
  );

  // Sierra - Soft, faded
  static final ImageFilterPreset sierra = ImageFilterPreset(
    name: 'Sierra',
    nameEn: 'Sierra',
    matrix: [
      0.95, 0.1, 0, 0, 20,
      0.1, 0.9, 0.1, 0, 20,
      0, 0.1, 0.8, 0, 20,
      0, 0, 0, 1, 0,
    ],
  );

  // Willow - Black and white with slight tint
  static final ImageFilterPreset willow = ImageFilterPreset(
    name: 'Willow',
    nameEn: 'Willow',
    matrix: [
      0.35, 0.35, 0.35, 0, 10,
      0.35, 0.35, 0.35, 0, 10,
      0.3, 0.3, 0.4, 0, 10,
      0, 0, 0, 1, 0,
    ],
  );

  // Lo-Fi - High saturation, strong shadows
  static final ImageFilterPreset lofi = ImageFilterPreset(
    name: 'Lo-Fi',
    nameEn: 'Lo-Fi',
    matrix: [
      1.4, 0, 0, 0, -30,
      0, 1.4, 0, 0, -30,
      0, 0, 1.4, 0, -30,
      0, 0, 0, 1, 0,
    ],
  );

  // Inkwell - Pure black and white
  static final ImageFilterPreset inkwell = ImageFilterPreset(
    name: 'Inkwell',
    nameEn: 'Inkwell',
    matrix: [
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );

  // Nashville - Warm vintage with pink tint
  static final ImageFilterPreset nashville = ImageFilterPreset(
    name: 'Nashville',
    nameEn: 'Nashville',
    matrix: [
      1.2, 0.1, 0.1, 0, 20,
      0, 1.0, 0.1, 0, 10,
      0, 0, 0.8, 0, -10,
      0, 0, 0, 1, 0,
    ],
  );

  // Sepia - Classic sepia tone
  static final ImageFilterPreset sepia = ImageFilterPreset(
    name: 'Sepia',
    nameEn: 'Sepia',
    matrix: [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ],
  );
}

/// A filter preset with name and color matrix
class ImageFilterPreset {
  final String name; // Swahili name
  final String nameEn; // English name
  final List<double>? matrix; // 4x5 color matrix (null = no filter)

  const ImageFilterPreset({
    required this.name,
    required this.nameEn,
    this.matrix,
  });

  /// Get the ColorFilter for this preset
  ColorFilter? get colorFilter {
    if (matrix == null) return null;
    return ColorFilter.matrix(matrix!);
  }

  /// Apply filter to a widget
  Widget apply(Widget child) {
    if (matrix == null) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix!),
      child: child,
    );
  }
}

/// Brightness adjustment helper
class ImageAdjustments {
  ImageAdjustments._();

  /// Create brightness adjustment matrix
  static List<double> brightness(double value) {
    // value: -1.0 to 1.0 (0 = no change)
    final b = value * 255;
    return [
      1, 0, 0, 0, b,
      0, 1, 0, 0, b,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ];
  }

  /// Create contrast adjustment matrix
  static List<double> contrast(double value) {
    // value: 0.0 to 2.0 (1 = no change)
    final c = value;
    final t = (1 - c) / 2 * 255;
    return [
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  /// Create saturation adjustment matrix
  static List<double> saturation(double value) {
    // value: 0.0 to 2.0 (1 = no change, 0 = grayscale)
    final s = value;
    final sr = (1 - s) * 0.299;
    final sg = (1 - s) * 0.587;
    final sb = (1 - s) * 0.114;
    return [
      sr + s, sg, sb, 0, 0,
      sr, sg + s, sb, 0, 0,
      sr, sg, sb + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// Create warmth adjustment matrix
  static List<double> warmth(double value) {
    // value: -1.0 to 1.0 (0 = no change, positive = warmer, negative = cooler)
    final w = value * 30;
    return [
      1, 0, 0, 0, w,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, -w,
      0, 0, 0, 1, 0,
    ];
  }

  /// Combine multiple matrices
  static List<double> combine(List<List<double>> matrices) {
    if (matrices.isEmpty) return identity;
    var result = matrices[0];
    for (var i = 1; i < matrices.length; i++) {
      result = _multiplyMatrices(result, matrices[i]);
    }
    return result;
  }

  static final List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static List<double> _multiplyMatrices(List<double> a, List<double> b) {
    // Simplified 4x5 matrix multiplication for color transforms
    return [
      a[0] * b[0] + a[1] * b[5] + a[2] * b[10] + a[3] * b[15],
      a[0] * b[1] + a[1] * b[6] + a[2] * b[11] + a[3] * b[16],
      a[0] * b[2] + a[1] * b[7] + a[2] * b[12] + a[3] * b[17],
      a[0] * b[3] + a[1] * b[8] + a[2] * b[13] + a[3] * b[18],
      a[0] * b[4] + a[1] * b[9] + a[2] * b[14] + a[3] * b[19] + a[4],
      a[5] * b[0] + a[6] * b[5] + a[7] * b[10] + a[8] * b[15],
      a[5] * b[1] + a[6] * b[6] + a[7] * b[11] + a[8] * b[16],
      a[5] * b[2] + a[6] * b[7] + a[7] * b[12] + a[8] * b[17],
      a[5] * b[3] + a[6] * b[8] + a[7] * b[13] + a[8] * b[18],
      a[5] * b[4] + a[6] * b[9] + a[7] * b[14] + a[8] * b[19] + a[9],
      a[10] * b[0] + a[11] * b[5] + a[12] * b[10] + a[13] * b[15],
      a[10] * b[1] + a[11] * b[6] + a[12] * b[11] + a[13] * b[16],
      a[10] * b[2] + a[11] * b[7] + a[12] * b[12] + a[13] * b[17],
      a[10] * b[3] + a[11] * b[8] + a[12] * b[13] + a[13] * b[18],
      a[10] * b[4] + a[11] * b[9] + a[12] * b[14] + a[13] * b[19] + a[14],
      a[15] * b[0] + a[16] * b[5] + a[17] * b[10] + a[18] * b[15],
      a[15] * b[1] + a[16] * b[6] + a[17] * b[11] + a[18] * b[16],
      a[15] * b[2] + a[16] * b[7] + a[17] * b[12] + a[18] * b[17],
      a[15] * b[3] + a[16] * b[8] + a[17] * b[13] + a[18] * b[18],
      a[15] * b[4] + a[16] * b[9] + a[17] * b[14] + a[18] * b[19] + a[19],
    ];
  }
}
