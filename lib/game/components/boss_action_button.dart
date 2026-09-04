import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';

class BossActionButton extends PositionComponent
    with HasGameReference<DinoRunGame>, TapCallbacks {
  BossActionButton()
    : super(size: Vector2.all(84), anchor: Anchor.bottomRight, priority: 120);

  final Paint _fill = Paint()..color = const Color(0xFFE86A17);
  final Paint _border = Paint()
    ..color = Colors.white
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
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(width / 2, height / 2);
    canvas.drawCircle(center, width / 2, _fill);
    canvas.drawCircle(center, width / 2 - 2, _border);
    _label.render(
      canvas,
      'GOLPE\nJEFE · E',
      Vector2(width / 2, height / 2),
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.useBossAction();
    event.handled = true;
  }
}
