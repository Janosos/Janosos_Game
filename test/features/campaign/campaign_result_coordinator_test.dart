import 'dart:math';

import 'package:dino_run_flame/core/errors/app_failure.dart';
import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/core/sync/encrypted_outbox.dart';
import 'package:dino_run_flame/features/campaign/application/campaign_result_coordinator.dart';
import 'package:dino_run_flame/features/campaign/application/run_result_recorder.dart';
import 'package:dino_run_flame/features/campaign/domain/campaign_repository.dart';
import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:dino_run_flame/game/domain/run_result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_protected_store.dart';

void main() {
  late AppDatabase database;
  late FakeAuthRepository auth;
  late EncryptedOutbox outbox;
  late RunResultRecorder recorder;
  late Future<List<ResultProjection>> Function() history;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    auth = FakeAuthRepository.signedIn(userId: 'user-a');
    outbox = EncryptedOutbox(
      database: database,
      protectedStore: MemoryProtectedStore(),
      authRepository: auth,
      jitterRandom: Random(1),
    );
    recorder = RunResultRecorder(database: database, authRepository: auth);
    history = () => database.personalResultHistory(
      userId: 'user-a',
      characterId: 'jano',
      mode: 'progression',
    );
  });

  tearDown(() async {
    await database.close();
    await auth.dispose();
  });

  test(
    'practice result is labeled limited and never enters the outbox',
    () async {
      final repository = _FakeCampaignRepository();
      final coordinator = CampaignResultCoordinator(
        repository: repository,
        outbox: outbox,
        recorder: recorder,
      );

      final message = await coordinator.sealAndSynchronize(
        _session(CampaignEligibility.practice),
        _result,
      );

      expect(message, contains('Práctica'));
      expect(repository.finishCalls, 0);
      expect(await database.outboxCount('user-a'), 0);
      final rows = await history();
      expect(rows.single.validationStatus, 'limited');
      expect(rows.single.isSynced, isTrue);
    },
  );

  test(
    'accepted result is sealed, synchronized and acknowledged once',
    () async {
      final repository = _FakeCampaignRepository();
      final coordinator = CampaignResultCoordinator(
        repository: repository,
        outbox: outbox,
        recorder: recorder,
      );

      final message = await coordinator.sealAndSynchronize(
        _session(CampaignEligibility.verifiedOnline),
        _result,
      );

      expect(message, contains('No hubo recompensa'));
      expect(repository.finishCalls, 1);
      expect(repository.cleared, isTrue);
      expect(await database.outboxCount('user-a'), 0);
      final rows = await history();
      expect(rows.single.validationStatus, 'verified');
      expect(rows.single.isSynced, isTrue);
    },
  );

  test(
    'local result grants progress without creating a cloud outbox',
    () async {
      final repository = _FakeCampaignRepository();
      final coordinator = CampaignResultCoordinator(
        repository: repository,
        outbox: outbox,
        recorder: recorder,
      );

      final message = await coordinator.sealAndSynchronize(
        _session(CampaignEligibility.local),
        _result,
      );

      expect(message, contains('Victoria local'));
      expect(repository.finishCalls, 1);
      expect(await database.outboxCount('user-a'), 0);
      final rows = await history();
      expect(rows.single.validationStatus, 'limited');
      expect(rows.single.isSynced, isTrue);
    },
  );

  test('transient failure keeps encrypted result pending for retry', () async {
    final repository = _FakeCampaignRepository(failWithNetwork: true);
    final coordinator = CampaignResultCoordinator(
      repository: repository,
      outbox: outbox,
      recorder: recorder,
    );

    final message = await coordinator.sealAndSynchronize(
      _session(CampaignEligibility.eligibleOffline),
      _result,
    );

    expect(message, contains('pendiente'));
    expect(await database.outboxCount('user-a'), 1);
    final rows = await history();
    expect(rows.single.validationStatus, 'pending');
    expect(rows.single.isSynced, isFalse);
  });

  test('pause-budget abandonment uses unranked fail command', () async {
    final repository = _FakeCampaignRepository();
    final coordinator = CampaignResultCoordinator(
      repository: repository,
      outbox: outbox,
      recorder: recorder,
    );
    final abandoned = RunResult(
      characterId: CharacterId.jano,
      mode: RunMode.progression,
      outcome: RunOutcome.abandoned,
      score: 400,
      duration: const Duration(minutes: 2),
      levelReached: 1,
      contentVersion: 'v6-preview-1',
      protocolVersion: 1,
    );

    final message = await coordinator.sealAndSynchronize(
      _session(CampaignEligibility.verifiedOnline),
      abandoned,
    );

    expect(message, contains('sin ranking'));
    expect(repository.failCalls, 1);
    expect(repository.finishCalls, 0);
    expect(await database.outboxCount('user-a'), 0);
    final rows = await history();
    expect(rows.single.outcome, 'abandoned');
    expect(rows.single.validationStatus, 'limited');
  });

  test('level ten seals completion and banks temporary currency', () async {
    final repository = _FakeCampaignRepository(readyToComplete: true);
    final coordinator = CampaignResultCoordinator(
      repository: repository,
      outbox: outbox,
      recorder: recorder,
    );
    final result = RunResult(
      characterId: CharacterId.jano,
      mode: RunMode.progression,
      outcome: RunOutcome.victory,
      score: 5000,
      duration: const Duration(minutes: 4),
      levelReached: 10,
      contentVersion: 'v6-preview-1',
      protocolVersion: 1,
    );

    final message = await coordinator.sealAndSynchronize(
      _session(CampaignEligibility.verifiedOnline, level: 10),
      result,
    );

    expect(message, contains('Campaña completada'));
    expect(message, contains('240 monedas'));
    expect(repository.finishCalls, 1);
    expect(repository.completeCalls, 1);
    expect(await database.outboxCount('user-a'), 0);
  });
}

