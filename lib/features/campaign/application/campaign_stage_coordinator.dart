import 'dart:math';

import '../../../core/config/app_environment.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/palette_transform.dart';
import '../../../game/domain/run_configuration.dart';
import '../../progression/domain/progression_build_policy.dart';
import '../../progression/domain/progression_repository.dart';
import '../domain/campaign_repository.dart';

class CampaignStageCoordinator {
  const CampaignStageCoordinator({
    required CampaignRepository campaignRepository,
    required ProgressionRepository progressionRepository,
    required AppEnvironment environment,
  }) : _campaignRepository = campaignRepository,
       _progressionRepository = progressionRepository,
       _environment = environment;

  final CampaignRepository _campaignRepository;
  final ProgressionRepository _progressionRepository;
  final AppEnvironment _environment;

  Future<CampaignStageSession> prepareStage(
    CharacterId requestedCharacter, {
    int requestedLevel = 1,
  }) async {
    final active = await _loadActiveCampaignSafely();
    final characterId = active?.characterId ?? requestedCharacter;
    final level = active?.currentLevel ?? requestedLevel.clamp(1, 10);
    final cached = await _campaignRepository.loadPreparedStage(characterId);
    if (cached != null && cached.configuration.level == level) return cached;

    try {
      final snapshot = await _progressionRepository.loadSnapshot(
        characterId: characterId,
        contentVersion: _environment.contentVersion,
      );
      final build = snapshot.authorizedBuild;
      final palette = snapshot.palettes
          .where((candidate) => candidate.equipped)
          .map((candidate) => candidate.transform)
          .firstOrNull;
      final configuration = RunConfiguration(
        characterId: characterId,
        mode: RunMode.progression,
        stats: ProgressionBuildPolicy.statsFor(
          characterId: characterId,
          mode: RunMode.progression,
          build: build,
        ),
        loadout: ProgressionBuildPolicy.loadoutFor(
          characterId: characterId,
          mode: RunMode.progression,
          build: build,
          skills: snapshot.skills,
        ),
        level: level,
        contentVersion: _environment.contentVersion,
        protocolVersion: 1,
        seed: Random.secure().nextInt(0x7fffffff),
        experience: RunExperience.campaignStage,
        palette: palette ?? PaletteTransform.identity,
      );
      return await _campaignRepository.startStage(
        configuration: configuration,
        bankedCurrency: snapshot.bankedCurrency,
        temporaryCurrency: snapshot.temporaryCurrency,
      );
    } on Object {
      final definition = characterId.definition;
      final practice = RunConfiguration(
        characterId: characterId,
        mode: RunMode.progression,
        stats: RunStats.base(definition),
        loadout: RunLoadout(activeAbility: definition.defaultActive),
        level: level,
        contentVersion: _environment.contentVersion,
        protocolVersion: 1,
        seed: Random.secure().nextInt(0x7fffffff),
        experience: RunExperience.campaignStage,
      );
      return CampaignStageSession(
        eligibility: CampaignEligibility.practice,
        configuration: practice,
        bankedCurrency: 0,
        temporaryCurrency: 0,
      );
    }
  }

  Future<CampaignProgress?> _loadActiveCampaignSafely() async {
    try {
      return await _campaignRepository.loadActiveCampaign();
    } on Object {
      return null;
    }
  }

  Future<void> markPlaying(CampaignStageSession session) =>
      _campaignRepository.markStagePlaying(session);

  Future<void> abandon(CampaignStageSession session) =>
      _campaignRepository.abandonCampaign(session);
}
