import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy configuration preserves the base character definition', () {
    final configuration = RunConfiguration.legacy(
      characterId: CharacterId.parker,
      legacyHighScore: 1234,
      seed: 99,
    );

    expect(configuration.characterId, CharacterId.parker);
    expect(configuration.mode, RunMode.standard);
    expect(configuration.stats.maxLives, 2);
    expect(configuration.legacyHighScore, 1234);
    expect(configuration.seed, 99);
    expect(configuration.contentVersion, 'v5-legacy');
  });

  test('only characters with a default active expose an active control', () {
    for (final id in CharacterId.values) {
      final configuration = RunConfiguration.legacy(characterId: id);
      expect(
        configuration.controlLayout.hasActiveAbilityControl,
        id.definition.defaultActive != null,
        reason: id.serialized,
      );
    }
  });

  test('copies accessibility preferences without changing the build', () {
    final configuration = RunConfiguration.legacy(
      characterId: CharacterId.nanic,
    );
    final accessible = configuration.copyWith(
      audioEnabled: false,
      reduceMotion: true,
    );

    expect(accessible.audioEnabled, isFalse);
    expect(accessible.reduceMotion, isTrue);
    expect(accessible.characterId, configuration.characterId);
    expect(accessible.loadout, same(configuration.loadout));
    expect(accessible.stats, same(configuration.stats));
  });

  test('copies passive skills into an immutable loadout snapshot', () {
    final sourceSkills = <String>['jano.quick_draw'];
    final loadout = RunLoadout(
      activeAbility: ActiveAbilityId.pistolShot,
      passiveSkillIds: sourceSkills,
    );

    sourceSkills.add('jano.bonus_damage');

    expect(loadout.passiveSkillIds, ['jano.quick_draw']);
    expect(
      () => loadout.passiveSkillIds.add('jano.bonus_damage'),
      throwsUnsupportedError,
    );
  });

  test('runtime skill parameters are immutable and selected by stable id', () {
    final parameters = <String, Object?>{'duration_ms': 450};
    final effect = RuntimeSkillEffect(
      skillId: 'parker_guard_dash',
      effectCode: 'guard_dash',
      parameters: parameters,
    );
    final loadout = RunLoadout(
      activeAbility: null,
      activeSkillId: effect.skillId,
      skillEffects: [effect],
    );
    parameters['duration_ms'] = 99999;

    expect(loadout.effectById(effect.skillId)?.effectCode, 'guard_dash');
    expect(effect.intParameter('duration_ms'), 450);
    expect(
      () => effect.parameters['duration_ms'] = 900,
      throwsUnsupportedError,
    );
  });
}
