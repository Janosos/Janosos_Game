import '../../../game/domain/run_configuration.dart';

enum BossRushEligibility { verified, local, practice }

class BossRushSession {
  const BossRushSession({
    required this.eligibility,
    required this.configuration,
    this.campaignId,
    this.attemptToken,
    this.expiresAt,
  });

  final BossRushEligibility eligibility;
  final RunConfiguration configuration;
  final String? campaignId;
  final String? attemptToken;
  final DateTime? expiresAt;

  bool get canEarnRewards =>
      eligibility != BossRushEligibility.practice && attemptToken != null;
}

class BossRushFinishReceipt {
  BossRushFinishReceipt({
    required this.accepted,
    required this.ranked,
    required this.masteryXpGranted,
    required this.bossesDefeated,
    required List<String> uniqueRewardsGranted,
  }) : uniqueRewardsGranted = List.unmodifiable(uniqueRewardsGranted);

  final bool accepted;
  final bool ranked;
  final int masteryXpGranted;
  final int bossesDefeated;
  final List<String> uniqueRewardsGranted;
}

abstract interface class BossRushRepository {
  Future<BossRushSession> start(RunConfiguration configuration);

  Future<BossRushFinishReceipt> finish(Map<String, Object?> payload);

  Future<void> abandon(BossRushSession session);

  Future<void> fail(Map<String, Object?> payload);
}
