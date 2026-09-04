import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';

enum CampaignEligibility { verifiedOnline, eligibleOffline, local, practice }

extension CampaignEligibilityCopy on CampaignEligibility {
  String get label => switch (this) {
    CampaignEligibility.verifiedOnline => 'Verificada en línea',
    CampaignEligibility.eligibleOffline => 'Elegible sin conexión',
    CampaignEligibility.local => 'Progreso local',
    CampaignEligibility.practice => 'Práctica',
  };
}

class CampaignStageSession {
  const CampaignStageSession({
    required this.eligibility,
    required this.configuration,
    required this.bankedCurrency,
    required this.temporaryCurrency,
    this.campaignId,
    this.stageToken,
    this.expiresAt,
  });

  final CampaignEligibility eligibility;
  final RunConfiguration configuration;
  final String? campaignId;
  final String? stageToken;
  final DateTime? expiresAt;
  final int bankedCurrency;
  final int temporaryCurrency;

  bool get canEarnRewards =>
      eligibility != CampaignEligibility.practice && stageToken != null;
}

class CampaignProgress {
  const CampaignProgress({
    required this.campaignId,
    required this.characterId,
    required this.currentLevel,
    required this.expectedSequence,
    required this.temporaryCurrency,
    required this.expiresAt,
  });

  final String campaignId;
  final CharacterId characterId;
  final int currentLevel;
  final int expectedSequence;
  final int temporaryCurrency;
  final DateTime expiresAt;

  bool get readyToComplete => expectedSequence == 11;
}

class CampaignFinishReceipt {
  const CampaignFinishReceipt({
    required this.accepted,
    required this.ranked,
    required this.masteryXpGranted,
    required this.temporaryCurrency,
    required this.currencyLost,
    required this.uniqueDropGranted,
    required this.nextLevel,
    required this.readyToComplete,
    this.uniqueRewardId,
    this.rejectionCode,
  });

  final bool accepted;
  final bool ranked;
  final int masteryXpGranted;
  final int temporaryCurrency;
  final int currencyLost;
  final bool uniqueDropGranted;
  final int nextLevel;
  final bool readyToComplete;
  final String? uniqueRewardId;
  final String? rejectionCode;
}

class CampaignCompletionReceipt {
  const CampaignCompletionReceipt({
    required this.accepted,
    required this.ranked,
    required this.bankedCurrency,
    required this.purchasePhaseUnlocked,
  });

  final bool accepted;
  final bool ranked;
  final int bankedCurrency;
  final bool purchasePhaseUnlocked;
}

abstract interface class CampaignRepository {
  Future<CampaignProgress?> loadActiveCampaign();

  Future<CampaignStageSession?> loadPreparedStage(CharacterId characterId);

  Future<CampaignStageSession> startStage({
    required RunConfiguration configuration,
    required int bankedCurrency,
    required int temporaryCurrency,
  });

  Future<void> markStagePlaying(CampaignStageSession session);

  Future<CampaignFinishReceipt> finishStage(Map<String, Object?> payload);

  Future<CampaignCompletionReceipt> completeCampaign(
    Map<String, Object?> payload,
  );

  Future<void> failCampaign(Map<String, Object?> payload);

  Future<void> abandonCampaign(CampaignStageSession session);

  Future<void> clearPreparedStage();
}
