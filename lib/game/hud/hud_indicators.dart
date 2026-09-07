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
  late TextPaint timerPaintCompact;
  late TextPaint timerPaintReady;
  late TextPaint timerPaintReadyCompact;

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

  late final TextPaint _bossTitlePaintCompact = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFD54F),
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      shadows: [
        Shadow(blurRadius: 3, color: Colors.black, offset: Offset(1.5, 1.5)),
        Shadow(blurRadius: 1, color: Color(0xFFFF6F00), offset: Offset(0, 1)),
      ],
    ),
  );

  late final TextPaint _bossHpPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _activePhasePaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.6,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _passedPhasePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFF69F0AE),
      fontSize: 9,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.6,
      shadows: [
        Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
      ],
    ),
  );

  late final TextPaint _lockedPhasePaint = TextPaint(
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
    );
    timerPaintCompact = TextPaint(
      style: const TextStyle(
        color: Colors.cyanAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
    );
    timerPaintReady = TextPaint(
      style: const TextStyle(
        color: Color(0xFF69F0AE),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
    );
    timerPaintReadyCompact = TextPaint(
      style: const TextStyle(
        color: Color(0xFF69F0AE),
        fontSize: 12,
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
    final barHeight = isCompact ? 16.0 : 20.0;
    final startX = (screenWidth - barWidth) / 2;
    final titleY = isCompact ? 8.0 : 14.0;

    // 1. Boss Name with Retro Arcade Accents (safely padded from top edge)
    final titlePaint = isCompact ? _bossTitlePaintCompact : _bossTitlePaint;
    final titleText = game.runConfiguration.experience == RunExperience.bossRush
        ? '✦ BOSS ${game.bossesDefeated + 1}/10 · $bossName ✦'
        : '✦ $bossName ✦';
    titlePaint.render(
      canvas,
      titleText,
      Vector2(startX + barWidth / 2, titleY),
      anchor: Anchor.topCenter,
    );

    final startY = titleY + (isCompact ? 17.0 : 22.0);

    // 2. Outer Retro 8-bit Frame
    final outerRect = Rect.fromLTWH(
      startX - 4,
      startY - 4,
      barWidth + 8,
      barHeight + 8,
    );
    canvas.drawRect(outerRect, Paint()..color = Colors.black);

    final frameRect = Rect.fromLTWH(
      startX - 2,
      startY - 2,
      barWidth + 4,
      barHeight + 4,
    );
    canvas.drawRect(frameRect, Paint()..color = const Color(0xFFE5A93B));

    canvas.drawLine(
      Offset(startX - 2, startY - 2),
      Offset(startX + barWidth + 2, startY - 2),
      Paint()
        ..color = const Color(0xFFFFE082)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(startX - 2, startY + barHeight + 2),
      Offset(startX + barWidth + 2, startY + barHeight + 2),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 2,
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
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 2,
      );

      final notchPaint = Paint()
        ..color = const Color(0x66000000)
        ..strokeWidth = 2;
      for (var x = startX + 14; x < startX + fillWidth - 2; x += 14) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + barHeight),
          notchPaint,
        );
      }
    }

    // 5. HP Numeric Text with Dark Backdrop Pill
    final hpCenter = Vector2(startX + barWidth / 2, startY + barHeight / 2);
    final hpBackdropRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(hpCenter.x, hpCenter.y),
        width: isCompact ? 104 : 120,
        height: barHeight - 4,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(hpBackdropRect, Paint()..color = const Color(0xCC000000));
    _bossHpPaint.render(
      canvas,
      'HP: $remainingHp / $maxHp',
      hpCenter,
      anchor: Anchor.center,
    );

    // 6. Phase Indicator Badges (Centered Retro Pills)
    final phaseY = startY + barHeight + (isCompact ? 6.0 : 8.0);
    final badgeWidth = isCompact ? 60.0 : 72.0;
    final badgeHeight = isCompact ? 14.0 : 16.0;
    final badgeGap = isCompact ? 6.0 : 8.0;
    final totalBadgesWidth = (badgeWidth * 3) + (badgeGap * 2);
    final badgesStartX = startX + (barWidth - totalBadgesWidth) / 2;

    for (var p = 1; p <= 3; p++) {
      final isCleared = p < phase;
      final isCurrent = p == phase;
      final bX = badgesStartX + (p - 1) * (badgeWidth + badgeGap);
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bX, phaseY, badgeWidth, badgeHeight),
        const Radius.circular(3),
      );

      final Paint bgPaint = Paint();
      final Paint borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final TextPaint textPaint;
      final String phaseLabel;

      if (isCurrent) {
        bgPaint.color = const Color(0xFFC62828);
        borderPaint.color = const Color(0xFFFFD54F);
        textPaint = _activePhasePaint;
        phaseLabel = 'FASE $p';
      } else if (isCleared) {
        bgPaint.color = const Color(0xFF1B5E20);
        borderPaint.color = const Color(0xFF00E676);
        textPaint = _passedPhasePaint;
        phaseLabel = '✓ FASE $p';
      } else {
        bgPaint.color = const Color(0x44000000);
        borderPaint.color = const Color(0x26FFFFFF);
        textPaint = _lockedPhasePaint;
        phaseLabel = 'FASE $p';
      }

      canvas.drawRRect(badgeRect, bgPaint);
      canvas.drawRRect(badgeRect, borderPaint);

      textPaint.render(
        canvas,
        phaseLabel,
        Vector2(bX + badgeWidth / 2, phaseY + badgeHeight / 2),
        anchor: Anchor.center,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final dino = game.dino;
    final isCompact = game.size.y < 500;
    final playerBase = Vector2(isCompact ? 48 : 56, isCompact ? 38 : 56);
    final heartSize = isCompact ? Vector2(22, 22) : Vector2(30, 30);
    final heartSpacing = isCompact ? 25.0 : 34.0;

    final hasHeartsRow =
        game.runConfiguration.experience != RunExperience.endlessRunner ||
        game.livesRemaining > 1;
    if (hasHeartsRow) {
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
    }

    final abilityBase = Vector2(
      playerBase.x,
      hasHeartsRow ? playerBase.y + (isCompact ? 24.0 : 34.0) : playerBase.y,
    );

    final tReadyPaint = isCompact ? timerPaintReadyCompact : timerPaintReady;

    // Vitalista: Show hearts (if in endless runner)
    if (!hasHeartsRow && dino.characterId == CharacterId.parker) {
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
    // Tanque (Chema): Show active Shield icon
    else if (dino.characterId == CharacterId.chema) {
      final shieldSize = isCompact ? Vector2(22, 22) : Vector2(30, 30);
      if (dino.hasShield) {
        shieldSprite.render(canvas, position: abilityBase, size: shieldSize);
      }
    }
    // Fantasma (Conra): Show Intangibility active duration
    else if (dino.characterId == CharacterId.conra) {
      if (dino.isIntangible) {
        tReadyPaint.render(
          canvas,
          'INTANGIBLE: ${dino.abilityDurationTimer.toStringAsFixed(1)}s',
          abilityBase,
        );
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

      final barWidth = isCompact ? 80.0 : 100.0;
      final barHeight = isCompact ? 16.0 : 20.0;
      final fillWidth = (dino.energy / dino.maxEnergy) * barWidth;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(abilityBase.x, abilityBase.y, barWidth, barHeight),
        const Radius.circular(8),
      );
      final fillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(abilityBase.x, abilityBase.y, fillWidth, barHeight),
        const Radius.circular(8),
      );

      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(fillRRect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);

      final iconSize = isCompact ? 32.0 : 44.0;
      lightningSprite.render(
        canvas,
        position: Vector2(
          abilityBase.x + barWidth + 4,
          abilityBase.y - (isCompact ? 8 : 12),
        ),
        size: Vector2(iconSize, iconSize),
      );

      if (dino.isSuperCharged) {
        tReadyPaint.render(
          canvas,
          'MAX POWER!',
          Vector2(abilityBase.x, abilityBase.y + barHeight + 3),
        );
      }
    }
  }
}
