import 'dart:math' as math;

enum LevelPhase { runner, bossIntro, bossCombat, victory, defeat }

enum BossAttackKind {
  warningCharge,
  sideCharge,
  spectralHazard,
  cardVolley,
  heartPlatform,
  shockwave,
  chemicalRush,
  echoPulse,
  darknessBlade,
  iceShard,
  frozenFloor,
  batSwarm,
  mistStep,
  cyclone,
  toxicZone,
  lightningColumn,
  armoredCharge,
  tideWave,
  chainSweep,
  decoyTrap,
  clockworkBurst,
}

class LevelDefinition {
  const LevelDefinition({
    required this.level,
    required this.scenario,
    required this.bossId,
    required this.bossName,
    required this.mechanic,
    required this.runnerDuration,
    required this.bossHealth,
    required this.bossActionCooldown,
    required this.uniqueRewardId,
    required this.uniqueRewardName,
    required this.attackPattern,
  });

  final int level;
  final String scenario;
  final String bossId;
  final String bossName;
  final String mechanic;
  final Duration runnerDuration;
  final int bossHealth;
  final Duration bossActionCooldown;
  final String uniqueRewardId;
  final String uniqueRewardName;
  final List<BossAttackKind> attackPattern;
}

const levelOneDefinition = LevelDefinition(
  level: 1,
  scenario: 'Sleepy Hollow',
  bossId: 'headless_horseman',
  bossName: 'Jinete sin Cabeza',
  mechanic: 'Cargas laterales y peligros espectrales',
  runnerDuration: Duration(minutes: 3),
  bossHealth: 4500,
  bossActionCooldown: Duration(milliseconds: 900),
  uniqueRewardId: 'headless_horseman.spectral_trail',
  uniqueRewardName: 'Estela espectral',
  attackPattern: [
    BossAttackKind.warningCharge,
    BossAttackKind.sideCharge,
    BossAttackKind.spectralHazard,
  ],
);

