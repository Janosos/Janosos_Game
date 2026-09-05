import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';

class BossActionButton extends PositionComponent
    with HasGameReference<DinoRunGame>, TapCallbacks {
  BossActionButton()
    : super(size: Vector2.all(84), anchor: Anchor.bottomRight, priority: 120);

  final Paint _fill = Paint();
  final Paint _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  late final TextPaint _label = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w900,
      shadows: [Shadow(color: Colors.black, blurRadius: 3)],
    ),
  );
  late final TextPaint _cooldownLabel = TextPaint(
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
  );

  double _pressTimer = 0;

  void triggerPress() {
    _pressTimer = 0.15;
  }

  @override
  Future<void> onLoad() async {
    position = Vector2(game.size.x - 20, game.size.y - 112);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 20, size.y - 112);
  }

  @override
  bool containsPoint(Vector2 point) {
    final left = position.x - width;
    final top = position.y - height;
    final right = position.x;
    final bottom = position.y;
    return point.x >= left - 8 &&
        point.x <= right + 8 &&
        point.y >= top - 8 &&
        point.y <= bottom + 8;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_pressTimer > 0) {
      _pressTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final canAct = game.canUseBossAction;

    if (canAct) {
      _fill.color = const Color(0xFFE86A17);
      _border.color = Colors.white;
    } else {
      _fill.color = const Color(0xFF4A3425);
      _border.color = Colors.grey.withValues(alpha: 0.6);
    }

    final center = Offset(width / 2, height / 2);
    final radius = _pressTimer > 0 ? (width / 2) * 0.92 : width / 2;

    canvas.drawCircle(center, radius, _fill);
    canvas.drawCircle(center, radius - 2, _border);

    if (canAct) {
      canvas.drawCircle(
        center,
        radius + 2,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _label.render(
        canvas,
        'GOLPE\nJEFE · E',
        Vector2(width / 2, height / 2),
        anchor: Anchor.center,
      );
    } else {
      _cooldownLabel.render(
        canvas,
        'ESPERA...',
        Vector2(width / 2, height / 2),
        anchor: Anchor.center,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.useBossAction();
    triggerPress();
    event.handled = true;
  }
}
