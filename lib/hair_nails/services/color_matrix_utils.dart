import 'dart:math' as math;

/// Pure math utilities for composing 4x5 color matrices used by
/// Flutter's [ColorFilter.matrix()].
///
/// A 4x5 color matrix transforms RGBA values as:
///   | R' |   | a00 a01 a02 a03 a04 |   | R |
///   | G' | = | a10 a11 a12 a13 a14 | * | G |
///   | B' |   | a20 a21 a22 a23 a24 |   | B |
///   | A' |   | a30 a31 a32 a33 a34 |   | A |
///                                        | 1 |
///
/// All matrices are represented as flat 20-element [List<double>] in row-major
/// order: [a00, a01, a02, a03, a04, a10, a11, ...].
class ColorMatrixUtils {
  ColorMatrixUtils._();

  /// The identity matrix — no colour transformation applied.
  static const List<double> identity = <double>[
    1, 0, 0, 0, 0, // R row
    0, 1, 0, 0, 0, // G row
    0, 0, 1, 0, 0, // B row
    0, 0, 0, 1, 0, // A row
  ];

  // ---------------------------------------------------------------------------
  // Core composition helpers
  // ---------------------------------------------------------------------------

  /// Multiplies two 4x5 colour matrices [a] and [b], returning a * b.
  ///
  /// The 5th column (translation/offset) is treated as a 4-component vector
  /// rather than a true matrix column, so the multiplication handles the
  /// homogeneous coordinate implicitly.
  static List<double> multiply(List<double> a, List<double> b) {
    assert(a.length == 20 && b.length == 20);
    final List<double> out = List<double>.filled(20, 0);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        if (col == 4) {
          // Translation column: sum of products + offset from b
          double sum = a[row * 5 + 4];
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + 4];
          }
          out[row * 5 + 4] = sum;
        } else {
          double sum = 0;
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + col];
          }
          out[row * 5 + col] = sum;
        }
      }
    }
    return out;
  }

  /// Chains multiple matrices together left-to-right, so the first matrix in
  /// [matrices] is applied first.
  ///
  /// Returns [identity] when [matrices] is empty.
  static List<double> chain(List<List<double>> matrices) {
    if (matrices.isEmpty) return List<double>.from(identity);
    List<double> result = List<double>.from(matrices.first);
    for (int i = 1; i < matrices.length; i++) {
      result = multiply(result, matrices[i]);
    }
    return result;
  }

  /// Linearly interpolates between [identity] and [matrix] by [t] (0.0–1.0).
  ///
  /// At t=0 returns identity; at t=1 returns [matrix].
  static List<double> lerp(List<double> matrix, double t) {
    assert(matrix.length == 20);
    final double s = t.clamp(0.0, 1.0);
    final List<double> out = List<double>.filled(20, 0);
    for (int i = 0; i < 20; i++) {
      out[i] = identity[i] + (matrix[i] - identity[i]) * s;
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Primitive filter matrices
  // ---------------------------------------------------------------------------

  /// Brightness filter.
  ///
  /// [amount]: 0 = black, 1 = no change, 2 = double brightness.
  static List<double> brightness(double amount) {
    final double a = amount.clamp(0.0, 10.0);
    return <double>[
      a, 0, 0, 0, 0,
      0, a, 0, 0, 0,
      0, 0, a, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// Contrast filter.
  ///
  /// [amount]: 0 = flat grey, 1 = no change, 2 = high contrast.
  static List<double> contrast(double amount) {
    final double a = amount.clamp(0.0, 10.0);
    final double t = (1 - a) / 2 * 255;
    return <double>[
      a, 0, 0, 0, t,
      0, a, 0, 0, t,
      0, 0, a, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  /// Saturation filter.
  ///
  /// [amount]: 0 = greyscale, 1 = no change, 2 = over-saturated.
  static List<double> saturation(double amount) {
    final double a = amount.clamp(0.0, 10.0);
    // Luminosity weights (ITU-R BT.601)
    const double lr = 0.299;
    const double lg = 0.587;
    const double lb = 0.114;
    return <double>[
      lr + (1 - lr) * a, lg * (a - 1),      lb * (a - 1),      0, 0,
      lr * (a - 1),      lg + (1 - lg) * a, lb * (a - 1),      0, 0,
      lr * (a - 1),      lg * (a - 1),      lb + (1 - lb) * a, 0, 0,
      0,                 0,                 0,                  1, 0,
    ];
  }

  /// Sepia tone filter.
  ///
  /// [intensity]: 0.0 = no effect, 1.0 = full sepia.
  static List<double> sepia(double intensity) {
    const List<double> sepiaMatrix = <double>[
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0,     0,     0,     1, 0,
    ];
    return lerp(sepiaMatrix, intensity);
  }

  /// Grayscale filter.
  ///
  /// [intensity]: 0.0 = no effect, 1.0 = full greyscale.
  static List<double> grayscale(double intensity) {
    const List<double> greyMatrix = <double>[
      0.3, 0.6, 0.1, 0, 0,
      0.3, 0.6, 0.1, 0, 0,
      0.3, 0.6, 0.1, 0, 0,
      0,   0,   0,   1, 0,
    ];
    return lerp(greyMatrix, intensity);
  }

  /// Hue rotation filter.
  ///
  /// [degrees]: rotation in degrees (-180 to 180).
  static List<double> hueRotate(double degrees) {
    final double rad = degrees * math.pi / 180;
    final double cos = math.cos(rad);
    final double sin = math.sin(rad);

    // Luminosity weights
    const double lr = 0.213;
    const double lg = 0.715;
    const double lb = 0.072;

    return <double>[
      lr + cos * (1 - lr) + sin * (-lr),
      lg + cos * (-lg)    + sin * (-lg),
      lb + cos * (-lb)    + sin * (1 - lb),
      0, 0,

      lr + cos * (-lr)    + sin * (0.143),
      lg + cos * (1 - lg) + sin * (0.140),
      lb + cos * (-lb)    + sin * (-0.283),
      0, 0,

      lr + cos * (-lr)    + sin * (-(1 - lr)),
      lg + cos * (-lg)    + sin * (lg),
      lb + cos * (1 - lb) + sin * (lb),
      0, 0,

      0, 0, 0, 1, 0,
    ];
  }
}
