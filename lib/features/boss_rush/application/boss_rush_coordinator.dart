import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/sync/encrypted_outbox.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/palette_transform.dart';
import '../../../game/domain/run_configuration.dart';
import '../../../game/domain/run_result.dart';
import '../../campaign/application/run_result_recorder.dart';
import '../../progression/domain/progression_build_policy.dart';
import '../../progression/domain/progression_repository.dart';
import '../domain/boss_rush_repository.dart';

class BossRushCoordinator {
  BossRushCoordinator({
    required BossRushRepository repository,
    required ProgressionRepository progressionRepository,
    required AppEnvironment environment,
    required EncryptedOutbox outbox,
    required RunResultRecorder recorder,
  }) : _repository = repository,
       _progressionRepository = progressionRepository,
       _environment = environment,
       _outbox = outbox,
       _recorder = recorder;

  static const _uuid = Uuid();
  final BossRushRepository _repository;
  final ProgressionRepository _progressionRepository;
  final AppEnvironment _environment;
  final EncryptedOutbox _outbox;
  final RunResultRecorder _recorder;

  Future<BossRushSession> prepare(CharacterId characterId) async {
    final snapshot = await _progressionRepository.loadSnapshot(
      characterId: characterId,
      contentVersion: _environment.contentVersion,
    );
    if (!snapshot.storeUnlocked) {
      throw const AppFailure(
        AppFailureCode.conflict,
        'Completa la campaña con este personaje para desbloquear Boss Rush.',
      );
    }
    final palette = snapshot.palettes
        .where((candidate) => candidate.equipped)
        .map((candidate) => candidate.transform)
        .firstOrNull;
    final configuration = RunConfiguration(
      characterId: characterId,
      mode: RunMode.bossRush,
      stats: ProgressionBuildPolicy.statsFor(
        characterId: characterId,
        mode: RunMode.bossRush,
        build: snapshot.authorizedBuild,
      ),
      loadout: ProgressionBuildPolicy.loadoutFor(
        characterId: characterId,
        mode: RunMode.bossRush,
        build: snapshot.authorizedBuild,
        skills: snapshot.skills,
      ),
      level: 1,
      contentVersion: _environment.contentVersion,
      protocolVersion: 1,
      seed: Random.secure().nextInt(0x7fffffff),
      experience: RunExperience.bossRush,
      palette: palette ?? PaletteTransform.identity,
    );
    return _repository.start(configuration);
  }

  Future<String> sealAndSynchronize(
    BossRushSession session,
    RunResult result,
  ) async {
    if (!session.canEarnRewards) {
      await _recorder.save(result, validationStatus: 'limited', isSynced: true);
      return 'Boss Rush de práctica: puntuación local sin recompensas.';
    }
    if (session.eligibility == BossRushEligibility.local) {
      return _finishLocal(session, result);
    }
    if (result.outcome == RunOutcome.abandoned) {
      return _sealAbandonment(session, result);
    }
    final projectionId = _uuid.v4();
    final idempotencyKey = _uuid.v4();
    final payload = <String, Object?>{
      'attempt_token': session.attemptToken,
      'idempotency_key': idempotencyKey,
      'outcome': result.outcome == RunOutcome.victory ? 'victory' : 'defeat',
      'bosses_defeated': result.levelReached,
      'score': result.score,
      'duration_ms': result.duration.inMilliseconds.clamp(1000, 21600000),
      '_projection': {
        'id': projectionId,
        'character_id': result.characterId.serialized,
        'mode': result.mode.serialized,
        'outcome': result.outcome.name,
        'score': result.score,
        'duration_ms': result.duration.inMilliseconds,
        'level_reached': result.levelReached,
        'content_version': result.contentVersion,
        'protocol_version': result.protocolVersion,
      },
    };
    final outboxId = await _outbox.enqueue(
      commandType: 'finish-boss-rush',
      idempotencyKey: idempotencyKey,
      payload: payload,
      projectionId: projectionId,
    );
    await _recorder.save(
      result,
      id: projectionId,
      validationStatus: 'pending',
      isSynced: false,
    );
    try {
      final receipt = await _repository.finish(payload);
      await _outbox.acknowledgeAccepted(outboxId);
      await _recorder.save(
        result,
        id: projectionId,
        validationStatus: receipt.accepted ? 'verified' : 'rejected',
        isSynced: true,
      );
      final drops = receipt.uniqueRewardsGranted.isEmpty
          ? 'Sin recompensa única esta vez.'
          : 'Recompensas únicas: ${receipt.uniqueRewardsGranted.join(', ')}.';
      return 'Boss Rush verificado: ${receipt.bossesDefeated}/10 jefes, '
          '+${receipt.masteryXpGranted} XP. $drops';
    } on AppFailure catch (error) {
      await _outbox.recordTransientFailure(
        id: outboxId,
        errorCode: error.code.name,
      );
      return 'Resultado de Boss Rush sellado y pendiente de sincronización.';
    }
  }

