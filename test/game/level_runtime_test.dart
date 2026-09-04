import 'package:dino_run_flame/game/domain/level_runtime.dart';
import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moves deterministically from runner to boss and victory', () {
    final runtime = LevelRuntime(
      definition: levelOneDefinition,
      maxLives: 1,
      damageMultiplier: 1,
      seed: 17,
    );

    runtime.update(levelOneDefinition.runnerDuration);
    expect(runtime.phase, LevelPhase.bossIntro);

    runtime.beginBossCombat();
    expect(runtime.phase, LevelPhase.bossCombat);
    while (!runtime.isTerminal) {
      final damage = runtime.useBossAction();
      if (damage == 0) {
        runtime.update(levelOneDefinition.bossActionCooldown);
      }
    }

    expect(runtime.phase, LevelPhase.victory);
    expect(runtime.bossHealthRemaining, 0);
  });

  test('uses lives and ignores hits during the invulnerability window', () {
    final runtime = LevelRuntime(
      definition: levelOneDefinition,
      maxLives: 2,
      damageMultiplier: 1,
      seed: 1,
    );

    expect(runtime.takePlayerHit(), isTrue);
    expect(runtime.livesRemaining, 1);
    expect(runtime.takePlayerHit(), isFalse);
    expect(runtime.livesRemaining, 1);

    runtime.update(LevelRuntime.hitInvulnerability);
    expect(runtime.takePlayerHit(), isTrue);
    expect(runtime.phase, LevelPhase.defeat);
  });

  test('boss attack order is reproducible for a seed', () {
    List<BossAttackCue> sample() {
      final runtime = LevelRuntime(
        definition: levelOneDefinition,
        maxLives: 1,
        damageMultiplier: 1,
        seed: 55,
      );
      runtime.update(levelOneDefinition.runnerDuration);
      runtime.beginBossCombat();
      return [
        for (var i = 0; i < 5; i++)
          ...runtime.update(const Duration(seconds: 3)),
      ];
    }

    final first = sample();
    final second = sample();
    expect(first.map((cue) => cue.kind), second.map((cue) => cue.kind));
    expect(
      first.map((cue) => cue.fromRight),
      second.map((cue) => cue.fromRight),
    );
  });

  test('defines ten ordered worlds with distinct bosses and rewards', () {
    expect(campaignLevelDefinitions, hasLength(10));
    expect(
      campaignLevelDefinitions.map((level) => level.level),
      orderedEquals(List.generate(10, (index) => index + 1)),
    );
    expect(
      campaignLevelDefinitions.map((level) => level.bossId).toSet(),
      hasLength(10),
    );
    expect(
      campaignLevelDefinitions.map((level) => level.uniqueRewardId).toSet(),
      hasLength(10),
    );
    for (final definition in campaignLevelDefinitions) {
      expect(definition.attackPattern.length, greaterThanOrEqualTo(3));
      expect(campaignLevelDefinition(definition.level), same(definition));
    }
  });

  test('every base character can defeat every boss without a purchase', () {
    for (final definition in campaignLevelDefinitions) {
      for (final character in CharacterId.values) {
        final runtime = LevelRuntime(
          definition: definition,
          maxLives: character.definition.baseLives,
          damageMultiplier: 1,
          seed: character.index + definition.level * 100,
        );
        runtime.update(definition.runnerDuration);
        runtime.beginBossCombat();
        var actions = 0;
        while (runtime.phase == LevelPhase.bossCombat) {
          if (runtime.useBossAction() > 0) actions += 1;
          runtime.update(definition.bossActionCooldown);
        }
        expect(
          runtime.phase,
          LevelPhase.victory,
          reason: '${character.serialized} vs ${definition.bossId}',
        );
        expect(
          actions,
          (definition.bossHealth / 100).ceil(),
          reason: '${character.serialized} vs ${definition.bossId}',
        );
      }
    }
  });

  test('Boss Rush chains ten bosses and heals only one life between them', () {
    final progress = BossRushProgress(maxLives: 3);
    expect(progress.nextLevel, 1);

    progress.recordVictory(survivingLives: 1);
    expect(progress.bossesDefeated, 1);
    expect(progress.livesForNextBoss, 2);
    expect(progress.nextLevel, 2);

    progress.recordVictory(survivingLives: 2);
    expect(progress.livesForNextBoss, 3);
    for (var level = 3; level <= 10; level++) {
      progress.recordVictory(survivingLives: 3);
    }
    expect(progress.isComplete, isTrue);
    expect(progress.bossesDefeated, 10);
    expect(progress.nextLevel, 10);
  });
}
