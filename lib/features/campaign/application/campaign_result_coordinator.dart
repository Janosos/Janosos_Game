import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/sync/encrypted_outbox.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../../../game/domain/run_result.dart';
import '../../../game/domain/level_runtime.dart';
import '../domain/campaign_repository.dart';
import 'run_result_recorder.dart';

class CampaignResultCoordinator {
  const CampaignResultCoordinator({
    required CampaignRepository repository,
    required EncryptedOutbox outbox,
    required RunResultRecorder recorder,
  }) : _repository = repository,
       _outbox = outbox,
       _recorder = recorder;

  static const _uuid = Uuid();
  final CampaignRepository _repository;
  final EncryptedOutbox _outbox;
  final RunResultRecorder _recorder;

  Future<String> sealAndSynchronize(
    CampaignStageSession session,
    RunResult result,
  ) async {
    if (!session.canEarnRewards) {
      await _recorder.save(result, validationStatus: 'limited', isSynced: true);
      return 'Práctica terminada: no concede moneda, maestría, recompensa ni ranking.';
    }

    if (session.eligibility == CampaignEligibility.local) {
      return _finishLocal(session, result);
    }

    if (result.outcome == RunOutcome.abandoned) {
      return _sealAbandonment(session, result);
    }

    final projectionId = _uuid.v4();
    final idempotencyKey = _uuid.v4();
    final payload = <String, Object?>{
      'stage_token': session.stageToken,
      'idempotency_key': idempotencyKey,
      'outcome': result.outcome == RunOutcome.victory ? 'victory' : 'defeat',
      'score': result.score,
      'duration_ms': result.duration.inMilliseconds.clamp(1000, 21600000),
      if (result.outcome != RunOutcome.victory)
        'defeat_reason': result.outcome == RunOutcome.abandoned
            ? 'pause_budget_exhausted'
            : 'lives_depleted',
      '_projection': _projectionPayload(projectionId, result),
    };
    final outboxId = await _outbox.enqueue(
      commandType: 'finish-stage',
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
    await _repository.clearPreparedStage();

    try {
      final receipt = await _repository.finishStage(payload);
      await _outbox.acknowledgeAccepted(outboxId);
      await _recorder.save(
        result,
        id: projectionId,
        validationStatus: receipt.accepted ? 'verified' : 'rejected',
        isSynced: true,
      );
      if (receipt.accepted &&
          result.outcome == RunOutcome.victory &&
          receipt.readyToComplete) {
        return await _sealCompletion(session, receipt);
      }
      if (receipt.uniqueDropGranted) {
        final reward = campaignLevelDefinition(result.levelReached);
        return 'Resultado verificado. ¡Obtuviste la recompensa única ${reward.uniqueRewardName}!';
      }
      if (result.outcome == RunOutcome.defeat) {
        return 'Derrota verificada. La moneda en riesgo se perdió; tu progreso permanente se conservó.';
      }
      return 'Victoria verificada. Nivel ${receipt.nextLevel}/10 desbloqueado. '
          'No hubo recompensa única en este intento (probabilidad: 1%).';
    } on AppFailure catch (error) {
      if (error.code == AppFailureCode.conflict ||
          error.code == AppFailureCode.invalidInput ||
          error.code == AppFailureCode.unauthorized) {
        await _outbox.rejectPermanently(
          id: outboxId,
          errorCode: error.code.name,
        );
        await _recorder.save(
          result,
          id: projectionId,
          validationStatus: 'rejected',
          isSynced: true,
        );
        return 'El servidor rechazó el resultado. No se otorgaron recompensas.';
      }
      await _outbox.recordTransientFailure(
        id: outboxId,
        errorCode: error.code.name,
      );
      return 'Resultado sellado y pendiente de sincronización. Las recompensas aún no están disponibles.';
    }
  }

  Future<String> _finishLocal(
    CampaignStageSession session,
    RunResult result,
  ) async {
    if (result.outcome == RunOutcome.abandoned) {
      await _repository.abandonCampaign(session);
      await _recorder.save(result, validationStatus: 'limited', isSynced: true);
      return 'Campaña local abandonada. La moneda en riesgo se perdió; tus compras y recompensas permanentes se conservaron.';
    }
    final payload = <String, Object?>{
      'stage_token': session.stageToken,
      'idempotency_key': _uuid.v4(),
      'outcome': result.outcome == RunOutcome.victory ? 'victory' : 'defeat',
      'score': result.score,
      'duration_ms': result.duration.inMilliseconds.clamp(1000, 21600000),
    };
    final receipt = await _repository.finishStage(payload);
    await _recorder.save(result, validationStatus: 'limited', isSynced: true);
    if (receipt.readyToComplete && session.campaignId != null) {
      final completion = await _repository.completeCampaign({
        'campaign_id': session.campaignId,
        'idempotency_key': _uuid.v4(),
      });
      return '¡Campaña local completada! Se guardaron ${completion.bankedCurrency} monedas y se desbloquearon la tienda y Boss Rush.';
    }
    if (receipt.uniqueDropGranted) {
      final reward = campaignLevelDefinition(result.levelReached);
      return 'Victoria local. ¡Obtuviste la recompensa única ${reward.uniqueRewardName}!';
    }
    if (result.outcome == RunOutcome.defeat) {
      return 'Derrota local. Regresas al nivel 1 y pierdes la moneda temporal; el progreso permanente se conservó.';
    }
    return 'Victoria local. Nivel ${receipt.nextLevel}/10 desbloqueado y ${receipt.temporaryCurrency} monedas siguen en riesgo.';
  }

  Future<int> synchronizePending() async {
    final commands = await _outbox.due();
    var synchronized = 0;
    for (final command in commands) {
      try {
        final validationStatus = command.commandType == 'finish-stage'
            ? (await _repository.finishStage(command.payload)).accepted
                  ? 'verified'
                  : 'rejected'
            : command.commandType == 'fail-campaign'
            ? await _synchronizeAbandonment(command.payload)
            : command.commandType == 'complete-campaign'
            ? await _synchronizeCompletion(command.payload)
            : null;
        if (validationStatus == null) continue;
        final projection = command.payload['_projection'];
        if (projection is Map) {
          await _saveProjection(
            Map<String, Object?>.from(projection),
            validationStatus: validationStatus,
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
          final projection = command.payload['_projection'];
          if (projection is Map) {
            await _saveProjection(
              Map<String, Object?>.from(projection),
              validationStatus: 'rejected',
            );
          }
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

  Future<String> _sealAbandonment(
    CampaignStageSession session,
    RunResult result,
  ) async {
    final projectionId = _uuid.v4();
    final idempotencyKey = _uuid.v4();
    final payload = <String, Object?>{
      'campaign_id': session.campaignId,
      'idempotency_key': idempotencyKey,
      '_projection': _projectionPayload(projectionId, result),
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
    await _repository.clearPreparedStage();
    try {
      await _repository.failCampaign(payload);
      await _outbox.acknowledgeAccepted(outboxId);
      await _recorder.save(
        result,
        id: projectionId,
        validationStatus: 'limited',
        isSynced: true,
      );
      return 'Campaña abandonada sin ranking. La moneda en riesgo se perdió y las compras permanentes se conservaron.';
    } on AppFailure catch (error) {
      await _outbox.recordTransientFailure(
        id: outboxId,
        errorCode: error.code.name,
      );
      return 'Abandono sellado y pendiente de sincronización; no se publicará en el ranking.';
    }
  }

  Future<String> _synchronizeAbandonment(Map<String, Object?> payload) async {
    await _repository.failCampaign(payload);
    return 'limited';
  }

  Future<String> _sealCompletion(
    CampaignStageSession session,
    CampaignFinishReceipt stageReceipt,
  ) async {
    final campaignId = session.campaignId;
    if (campaignId == null) {
      return 'Campaña completada en práctica; no concede recompensas.';
    }
    final idempotencyKey = _uuid.v4();
    final payload = <String, Object?>{
      'campaign_id': campaignId,
      'idempotency_key': idempotencyKey,
    };
    final outboxId = await _outbox.enqueue(
      commandType: 'complete-campaign',
      idempotencyKey: idempotencyKey,
      payload: payload,
    );
    try {
      final receipt = await _repository.completeCampaign(payload);
      await _outbox.acknowledgeAccepted(outboxId);
      return '¡Campaña completada! Se guardaron ${receipt.bankedCurrency} '
          'monedas y se desbloquearon la tienda y Boss Rush.';
    } on AppFailure catch (error) {
      await _outbox.recordTransientFailure(
        id: outboxId,
        errorCode: error.code.name,
      );
      return 'Nivel 10 verificado. El cierre y las '
          '${stageReceipt.temporaryCurrency} monedas están sellados y pendientes de sincronización.';
    }
  }

  Future<String> _synchronizeCompletion(Map<String, Object?> payload) async {
    final receipt = await _repository.completeCampaign(payload);
    return receipt.accepted ? 'verified' : 'rejected';
  }

  static Map<String, Object?> _projectionPayload(String id, RunResult result) =>
      {
        'id': id,
        'character_id': result.characterId.serialized,
        'mode': result.mode.serialized,
        'outcome': result.outcome.name,
        'score': result.score,
        'duration_ms': result.duration.inMilliseconds,
        'level_reached': result.levelReached,
        'content_version': result.contentVersion,
        'protocol_version': result.protocolVersion,
      };

  Future<void> _saveProjection(
    Map<String, Object?> row, {
    required String validationStatus,
  }) {
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
}
