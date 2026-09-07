import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import 'progression_models.dart';

class ProgressionBuildPolicy {
  const ProgressionBuildPolicy._();

  static RunStats statsFor({
    required CharacterId characterId,
    required RunMode mode,
    required AuthorizedBuild build,
  }) {
    final definition = characterId.definition;
    final isEndless = mode == RunMode.standard;
    final extraLives = (build.vitalityBasisPoints ~/ 1000).clamp(0, 3);
    final targetMaxLives = build.maxLives > definition.baseLives
        ? build.maxLives
        : definition.baseLives + extraLives;

    return RunStats(
      speedMultiplier: isEndless
          ? (1 + build.speedBasisPoints.clamp(0, 5000) / 10000)
          : 1.0,
      jumpMultiplier: 1.0,
      damageMultiplier: 1.0,
      fortuneMultiplier: 1 + build.fortuneBasisPoints.clamp(0, 5000) / 10000,
      maxLives: targetMaxLives.clamp(
        definition.baseLives,
        definition.baseLives + 3,
      ),
    );
  }

  static RunLoadout loadoutFor({
    required CharacterId characterId,
    required RunMode mode,
    required AuthorizedBuild build,
    List<ProgressionSkill> skills = const [],
  }) {
    final definition = characterId.definition;
    if (mode == RunMode.standard) {
      return RunLoadout(
        activeAbility: definition.defaultActive,
        passiveSkillIds: const [],
      );
    }
    return RunLoadout(
      activeAbility: build.activeSkillId == null
          ? definition.defaultActive
          : null,
      activeSkillId: build.activeSkillId,
      passiveSkillIds: build.passiveSkillIds.take(2).toList(),
      skillEffects: [
        for (final skill in skills)
          if (skill.id == build.activeSkillId ||
              build.passiveSkillIds.contains(skill.id))
            RuntimeSkillEffect(
              skillId: skill.id,
              effectCode: skill.effectCode,
              parameters: skill.effectParameters,
            ),
      ],
    );
  }
}
