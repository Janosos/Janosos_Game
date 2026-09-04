import 'dart:developer' as developer;

import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'components/dino.dart';
import 'components/boss_action_button.dart';
import 'components/ground.dart';
import 'components/campaign_boss.dart';
import 'components/obstacle_manager.dart';
import 'components/orb.dart';
import 'components/projectile.dart';
import 'components/sky.dart';
import 'domain/character_definition.dart';
import 'domain/character_id.dart';
import 'domain/gameplay_event.dart';
import 'domain/level_runtime.dart';
import 'domain/run_configuration.dart';
import 'domain/run_result.dart';
import 'hud/ability_button.dart';
import 'hud/hud_indicators.dart';
import 'hud/score.dart';
import 'runtime/gameplay_event_sink.dart';

class DinoRunGame extends FlameGame
    with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  DinoRunGame({
    required RunConfiguration configuration,
    GameplayEventSink onEvent = ignoreGameplayEvent,
    DateTime Function()? now,
  }) : _configuration = configuration,
       _eventSink = onEvent,
       _now = now ?? DateTime.now;

  late DinoComponent _dino;
  late GroundComponent _ground;
  late SkyComponent _sky;
  late ObstacleManager _obstacleManager;
  late ScoreSystem _scoreSystem;
  AbilityButton? _abilityButton;
  HudIndicators? _hudIndicators;
  BossActionButton? _bossActionButton;
  CampaignBoss? _boss;
  LevelRuntime? _levelRuntime;

  RunConfiguration _configuration;
  final GameplayEventSink _eventSink;
  final DateTime Function() _now;
  Duration _elapsedRunTime = Duration.zero;
  Duration _pauseConsumed = Duration.zero;
  DateTime? _pauseStartedAt;
  bool _runActive = false;
  RunResult? _lastRunResult;

  DinoComponent get dino => _dino;
  ScoreSystem get scoreSystem => _scoreSystem;
  RunConfiguration get runConfiguration => _configuration;
  CharacterId get selectedCharacter => _configuration.characterId;
  int get legacyHighScore => _scoreSystem.highScore;
  RunResult? get lastRunResult => _lastRunResult;
  LevelPhase? get levelPhase => _levelRuntime?.phase;
  int get livesRemaining =>
      _levelRuntime?.livesRemaining ?? _configuration.stats.maxLives;
  int get bossHealthRemaining => _levelRuntime?.bossHealthRemaining ?? 0;
  double get bossHealthFraction => _levelRuntime?.bossHealthFraction ?? 0;
  int get bossPhase => _levelRuntime?.bossPhase ?? 0;
  LevelDefinition? get currentLevelDefinition => _levelRuntime?.definition;
  int get bossesDefeated => _bossRushProgress?.bossesDefeated ?? 0;
  int bossAttackOrdinal = 0;
  BossRushProgress? _bossRushProgress;
  final Map<String, int> _skillUses = {};
  int _precisionBonusAwarded = 0;

  double currentSpeed = 200;
  final double startSpeed = 200;
  final double maxSpeed = 600;
  double speedMultiplier = 1;

  static const double virtualGroundHeight = 160;

  double orbTimer = 2;

  @override
  Future<void> onLoad() async {
    FlameAudio.bgm.initialize();

    _sky = SkyComponent();
    add(_sky);

    _ground = GroundComponent();
    add(_ground);

    _dino = DinoComponent();
    _dino.priority = 10;
    add(_dino);

    _obstacleManager = ObstacleManager();
    _obstacleManager.priority = 10;
    add(_obstacleManager);

    _scoreSystem = ScoreSystem(
      initialHighScore: _configuration.legacyHighScore,
    );
    _scoreSystem.priority = 100;
    add(_scoreSystem);

    await images.loadAll([
      'ability_button.png',
      'heart_indicator.png',
      'tank_shield_icon.png',
      'lightning_icon.png',
      'aura.png',
      'jano_clean.png',
      'parker_clean.png',
      'chema_clean.png',
      'conra_clean.png',
      'shyno_clean.png',
      'nakama_clean.png',
      'nanic_clean.png',
      'bullet.png',
      'orb.png',
    ]);

    await FlameAudio.audioCache.loadAll([
      'Jump.wav',
      'Select.wav',
      'Shoot.wav',
      'Invisibility.wav',
      'Hit.wav',
      'LoopSong.wav',
    ]);

    pauseEngine();
    overlays.add('StartMenu');
  }

  Future<void> startGame(RunConfiguration configuration) async {
    _configuration = configuration;
    _lastRunResult = null;
    _elapsedRunTime = Duration.zero;
    _pauseConsumed = Duration.zero;
    _pauseStartedAt = null;
    _runActive = false;
    _levelRuntime = configuration.experience != RunExperience.endlessRunner
        ? LevelRuntime(
            definition: campaignLevelDefinition(
              configuration.experience == RunExperience.bossRush
                  ? 1
                  : configuration.level,
            ),
            maxLives: configuration.stats.maxLives,
            damageMultiplier: configuration.stats.damageMultiplier,
            seed: configuration.seed,
            attackCadenceMultiplier: configuration.stats.speedMultiplier,
          )
        : null;
    if (configuration.experience == RunExperience.bossRush) {
      _levelRuntime!.skipRunner();
    }
    bossAttackOrdinal = 0;
    _bossRushProgress = configuration.experience == RunExperience.bossRush
        ? BossRushProgress(maxLives: configuration.stats.maxLives)
        : null;
    _skillUses.clear();
    _precisionBonusAwarded = 0;

    overlays.remove('StartMenu');
    overlays.remove('CharacterSelection');
    overlays.remove('GameOverMenu');

    await _dino.setConfiguration(configuration);

    if (_abilityButton != null) {
      camera.viewport.remove(_abilityButton!);
      _abilityButton = null;
    }
    if (_hudIndicators != null) {
      camera.viewport.remove(_hudIndicators!);
      _hudIndicators = null;
    }

    _hudIndicators = HudIndicators();
    camera.viewport.add(_hudIndicators!);

    if (configuration.controlLayout.hasActiveAbilityControl) {
      _abilityButton = AbilityButton(dinoGame: this);
      camera.viewport.add(_abilityButton!);
    }

    _dino.reset();
    _obstacleManager.reset(seed: configuration.seed);
    _removeBossEncounter();
    for (final orb in children.whereType<OrbComponent>()) {
      orb.removeFromParent();
    }
    _scoreSystem.reset(highScore: configuration.legacyHighScore);
    currentSpeed = startSpeed;
    speedMultiplier = 1;
    orbTimer = 2;

    try {
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.stop();
      }
      if (configuration.audioEnabled) {
        await FlameAudio.bgm.play('LoopSong.wav', volume: 0.5);
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Unable to start background music',
        name: 'DinoRunGame',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _runActive = true;
    _eventSink(RunStartedEvent(configuration));
    if (configuration.experience == RunExperience.bossRush) {
      _obstacleManager.pauseSpawning();
      _showBossIntro(_levelRuntime!);
    } else {
      resumeEngine();
    }
  }

  void gameOver() {
    _finishRun(RunOutcome.defeat);
  }

  void _finishRun(RunOutcome outcome) {
    if (!_runActive) {
      return;
    }
    _runActive = false;

    try {
      FlameAudio.bgm.stop();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Unable to stop background music',
        name: 'DinoRunGame',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _scoreSystem.completeRun();
    final result = RunResult(
      characterId: _configuration.characterId,
      mode: _configuration.mode,
      outcome: outcome,
      score: _scoreSystem.currentScore.toInt(),
      duration: _elapsedRunTime,
      levelReached: _configuration.experience == RunExperience.bossRush
          ? (_bossRushProgress?.bossesDefeated ?? 0)
          : _configuration.level,
      contentVersion: _configuration.contentVersion,
      protocolVersion: _configuration.protocolVersion,
    );
    _lastRunResult = result;
    _eventSink(RunFinishedEvent(result));

    pauseEngine();
    overlays.add('GameOverMenu');
  }

  void resetGame() {
    _runActive = false;
    overlays.remove('GameOverMenu');
    overlays.add('StartMenu');
    _dino.reset();
    _obstacleManager.reset();
    _removeBossEncounter();
    _levelRuntime = null;
    _scoreSystem.reset();
    currentSpeed = startSpeed;
    speedMultiplier = 1;
    if (_abilityButton != null) {
      camera.viewport.remove(_abilityButton!);
      _abilityButton = null;
    }
    if (_hudIndicators != null) {
      camera.viewport.remove(_hudIndicators!);
      _hudIndicators = null;
    }
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_runActive || !isMounted) {
      return;
    }

    final expiry = _configuration.stageExpiresAt;
    if (expiry != null && !_now().toUtc().isBefore(expiry.toUtc())) {
      _finishRun(RunOutcome.abandoned);
      return;
    }

    _elapsedRunTime += Duration(microseconds: (dt * 1000000).round());

    final runtime = _levelRuntime;
    if (runtime != null) {
      final previousPhase = runtime.phase;
      final previousBossPhase = runtime.bossPhase;
      final cues = runtime.update(
        Duration(microseconds: (dt * 1000000).round()),
      );
      if (previousPhase != runtime.phase) {
        _onLevelPhaseChanged(previousPhase, runtime.phase);
      }
      if (runtime.phase == LevelPhase.bossCombat) {
        if (previousBossPhase != runtime.bossPhase) {
          _eventSink(
            BossPhaseChangedEvent(
              bossId: runtime.definition.bossId,
              phase: runtime.bossPhase,
            ),
          );
        }
        for (final cue in cues) {
          bossAttackOrdinal += 1;
          _boss?.handleAttack(cue);
        }
      }
    }

    final score = _scoreSystem.currentScore;
    final baseSpeed = (startSpeed + (score / 10))
        .clamp(startSpeed, maxSpeed)
        .toDouble();
    currentSpeed = baseSpeed * speedMultiplier;

    if (selectedCharacter == CharacterId.nanic && !dino.isSuperCharged) {
      orbTimer -= dt;
      if (orbTimer <= 0) {
        orbTimer = 3;
        final spawnY = size.y - virtualGroundHeight - 40;
        add(
          OrbComponent(
            position: Vector2(size.x + 50, spawnY),
            speed: currentSpeed,
          ),
        );
      }
    }
  }

  void increaseSpeed() {
    speedMultiplier = 1.5;
  }

  void resetSpeed() {
    speedMultiplier = 1;
  }

  void scoreChanged(int score) {
    if (_runActive) {
      _eventSink(ScoreChangedEvent(score));
    }
  }

  void playerDamaged({required bool wasAbsorbed}) {
    if (_runActive) {
      _eventSink(PlayerDamagedEvent(wasAbsorbed: wasAbsorbed));
    }
  }

  void receiveUnabsorbedHit() {
    if (!_runActive || _dino.isDamageInvulnerable) return;
    final runtime = _levelRuntime;
    if (runtime == null) {
      playerDamaged(wasAbsorbed: false);
      gameOver();
      return;
    }
    final consumed = runtime.takePlayerHit();
    if (!consumed) return;
    playerDamaged(wasAbsorbed: false);
    _eventSink(LifeDepletedEvent(remainingLives: runtime.livesRemaining));
    if (runtime.phase == LevelPhase.defeat) {
      _finishRun(RunOutcome.defeat);
      return;
    }
    final reinforced = passiveParameter(
      'post_hit_invulnerability',
      'basis_points',
    );
    final invulnerability = Duration(
      microseconds:
          (LevelRuntime.hitInvulnerability.inMicroseconds *
                  (1 + reinforced.clamp(0, 1000) / 10000))
              .round(),
    );
    _dino.beginDamageInvulnerability(invulnerability);
    _dino.applyRecovery(
      Duration(
        milliseconds: passiveParameter(
          'recovery_after_life_loss',
          'duration_ms',
        ),
      ),
      passiveParameter('recovery_after_life_loss', 'basis_points'),
    );
  }

  double activatePurchasedSkill(String skillId) {
    if (!_runActive) return 0;
    final effect = _configuration.loadout.effectById(skillId);
    if (effect == null) return 0;
    final useLimit = effect.intParameter('uses_per_stage', fallback: 99);
    final used = _skillUses[skillId] ?? 0;
    if (used >= useLimit) return 0;
    if (!_applyActiveSkill(effect)) return 0;
    _skillUses[skillId] = used + 1;
    _eventSink(SkillActivatedEvent(skillId));
    final cooldownMs = effect.intParameter('cooldown_ms', fallback: 8000);
    return (cooldownMs / 1000) /
        _configuration.stats.speedMultiplier.clamp(1, 1.1);
  }

  bool _applyActiveSkill(RuntimeSkillEffect effect) {
    final inBoss = _levelRuntime?.phase == LevelPhase.bossCombat;
    double basisMultiplier(String key) =>
        effect.intParameter(key, fallback: 5000) / 10000;
    void bossHit(double multiplier) {
      if (inBoss) {
        _useBossAction(bonusMultiplier: multiplier, ignoresCooldown: true);
      }
    }

    switch (effect.effectCode) {
      case 'ricochet_projectile':
        if (inBoss) {
          bossHit(basisMultiplier('damage_basis_points'));
        } else {
          add(Projectile(position: _dino.position + Vector2(_dino.width, -30)));
        }
      case 'projectile_burst':
        final projectiles = effect.intParameter('projectiles', fallback: 3);
        if (inBoss) {
          bossHit(projectiles * basisMultiplier('damage_basis_points'));
        } else {
          for (var index = 0; index < projectiles; index++) {
            add(
              Projectile(
                position:
                    _dino.position + Vector2(_dino.width, -24 - index * 10),
              ),
            );
          }
        }
      case 'guard_dash':
        _dino.beginDamageInvulnerability(
          Duration(milliseconds: effect.intParameter('duration_ms')),
        );
        bossHit(0.75);
      case 'last_life_rally':
        if (livesRemaining != 1) return false;
        _dino.beginDamageInvulnerability(
          Duration(milliseconds: effect.intParameter('duration_ms')),
        );
        bossHit(0.6);
      case 'shield_pulse':
        _clearBossHazards();
        bossHit(basisMultiplier('damage_basis_points'));
      case 'penalty_discharge':
        bossHit(0.75);
      case 'phase_dash':
        _dino.beginDamageInvulnerability(
          Duration(milliseconds: effect.intParameter('duration_ms')),
        );
        bossHit(0.7);
      case 'spectral_decoy':
        _clearBossHazards();
        _dino.beginDamageInvulnerability(
          Duration(milliseconds: effect.intParameter('duration_ms')),
        );
      case 'aerial_stomp':
        if (!_dino.isAirborne) return false;
        _clearBossHazards();
        bossHit(basisMultiplier('damage_basis_points'));
      case 'vertical_burst':
        _dino.launchVertical(
          effect.intParameter('impulse_basis_points') / 10000,
        );
        bossHit(0.45);
      case 'glide_tailwind':
        if (!_dino.isGliding) return false;
        _dino.beginDamageInvulnerability(
          Duration(milliseconds: effect.intParameter('duration_ms')),
        );
        bossHit(0.55);
      case 'glide_projectile_guard':
        _dino.beginDamageInvulnerability(
          Duration(milliseconds: effect.intParameter('duration_ms')),
        );
      case 'electric_chain':
        if (!_dino.consumeEnergyForExclusiveSkill()) return false;
        _clearBossHazards(limit: effect.intParameter('targets', fallback: 2));
        bossHit(
          effect.intParameter('targets', fallback: 2) *
              basisMultiplier('damage_basis_points'),
        );
      case 'energy_overclock':
        if (!_dino.consumeEnergyForExclusiveSkill()) return false;
        _dino.applyRecovery(
          Duration(milliseconds: effect.intParameter('duration_ms')),
          effect.intParameter('speed_basis_points'),
        );
        bossHit(1 + effect.intParameter('damage_basis_points') / 10000);
      default:
        return false;
    }
    return true;
  }

  void _clearBossHazards({int? limit}) {
    var removed = 0;
    for (final hazard in children.whereType<CampaignBossHazard>().toList()) {
      if (limit != null && removed >= limit) break;
      hazard.removeFromParent();
      removed += 1;
    }
  }

  bool hasPassiveEffect(String effectCode) => _configuration
      .loadout
      .passiveEffects
      .any((effect) => effect.effectCode == effectCode);

  int passiveParameter(String effectCode, String key, {int fallback = 0}) {
    for (final effect in _configuration.loadout.passiveEffects) {
      if (effect.effectCode == effectCode) {
        return effect.intParameter(key, fallback: fallback);
      }
    }
    return fallback;
  }

  void projectileHit() {
    final reduction = passiveParameter('cooldown_reduction', 'basis_points');
    if (reduction > 0) _dino.reduceCooldownBasisPoints(reduction);
    final bonus = passiveParameter('precision_score_bonus', 'basis_points');
    final cap = passiveParameter('precision_score_bonus', 'encounter_cap');
    if (bonus > 0 && _precisionBonusAwarded < cap) {
      final award = (50 * bonus / 10000).ceil().clamp(1, cap);
      final bounded = award.clamp(0, cap - _precisionBonusAwarded);
      _precisionBonusAwarded += bounded;
      _scoreSystem.score += bounded;
    }
  }

  void useBossAction() => _useBossAction();

  void _useBossAction({
    double bonusMultiplier = 1,
    bool ignoresCooldown = false,
  }) {
    final runtime = _levelRuntime;
    if (!_runActive || runtime == null) return;
    final damage = runtime.useBossAction(
      bonusMultiplier: bonusMultiplier,
      ignoreCooldown: ignoresCooldown,
    );
    if (damage == 0) return;
    _eventSink(
      BossDamagedEvent(
        bossId: runtime.definition.bossId,
        damage: damage,
        healthRemaining: runtime.bossHealthRemaining,
      ),
    );
    if (runtime.phase == LevelPhase.victory) {
      if (_configuration.experience == RunExperience.bossRush) {
        final progress = _bossRushProgress!;
        progress.recordVictory(survivingLives: runtime.livesRemaining);
        if (progress.isComplete) {
          _finishRun(RunOutcome.victory);
        } else {
          _advanceBossRush();
        }
      } else {
        _finishRun(RunOutcome.victory);
      }
    }
  }

  void beginBossEncounter() {
    final runtime = _levelRuntime;
    if (runtime == null || runtime.phase != LevelPhase.bossIntro) return;
    overlays.remove('BossTutorial');
    if (!_resumeWithinBudget()) return;
    runtime.beginBossCombat();
    _eventSink(
      BossPhaseChangedEvent(
        bossId: runtime.definition.bossId,
        phase: runtime.bossPhase,
      ),
    );
    resumeEngine();
  }

  void openBossHelp() {
    if (!_runActive || _levelRuntime?.phase != LevelPhase.bossCombat) return;
    pauseEngine();
    _beginPause();
    overlays.add('BossHelp');
    _eventSink(const RunPausedEvent());
  }

  void closeBossHelp() {
    if (!overlays.isActive('BossHelp')) return;
    overlays.remove('BossHelp');
    if (!_resumeWithinBudget()) return;
    resumeEngine();
    _eventSink(const RunResumedEvent());
  }

  void _onLevelPhaseChanged(LevelPhase previous, LevelPhase current) {
    final runtime = _levelRuntime!;
    _eventSink(
      LevelPhaseChangedEvent(
        level: runtime.definition.level,
        phase: current.name,
      ),
    );
    if (current != LevelPhase.bossIntro) return;
    _showBossIntro(runtime);
  }

  void _showBossIntro(LevelRuntime runtime) {
    _obstacleManager.pauseSpawning();
    _boss = CampaignBoss(definition: runtime.definition);
    add(_boss!);
    _bossActionButton = BossActionButton();
    camera.viewport.add(_bossActionButton!);
    pauseEngine();
    _beginPause();
    overlays.add('BossTutorial');
  }

  void _advanceBossRush() {
    final progress = _bossRushProgress!;
    _removeBossEncounter();
    _skillUses.clear();
    final runtime = LevelRuntime(
      definition: campaignLevelDefinition(progress.nextLevel),
      maxLives: progress.livesForNextBoss,
      damageMultiplier: _configuration.stats.damageMultiplier,
      seed: _configuration.seed + progress.bossesDefeated * 1009,
      attackCadenceMultiplier: _configuration.stats.speedMultiplier,
    )..skipRunner();
    _levelRuntime = runtime;
    _scoreSystem.score += 1000 * progress.bossesDefeated;
    _showBossIntro(runtime);
  }

  void pauseForInterruption() {
    if (!_runActive || paused) return;
    pauseEngine();
    _beginPause();
    _eventSink(const RunPausedEvent());
  }

  void resumeFromInterruption() {
    if (!_runActive ||
        overlays.isActive('BossTutorial') ||
        overlays.isActive('BossHelp')) {
      return;
    }
    if (!_resumeWithinBudget()) return;
    resumeEngine();
    _eventSink(const RunResumedEvent());
  }

  void _beginPause() {
    _pauseStartedAt ??= _now().toUtc();
  }

  bool _resumeWithinBudget() {
    final startedAt = _pauseStartedAt;
    if (startedAt != null) {
      final elapsed = _now().toUtc().difference(startedAt);
      if (!elapsed.isNegative) _pauseConsumed += elapsed;
      _pauseStartedAt = null;
    }
    final expiry = _configuration.stageExpiresAt;
    final expired = expiry != null && !_now().toUtc().isBefore(expiry.toUtc());
    if (_pauseConsumed > _configuration.pauseBudget || expired) {
      _finishRun(RunOutcome.abandoned);
      return false;
    }
    return true;
  }

  void _removeBossEncounter() {
    _boss?.removeFromParent();
    _boss = null;
    final button = _bossActionButton;
    if (button != null) camera.viewport.remove(button);
    _bossActionButton = null;
    for (final hazard in children.whereType<CampaignBossHazard>()) {
      hazard.removeFromParent();
    }
    overlays.remove('BossTutorial');
    overlays.remove('BossHelp');
  }

  void abilityActivated(ActiveAbilityId abilityId) {
    if (_runActive) {
      _eventSink(AbilityActivatedEvent(abilityId));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (overlays.isActive('StartMenu')) {
      return;
    }

    final abilityButton = _abilityButton;
    if (abilityButton != null &&
        abilityButton.containsPoint(event.canvasPosition)) {
      _dino.activateAbility();
      event.handled = true;
      return;
    }

    if (overlays.isActive('GameOverMenu')) {
      resetGame();
    } else if (_runActive) {
      _dino.jump();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _dino.stopGlide();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isSpace = keysPressed.contains(LogicalKeyboardKey.space);
    final isActive = keysPressed.contains(LogicalKeyboardKey.keyA);
    final isBossAction = keysPressed.contains(LogicalKeyboardKey.keyE);

    if (event is KeyDownEvent && isSpace) {
      if (overlays.isActive('GameOverMenu')) {
        resetGame();
      } else if (_runActive) {
        _dino.jump();
      }
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent && isActive && _runActive) {
      _dino.activateAbility();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && isBossAction && _runActive) {
      useBossAction();
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _dino.stopGlide();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void onRemove() {
    FlameAudio.bgm.dispose();
    super.onRemove();
  }
}
