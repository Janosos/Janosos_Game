import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../game/domain/level_runtime.dart';
import '../../../game/domain/run_configuration.dart';
import '../../progression/data/local_game_state_store.dart';
import '../domain/boss_rush_repository.dart';

class LocalBossRushRepository implements BossRushRepository {
  LocalBossRushRepository({required LocalGameStateStore store, Random? random})
    : _store = store,
      _random = random ?? Random.secure();

  static const _uuid = Uuid();
  final LocalGameStateStore _store;
  final Random _random;

  @override
  Future<BossRushSession> start(RunConfiguration configuration) {
    return _store.mutate((state) {
      if (state.campaign != null || state.bossRush != null) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Termina o abandona la partida activa antes de iniciar Boss Rush.',
        );
      }
      final progress = state.character(configuration.characterId);
      if (!progress.storeUnlocked) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'Completa la campaña con este personaje para desbloquear Boss Rush.',
        );
      }
      final attempt = LocalBossRushState(
        id: _uuid.v4(),
        characterId: configuration.characterId,
      );
      state.bossRush = attempt;
      return BossRushSession(
        eligibility: BossRushEligibility.local,
        configuration: configuration,
        campaignId: attempt.id,
        attemptToken: _token(attempt),
      );
    });
  }

  @override
  Future<BossRushFinishReceipt> finish(Map<String, Object?> payload) {
    return _store.mutate((state) {
      final idempotencyKey = _requiredString(payload, 'idempotency_key');
      final prior = state.receipt('finish-boss-rush', idempotencyKey);
      if (prior != null) return _receipt(prior);
      final attempt = state.bossRush;
      if (attempt == null || payload['attempt_token'] != _token(attempt)) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'El intento local de Boss Rush ya no está activo.',
        );
      }
      final bossesDefeated = _requiredInt(
        payload,
        'bosses_defeated',
      ).clamp(0, 10);
      final progress = state.character(attempt.characterId);
      final granted = <String>[];
      for (var level = 1; level <= bossesDefeated; level++) {
        final rewardId = campaignLevelDefinition(level).uniqueRewardId;
        if (!progress.uniqueRewardIds.contains(rewardId) &&
            _random.nextInt(100) == 0) {
          progress.uniqueRewardIds.add(rewardId);
          granted.add(rewardId);
        }
      }
      final masteryXp = bossesDefeated * 20 + (bossesDefeated == 10 ? 50 : 0);
      progress.masteryXp += masteryXp;
      final response = <String, Object?>{
        'accepted': true,
        'ranked': false,
        'mastery_xp_granted': masteryXp,
        'bosses_defeated': bossesDefeated,
        'unique_rewards_granted': granted,
      };
      state.bossRush = null;
      state.saveReceipt('finish-boss-rush', idempotencyKey, response);
      return _receipt(response);
    });
  }

  @override
  Future<void> abandon(BossRushSession session) {
    return _store.mutate((state) {
      if (state.bossRush?.id == session.campaignId) state.bossRush = null;
    });
  }

  @override
  Future<void> fail(Map<String, Object?> payload) {
    return _store.mutate((state) => state.bossRush = null);
  }

  static String _token(LocalBossRushState state) => 'local:${state.id}:rush';

  static BossRushFinishReceipt _receipt(Map<String, Object?> row) =>
      BossRushFinishReceipt(
        accepted: row['accepted'] == true,
        ranked: row['ranked'] == true,
        masteryXpGranted: _requiredInt(row, 'mastery_xp_granted'),
        bossesDefeated: _requiredInt(row, 'bosses_defeated'),
        uniqueRewardsGranted:
            (row['unique_rewards_granted'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
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
