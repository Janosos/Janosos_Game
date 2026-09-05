import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';

/// On-screen retro directional controls allowing the player to move left and right.
class DirectionalPad extends PositionComponent
    with HasGameReference<DinoRunGame>, TapCallbacks {
  DirectionalPad()
    : super(
        size: Vector2(136, 56),
        anchor: Anchor.bottomLeft,
        priority: 120,
      );

  bool _leftPressed = false;
  bool _rightPressed = false;

  late final TextPaint _arrowPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
      ],
    ),
  );

  @override
  Future<void> onLoad() async {
    position = Vector2(16, game.size.y - 16);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(16, size.y - 16);
  }

  @override
  bool containsPoint(Vector2 point) {
    final left = position.x;
    final top = position.y - height;
    final right = position.x + width;
    final bottom = position.y;
    return point.x >= left - 6 &&
        point.x <= right + 6 &&
        point.y >= top - 6 &&
        point.y <= bottom + 6;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final localX = event.localPosition.x;
    if (localX <= 64) {
      _leftPressed = true;
      _rightPressed = false;
      game.dino.moveLeft();
    } else if (localX >= 72) {
      _rightPressed = true;
      _leftPressed = false;
      game.dino.moveRight();
    }
    event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _leftPressed = false;
    _rightPressed = false;
    game.dino.stopMoving();
    event.handled = true;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _leftPressed = false;
    _rightPressed = false;
    game.dino.stopMoving();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _renderButton(
      canvas,
      rect: const Rect.fromLTWH(0, 0, 62, 56),
      label: '◀',
      pressed: _leftPressed,
    );

    _renderButton(
      canvas,
      rect: const Rect.fromLTWH(74, 0, 62, 56),
      label: '▶',
      pressed: _rightPressed,
    );
  }

  void _renderButton(
    Canvas canvas, {
    required Rect rect,
    required String label,
    required bool pressed,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final bgColor = pressed
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF121722).withValues(alpha: 0.85);
    final borderColor = pressed
        ? const Color(0xFF00E5FF)
        : const Color(0xFF4A5568).withValues(alpha: 0.90);

    // Drop shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3)),
      Paint()..color = Colors.black45,
    );

    // Background fill
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = pressed ? 3 : 2,
    );

    // Arrow icon
    _arrowPaint.render(
      canvas,
      label,
      Vector2(rect.center.dx, rect.center.dy - 1),
      anchor: Anchor.center,
    );
  }
}
