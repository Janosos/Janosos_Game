import 'character_definition.dart';
import 'character_id.dart';
import 'control_layout.dart';
import 'palette_transform.dart';

enum RunMode { standard, progression, bossRush }

enum RunExperience { endlessRunner, campaignStage, bossRush }

extension RunModeSerialization on RunMode {
  String get serialized => switch (this) {
    RunMode.standard => 'standard',
    RunMode.progression => 'progression',
    RunMode.bossRush => 'boss_rush',
  };

  static RunMode parse(String value) {
    return switch (value) {
      'standard' => RunMode.standard,
      'progression' => RunMode.progression,
      'boss_rush' => RunMode.bossRush,
      _ => throw FormatException('Unknown run mode: $value'),
    };
  }
}

class RunStats {
  const RunStats({
    required this.speedMultiplier,
    required this.jumpMultiplier,
    required this.damageMultiplier,
    required this.fortuneMultiplier,
    required this.maxLives,
  });

  factory RunStats.base(CharacterDefinition character) {
    return RunStats(
      speedMultiplier: 1,
      jumpMultiplier: 1,
      damageMultiplier: 1,
      fortuneMultiplier: 1,
      maxLives: character.baseLives,
    );
  }

  final double speedMultiplier;
  final double jumpMultiplier;
  final double damageMultiplier;
  final double fortuneMultiplier;
  final int maxLives;
}

class RunLoadout {
  RunLoadout({
    required this.activeAbility,
    this.activeSkillId,
    List<String> passiveSkillIds = const <String>[],
    List<RuntimeSkillEffect> skillEffects = const <RuntimeSkillEffect>[],
  }) : passiveSkillIds = List.unmodifiable(passiveSkillIds),
       skillEffects = List.unmodifiable(skillEffects);

  final ActiveAbilityId? activeAbility;
  final String? activeSkillId;
  final List<String> passiveSkillIds;
  final List<RuntimeSkillEffect> skillEffects;

  RuntimeSkillEffect? effectById(String? id) {
    if (id == null) return null;
    for (final effect in skillEffects) {
      if (effect.skillId == id) return effect;
    }
    return null;
  }

  Iterable<RuntimeSkillEffect> get passiveEffects =>
      skillEffects.where((effect) => passiveSkillIds.contains(effect.skillId));
}

class RuntimeSkillEffect {
  RuntimeSkillEffect({
    required this.skillId,
    required this.effectCode,
    required Map<String, Object?> parameters,
  }) : parameters = Map.unmodifiable(parameters);

  final String skillId;
  final String effectCode;
  final Map<String, Object?> parameters;

  int intParameter(String key, {int fallback = 0}) {
    final value = parameters[key];
    return value is num ? value.toInt() : fallback;
  }
}

class RunConfiguration {
  const RunConfiguration({
    required this.characterId,
    required this.mode,
    required this.stats,
    required this.loadout,
    required this.level,
    required this.contentVersion,
    required this.protocolVersion,
    required this.seed,
    this.experience = RunExperience.endlessRunner,
    this.stageExpiresAt,
    this.pauseBudget = const Duration(minutes: 5),
    this.palette = PaletteTransform.identity,
    this.legacyHighScore = 0,
    this.audioEnabled = true,
    this.reduceMotion = false,
  });

  factory RunConfiguration.legacy({
    required CharacterId characterId,
    int legacyHighScore = 0,
    int seed = 0,
  }) {
    final definition = characterId.definition;
    return RunConfiguration(
      characterId: characterId,
      mode: RunMode.standard,
      stats: RunStats.base(definition),
      loadout: RunLoadout(activeAbility: definition.defaultActive),
      level: 1,
      contentVersion: 'v5-legacy',
      protocolVersion: 1,
      seed: seed,
      legacyHighScore: legacyHighScore,
    );
  }

  final CharacterId characterId;
  final RunMode mode;
  final RunStats stats;
  final RunLoadout loadout;
  final int level;
  final String contentVersion;
  final int protocolVersion;
  final int seed;
  final RunExperience experience;
  final DateTime? stageExpiresAt;
  final Duration pauseBudget;
  final PaletteTransform palette;
  final int legacyHighScore;
  final bool audioEnabled;
  final bool reduceMotion;

  RunConfiguration copyWith({
    int? level,
    DateTime? stageExpiresAt,
    RunExperience? experience,
    bool? audioEnabled,
    bool? reduceMotion,
  }) {
    return RunConfiguration(
      characterId: characterId,
      mode: mode,
      stats: stats,
      loadout: loadout,
      level: level ?? this.level,
      contentVersion: contentVersion,
      protocolVersion: protocolVersion,
      seed: seed,
      experience: experience ?? this.experience,
      stageExpiresAt: stageExpiresAt ?? this.stageExpiresAt,
      pauseBudget: pauseBudget,
      palette: palette,
      legacyHighScore: legacyHighScore,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  ControlLayout get controlLayout => ControlLayout.forActiveAbility(
    loadout.activeAbility,
    hasPurchasedActive: loadout.activeSkillId != null,
    hasBossAction: experience != RunExperience.endlessRunner,
  );
}
