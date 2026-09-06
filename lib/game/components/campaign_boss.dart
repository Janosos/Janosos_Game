import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';
import '../domain/level_runtime.dart';
import 'dino.dart';

/// Lightweight, original presentation shared by all campaign bosses.
///
/// The silhouette deliberately uses generated shapes rather than third-party
/// character art. Identity and gameplay come from the level definition and
/// the attack profile below.
class CampaignBoss extends PositionComponent
    with HasGameReference<DinoRunGame>, CollisionCallbacks {
  CampaignBoss({required this.definition})
    : super(size: Vector2(184, 184), anchor: Anchor.bottomRight, priority: 15);

  final LevelDefinition definition;
  SpriteAnimation? _bossAnimation;
  SpriteAnimationTicker? _bossAnimationTicker;
  double _elapsed = 0;
  double _damageFlashTimer = 0;

  void flashDamage() {
    _damageFlashTimer = 0.28;
  }

  Color get _accent => _bossAccent(definition.level);

  late final TextPaint _namePaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFFD54F),
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
      ],
    ),
  );

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        position: Vector2(15, 10),
        size: Vector2(154, 164),
      ),
    );
    final asset = _bossAsset(definition.level);
    try {
      final spriteSheet = await game.images.load(asset);
      final double fw = spriteSheet.width / 2;
      final double fh = spriteSheet.height / 2;

      final frame0 = Sprite(
        spriteSheet,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(fw, fh),
      );
      final frame1 = Sprite(
        spriteSheet,
        srcPosition: Vector2(fw, 0),
        srcSize: Vector2(fw, fh),
      );
      final frame2 = Sprite(
        spriteSheet,
        srcPosition: Vector2(0, fh),
        srcSize: Vector2(fw, fh),
      );
      final frame3 = Sprite(
        spriteSheet,
        srcPosition: Vector2(fw, fh),
        srcSize: Vector2(fw, fh),
      );

      _bossAnimation = SpriteAnimation.spriteList(
        [frame0, frame1, frame2, frame3],
        stepTime: 0.15,
      );
      _bossAnimationTicker = _bossAnimation?.createTicker();
    } catch (_) {}
    position = Vector2(
      game.size.x - 24,
      game.size.y - game.effectiveGroundHeight,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 24, size.y - game.effectiveGroundHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
    }
    _bossAnimationTicker?.update(dt);
    final hover = math.sin(_elapsed * 3.5) * 6.0;
    position.y = game.size.y - game.effectiveGroundHeight + hover;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sprite = _bossAnimationTicker?.getSprite();
    if (sprite != null) {
      final shadowRect = Rect.fromCenter(
        center: Offset(width * 0.5, height - 4),
        width: width * 0.70,
        height: 14,
      );
      canvas.drawOval(
        shadowRect,
        Paint()..color = Colors.black.withValues(alpha: 0.40),
      );
      if (_damageFlashTimer > 0) {
        final recoil = math.sin(_damageFlashTimer * 35) * 7.0;
        canvas.save();
        canvas.translate(recoil, 0);
        sprite.render(
          canvas,
          size: size,
          overridePaint: Paint()
            ..colorFilter = const ColorFilter.mode(
              Color(0xFFFF3333),
              BlendMode.srcATop,
            )
            ..filterQuality = FilterQuality.none,
        );
        canvas.restore();
      } else {
        sprite.render(
          canvas,
          size: size,
          overridePaint: Paint()..filterQuality = FilterQuality.none,
        );
      }
    } else {
      final body = Path()
        ..moveTo(14, height)
        ..lineTo(width * 0.35, 34)
        ..quadraticBezierTo(width * 0.55, 10, width * 0.76, 34)
        ..lineTo(width - 6, height)
        ..close();
      final fill = Paint()..color = const Color(0xFF171827);
      final outline = Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawPath(body, fill);
      canvas.drawPath(body, outline);
      canvas.drawCircle(Offset(width * 0.56, 27), 18, Paint()..color = _accent);
      canvas.drawCircle(
        Offset(width * 0.51, 25),
        3,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(width * 0.61, 25),
        3,
        Paint()..color = Colors.white,
      );
    }
    if (game.levelPhase != LevelPhase.bossCombat) {
      _namePaint.render(
        canvas,
        definition.bossName.toUpperCase(),
        Vector2(width / 2, -12),
        anchor: Anchor.bottomCenter,
      );
    }
  }

  void handleAttack(BossAttackCue cue) {
    game.add(CampaignBossHazard(cue: cue, level: definition.level));
  }
}

