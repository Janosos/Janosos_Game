import 'package:dino_run_flame/game/domain/palette_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identity palette preserves the sprite without a filter', () {
    expect(PaletteTransform.identity.isIdentity, isTrue);
    expect(PaletteTransform.identity.colorFilter, isNull);
    final matrix = PaletteTransform.identity.colorMatrix;
    expect(matrix, hasLength(20));
    expect(matrix[0], closeTo(1, 0.000001));
    expect(matrix[6], closeTo(1, 0.000001));
    expect(matrix[12], closeTo(1, 0.000001));
    expect(matrix[18], closeTo(1, 0.000001));
  });

  test('earned palette creates a finite render-only color matrix', () {
    final palette = PaletteTransform(
      hueShift: 210,
      saturationBasisPoints: 9000,
      valueBasisPoints: 7800,
    );
    expect(palette.isIdentity, isFalse);
    expect(palette.colorFilter, isNotNull);
    expect(palette.colorMatrix, hasLength(20));
    expect(palette.colorMatrix.every((value) => value.isFinite), isTrue);
  });

  test('palette limits reject content that could corrupt rendering', () {
    expect(
      () => PaletteTransform(
        hueShift: 360,
        saturationBasisPoints: 10000,
        valueBasisPoints: 10000,
      ),
      throwsArgumentError,
    );
    expect(
      () => PaletteTransform(
        hueShift: 0,
        saturationBasisPoints: 4999,
        valueBasisPoints: 10000,
      ),
      throwsArgumentError,
    );
    expect(
      () => PaletteTransform(
        hueShift: 0,
        saturationBasisPoints: 10000,
        valueBasisPoints: 15001,
      ),
      throwsArgumentError,
    );
  });
}