const campaignLevelDefinitions = <LevelDefinition>[
  levelOneDefinition,
  LevelDefinition(
    level: 2,
    scenario: 'Corte del Caos',
    bossId: 'queen_of_hearts',
    bossName: 'Reina de Corazones',
    mechanic: 'Cartas, plataformas móviles y cambios de tamaño',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 5000,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'queen_of_hearts.card_aura',
    uniqueRewardName: 'Aura de cartas',
    attackPattern: [
      BossAttackKind.cardVolley,
      BossAttackKind.heartPlatform,
      BossAttackKind.cardVolley,
    ],
  ),
  LevelDefinition(
    level: 3,
    scenario: 'Londres Químico',
    bossId: 'mister_hyde',
    bossName: 'Señor Hyde',
    mechanic: 'Cambios de fuerza, velocidad y ondas de choque',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 5500,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'mister_hyde.hyde_serum',
    uniqueRewardName: 'Suero de Hyde',
    attackPattern: [
      BossAttackKind.shockwave,
      BossAttackKind.chemicalRush,
      BossAttackKind.shockwave,
    ],
  ),
  LevelDefinition(
    level: 4,
    scenario: 'Ópera Subterránea',
    bossId: 'phantom',
    bossName: 'El Fantasma',
    mechanic: 'Oscuridad, ecos y ataques guiados por sonido',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 6000,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'phantom.phantom_mask',
    uniqueRewardName: 'Máscara fantasma',
    attackPattern: [
      BossAttackKind.echoPulse,
      BossAttackKind.darknessBlade,
      BossAttackKind.echoPulse,
    ],
  ),
  LevelDefinition(
    level: 5,
    scenario: 'Palacio Invernal',
    bossId: 'snow_queen',
    bossName: 'Reina de las Nieves',
    mechanic: 'Suelo resbaladizo y proyectiles de hielo',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 6500,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'snow_queen.frost_heart',
    uniqueRewardName: 'Corazón de escarcha',
    attackPattern: [
      BossAttackKind.iceShard,
      BossAttackKind.frozenFloor,
      BossAttackKind.iceShard,
    ],
  ),
  LevelDefinition(
    level: 6,
    scenario: 'Castillo Transilvano',
    bossId: 'dracula',
    bossName: 'Drácula',
    mechanic: 'Murciélagos, niebla, teletransporte y curación',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 7000,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'dracula.crimson_cape',
    uniqueRewardName: 'Capa carmesí',
    attackPattern: [
      BossAttackKind.batSwarm,
      BossAttackKind.mistStep,
      BossAttackKind.batSwarm,
    ],
  ),
  LevelDefinition(
    level: 7,
    scenario: 'Reino Esmeralda',
    bossId: 'wicked_witch',
    bossName: 'Bruja Malvada del Oeste',
    mechanic: 'Vuelo, ciclones y zonas tóxicas',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 7500,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'wicked_witch.silver_shoes',
    uniqueRewardName: 'Zapatos plateados',
    attackPattern: [
      BossAttackKind.cyclone,
      BossAttackKind.toxicZone,
      BossAttackKind.cyclone,
    ],
  ),
  LevelDefinition(
    level: 8,
    scenario: 'Laboratorio de Tormentas',
    bossId: 'frankenstein_creature',
    bossName: 'Criatura de Frankenstein',
    mechanic: 'Rayos, armadura rompible y embestidas',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 8000,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'frankenstein_creature.galvanic_core',
    uniqueRewardName: 'Núcleo galvánico',
    attackPattern: [
      BossAttackKind.lightningColumn,
      BossAttackKind.armoredCharge,
      BossAttackKind.lightningColumn,
    ],
  ),
  LevelDefinition(
    level: 9,
    scenario: 'Puerto Abisal',
    bossId: 'davy_jones',
    bossName: 'Davy Jones',
    mechanic: 'Mareas, cadenas y cubierta inclinada',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 8500,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'davy_jones.abyssal_compass',
    uniqueRewardName: 'Brújula abisal',
    attackPattern: [
      BossAttackKind.tideWave,
      BossAttackKind.chainSweep,
      BossAttackKind.tideWave,
    ],
  ),
  LevelDefinition(
    level: 10,
    scenario: 'Londres Mecánico',
    bossId: 'moriarty',
    bossName: 'Profesor Moriarty',
    mechanic: 'Trampas, señuelos y mecánicas combinadas',
    runnerDuration: Duration(minutes: 3),
    bossHealth: 9000,
    bossActionCooldown: Duration(milliseconds: 900),
    uniqueRewardId: 'moriarty.strategist_crown',
    uniqueRewardName: 'Corona del estratega',
    attackPattern: [
      BossAttackKind.decoyTrap,
      BossAttackKind.clockworkBurst,
      BossAttackKind.sideCharge,
      BossAttackKind.lightningColumn,
    ],
  ),
];

LevelDefinition campaignLevelDefinition(int level) {
  if (level < 1 || level > campaignLevelDefinitions.length) {
    throw RangeError.range(level, 1, campaignLevelDefinitions.length, 'level');
  }
  return campaignLevelDefinitions[level - 1];
}

class BossRushProgress {
  BossRushProgress({required this.maxLives})
    : assert(maxLives > 0),
      livesForNextBoss = maxLives;

  final int maxLives;
  int bossesDefeated = 0;
  int livesForNextBoss;

  bool get isComplete => bossesDefeated == campaignLevelDefinitions.length;
  int get nextLevel => (bossesDefeated + 1).clamp(1, 10);

  void recordVictory({required int survivingLives}) {
    if (isComplete) return;
    bossesDefeated += 1;
    livesForNextBoss = math.min(
      maxLives,
      survivingLives.clamp(1, maxLives) + 1,
    );
  }
}

class BossAttackCue {
  const BossAttackCue({required this.kind, required this.fromRight});

  final BossAttackKind kind;
  final bool fromRight;
}

/// Pure deterministic state machine for one runner section plus its boss.
///
/// Flame owns presentation and collisions; this class owns progression,
/// cooldowns and terminal state so the same seed and inputs are testable.
class LevelRuntime {
  LevelRuntime({
    required this.definition,
    required int maxLives,
    required this.damageMultiplier,
    required this.seed,
    this.attackCadenceMultiplier = 1,
  }) : assert(maxLives > 0),
       livesRemaining = maxLives,
       bossHealthRemaining = definition.bossHealth;

  static const hitInvulnerability = Duration(milliseconds: 1200);