enum _HazardMotion { charge, stationary, falling, wave }

class _AttackProfile {
  const _AttackProfile({
    required this.label,
    required this.color,
    required this.size,
    required this.motion,
    required this.speed,
    required this.activeSeconds,
  });

  final String label;
  final Color color;
  final Vector2 size;
  final _HazardMotion motion;
  final double speed;
  final double activeSeconds;
}

class CampaignBossHazard extends PositionComponent
    with HasGameReference<DinoRunGame>, CollisionCallbacks {
  CampaignBossHazard({required this.cue, required this.level})
    : _profile = _profileFor(cue.kind),
      super(size: _profileFor(cue.kind).size, priority: 18);

  static const warningTime = 0.85;
  final BossAttackCue cue;
  final int level;
  final _AttackProfile _profile;
  Sprite? _hazardSprite;
  double _elapsed = 0;
  bool _armed = false;
  late double _ground;
  late final double _laneSeed;
  late final TextPaint _warningPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w900,
      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
    ),
  );

  bool get isWarning => _elapsed < warningTime;

  @override
  Future<void> onLoad() async {
    final asset = _hazardAsset(cue.kind);
    try {
      _hazardSprite = await game.loadSprite(asset);
    } catch (_) {}
    _ground = game.size.y - game.effectiveGroundHeight;
    _laneSeed =
        ((game.runConfiguration.seed + game.bossAttackOrdinal * 97) % 61) / 100;
    switch (_profile.motion) {
      case _HazardMotion.stationary:
        position = Vector2(
          game.size.x * (0.35 + _laneSeed * 0.35),
          _ground - height,
        );
      case _HazardMotion.falling:
        // Falling hazards (like Queen of Hearts cards) actively target the player's position
        // with slight variation, forcing the player to move left/right to dodge!
        final playerX = game.dino.x;
        final spread = (_laneSeed - 0.5) * 110.0;
        final targetX = (playerX + spread).clamp(35.0, game.size.x - width - 40.0);
        position = Vector2(targetX, -height);
      case _HazardMotion.charge || _HazardMotion.wave:
        position = Vector2(
          game.size.x + width,
          _ground - height,
        );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (!_armed && !isWarning) {
      _armed = true;
      final isCircular = cue.kind == BossAttackKind.warningCharge ||
          cue.kind == BossAttackKind.sideCharge ||
          cue.kind == BossAttackKind.spectralHazard ||
          cue.kind == BossAttackKind.chemicalRush ||
          cue.kind == BossAttackKind.cyclone ||
          cue.kind == BossAttackKind.echoPulse ||
          cue.kind == BossAttackKind.armoredCharge;
      if (isCircular) {
        add(
          CircleHitbox(
            radius: width * 0.35,
            position: Vector2(width * 0.15, height * 0.15),
          ),
        );
      } else {
        add(
          RectangleHitbox(
            position: Vector2(width * 0.18, height * 0.14),
            size: Vector2(width * 0.64, height * 0.72),
          ),
        );
      }
    }
    if (isWarning) return;

    final activeElapsed = _elapsed - warningTime;
    switch (_profile.motion) {
      case _HazardMotion.stationary:
        scale.x = game.runConfiguration.reduceMotion
            ? 1
            : 1 + math.sin(activeElapsed * 8).abs() * 0.12;
      case _HazardMotion.falling:
        y += _profile.speed * (1 + level * 0.025) * dt;
      case _HazardMotion.charge:
        x -= _profile.speed * (1 + game.bossPhase * 0.08) * dt;
      case _HazardMotion.wave:
        x -= _profile.speed * dt;
        final waveOffset = cue.kind == BossAttackKind.spectralHazard
            ? (math.sin(activeElapsed * 4.5) + 1.0) * 36
            : math.sin(activeElapsed * 6) * 30;
        y =
            _ground -
            height -
            (game.runConfiguration.reduceMotion ? 0 : waveOffset);
    }

    final bool shouldDespawn;
    switch (_profile.motion) {
      case _HazardMotion.charge || _HazardMotion.wave:
        // Continues across the entire terrain until exiting off the left edge of the screen!
        shouldDespawn = x < -width * 2;
      case _HazardMotion.falling:
        shouldDespawn = y > game.size.y + height;
      case _HazardMotion.stationary:
        shouldDespawn = activeElapsed > _profile.activeSeconds;
    }
    if (shouldDespawn || activeElapsed > 15.0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final warning = isWarning;
    if (warning) {
      final fill = Paint()
        ..color = const Color(0xFFFFB000).withValues(alpha: 0.35);
      final border = Paint()
        ..color = const Color(0xFFFFB000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        border,
      );
      _warningPaint.render(
        canvas,
        '⚠ ${_profile.label}',
        Vector2(width / 2, height / 2),
        anchor: Anchor.center,
      );
      return;
    }

    if (_hazardSprite != null) {
      if (cue.kind == BossAttackKind.spectralHazard) {
        // Floating ghostly apparition: subtle ethereal hover tilt
        canvas.save();
        canvas.translate(width / 2, height / 2);
        final tilt = math.sin(_elapsed * 5) * 0.08;
        canvas.rotate(tilt);
        _hazardSprite!.render(
          canvas,
          position: -Vector2(width / 2, height / 2),
          size: size,
          overridePaint: Paint()..filterQuality = FilterQuality.none,
        );
        canvas.restore();
      } else if (_profile.motion == _HazardMotion.charge ||
          cue.kind == BossAttackKind.cardVolley ||
          cue.kind == BossAttackKind.clockworkBurst) {
        canvas.save();
        canvas.translate(width / 2, height / 2);
        canvas.rotate(_elapsed * 8);
        _hazardSprite!.render(
          canvas,
          position: -Vector2(width / 2, height / 2),
          size: size,
          overridePaint: Paint()..filterQuality = FilterQuality.none,
        );
        canvas.restore();
      } else {
        _hazardSprite!.render(
          canvas,
          size: size,
          overridePaint: Paint()..filterQuality = FilterQuality.none,
        );
      }
    } else {
      final fill = Paint()..color = _profile.color.withValues(alpha: 0.76);
      final border = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final rect = Rect.fromLTWH(0, 0, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        border,
      );
      _warningPaint.render(
        canvas,
        _profile.label,
        Vector2(width / 2, height / 2),
        anchor: Anchor.center,
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_armed && other is DinoComponent) {
      game.receiveUnabsorbedHit();
      removeFromParent();
    }
  }
}

String _bossAsset(int level) => switch (level) {
  1 => 'boss_horseman_pixel.png',
  2 => 'boss_queen_pixel.png',
  3 => 'boss_hyde_pixel.png',
  4 => 'boss_phantom_pixel.png',
  5 => 'boss_snow_queen_pixel.png',
  6 => 'boss_dracula_pixel.png',
  7 => 'boss_witch_pixel.png',
  8 => 'boss_frankenstein_pixel.png',
  9 => 'boss_davy_jones_pixel.png',
  10 => 'boss_moriarty_pixel.png',
  _ => 'boss_horseman_pixel.png',
};

String _hazardAsset(BossAttackKind kind) => switch (kind) {
  BossAttackKind.warningCharge ||
  BossAttackKind.sideCharge ||
  BossAttackKind.armoredCharge => 'hazard_spectral_pixel.png',
  BossAttackKind.spectralHazard => 'hazard_ghost_pixel.png',
  BossAttackKind.cardVolley => 'hazard_card_pixel.png',
  BossAttackKind.heartPlatform => 'hazard_heart_pixel.png',
  BossAttackKind.shockwave => 'hazard_shockwave_pixel.png',
  BossAttackKind.chemicalRush => 'hazard_chemical_pixel.png',
  BossAttackKind.echoPulse => 'hazard_echo_pixel.png',
  BossAttackKind.darknessBlade => 'hazard_darkness_pixel.png',
  BossAttackKind.iceShard => 'hazard_ice_shard_pixel.png',
  BossAttackKind.frozenFloor => 'hazard_ice_shard_pixel.png',
  BossAttackKind.batSwarm => 'hazard_bat_pixel.png',
  BossAttackKind.mistStep => 'hazard_bat_pixel.png',
  BossAttackKind.cyclone => 'hazard_cyclone_pixel.png',
  BossAttackKind.toxicZone => 'hazard_chemical_pixel.png',
  BossAttackKind.lightningColumn => 'hazard_lightning_pixel.png',
  BossAttackKind.tideWave => 'hazard_tide_pixel.png',
  BossAttackKind.chainSweep => 'hazard_tide_pixel.png',
  BossAttackKind.decoyTrap => 'hazard_clockwork_pixel.png',
  BossAttackKind.clockworkBurst => 'hazard_clockwork_pixel.png',
};

Color _bossAccent(int level) => <Color>[
  const Color(0xFFFF7A00),
  const Color(0xFFE53371),
  const Color(0xFF72E06A),
  const Color(0xFF9B7BFF),
  const Color(0xFF66D9FF),
  const Color(0xFFB51935),
  const Color(0xFF63C132),
  const Color(0xFFFFE45C),
  const Color(0xFF23A7C9),
  const Color(0xFFC99858),
][(level - 1).clamp(0, 9)];

_AttackProfile _profileFor(BossAttackKind kind) => switch (kind) {
  BossAttackKind.warningCharge => _charge('CALAVERA', const Color(0xFFFF7A00)),
  BossAttackKind.sideCharge => _charge('EMBESTIDA', const Color(0xFFEB4D4B)),
  BossAttackKind.spectralHazard => _wave('OLEADA ESPECTRAL', const Color(0xFF00F0FF)),
  BossAttackKind.cardVolley => _fall('CARTAS', const Color(0xFFE53371)),
  BossAttackKind.heartPlatform => _wave('CORAZÓN', const Color(0xFFFF5B99)),
  BossAttackKind.shockwave => _wave('ONDA', const Color(0xFFFFD166)),
  BossAttackKind.chemicalRush => _charge('QUÍMICO', const Color(0xFF72E06A)),
  BossAttackKind.echoPulse => _wave('ECO', const Color(0xFF9B7BFF)),
  BossAttackKind.darknessBlade => _fall('SOMBRA', const Color(0xFF4C3F78)),
  BossAttackKind.iceShard => _fall('HIELO', const Color(0xFF66D9FF)),
  BossAttackKind.frozenFloor => _zone('SUELO HELADO', const Color(0xFFB8F2FF)),
  BossAttackKind.batSwarm => _wave('MURCIÉLAGOS', const Color(0xFF722F45)),
  BossAttackKind.mistStep => _charge('NIEBLA', const Color(0xFF9AA7B8)),
  BossAttackKind.cyclone => _wave('CICLÓN', const Color(0xFF86C766)),
  BossAttackKind.toxicZone => _zone('TÓXICO', const Color(0xFF63C132)),
  BossAttackKind.lightningColumn => _fall('RAYO', const Color(0xFFFFE45C)),
  BossAttackKind.armoredCharge => _charge('ARMADURA', const Color(0xFF89939E)),
  BossAttackKind.tideWave => _wave('MAREA', const Color(0xFF23A7C9)),
  BossAttackKind.chainSweep => _charge('CADENA', const Color(0xFFB8A48A)),
  BossAttackKind.decoyTrap => _zone('TRAMPA', const Color(0xFFC99858)),
  BossAttackKind.clockworkBurst => _fall('RELOJ', const Color(0xFFE3A857)),
};

_AttackProfile _charge(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(78, 78),
  motion: _HazardMotion.charge,
  speed: 470,
  activeSeconds: 5.0,
);

_AttackProfile _zone(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(76, 76),
  motion: _HazardMotion.charge,
  speed: 380,
  activeSeconds: 5.0,
);

_AttackProfile _fall(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(74, 74),
  motion: _HazardMotion.falling,
  speed: 430,
  activeSeconds: 3.5,
);

_AttackProfile _wave(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(80, 80),
  motion: _HazardMotion.wave,
  speed: 410,
  activeSeconds: 5.0,
);
