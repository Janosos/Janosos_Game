import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';
import '../domain/character_id.dart';
import '../domain/level_runtime.dart';
import '../domain/run_configuration.dart';

class HudIndicators extends PositionComponent
    with HasGameReference<DinoRunGame> {
  late Sprite heartSprite;
  late Sprite shieldSprite;
  late Sprite lightningSprite;
  late TextPaint timerPaint;

  late final TextPaint _bossTitlePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFD54F),
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.4,
      shadows: [
        Shadow(blurRadius: 3, color: Colors.black, offset: Offset(2, 2)),
        Shadow(blurRadius: 1, color: Color(0xFFFF6F00), offset: Offset(0, 1)),
      ],
    ),
  );

  late final TextPaint _bossHpPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _activePhasePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFF5252),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _passedPhasePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFD54F),
      fontSize: 10,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _lockedPhasePaint = TextPaint(
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.35),
      fontSize: 10,
      fontWeight: FontWeight.normal,
    ),
  );

  HudIndicators() : super(position: Vector2.zero(), priority: 100);

  @override
  Future<void> onLoad() async {
    heartSprite = await game.loadSprite('heart_indicator.png');
    shieldSprite = await game.loadSprite('tank_shield_icon.png');
    lightningSprite = await game.loadSprite('lightning_icon.png');
    timerPaint = TextPaint(
      style: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
    );
  }

  void _renderBossHealthBar(Canvas canvas) {
    final definition = game.currentLevelDefinition;
    if (definition == null) return;

    final bossName = definition.bossName.toUpperCase();
    final healthFraction = game.bossHealthFraction.clamp(0.0, 1.0);
    final remainingHp = game.bossHealthRemaining;
    final maxHp = definition.bossHealth;
    final phase = game.bossPhase;

    final screenWidth = game.size.x;
    final isCompact = game.size.y < 500;
    final barWidth = isCompact
        ? (screenWidth * 0.44).clamp(190.0, 360.0)
        : (screenWidth * 0.52).clamp(290.0, 500.0);
    final barHeight = isCompact ? 16.0 : 22.0;
    final startX = (screenWidth - barWidth) / 2;
    final titleY = isCompact ? 3.0 : 6.0;

    // 1. Boss Name with Retro Arcade Accents (safely padded from top edge)
    final titleText = game.runConfiguration.experience == RunExperience.bossRush
        ? '★ BOSS ${game.bossesDefeated + 1}/10 · $bossName ★'
        : '★ $bossName ★';
    _bossTitlePaint.render(
      canvas,
      titleText,
      Vector2(startX + barWidth / 2, titleY),
      anchor: Anchor.topCenter,
    );

    final startY = titleY + (isCompact ? 13.0 : 16.0);

    // 2. Outer Retro 8-bit Frame
    final outerRect = Rect.fromLTWH(startX - 4, startY - 4, barWidth + 8, barHeight + 8);
    canvas.drawRect(outerRect, Paint()..color = Colors.black);

    final frameRect = Rect.fromLTWH(startX - 2, startY - 2, barWidth + 4, barHeight + 4);
    canvas.drawRect(frameRect, Paint()..color = const Color(0xFFE5A93B));

    canvas.drawLine(
      Offset(startX - 2, startY - 2),
      Offset(startX + barWidth + 2, startY - 2),
      Paint()..color = const Color(0xFFFFE082)..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(startX - 2, startY + barHeight + 2),
      Offset(startX + barWidth + 2, startY + barHeight + 2),
      Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 2,
    );

    // 3. Dark Inset Background
    final innerRect = Rect.fromLTWH(startX, startY, barWidth, barHeight);
    canvas.drawRect(innerRect, Paint()..color = const Color(0xFF14070A));

    // 4. Segmented 8-bit Health Fill
    final fillWidth = barWidth * healthFraction;
    if (fillWidth > 0) {
      final fillRect = Rect.fromLTWH(startX, startY, fillWidth, barHeight);
      final Color topColor;
      final Color bottomColor;
      if (healthFraction > 0.5) {
        topColor = const Color(0xFFFF5252);
        bottomColor = const Color(0xFFD50000);
      } else if (healthFraction > 0.25) {
        topColor = const Color(0xFFFFB300);
        bottomColor = const Color(0xFFFF6F00);
      } else {
        topColor = const Color(0xFFFF1744);
        bottomColor = const Color(0xFF880E4F);
      }
      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(fillRect);
      canvas.drawRect(fillRect, Paint()..shader = fillGradient);

      canvas.drawLine(
        Offset(startX, startY + 2),
        Offset(startX + fillWidth, startY + 2),
        Paint()..color = Colors.white.withValues(alpha: 0.45)..strokeWidth = 2,
      );

      final notchPaint = Paint()..color = const Color(0xFF0D0204)..strokeWidth = 2;
      for (var x = startX + 14; x < startX + fillWidth - 2; x += 14) {
        canvas.drawLine(Offset(x, startY), Offset(x, startY + barHeight), notchPaint);
      }
    }

    // 5. HP Numeric Text
    _bossHpPaint.render(
      canvas,
      'HP: $remainingHp / $maxHp',
      Vector2(startX + barWidth / 2, startY + barHeight / 2),
      anchor: Anchor.center,
    );

    // 6. Phase Indicator Badges
    final phaseY = startY + barHeight + (isCompact ? 2 : 5);
    final phaseSpacing = barWidth / 3;
    for (var p = 1; p <= 3; p++) {
      final active = p <= phase;
      final current = p == phase;
      final badgeX = startX + (p - 1) * phaseSpacing + phaseSpacing / 2;
      final phaseText = 'FASE $p';
      final phasePaint = current
          ? _activePhasePaint
          : (active ? _passedPhasePaint : _lockedPhasePaint);
      phasePaint.render(
        canvas,
        current ? '▶ $phaseText ◀' : phaseText,
        Vector2(badgeX, phaseY),
        anchor: Anchor.topCenter,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final dino = game.dino;
    final isCompact = game.size.y < 500;
    final playerBase = Vector2(
      isCompact ? 48 : 56,
      isCompact ? 38 : 56,
    );
    final heartSize = isCompact ? Vector2(22, 22) : Vector2(30, 30);
    final heartSpacing = isCompact ? 25.0 : 34.0;

    if (game.runConfiguration.experience != RunExperience.endlessRunner) {
      for (var index = 0; index < game.livesRemaining; index++) {
        heartSprite.render(
          canvas,
          position: Vector2(playerBase.x + index * heartSpacing, playerBase.y),
          size: heartSize,
        );
      }
      if (game.levelPhase == LevelPhase.bossCombat) {
        _renderBossHealthBar(canvas);
      }
      return;
    }

    // Vitalista: Show hearts
    if (dino.characterId == CharacterId.parker) {
      if (dino.hasShield) {
        heartSprite.render(
          canvas,
          position: Vector2(playerBase.x, playerBase.y),
          size: heartSize,
        );
        heartSprite.render(
          canvas,
          position: Vector2(playerBase.x + heartSpacing, playerBase.y),
          size: heartSize,
        );
      } else {
        heartSprite.render(
          canvas,
          position: Vector2(playerBase.x, playerBase.y),
          size: heartSize,
        );
      }
    }
    // Tanque: Show Shield + Timer
    else if (dino.characterId == CharacterId.chema) {
      if (dino.hasShield) {
        shieldSprite.render(
          canvas,
          position: Vector2(playerBase.x, playerBase.y),
          size: Vector2(32, 32),
        );
        timerPaint.render(canvas, 'READY', Vector2(playerBase.x + 40, playerBase.y + 5));
      } else {
        final timeLeft = dino.cooldownTimer.toStringAsFixed(1);
        shieldSprite.render(
          canvas,
          position: Vector2(playerBase.x, playerBase.y),
          size: Vector2(32, 32),
          overridePaint: Paint()..color = Colors.grey.withValues(alpha: 0.5),
        );
        timerPaint.render(canvas, timeLeft, Vector2(playerBase.x + 40, playerBase.y + 5));
      }
    }
    // Pistolero or Fantasma: Show cooldown
    else if (dino.characterId == CharacterId.jano ||
        dino.characterId == CharacterId.conra) {
      if (dino.cooldownTimer > 0) {
        timerPaint.render(
          canvas,
          dino.cooldownTimer.toStringAsFixed(1),
          Vector2(playerBase.x, playerBase.y),
        );
      } else {
        timerPaint.render(canvas, 'READY', Vector2(playerBase.x, playerBase.y));
      }
    }
    // Nanic: Show Energy Bar
    else if (dino.characterId == CharacterId.nanic) {
      final Paint bgPaint = Paint()..color = Colors.grey.withValues(alpha: 0.5);
      final Paint fillPaint = Paint()..color = Colors.yellow;
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      const barWidth = 100.0;
      const barHeight = 20.0;
      final fillWidth = (dino.energy / dino.maxEnergy) * barWidth;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(playerBase.x, playerBase.y, barWidth, barHeight),
        const Radius.circular(10),
      );
      final fillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(playerBase.x, playerBase.y, fillWidth, barHeight),
        const Radius.circular(10),
      );

      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(fillRRect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);

      lightningSprite.render(
        canvas,
        position: Vector2(playerBase.x + barWidth + 5, playerBase.y - 12),
        size: Vector2(48, 48),
      );

      if (dino.isSuperCharged) {
        timerPaint.render(canvas, 'MAX POWER!', Vector2(playerBase.x, playerBase.y + barHeight + 5));
      }
    }
  }
}