  final LevelDefinition definition;
  final double damageMultiplier;
  final int seed;
  final double attackCadenceMultiplier;

  LevelPhase phase = LevelPhase.runner;
  Duration runnerElapsed = Duration.zero;
  Duration bossElapsed = Duration.zero;
  Duration _invulnerabilityRemaining = Duration.zero;
  Duration _bossActionCooldownRemaining = Duration.zero;
  Duration _bossAttackCountdown = const Duration(seconds: 2);
  int _attackIndex = 0;

  int livesRemaining;
  int bossHealthRemaining;

  bool get isTerminal =>
      phase == LevelPhase.victory || phase == LevelPhase.defeat;
  bool get isInvulnerable => _invulnerabilityRemaining > Duration.zero;
  bool get canUseBossAction =>
      phase == LevelPhase.bossCombat &&
      _bossActionCooldownRemaining <= Duration.zero;
  double get bossHealthFraction =>
      (bossHealthRemaining / definition.bossHealth).clamp(0, 1);
  int get bossPhase => switch (bossHealthFraction) {
    > 0.66 => 1,
    > 0.33 => 2,
    _ => 3,
  };

  List<BossAttackCue> update(Duration delta) {
    if (delta <= Duration.zero || isTerminal) return const [];
    _invulnerabilityRemaining = _subtract(_invulnerabilityRemaining, delta);
    _bossActionCooldownRemaining = _subtract(
      _bossActionCooldownRemaining,
      delta,
    );

    if (phase == LevelPhase.runner) {
      runnerElapsed += delta;
      if (runnerElapsed >= definition.runnerDuration) {
        phase = LevelPhase.bossIntro;
      }
      return const [];
    }
    if (phase != LevelPhase.bossCombat) return const [];

    bossElapsed += delta;
    _bossAttackCountdown -= delta;
    if (_bossAttackCountdown > Duration.zero) return const [];

    final cue = _nextAttack();
    final phaseAdjustment = Duration(milliseconds: (bossPhase - 1) * 250);
    _bossAttackCountdown = const Duration(milliseconds: 2200) - phaseAdjustment;
    return [cue];
  }

  void beginBossCombat() {
    if (phase != LevelPhase.bossIntro) return;
    phase = LevelPhase.bossCombat;
    _bossAttackCountdown = const Duration(seconds: 2);
  }

  void skipRunner() {
    if (phase != LevelPhase.runner) return;
    runnerElapsed = definition.runnerDuration;
    phase = LevelPhase.bossIntro;
  }

  bool takePlayerHit() {
    if (isTerminal || isInvulnerable) return false;
    livesRemaining = math.max(0, livesRemaining - 1);
    if (livesRemaining == 0) {
      phase = LevelPhase.defeat;
    } else {
      _invulnerabilityRemaining = hitInvulnerability;
    }
    return true;
  }

  int useBossAction({double bonusMultiplier = 1, bool ignoreCooldown = false}) {
    if (phase != LevelPhase.bossCombat ||
        (!ignoreCooldown && !canUseBossAction)) {
      return 0;
    }
    _bossActionCooldownRemaining = Duration(
      microseconds:
          (definition.bossActionCooldown.inMicroseconds /
                  attackCadenceMultiplier.clamp(1, 1.1))
              .round(),
    );
    final boundedMultiplier = (damageMultiplier * bonusMultiplier).clamp(
      0.5,
      2,
    );
    final damage = (100 * boundedMultiplier).round();
    bossHealthRemaining = math.max(0, bossHealthRemaining - damage);
    if (bossHealthRemaining == 0) phase = LevelPhase.victory;
    return damage;
  }

  BossAttackCue _nextAttack() {
    final mixed = (seed ^ ((_attackIndex + 1) * 0x45d9f3b)) & 0x7fffffff;
    final fromRight = mixed.isEven;
    final pattern = definition.attackPattern;
    final patternIndex = (_attackIndex + bossPhase + mixed) % pattern.length;
    _attackIndex += 1;
    return BossAttackCue(kind: pattern[patternIndex], fromRight: fromRight);
  }

  static Duration _subtract(Duration value, Duration delta) {
    final next = value - delta;
    return next.isNegative ? Duration.zero : next;
  }
}
