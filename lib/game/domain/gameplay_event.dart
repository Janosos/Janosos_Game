import 'character_definition.dart';
import 'run_configuration.dart';
import 'run_result.dart';

sealed class GameplayEvent {
  const GameplayEvent();
}

class RunStartedEvent extends GameplayEvent {
  const RunStartedEvent(this.configuration);

  final RunConfiguration configuration;
}

class ScoreChangedEvent extends GameplayEvent {
  const ScoreChangedEvent(this.score);

  final int score;
}

class PlayerDamagedEvent extends GameplayEvent {
  const PlayerDamagedEvent({required this.wasAbsorbed});

  final bool wasAbsorbed;
}

class LifeDepletedEvent extends GameplayEvent {
  const LifeDepletedEvent({required this.remainingLives});

  final int remainingLives;
}

class AbilityActivatedEvent extends GameplayEvent {
  const AbilityActivatedEvent(this.abilityId);

  final ActiveAbilityId abilityId;
}

class SkillActivatedEvent extends GameplayEvent {
  const SkillActivatedEvent(this.skillId);

  final String skillId;
}

class BossPhaseChangedEvent extends GameplayEvent {
  const BossPhaseChangedEvent({required this.bossId, required this.phase});

  final String bossId;
  final int phase;
}

class LevelPhaseChangedEvent extends GameplayEvent {
  const LevelPhaseChangedEvent({required this.level, required this.phase});

  final int level;
  final String phase;
}

class BossDamagedEvent extends GameplayEvent {
  const BossDamagedEvent({
    required this.bossId,
    required this.damage,
    required this.healthRemaining,
  });

  final String bossId;
  final int damage;
  final int healthRemaining;
}

class RunPausedEvent extends GameplayEvent {
  const RunPausedEvent();
}

class RunResumedEvent extends GameplayEvent {
  const RunResumedEvent();
}

class RunFinishedEvent extends GameplayEvent {
  const RunFinishedEvent(this.result);

  final RunResult result;
}
