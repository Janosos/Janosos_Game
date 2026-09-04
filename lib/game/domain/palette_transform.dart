import 'dart:math' as math;
import 'dart:ui' show ColorFilter;

class PaletteTransform {
  const PaletteTransform._({
    required this.hueShift,
    required this.saturationBasisPoints,
    required this.valueBasisPoints,
  });

  factory PaletteTransform({
    required int hueShift,
    required int saturationBasisPoints,
    required int valueBasisPoints,
  }) {
    if (hueShift < 0 || hueShift >= 360) {
      throw ArgumentError.value(hueShift, 'hueShift', 'Expected 0–359.');
    }
    if (saturationBasisPoints < 5000 || saturationBasisPoints > 15000) {
      throw ArgumentError.value(
        saturationBasisPoints,
        'saturationBasisPoints',
        'Expected 5000–15000.',
      );
    }
    if (valueBasisPoints < 5000 || valueBasisPoints > 15000) {
      throw ArgumentError.value(
        valueBasisPoints,
        'valueBasisPoints',
        'Expected 5000–15000.',
      );
    }
    return PaletteTransform._(
      hueShift: hueShift,
      saturationBasisPoints: saturationBasisPoints,
      valueBasisPoints: valueBasisPoints,
    );
  }

  static const identity = PaletteTransform._(
    hueShift: 0,
    saturationBasisPoints: 10000,
    valueBasisPoints: 10000,
  );

  final int hueShift;
  final int saturationBasisPoints;
  final int valueBasisPoints;

  bool get isIdentity =>
      hueShift == 0 &&
      saturationBasisPoints == 10000 &&
      valueBasisPoints == 10000;

  ColorFilter? get colorFilter =>
      isIdentity ? null : ColorFilter.matrix(colorMatrix);

  List<double> get colorMatrix {
    final radians = hueShift * math.pi / 180;
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    final hue = <List<double>>[
      [
        0.213 + cosine * 0.787 - sine * 0.213,
        0.715 - cosine * 0.715 - sine * 0.715,
        0.072 - cosine * 0.072 + sine * 0.928,
        0,
        0,
      ],
      [
        0.213 - cosine * 0.213 + sine * 0.143,
        0.715 + cosine * 0.285 + sine * 0.140,
        0.072 - cosine * 0.072 - sine * 0.283,
        0,
        0,
      ],
      [
        0.213 - cosine * 0.213 - sine * 0.787,
        0.715 - cosine * 0.715 + sine * 0.715,
        0.072 + cosine * 0.928 + sine * 0.072,
        0,
        0,
      ],
      [0, 0, 0, 1, 0],
    ];
    final saturation = saturationBasisPoints / 10000;
    const luminance = [0.213, 0.715, 0.072];
    final saturationMatrix = <List<double>>[
      [
        luminance[0] * (1 - saturation) + saturation,
        luminance[1] * (1 - saturation),
        luminance[2] * (1 - saturation),
        0,
        0,
      ],
      [
        luminance[0] * (1 - saturation),
        luminance[1] * (1 - saturation) + saturation,
        luminance[2] * (1 - saturation),
        0,
        0,
      ],
      [
        luminance[0] * (1 - saturation),
        luminance[1] * (1 - saturation),
        luminance[2] * (1 - saturation) + saturation,
        0,
        0,
      ],
      [0, 0, 0, 1, 0],
    ];
    final combined = _multiply(saturationMatrix, hue);
    final value = valueBasisPoints / 10000;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 5; column++) {
        combined[row][column] *= value;
      }
    }
    return [for (final row in combined) ...row];
  }

  static List<List<double>> _multiply(
    List<List<double>> left,
    List<List<double>> right,
  ) {
    return List.generate(4, (row) {
      return List.generate(5, (column) {
        if (column == 4) {
          return left[row][4] +
              left[row][0] * right[0][4] +
              left[row][1] * right[1][4] +
              left[row][2] * right[2][4] +
              left[row][3] * right[3][4];
        }
        return left[row][0] * right[0][column] +
            left[row][1] * right[1][column] +
            left[row][2] * right[2][column] +
            left[row][3] * right[3][column];
      });
    });
  }
}
