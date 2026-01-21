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

  late Sprite lightningSprite; // New icon

  @override
  Future<void> onLoad() async {
    heartSprite = await gameRef.loadSprite('heart_indicator.png');
    shieldSprite = await gameRef.loadSprite('tank_shield_icon.png');
    lightningSprite = await gameRef.loadSprite('lightning_icon.png'); // Load asset
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
    // Pistolero or Fantasma: Show cooldown
    else if (dino.characterType == CharacterType.pistolero || dino.characterType == CharacterType.fantasma) {
        if (dino.cooldownTimer > 0) {
           timerPaint.render(canvas, dino.cooldownTimer.toStringAsFixed(1), Vector2(0, 0));
        } else {
           timerPaint.render(canvas, 'READY', Vector2(0, 0));
        }
    }
    // Nanic: Show Energy Bar
    else if (dino.characterType == CharacterType.nanic) {
      // Draw Bar Background
      final Paint bgPaint = Paint()..color = Colors.grey.withOpacity(0.5);
      final Paint fillPaint = Paint()..color = Colors.yellow;
      final Paint borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
      
      final barWidth = 100.0;
      final barHeight = 20.0;
      final fillWidth = (dino.energy / dino.maxEnergy) * barWidth;
      
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, barWidth, barHeight), const Radius.circular(10));
      final fillRRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, fillWidth, barHeight), const Radius.circular(10));
      
      // Draw Background
      canvas.drawRRect(rrect, bgPaint);
      
      // Draw Fill
      canvas.drawRRect(fillRRect, fillPaint);
      
      // Draw Border
      canvas.drawRRect(rrect, borderPaint);
      
      // Draw Lightning Icon to the right (Larger)
      lightningSprite.render(canvas, position: Vector2(barWidth + 5, -12), size: Vector2(48, 48)); 

      // Draw text
      if (dino.isSuperCharged) {
         // Move text below the bar (positive Y)
         timerPaint.render(canvas, 'MAX POWER!', Vector2(0, barHeight + 5));
      }
    }
  }
}
