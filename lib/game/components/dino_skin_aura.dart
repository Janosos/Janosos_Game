import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../domain/palette_transform.dart';

class DinoSkinAuraComponent extends PositionComponent {
  DinoSkinAuraComponent({
    required this.auraType,
    this.isNanicDischarging = false,
  }) : super(priority: -1, anchor: Anchor.center);

  SkinAuraType auraType;
  bool isNanicDischarging;
  double opacity = 1.0;
  double _time = 0.0;
  Sprite? auraSprite;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final speed = isNanicDischarging
        ? 6.0
        : (auraType == SkinAuraType.rainbow ? 3.0 : 1.8);
    angle += dt * speed;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.001) return;
    if (auraType == SkinAuraType.none && !isNanicDischarging) return;

    final center = Offset(size.x / 2, size.y / 2);
    final pulse = 0.88 + 0.12 * math.sin(_time * 4.5);
    final baseRadius = (size.x * 0.46) * pulse;

    final glowPaint = Paint()..style = PaintingStyle.fill;

    if (isNanicDischarging) {
      glowPaint.shader = ui.Gradient.radial(
        center,
        baseRadius * 1.15,
        [
          const Color(0xEEFFE600),
          const Color(0x9900F5FF),
          const Color(0x000044FF),
        ],
        [0.0, 0.6, 1.0],
      );
      canvas.drawCircle(center, baseRadius * 1.15, glowPaint);
    } else {
      switch (auraType) {
        case SkinAuraType.aurora:
          glowPaint.shader = ui.Gradient.radial(
            center,
            baseRadius,
            [
              const Color(0xCC00FFD5),
              const Color(0x7700B4D8),
              const Color(0x00003049),
            ],
            [0.0, 0.65, 1.0],
          );
          canvas.drawCircle(center, baseRadius, glowPaint);

          final ringPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = Color.fromRGBO(
              0,
              255,
              213,
              (0.4 + 0.2 * math.sin(_time * 6)).clamp(0.0, 1.0),
            );
          canvas.drawCircle(center, baseRadius * 0.75, ringPaint);
          break;

        case SkinAuraType.eclipse:
          glowPaint.shader = ui.Gradient.radial(
            center,
            baseRadius * 1.05,
            [
              const Color(0xDDB347FF),
              const Color(0x886A0DAD),
              const Color(0x001B003A),
            ],
            [0.0, 0.6, 1.0],
          );
          canvas.drawCircle(center, baseRadius * 1.05, glowPaint);

          final darkRing = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Color.fromRGBO(
              179,
              71,
              255,
              (0.5 + 0.25 * math.cos(_time * 5)).clamp(0.0, 1.0),
            );
          canvas.drawCircle(center, baseRadius * 0.8, darkRing);
          break;

        case SkinAuraType.rainbow:
          const rainbowColors = [
            Color(0xCCFF0055),
            Color(0xCCFF8800),
            Color(0xCCFFEE00),
            Color(0xCC00FF66),
            Color(0xCC00F5FF),
            Color(0xCC7928CA),
            Color(0xCCFF0055),
          ];
          glowPaint.shader = ui.Gradient.sweep(
            center,
            rainbowColors,
            null,
            TileMode.clamp,
            _time * 2.5,
            _time * 2.5 + 2 * math.pi,
          );
          canvas.drawCircle(center, baseRadius * 1.1, glowPaint);

          final corePaint = Paint()
            ..shader = ui.Gradient.radial(
              center,
              baseRadius * 0.65,
              [
                const Color(0xEEFFFFFF),
                const Color(0x66FFDD00),
                const Color(0x00000000),
              ],
              [0.0, 0.5, 1.0],
            );
          canvas.drawCircle(center, baseRadius * 0.65, corePaint);
          break;

        case SkinAuraType.none:
          break;
      }
    }

    if (auraSprite != null) {
      final spriteAlpha = isNanicDischarging
          ? 0.85 * opacity
          : (auraType != SkinAuraType.none ? 0.40 * pulse * opacity : 0.0);
      if (spriteAlpha > 0.01) {
        final spritePaint = Paint()
          ..color = Color.fromRGBO(255, 255, 255, spriteAlpha.clamp(0.0, 1.0));
        auraSprite!.render(
          canvas,
          position: Vector2.zero(),
          size: size,
          overridePaint: spritePaint,
        );
      }
    }
  }
}
