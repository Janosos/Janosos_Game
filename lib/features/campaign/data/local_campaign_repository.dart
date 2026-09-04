import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/level_runtime.dart';
import '../../../game/domain/run_configuration.dart';
import '../../progression/data/local_game_state_store.dart';
import '../../progression/data/local_progression_repository.dart';
import '../domain/campaign_repository.dart';

class LocalCampaignRepository implements CampaignRepository {
  LocalCampaignRepository({required LocalGameStateStore store, Random? random})
    : _store = store,
      _random = random ?? Random.secure();

  static const _uuid = Uuid();
  final LocalGameStateStore _store;
  final Random _random;

  @override
  Future<CampaignProgress?> loadActiveCampaign() {
    return _store.mutate((state) {
      final campaign = state.campaign;
      if (campaign == null) return null;
      if (campaign.expectedSequence == 11) {
        _bankCompletedCampaign(state, campaign);
        return null;
      }
      return _progress(campaign);
    });
  }

  @override
  Future<CampaignStageSession?> loadPreparedStage(
    CharacterId characterId,
  ) async => null;

  @override
  Future<CampaignStageSession> startStage({
    required RunConfiguration configuration,
    required int bankedCurrency,
    required int temporaryCurrency,
  }) {
    return _store.mutate((state) {
      if (state.bossRush != null) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Termina o abandona Boss Rush antes de iniciar una campaña.',
        );
      }
      var campaign = state.campaign;
      if (campaign == null) {
        campaign = LocalCampaignState(
          id: _uuid.v4(),
          characterId: configuration.characterId,
          level: 1,
          expectedSequence: 1,
          temporaryCurrency: 0,
          totalScore: 0,
          totalDurationMs: 0,
          startedAt: DateTime.now().toUtc(),
        );
        state.campaign = campaign;
      }
      if (campaign.characterId != configuration.characterId) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Termina o abandona la campaña activa antes de cambiar personaje.',
        );
      }
      return CampaignStageSession(
        eligibility: CampaignEligibility.local,
        configuration: configuration.copyWith(
          level: campaign.level,
          experience: RunExperience.campaignStage,
        ),
        campaignId: campaign.id,
        stageToken: _stageToken(campaign),
        bankedCurrency: state.character(campaign.characterId).bankedCurrency,
        temporaryCurrency: campaign.temporaryCurrency,
      );
    });
  }

  @override
  Future<void> markStagePlaying(CampaignStageSession session) async {}

  @override
  Future<CampaignFinishReceipt> finishStage(Map<String, Object?> payload) {
    return _store.mutate((state) {
      final idempotencyKey = _requiredString(payload, 'idempotency_key');
      final prior = state.receipt('finish-stage', idempotencyKey);
      if (prior != null) return _finishReceipt(prior);

      final campaign = state.campaign;
      if (campaign == null || payload['stage_token'] != _stageToken(campaign)) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'La etapa local ya no está activa.',
        );
      }
      final progress = state.character(campaign.characterId);
      final outcome = _requiredString(payload, 'outcome');
      final score = _requiredInt(payload, 'score').clamp(0, 1000000000);
      final durationMs = _requiredInt(
        payload,
        'duration_ms',
      ).clamp(1000, 21600000);
      final sequence = campaign.expectedSequence;
      final victory = outcome == 'victory';
      if (!victory && outcome != 'defeat') {
        throw const AppFailure(
          AppFailureCode.invalidInput,
          'El resultado local no es válido.',
        );
      }

      final masteryXp = victory ? 100 + sequence * 10 : 25 + sequence * 5;
      final fortuneBasisPoints = localEffectiveBasisPoints(progress, 'fortune');
      final baseCurrency = max(10, min(100000, score ~/ 10));
      final currencyEarned = victory
          ? baseCurrency * (10000 + fortuneBasisPoints) ~/ 10000
          : 0;
      progress.masteryXp += masteryXp;
      campaign.totalScore += score;
      campaign.totalDurationMs += durationMs;

      var dropGranted = false;
      String? rewardId;
      var lostCurrency = 0;
      var readyToComplete = false;
      var nextLevel = 1;
      if (victory) {
        campaign.temporaryCurrency += currencyEarned;
        rewardId = campaignLevelDefinition(sequence).uniqueRewardId;
        if (!progress.uniqueRewardIds.contains(rewardId) &&
            _random.nextInt(100) == 0) {
          progress.uniqueRewardIds.add(rewardId);
          dropGranted = true;
        }
        readyToComplete = sequence == 10;
        if (readyToComplete) {
          nextLevel = 10;
          campaign.level = 10;
          campaign.expectedSequence = 11;
        } else {
          campaign.level = sequence + 1;
          campaign.expectedSequence = sequence + 1;
          nextLevel = campaign.level;
        }
      } else {
        lostCurrency = campaign.temporaryCurrency;
        state.campaign = null;
      }

      final response = <String, Object?>{
        'accepted': true,
        'ranked': false,
        'mastery_xp_granted': masteryXp,
        'temporary_currency': victory ? campaign.temporaryCurrency : 0,
        'currency_lost': lostCurrency,
        'unique_drop_granted': dropGranted,
        'unique_reward_id': dropGranted ? rewardId : null,
        'next_level': nextLevel,
        'ready_to_complete': readyToComplete,
      };
      state.saveReceipt('finish-stage', idempotencyKey, response);
      return _finishReceipt(response);
    });
  }

  @override
  Future<CampaignCompletionReceipt> completeCampaign(
    Map<String, Object?> payload,
  ) {
    return _store.mutate((state) {
      final idempotencyKey = _requiredString(payload, 'idempotency_key');
      final prior = state.receipt('complete-campaign', idempotencyKey);
      if (prior != null) return _completionReceipt(prior);
      final campaign = state.campaign;
      if (campaign == null ||
          campaign.id != payload['campaign_id'] ||
          campaign.expectedSequence != 11) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'La campaña local todavía no está lista para completarse.',
        );
      }
      final newlyBanked = campaign.temporaryCurrency;
      _bankCompletedCampaign(state, campaign);
      final response = <String, Object?>{
        'accepted': true,
        'ranked': false,
        'banked_currency': newlyBanked,
        'purchase_phase_unlocked': true,
      };
      state.saveReceipt('complete-campaign', idempotencyKey, response);
      return _completionReceipt(response);
    });
  }

  @override
  Future<void> failCampaign(Map<String, Object?> payload) {
    return _store.mutate((state) {
      final campaign = state.campaign;
      if (campaign == null) return;
      final campaignId = payload['campaign_id'];
      if (campaignId != null && campaignId != campaign.id) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'La campaña local indicada ya no está activa.',
        );
      }
      state.campaign = null;
    });
  }

  @override
  Future<void> abandonCampaign(CampaignStageSession session) {
    return _store.mutate((state) {
      if (state.campaign?.id == session.campaignId) {
        state.campaign = null;
      }
    });
  }

  @override
  Future<void> clearPreparedStage() async {}

  static CampaignProgress _progress(LocalCampaignState campaign) =>
      CampaignProgress(
        campaignId: campaign.id,
        characterId: campaign.characterId,
        currentLevel: campaign.level,
        expectedSequence: campaign.expectedSequence,
        temporaryCurrency: campaign.temporaryCurrency,
        expiresAt: DateTime.utc(9999),
      );

  static String _stageToken(LocalCampaignState campaign) =>
      'local:${campaign.id}:${campaign.expectedSequence}';

  static void _bankCompletedCampaign(
    LocalGameState state,
    LocalCampaignState campaign,
  ) {
    final progress = state.character(campaign.characterId);
    progress.bankedCurrency += campaign.temporaryCurrency;
    progress.storeUnlocked = true;
    state.campaign = null;
  }

  static CampaignFinishReceipt _finishReceipt(Map<String, Object?> row) =>
      CampaignFinishReceipt(
        accepted: row['accepted'] == true,
        ranked: row['ranked'] == true,
        masteryXpGranted: _requiredInt(row, 'mastery_xp_granted'),
        temporaryCurrency: _requiredInt(row, 'temporary_currency'),
        currencyLost: _requiredInt(row, 'currency_lost'),
        uniqueDropGranted: row['unique_drop_granted'] == true,
        nextLevel: _requiredInt(row, 'next_level'),
        readyToComplete: row['ready_to_complete'] == true,
        uniqueRewardId: row['unique_reward_id'] as String?,
      );

  static CampaignCompletionReceipt _completionReceipt(
    Map<String, Object?> row,
  ) => CampaignCompletionReceipt(
    accepted: row['accepted'] == true,
    ranked: row['ranked'] == true,
    bankedCurrency: _requiredInt(row, 'banked_currency'),
    purchasePhaseUnlocked: row['purchase_phase_unlocked'] == true,
  );

  static String _requiredString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw AppFailure(AppFailureCode.invalidInput, 'Falta el campo $key.');
  }

  static int _requiredInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is num) return value.toInt();
    throw AppFailure(AppFailureCode.invalidInput, 'Falta el campo $key.');
  }
}