  Future<void> abandon(BossRushSession session) async {
    if (session.eligibility == BossRushEligibility.local) {
      return _repository.abandon(session);
    }
    if (!session.canEarnRewards || session.campaignId == null) {
      return _repository.abandon(session);
    }
    final idempotencyKey = _uuid.v4();
    final payload = <String, Object?>{
      'campaign_id': session.campaignId,
      'idempotency_key': idempotencyKey,
    };
    final outboxId = await _outbox.enqueue(
      commandType: 'fail-campaign',
      idempotencyKey: idempotencyKey,
      payload: payload,
    );
    try {
      await _repository.fail(payload);
      await _outbox.acknowledgeAccepted(outboxId);
    } on AppFailure catch (error) {
      await _outbox.recordTransientFailure(
        id: outboxId,
        errorCode: error.code.name,
      );
    }
  }

  Future<String> _finishLocal(BossRushSession session, RunResult result) async {
    if (result.outcome == RunOutcome.abandoned) {
      await _repository.abandon(session);
      await _recorder.save(result, validationStatus: 'limited', isSynced: true);
      return 'Boss Rush local abandonado sin perder compras ni moneda.';
    }
    final receipt = await _repository.finish({
      'attempt_token': session.attemptToken,
      'idempotency_key': _uuid.v4(),
      'outcome': result.outcome == RunOutcome.victory ? 'victory' : 'defeat',
      'bosses_defeated': result.levelReached,
      'score': result.score,
      'duration_ms': result.duration.inMilliseconds.clamp(1000, 21600000),
    });
    await _recorder.save(result, validationStatus: 'limited', isSynced: true);
    final drops = receipt.uniqueRewardsGranted.isEmpty
        ? 'Sin recompensa única esta vez.'
        : 'Recompensas únicas: ${receipt.uniqueRewardsGranted.join(', ')}.';
    return 'Boss Rush local: ${receipt.bossesDefeated}/10 jefes, '
        '+${receipt.masteryXpGranted} XP. $drops';
  }

  Future<int> synchronizePending() async {
    var synchronized = 0;
    for (final command in await _outbox.due()) {
      if (command.commandType != 'finish-boss-rush') continue;
      try {
        final receipt = await _repository.finish(command.payload);
        final projection = command.payload['_projection'];
        if (projection is Map) {
          await _saveProjection(
            Map<String, Object?>.from(projection),
            receipt.accepted ? 'verified' : 'rejected',
          );
        }
        await _outbox.acknowledgeAccepted(command.id);
        synchronized += 1;
      } on AppFailure catch (error) {
        if (error.code == AppFailureCode.conflict ||
            error.code == AppFailureCode.invalidInput ||
            error.code == AppFailureCode.unauthorized) {
          await _outbox.rejectPermanently(
            id: command.id,
            errorCode: error.code.name,
          );
        } else {
          await _outbox.recordTransientFailure(
            id: command.id,
            errorCode: error.code.name,
          );
        }
      }
    }
    return synchronized;
  }

  Future<void> _saveProjection(
    Map<String, Object?> row,
    String validationStatus,
  ) {
    return _recorder.save(
      RunResult(
        characterId: CharacterIdSerialization.parse(
          row['character_id'] as String,
        ),
        mode: RunModeSerialization.parse(row['mode'] as String),
        outcome: RunOutcome.values.byName(row['outcome'] as String),
        score: (row['score'] as num).toInt(),
        duration: Duration(milliseconds: (row['duration_ms'] as num).toInt()),
        levelReached: (row['level_reached'] as num).toInt(),
        contentVersion: row['content_version'] as String,
        protocolVersion: (row['protocol_version'] as num).toInt(),
      ),
      id: row['id'] as String,
      validationStatus: validationStatus,
      isSynced: true,
    );
  }

  Future<String> _sealAbandonment(
    BossRushSession session,
    RunResult result,
  ) async {
    final projectionId = _uuid.v4();
    final idempotencyKey = _uuid.v4();
    final payload = <String, Object?>{
      'campaign_id': session.campaignId,
      'idempotency_key': idempotencyKey,
      '_projection': {
        'id': projectionId,
        'character_id': result.characterId.serialized,
        'mode': result.mode.serialized,
        'outcome': result.outcome.name,
        'score': result.score,
        'duration_ms': result.duration.inMilliseconds,
        'level_reached': result.levelReached,
        'content_version': result.contentVersion,
        'protocol_version': result.protocolVersion,
      },
    };
    final outboxId = await _outbox.enqueue(
      commandType: 'fail-campaign',
      idempotencyKey: idempotencyKey,
      payload: payload,
      projectionId: projectionId,
    );
    await _recorder.save(
      result,
      id: projectionId,
      validationStatus: 'pending',
      isSynced: false,
    );
    try {
      await _repository.fail(payload);
      await _outbox.acknowledgeAccepted(outboxId);
      await _recorder.save(
        result,
        id: projectionId,
        validationStatus: 'limited',
        isSynced: true,
      );
      return 'Boss Rush abandonado sin ranking ni recompensas.';
    } on AppFailure catch (error) {
      await _outbox.recordTransientFailure(
        id: outboxId,
        errorCode: error.code.name,
      );
      return 'Abandono de Boss Rush sellado y pendiente de sincronización.';
    }
  }
}
