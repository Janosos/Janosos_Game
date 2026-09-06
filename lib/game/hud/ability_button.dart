import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';

class AbilityButton extends HudButtonComponent {
  final DinoRunGame dinoGame;
  Sprite? _buttonSprite;

  late final TextPaint _cooldownPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _cooldownPaintCompact = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
      ],
    ),
  );

  AbilityButton({required this.dinoGame})
    : super(
        margin: const EdgeInsets.only(right: 20, bottom: 20),
        anchor: Anchor.bottomRight,
        priority: 100,
      );

  void _updateLayout(Vector2 size) {
    final isCompact = size.y < 500;
    final btnSize = isCompact ? Vector2(62, 62) : Vector2(80, 80);
    this.size = btnSize;
    if (_buttonSprite != null) {
      button = SpriteComponent(sprite: _buttonSprite, size: btnSize);
    }
  }

  @override
  Future<void> onLoad() async {
    try {
      final spriteImg = await dinoGame.images.load('ability_button.png');
      _buttonSprite = Sprite(spriteImg);
    } catch (_) {}
    _updateLayout(dinoGame.size);
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    _updateLayout(gameSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final dino = dinoGame.dino;
    final isCompact = dinoGame.size.y < 500;
    final currentSize = isCompact ? Vector2(62, 62) : Vector2(80, 80);

    if (dino.cooldownTimer > 0) {
      final center = Offset(currentSize.x / 2, currentSize.y / 2);
      final radius = currentSize.x / 2;

      // Dark translucent circular overlay
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.65),
      );

      // Cooldown timer countdown text
      final text = '${dino.cooldownTimer.toStringAsFixed(1)}s';
      final paint = isCompact ? _cooldownPaintCompact : _cooldownPaint;
      paint.render(
        canvas,
        text,
        Vector2(currentSize.x / 2, currentSize.y / 2),
        anchor: Anchor.center,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (dinoGame.dino.cooldownTimer > 0) {
      event.handled = true;
      return;
    }
    super.onTapDown(event);
    dinoGame.dino.activateAbility();
    event.handled = true;
  }
}
