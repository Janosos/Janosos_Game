import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';
import '../components/dino.dart';
import 'character_selection_overlay.dart';

class HudIndicators extends PositionComponent with HasGameRef<DinoRunGame> {
  late Sprite heartSprite;
  late Sprite shieldSprite;
  late TextPaint timerPaint;

  HudIndicators() : super(position: Vector2(20, 60), priority: 100);

  @override
  Future<void> onLoad() async {
    heartSprite = await gameRef.loadSprite('heart_indicator.png');
    shieldSprite = await gameRef.loadSprite('tank_shield_icon.png');
    timerPaint = TextPaint(
      style: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final dino = gameRef.dino;

    // Vitalista: Show hearts
    if (dino.characterType == CharacterType.vitalista) {
      if (dino.hasShield) {
        // Draw 2 hearts (one for shield/extra life, one for base life)
        // Or visually: Base life + Extra layer. 
        // User asked for "indicador de corazones".
        // Let's draw 2 hearts if hasShield, 1 if not.
        heartSprite.render(canvas, position: Vector2(0, 0), size: Vector2(32, 32));
        heartSprite.render(canvas, position: Vector2(35, 0), size: Vector2(32, 32));
      } else {
         // 1 heart left
        heartSprite.render(canvas, position: Vector2(0, 0), size: Vector2(32, 32));
      }
    } 
    // Tanque: Show Shield + Timer
    else if (dino.characterType == CharacterType.tanque) {
       if (dino.hasShield) {
         shieldSprite.render(canvas, position: Vector2(0, 0), size: Vector2(32, 32));
         timerPaint.render(canvas, 'READY', Vector2(40, 5));
       } else {
         // Show timer
         String timeLeft = dino.cooldownTimer.toStringAsFixed(1);
         shieldSprite.render(canvas, position: Vector2(0, 0), size: Vector2(32, 32), overridePaint: Paint()..color = Colors.grey.withOpacity(0.5));
         timerPaint.render(canvas, timeLeft, Vector2(40, 5));
       }
    }
    // Pistolero: Show cooldown?
    else if (dino.characterType == CharacterType.pistolero) {
        if (dino.cooldownTimer > 0) {
           timerPaint.render(canvas, dino.cooldownTimer.toStringAsFixed(1), Vector2(0, 0));
        } else {
           timerPaint.render(canvas, 'READY', Vector2(0, 0));
        }
    }
  }
}
