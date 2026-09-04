import '../../../game/domain/character_id.dart';
import '../../../game/domain/palette_transform.dart';
import '../../../game/domain/run_configuration.dart';

enum SkillSlot { active, passive }

extension SkillSlotLabel on SkillSlot {
  String get label => switch (this) {
    SkillSlot.active => 'Activa',
    SkillSlot.passive => 'Pasiva',
  };
}

class ProgressionStat {
  const ProgressionStat({
    required this.id,
    required this.displayName,
    required this.description,
    required this.rank,
    required this.maxRank,
    required this.effectiveBasisPoints,
    this.nextCost,
    this.nextUnlockLevel,
    this.nextBonusBasisPoints,
    this.nextBonusLives = 0,
  });

  final String id;
  final String displayName;
  final String description;
  final int rank;
  final int maxRank;
  final int effectiveBasisPoints;
  final int? nextCost;
  final int? nextUnlockLevel;
  final int? nextBonusBasisPoints;
  final int nextBonusLives;

  bool get isCapped => rank >= maxRank || nextCost == null;
  double get effectivePercent => effectiveBasisPoints / 100;
}

class ProgressionSkill {
  ProgressionSkill({
    required this.id,
    required this.characterId,
    required this.slot,
    required this.displayName,
    required this.description,
    required this.unlockLevel,
    required this.cost,
    required this.effectCode,
    required Map<String, Object?> effectParameters,
    required this.uiExplanation,
    required List<RunMode> compatibleModes,
    required this.owned,
  }) : effectParameters = Map.unmodifiable(effectParameters),
       compatibleModes = List.unmodifiable(compatibleModes);

  final String id;
  final CharacterId characterId;
  final SkillSlot slot;
  final String displayName;
  final String description;
  final int unlockLevel;
  final int cost;
  final String effectCode;
  final Map<String, Object?> effectParameters;
  final String uiExplanation;
  final List<RunMode> compatibleModes;
  final bool owned;

  bool worksIn(RunMode mode) => compatibleModes.contains(mode);
}

class PaletteVariant {
  const PaletteVariant({
    required this.id,
    required this.characterId,
    required this.displayName,
    required this.hueShift,
    required this.saturationBasisPoints,
    required this.valueBasisPoints,
    required this.unlockLevel,
    required this.cost,
    required this.owned,
    required this.equipped,
  });

  final String id;
  final CharacterId characterId;
  final String displayName;
  final int hueShift;
  final int saturationBasisPoints;
  final int valueBasisPoints;
  final int unlockLevel;
  final int cost;
  final bool owned;
  final bool equipped;

  PaletteTransform get transform => PaletteTransform(
    hueShift: hueShift,
    saturationBasisPoints: saturationBasisPoints,
    valueBasisPoints: valueBasisPoints,
  );
}

class AuthorizedBuild {
  AuthorizedBuild({
    required this.speedBasisPoints,
    required this.jumpBasisPoints,
    required this.damageBasisPoints,
    required this.vitalityBasisPoints,
    required this.fortuneBasisPoints,
    required this.maxLives,
    required this.activeSkillId,
    required this.defaultActiveId,
    required List<String> passiveSkillIds,
    required this.skinId,
  }) : passiveSkillIds = List.unmodifiable(passiveSkillIds);

  final int speedBasisPoints;
  final int jumpBasisPoints;
  final int damageBasisPoints;
  final int vitalityBasisPoints;
  final int fortuneBasisPoints;
  final int maxLives;
  final String? activeSkillId;
  final String? defaultActiveId;
  final List<String> passiveSkillIds;
  final String skinId;

  bool get hasPurchasedPower =>
      speedBasisPoints > 0 ||
      jumpBasisPoints > 0 ||
      damageBasisPoints > 0 ||
      vitalityBasisPoints > 0 ||
      fortuneBasisPoints > 0 ||
      activeSkillId != null ||
      passiveSkillIds.isNotEmpty;
}

class ProgressionSnapshot {
  ProgressionSnapshot({
    required this.characterId,
    required this.contentVersion,
    required this.contentDigest,
    required this.masteryXp,
    required this.masteryLevel,
    required this.nextLevelXp,
    required this.bankedCurrency,
    required this.temporaryCurrency,
    required this.storeUnlocked,
    required this.authorizedBuild,
    required List<ProgressionStat> stats,
    required List<ProgressionSkill> skills,
    required List<PaletteVariant> palettes,
  }) : stats = List.unmodifiable(stats),
       skills = List.unmodifiable(skills),
       palettes = List.unmodifiable(palettes);

  final CharacterId characterId;
  final String contentVersion;
  final String contentDigest;
  final int masteryXp;
  final int masteryLevel;
  final int nextLevelXp;
  final int bankedCurrency;
  final int temporaryCurrency;
  final bool storeUnlocked;
  final AuthorizedBuild authorizedBuild;
  final List<ProgressionStat> stats;
  final List<ProgressionSkill> skills;
  final List<PaletteVariant> palettes;

  double get masteryProgress {
    if (masteryLevel >= 30) return 1;
    final currentThreshold = masteryLevel == 0
        ? 0
        : 100 * masteryLevel * (masteryLevel + 1) ~/ 2;
    final span = nextLevelXp - currentThreshold;
    if (span <= 0) return 1;
    return ((masteryXp - currentThreshold) / span).clamp(0, 1);
  }

  ProgressionSkill? skillById(String? id) {
    if (id == null) return null;
    for (final skill in skills) {
      if (skill.id == id) return skill;
    }
    return null;
  }
}

class LoadoutSelection {
  LoadoutSelection({
    required this.activeSkillId,
    required List<String> passiveSkillIds,
    required this.skinId,
  }) : passiveSkillIds = List.unmodifiable(passiveSkillIds) {
    if (this.passiveSkillIds.length > 2 ||
        this.passiveSkillIds.toSet().length != this.passiveSkillIds.length) {
      throw ArgumentError.value(
        passiveSkillIds,
        'passiveSkillIds',
        'A loadout accepts at most two distinct passives.',
      );
    }
  }

  final String? activeSkillId;
  final List<String> passiveSkillIds;
  final String? skinId;
}
