import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../domain/progression_catalog.dart';
import '../domain/progression_models.dart';
import '../domain/progression_repository.dart';
import 'local_game_state_store.dart';

class LocalProgressionRepository implements ProgressionRepository {
  const LocalProgressionRepository({required LocalGameStateStore store})
    : _store = store;

  final LocalGameStateStore _store;

  @override
  Future<ProgressionSnapshot> loadSnapshot({
    required CharacterId characterId,
    required String contentVersion,
  }) {
    return _store.read((state) {
      final progress = state.character(characterId);
      final temporaryCurrency = state.campaign?.characterId == characterId
          ? state.campaign!.temporaryCurrency
          : 0;
      return _snapshot(
        characterId,
        contentVersion,
        progress,
        temporaryCurrency,
      );
    });
  }

  @override
  Future<void> purchaseUpgrade({
    required ProgressionSnapshot snapshot,
    required ProgressionStat stat,
  }) {
    return _store.mutate((state) {
      final progress = state.character(snapshot.characterId);
      _requireMutableStore(state, progress);
      final rules = _rankRules[stat.id];
      if (rules == null) {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'La mejora seleccionada no existe.',
        );
      }
      final rank = progress.statRanks[stat.id] ?? 0;
      if (rank >= rules.length) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Esta mejora ya alcanzó su rango máximo.',
        );
      }
      final next = rules[rank];
      _requireMasteryAndBalance(progress, next.masteryLevel, next.cost);
      progress.bankedCurrency -= next.cost;
      progress.statRanks[stat.id] = rank + 1;
    });
  }

  @override
  Future<void> purchaseSkill({
    required ProgressionSnapshot snapshot,
    required ProgressionSkill skill,
  }) {
    return _store.mutate((state) {
      final progress = state.character(snapshot.characterId);
      _requireMutableStore(state, progress);
      final canonical = ProgressionCatalog.skills
          .where(
            (candidate) =>
                candidate.id == skill.id &&
                candidate.characterId == snapshot.characterId,
          )
          .firstOrNull;
      if (canonical == null) {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'La habilidad no pertenece a este personaje.',
        );
      }
      if (progress.ownedSkillIds.contains(canonical.id)) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Esta habilidad ya pertenece al personaje.',
        );
      }
      _requireMasteryAndBalance(
        progress,
        canonical.unlockLevel,
        canonical.cost,
      );
      progress.bankedCurrency -= canonical.cost;
      progress.ownedSkillIds.add(canonical.id);
    });
  }

  @override
  Future<void> purchasePalette({
    required ProgressionSnapshot snapshot,
    required PaletteVariant palette,
  }) {
    return _store.mutate((state) {
      final progress = state.character(snapshot.characterId);
      _requireMutableStore(state, progress);
      final canonical = ProgressionCatalog.preview(
        snapshot.characterId,
        snapshot.contentVersion,
      ).palettes.where((candidate) => candidate.id == palette.id).firstOrNull;
      if (canonical == null) {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'La paleta no pertenece a este personaje.',
        );
      }
      if (progress.ownedPaletteIds.contains(canonical.id)) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Esta paleta ya pertenece al personaje.',
        );
      }
      if (progress.bankedCurrency < canonical.cost) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Monedas insuficientes para adquirir este aspecto.',
        );
      }
      progress.bankedCurrency -= canonical.cost;
      progress.ownedPaletteIds.add(canonical.id);
    });
  }

  @override
  Future<void> equipLoadout({
    required ProgressionSnapshot snapshot,
    required LoadoutSelection selection,
  }) {
    return _store.mutate((state) {
      final progress = state.character(snapshot.characterId);
      _requireMutableStore(state, progress);
      final ownedSkills = ProgressionCatalog.skills
          .where(
            (skill) =>
                skill.characterId == snapshot.characterId &&
                progress.ownedSkillIds.contains(skill.id),
          )
          .toList();
      if (selection.activeSkillId != null &&
          !ownedSkills.any(
            (skill) =>
                skill.id == selection.activeSkillId &&
                skill.slot == SkillSlot.active,
          )) {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'La habilidad activa no está disponible.',
        );
      }
      if (selection.passiveSkillIds.any(
        (id) => !ownedSkills.any(
          (skill) => skill.id == id && skill.slot == SkillSlot.passive,
        ),
      )) {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'Una habilidad pasiva no está disponible.',
        );
      }
      final paletteId =
          selection.skinId ?? '${snapshot.characterId.serialized}_default';
      if (!progress.ownedPaletteIds.contains(paletteId)) {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'La paleta seleccionada no está disponible.',
        );
      }
      progress.activeSkillId = selection.activeSkillId;
      progress.passiveSkillIds
        ..clear()
        ..addAll(selection.passiveSkillIds);
      progress.equippedPaletteId = paletteId;
    });
  }

  static ProgressionSnapshot _snapshot(
    CharacterId characterId,
    String contentVersion,
    LocalCharacterProgress progress,
    int temporaryCurrency,
  ) {
    final preview = ProgressionCatalog.preview(characterId, contentVersion);
    final masteryLevel = localMasteryLevel(progress.masteryXp);
    final stats = [
      for (final base in preview.stats)
        _stat(base, progress.statRanks[base.id] ?? 0, masteryLevel),
    ];
    final effective = {
      for (final stat in stats) stat.id: stat.effectiveBasisPoints,
    };
    final vitalityRank = (progress.statRanks['vitality'] ?? 0).clamp(0, 3);
    final bonusLives = vitalityRank;
    return ProgressionSnapshot(
      characterId: characterId,
      contentVersion: contentVersion,
      contentDigest: List.filled(64, '0').join(),
      masteryXp: progress.masteryXp,
      masteryLevel: masteryLevel,
      nextLevelXp: masteryLevel >= 30
          ? progress.masteryXp
          : 100 * (masteryLevel + 1) * (masteryLevel + 2) ~/ 2,
      bankedCurrency: progress.bankedCurrency,
      temporaryCurrency: temporaryCurrency,
      storeUnlocked: true,
      authorizedBuild: AuthorizedBuild(
        speedBasisPoints: effective['speed'] ?? 0,
        jumpBasisPoints: effective['jump'] ?? 0,
        damageBasisPoints: effective['damage'] ?? 0,
        vitalityBasisPoints: effective['vitality'] ?? 0,
        fortuneBasisPoints: effective['fortune'] ?? 0,
        maxLives: characterId.definition.baseLives + bonusLives,
        activeSkillId: progress.activeSkillId,
        defaultActiveId: characterId.definition.defaultActive?.name,
        passiveSkillIds: progress.passiveSkillIds,
        skinId: progress.equippedPaletteId,
      ),
      stats: stats,
      skills: [
        for (final skill in preview.skills)
          ProgressionSkill(
            id: skill.id,
            characterId: skill.characterId,
            slot: skill.slot,
            displayName: skill.displayName,
            description: skill.description,
            unlockLevel: skill.unlockLevel,
            cost: skill.cost,
            effectCode: skill.effectCode,
            effectParameters: skill.effectParameters,
            uiExplanation: skill.uiExplanation,
            compatibleModes: skill.compatibleModes,
            owned: progress.ownedSkillIds.contains(skill.id),
          ),
      ],
      palettes: [
        for (final palette in preview.palettes)
          PaletteVariant(
            id: palette.id,
            characterId: palette.characterId,
            displayName: palette.displayName,
            hueShift: palette.hueShift,
            saturationBasisPoints: palette.saturationBasisPoints,
            valueBasisPoints: palette.valueBasisPoints,
            unlockLevel: palette.unlockLevel,
            cost: palette.cost,
            owned: progress.ownedPaletteIds.contains(palette.id),
            equipped: progress.equippedPaletteId == palette.id,
          ),
      ],
    );
  }

  static ProgressionStat _stat(
    ProgressionStat base,
    int rank,
    int masteryLevel,
  ) {
    final rules = _rankRules[base.id]!;
    final safeRank = rank.clamp(0, rules.length);
    final purchased = safeRank == 0 ? 0 : rules[safeRank - 1].basisPoints;
    final effective = purchased.clamp(
      0,
      _statCaps[base.id]!,
    );
    final next = safeRank >= rules.length ? null : rules[safeRank];
    return ProgressionStat(
      id: base.id,
      displayName: base.displayName,
      description: base.description,
      rank: safeRank,
      maxRank: rules.length,
      effectiveBasisPoints: effective,
      nextCost: next?.cost,
      nextUnlockLevel: next?.masteryLevel,
      nextBonusBasisPoints: next?.basisPoints,
      nextBonusLives: next?.bonusLives ?? 0,
    );
  }

  static void _requireMutableStore(
    LocalGameState state,
    LocalCharacterProgress progress,
  ) {
    if (state.campaign != null || state.bossRush != null) {
      throw const AppFailure(
        AppFailureCode.conflict,
        'Las compras y el equipamiento se bloquean durante una partida activa.',
      );
    }
  }

  static void _requireMasteryAndBalance(
    LocalCharacterProgress progress,
    int masteryLevel,
    int cost,
  ) {
    if (localMasteryLevel(progress.masteryXp) < masteryLevel) {
      throw AppFailure(
        AppFailureCode.conflict,
        'Esta compra requiere maestría $masteryLevel.',
      );
    }
    if (progress.bankedCurrency < cost) {
      throw const AppFailure(
        AppFailureCode.conflict,
        'No hay suficientes monedas guardadas para esta compra.',
      );
    }
  }
}