final _result = RunResult(
  characterId: CharacterId.jano,
  mode: RunMode.progression,
  outcome: RunOutcome.victory,
  score: 2400,
  duration: const Duration(minutes: 4),
  levelReached: 1,
  contentVersion: 'v6-preview-1',
  protocolVersion: 1,
);

CampaignStageSession _session(
  CampaignEligibility eligibility, {
  int level = 1,
}) {
  final definition = CharacterId.jano.definition;
  return CampaignStageSession(
    eligibility: eligibility,
    configuration: RunConfiguration(
      characterId: CharacterId.jano,
      mode: RunMode.progression,
      stats: RunStats.base(definition),
      loadout: RunLoadout(activeAbility: definition.defaultActive),
      level: level,
      contentVersion: 'v6-preview-1',
      protocolVersion: 1,
      seed: 7,
      experience: RunExperience.campaignStage,
    ),
    campaignId: eligibility == CampaignEligibility.practice
        ? null
        : 'campaign-a',
    stageToken: eligibility == CampaignEligibility.practice
        ? null
        : 'stage-token',
    expiresAt: eligibility == CampaignEligibility.practice
        ? null
        : DateTime.utc(2026, 9, 2),
    bankedCurrency: 100,
    temporaryCurrency: 50,
  );
}

class _FakeCampaignRepository implements CampaignRepository {
  _FakeCampaignRepository({
    this.failWithNetwork = false,
    this.readyToComplete = false,
  });

  final bool failWithNetwork;
  final bool readyToComplete;
  int finishCalls = 0;
  int completeCalls = 0;
  int failCalls = 0;
  bool cleared = false;

  @override
  Future<CampaignFinishReceipt> finishStage(
    Map<String, Object?> payload,
  ) async {
    finishCalls += 1;
    if (failWithNetwork) {
      throw const AppFailure(AppFailureCode.network, 'offline');
    }
    return CampaignFinishReceipt(
      accepted: true,
      ranked: false,
      masteryXpGranted: 110,
      temporaryCurrency: 240,
      currencyLost: 0,
      uniqueDropGranted: false,
      nextLevel: readyToComplete ? 11 : 2,
      readyToComplete: readyToComplete,
      uniqueRewardId: 'headless_horseman.spectral_trail',
    );
  }

  @override
  Future<void> clearPreparedStage() async => cleared = true;

  @override
  Future<void> failCampaign(Map<String, Object?> payload) async {
    failCalls += 1;
    if (failWithNetwork) {
      throw const AppFailure(AppFailureCode.network, 'offline');
    }
  }

  @override
  Future<void> abandonCampaign(CampaignStageSession session) async {}

  @override
  Future<CampaignProgress?> loadActiveCampaign() async => null;

  @override
  Future<CampaignCompletionReceipt> completeCampaign(
    Map<String, Object?> payload,
  ) async {
    completeCalls += 1;
    return const CampaignCompletionReceipt(
      accepted: true,
      ranked: true,
      bankedCurrency: 240,
      purchasePhaseUnlocked: true,
    );
  }

  @override
  Future<CampaignStageSession?> loadPreparedStage(
    CharacterId characterId,
  ) async => null;

  @override
  Future<void> markStagePlaying(CampaignStageSession session) async {}

  @override
  Future<CampaignStageSession> startStage({
    required RunConfiguration configuration,
    required int bankedCurrency,
    required int temporaryCurrency,
  }) => throw UnimplementedError();
}
