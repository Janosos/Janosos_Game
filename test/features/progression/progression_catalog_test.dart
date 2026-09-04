import 'package:dino_run_flame/features/progression/domain/progression_build_policy.dart';
import 'package:dino_run_flame/features/progression/domain/progression_catalog.dart';
import 'package:dino_run_flame/features/progression/domain/progression_models.dart';
import 'package:dino_run_flame/features/progression/domain/skill_effect_engine.dart';
import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exclusive skill catalog', () {
    test('contains two active and two passive skills for every character', () {
      expect(ProgressionCatalog.skills, hasLength(28));
      expect(
        ProgressionCatalog.skills.map((skill) => skill.id).toSet(),
        hasLength(28),
      );
      for (final characterId in CharacterId.values) {
        final owned = ProgressionCatalog.skills
            .where((skill) => skill.characterId == characterId)
            .toList();
        expect(owned, hasLength(4), reason: characterId.serialized);
        expect(
          owned.where((skill) => skill.slot == SkillSlot.active),
          hasLength(2),
        );
        expect(
          owned.where((skill) => skill.slot == SkillSlot.passive),
          hasLength(2),
        );
      }
    });

    test('never enables purchased power in Standard', () {
      for (final skill in ProgressionCatalog.skills) {
        expect(skill.worksIn(RunMode.progression), isTrue);
        expect(skill.worksIn(RunMode.bossRush), isTrue);
        expect(skill.worksIn(RunMode.standard), isFalse);
        expect(skill.effectCode, isNotEmpty);
        expect(skill.effectParameters, isNotEmpty);
      }
    });

    for (final skill in ProgressionCatalog.skills) {
      test('${skill.id} has a deterministic bounded runtime contract', () {
        final first = SkillEffectEngine.resolve(
          skill: skill,
          mode: RunMode.progression,
        );
        final second = SkillEffectEngine.resolve(
          skill: skill,
          mode: RunMode.progression,
        );
        final standard = SkillEffectEngine.resolve(
          skill: skill,
          mode: RunMode.standard,
        );

        expect(first.applied, isTrue);
        expect(first.parameters, isNotEmpty);
        expect(first.deterministicSignature, second.deterministicSignature);
        expect(standard.applied, isFalse);
        expect(standard.parameters, isEmpty);
      });
    }

    test('does not sell an existing default active back to its owner', () {
      const reservedIds = {
        'pistol_shot',
        'intangibility',
        'electric_discharge',
      };
      expect(
        ProgressionCatalog.skills.any(
          (skill) => reservedIds.contains(skill.id),
        ),
        isFalse,
      );
    });
  });

  test('Standard replaces a fully upgraded build with the base character', () {
    final build = AuthorizedBuild(
      speedBasisPoints: 5000,
      jumpBasisPoints: 5000,
      damageBasisPoints: 9000,
      vitalityBasisPoints: 9000,
      fortuneBasisPoints: 9000,
      maxLives: 99,
      activeSkillId: 'jano_burst_protocol',
      defaultActiveId: 'pistol_shot',
      passiveSkillIds: const ['jano_quickdraw', 'jano_scavenger_sight'],
      skinId: 'jano_eclipse',
    );

    final stats = ProgressionBuildPolicy.statsFor(
      characterId: CharacterId.jano,
      mode: RunMode.standard,
      build: build,
    );
    final loadout = ProgressionBuildPolicy.loadoutFor(
      characterId: CharacterId.jano,
      mode: RunMode.standard,
      build: build,
    );

    expect(stats.speedMultiplier, 1);
    expect(stats.jumpMultiplier, 1);
    expect(stats.damageMultiplier, 1);
    expect(stats.fortuneMultiplier, 1);
    expect(stats.maxLives, CharacterId.jano.definition.baseLives);
    expect(loadout.activeAbility, ActiveAbilityId.pistolShot);
    expect(loadout.activeSkillId, isNull);
    expect(loadout.passiveSkillIds, isEmpty);
  });

  test('Progression clamps every server build to the approved caps', () {
    final build = AuthorizedBuild(
      speedBasisPoints: 5000,
      jumpBasisPoints: 5000,
      damageBasisPoints: 9000,
      vitalityBasisPoints: 9000,
      fortuneBasisPoints: 9000,
      maxLives: 99,
      activeSkillId: 'parker_guard_dash',
      defaultActiveId: null,
      passiveSkillIds: const [
        'parker_reinforced_vest',
        'parker_second_wind',
        'unexpected_third',
      ],
      skinId: 'parker_eclipse',
    );

    final stats = ProgressionBuildPolicy.statsFor(
      characterId: CharacterId.parker,
      mode: RunMode.progression,
      build: build,
    );
    final loadout = ProgressionBuildPolicy.loadoutFor(
      characterId: CharacterId.parker,
      mode: RunMode.progression,
      build: build,
    );

    expect(stats.speedMultiplier, 1.10);
    expect(stats.jumpMultiplier, 1.10);
    expect(stats.damageMultiplier, 1.50);
    expect(stats.fortuneMultiplier, 1.15);
    expect(stats.maxLives, 3);
    expect(loadout.activeSkillId, 'parker_guard_dash');
    expect(loadout.passiveSkillIds, hasLength(2));
  });

  test('Progression carries only equipped exclusive effect contracts', () {
    for (final character in CharacterId.values) {
      final skills = ProgressionCatalog.skills
          .where((skill) => skill.characterId == character)
          .toList();
      final active = skills.firstWhere(
        (skill) => skill.slot == SkillSlot.active,
      );
      final passives = skills
          .where((skill) => skill.slot == SkillSlot.passive)
          .toList();
      final build = AuthorizedBuild(
        speedBasisPoints: 0,
        jumpBasisPoints: 0,
        damageBasisPoints: 0,
        vitalityBasisPoints: 0,
        fortuneBasisPoints: 0,
        maxLives: character.definition.baseLives,
        activeSkillId: active.id,
        defaultActiveId: character.definition.defaultActive?.name,
        passiveSkillIds: passives.map((skill) => skill.id).toList(),
        skinId: '${character.serialized}_default',
      );

      final loadout = ProgressionBuildPolicy.loadoutFor(
        characterId: character,
        mode: RunMode.progression,
        build: build,
        skills: skills,
      );

      expect(loadout.skillEffects, hasLength(3), reason: character.serialized);
      expect(
        loadout.effectById(active.id)?.effectCode,
        active.effectCode,
        reason: character.serialized,
      );
      expect(
        loadout.passiveEffects.map((effect) => effect.skillId),
        containsAll(passives.map((skill) => skill.id)),
        reason: character.serialized,
      );
    }
  });

  test('loadouts reject duplicate or excess passive selections', () {
    expect(
      () => LoadoutSelection(
        activeSkillId: null,
        passiveSkillIds: const ['one', 'one'],
        skinId: null,
      ),
      throwsArgumentError,
    );
    expect(
      () => LoadoutSelection(
        activeSkillId: null,
        passiveSkillIds: const ['one', 'two', 'three'],
        skinId: null,
      ),
      throwsArgumentError,
    );
  });
}