int localMasteryLevel(int xp) {
  var level = 0;
  while (level < 30 && xp >= 100 * (level + 1) * (level + 2) ~/ 2) {
    level += 1;
  }
  return level;
}

int localEffectiveBasisPoints(LocalCharacterProgress progress, String statId) {
  final rules = _rankRules[statId];
  if (rules == null) return 0;
  final rank = (progress.statRanks[statId] ?? 0).clamp(0, rules.length);
  final purchased = rank == 0 ? 0 : rules[rank - 1].basisPoints;
  return purchased.clamp(0, _statCaps[statId] ?? 5000);
}

const _statCaps = {
  'speed': 5000,
  'vitality': 3000,
  'fortune': 5000,
};

typedef _RankRule = ({
  int cost,
  int masteryLevel,
  int basisPoints,
  int bonusLives,
});

const _rankRules = <String, List<_RankRule>>{
  'speed': [
    (cost: 150, masteryLevel: 0, basisPoints: 1000, bonusLives: 0),
    (cost: 350, masteryLevel: 0, basisPoints: 2000, bonusLives: 0),
    (cost: 650, masteryLevel: 0, basisPoints: 3000, bonusLives: 0),
    (cost: 1050, masteryLevel: 0, basisPoints: 4000, bonusLives: 0),
    (cost: 1550, masteryLevel: 0, basisPoints: 5000, bonusLives: 0),
  ],
  'vitality': [
    (cost: 1500, masteryLevel: 0, basisPoints: 1000, bonusLives: 1),
    (cost: 3500, masteryLevel: 0, basisPoints: 2000, bonusLives: 2),
    (cost: 6500, masteryLevel: 0, basisPoints: 3000, bonusLives: 3),
  ],
  'fortune': [
    (cost: 200, masteryLevel: 0, basisPoints: 1000, bonusLives: 0),
    (cost: 450, masteryLevel: 0, basisPoints: 2000, bonusLives: 0),
    (cost: 800, masteryLevel: 0, basisPoints: 3000, bonusLives: 0),
    (cost: 1250, masteryLevel: 0, basisPoints: 4000, bonusLives: 0),
    (cost: 1800, masteryLevel: 0, basisPoints: 5000, bonusLives: 0),
  ],
};
