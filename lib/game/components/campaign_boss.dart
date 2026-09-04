import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
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
    with HasGameReference<DinoRunGame> {
  CampaignBoss({required this.definition})
    : super(size: Vector2(156, 136), anchor: Anchor.bottomRight, priority: 15);

  final LevelDefinition definition;

  Color get _accent => _bossAccent(definition.level);

  late final TextPaint _namePaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black, blurRadius: 3)],
    ),
  );

  @override
  Future<void> onLoad() async {
    position = Vector2(
      game.size.x - 28,
      game.size.y - DinoRunGame.virtualGroundHeight,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 28, size.y - DinoRunGame.virtualGroundHeight);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
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
    _namePaint.render(
      canvas,
      definition.bossName.toUpperCase(),
      Vector2(width - 2, -22),
      anchor: Anchor.bottomRight,
    );
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
    _ground = game.size.y - DinoRunGame.virtualGroundHeight;
    _laneSeed =
        ((game.runConfiguration.seed + game.bossAttackOrdinal * 97) % 61) / 100;
    switch (_profile.motion) {
      case _HazardMotion.stationary:
        position = Vector2(game.size.x * (0.18 + _laneSeed), _ground - height);
      case _HazardMotion.falling:
        position = Vector2(game.size.x * (0.18 + _laneSeed), -height);
      case _HazardMotion.charge || _HazardMotion.wave:
        position = Vector2(
          cue.fromRight ? game.size.x + width : -width,
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
      add(RectangleHitbox());
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
        x +=
            (cue.fromRight ? -1 : 1) *
            _profile.speed *
            (1 + game.bossPhase * 0.08) *
            dt;
      case _HazardMotion.wave:
        x += (cue.fromRight ? -1 : 1) * _profile.speed * dt;
        y =
            _ground -
            height -
            (game.runConfiguration.reduceMotion
                ? 0
                : math.sin(activeElapsed * 7) * 34);
    }
    if (activeElapsed > _profile.activeSeconds ||
        x < -width * 2 ||
        x > game.size.x + width * 2 ||
        y > _ground + height) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final warning = isWarning;
    final fill = Paint()
      ..color = warning
          ? const Color(0xFFFFB000).withValues(alpha: 0.34)
          : _profile.color.withValues(alpha: 0.76);
    final border = Paint()
      ..color = warning ? const Color(0xFFFFB000) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = warning ? 5 : 3;
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
      warning ? '⚠ ${_profile.label}' : _profile.label,
      Vector2(width / 2, height / 2),
      anchor: Anchor.center,
    );
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
  BossAttackKind.warningCharge => _charge('CARGA', const Color(0xFFFF7A00)),
  BossAttackKind.sideCharge => _charge('EMBESTIDA', const Color(0xFFEB4D4B)),
  BossAttackKind.spectralHazard => _zone('ESPECTRO', const Color(0xFF00F0FF)),
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
  size: Vector2(112, 68),
  motion: _HazardMotion.charge,
  speed: 470,
  activeSeconds: 2.3,
);

_AttackProfile _zone(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(76, 138),
  motion: _HazardMotion.stationary,
  speed: 0,
  activeSeconds: 1.35,
);

_AttackProfile _fall(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(68, 94),
  motion: _HazardMotion.falling,
  speed: 430,
  activeSeconds: 2.1,
);

_AttackProfile _wave(String label, Color color) => _AttackProfile(
  label: label,
  color: color,
  size: Vector2(104, 74),
  motion: _HazardMotion.wave,
  speed: 390,
  activeSeconds: 2.6,
);
