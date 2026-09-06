import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';
import '../domain/hud_settings.dart';

class AbilityButton extends HudButtonComponent {
  final DinoRunGame dinoGame;
  final HudSettings settings;
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

  AbilityButton({
    required this.dinoGame,
    this.settings = HudSettings.defaults,
  }) : super(
         margin: EdgeInsets.only(
           right: 18,
           bottom: settings.swapActionButtons ? 95 : 18,
         ),
         anchor: Anchor.bottomRight,
         priority: 100,
       );

  void _updateLayout(Vector2 size) {
    final isCompact = size.y < 500;
    final scale = settings.abilityScale;
    final btnSize = isCompact
        ? Vector2(62 * scale, 62 * scale)
        : Vector2(80 * scale, 80 * scale);
    this.size = btnSize;
    margin = EdgeInsets.only(
      right: isCompact ? 14 : 20,
      bottom: settings.swapActionButtons
          ? (isCompact ? 86 : 112)
          : (isCompact ? 14 : 20),
    );
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
    if (settings.abilityOpacity < 1.0) {
      canvas.saveLayer(
        null,
        Paint()
          ..color = Colors.white.withValues(alpha: settings.abilityOpacity),
      );
    }

    super.render(canvas);
    final dino = dinoGame.dino;
    final isCompact = dinoGame.size.y < 500;
    final scale = settings.abilityScale;
    final currentSize = isCompact
        ? Vector2(62 * scale, 62 * scale)
        : Vector2(80 * scale, 80 * scale);

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

    if (settings.abilityOpacity < 1.0) {
      canvas.restore();
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

