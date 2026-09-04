import 'dart:math';

import 'package:dino_run_flame/core/config/app_environment.dart';
import 'package:dino_run_flame/core/errors/app_failure.dart';
import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/core/sync/encrypted_outbox.dart';
import 'package:dino_run_flame/features/boss_rush/application/boss_rush_coordinator.dart';
import 'package:dino_run_flame/features/boss_rush/domain/boss_rush_repository.dart';
import 'package:dino_run_flame/features/campaign/application/run_result_recorder.dart';
import 'package:dino_run_flame/features/progression/data/local_progression_repository.dart';
import 'package:dino_run_flame/features/progression/data/local_game_state_store.dart';
import 'package:dino_run_flame/game/domain/character_definition.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:dino_run_flame/game/domain/run_result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_protected_store.dart';

void main() {
  late AppDatabase database;
  late FakeAuthRepository auth;
  late EncryptedOutbox outbox;
  late RunResultRecorder recorder;
  late LocalProgressionRepository progressionRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    auth = FakeAuthRepository.signedIn(userId: 'boss-user');
    progressionRepository = LocalProgressionRepository(
      store: LocalGameStateStore(
        preferences: preferences,
        authRepository: auth,
      ),
    );
    outbox = EncryptedOutbox(
      database: database,
      protectedStore: MemoryProtectedStore(),
      authRepository: auth,
      jitterRandom: Random(1),
    );
    recorder = RunResultRecorder(database: database, authRepository: auth);
  });

  tearDown(() async {
    await database.close();
    await auth.dispose();
  });

  BossRushCoordinator coordinator(_FakeBossRushRepository repository) {
    return BossRushCoordinator(
      repository: repository,
      progressionRepository: progressionRepository,
      environment: _environment,
      outbox: outbox,
      recorder: recorder,
    );
  }

  test('practice Boss Rush remains local and grants nothing', () async {
    final repository = _FakeBossRushRepository();
    final message = await coordinator(
      repository,
    ).sealAndSynchronize(_session(BossRushEligibility.practice), _result);

    expect(message, contains('práctica'));
    expect(repository.finishCalls, 0);
    expect(await database.outboxCount('boss-user'), 0);
    final history = await _history(database);
    expect(history.single.validationStatus, 'limited');
  });

  test('verified Boss Rush seals and acknowledges its result once', () async {
    final repository = _FakeBossRushRepository();
    final message = await coordinator(
      repository,
    ).sealAndSynchronize(_session(BossRushEligibility.verified), _result);

    expect(message, contains('3/10'));
    expect(message, contains('+60 XP'));
    expect(repository.finishCalls, 1);
    expect(await database.outboxCount('boss-user'), 0);
    final history = await _history(database);
    expect(history.single.validationStatus, 'verified');
    expect(history.single.mode, 'boss_rush');
  });

  test('local Boss Rush grants local XP without a cloud outbox', () async {
    final repository = _FakeBossRushRepository();
    final message = await coordinator(
      repository,
    ).sealAndSynchronize(_session(BossRushEligibility.local), _result);

    expect(message, contains('Boss Rush local'));
    expect(repository.finishCalls, 1);
    expect(await database.outboxCount('boss-user'), 0);
    final history = await _history(database);
    expect(history.single.validationStatus, 'limited');
    expect(history.single.isSynced, isTrue);
  });

  test('network failure keeps encrypted Boss Rush result pending', () async {
    final repository = _FakeBossRushRepository(failWithNetwork: true);
    final message = await coordinator(
      repository,
    ).sealAndSynchronize(_session(BossRushEligibility.verified), _result);

    expect(message, contains('pendiente'));
    expect(await database.outboxCount('boss-user'), 1);
    final history = await _history(database);
    expect(history.single.validationStatus, 'pending');
    expect(history.single.isSynced, isFalse);
  });

  test('pause expiry abandons Boss Rush without ranking it', () async {
    final repository = _FakeBossRushRepository();
    final abandoned = RunResult(
      characterId: CharacterId.jano,
      mode: RunMode.bossRush,
      outcome: RunOutcome.abandoned,
      score: 100,
      duration: const Duration(minutes: 1),
      levelReached: 0,
      contentVersion: 'v6-preview-1',
      protocolVersion: 1,
    );

    final message = await coordinator(
      repository,
    ).sealAndSynchronize(_session(BossRushEligibility.verified), abandoned);

    expect(message, contains('sin ranking'));
    expect(repository.finishCalls, 0);
    final history = await _history(database);
    expect(history.single.validationStatus, 'limited');
    expect(history.single.outcome, 'abandoned');
  });
}

final _environment = AppEnvironment(
  backendMode: BackendMode.local,
  supabaseUrl: '',
  supabasePublishableKey: '',
  authRedirectUri: Uri.parse('janosos://auth'),
  contentVersion: 'v6-preview-1',
);

final _result = RunResult(
  characterId: CharacterId.jano,
  mode: RunMode.bossRush,
  outcome: RunOutcome.defeat,
  score: 9000,
  duration: const Duration(minutes: 7),
  levelReached: 3,
  contentVersion: 'v6-preview-1',
  protocolVersion: 1,
);

BossRushSession _session(BossRushEligibility eligibility) {
  final character = CharacterId.jano.definition;
  return BossRushSession(
    eligibility: eligibility,
    configuration: RunConfiguration(
      characterId: CharacterId.jano,
      mode: RunMode.bossRush,
      stats: RunStats.base(character),
      loadout: RunLoadout(activeAbility: character.defaultActive),
      level: 1,
      contentVersion: 'v6-preview-1',
      protocolVersion: 1,
      seed: 6,
      experience: RunExperience.bossRush,
    ),
    campaignId: eligibility == BossRushEligibility.practice ? null : 'attempt',
    attemptToken: eligibility == BossRushEligibility.practice ? null : 'token',
  );
}

Future<List<ResultProjection>> _history(AppDatabase database) {
  return database.personalResultHistory(
    userId: 'boss-user',
    characterId: 'jano',
    mode: 'boss_rush',
  );
}

class _FakeBossRushRepository implements BossRushRepository {
  _FakeBossRushRepository({this.failWithNetwork = false});

  final bool failWithNetwork;
  int finishCalls = 0;

  @override
  Future<void> abandon(BossRushSession session) async {}

  @override
  Future<void> fail(Map<String, Object?> payload) async {
    if (failWithNetwork) {
      throw const AppFailure(AppFailureCode.network, 'offline');
    }
  }

  @override
  Future<BossRushFinishReceipt> finish(Map<String, Object?> payload) async {
    finishCalls += 1;
    if (failWithNetwork) {
      throw const AppFailure(AppFailureCode.network, 'offline');
    }
    return BossRushFinishReceipt(
      accepted: true,
      ranked: true,
      masteryXpGranted: 60,
      bossesDefeated: 3,
      uniqueRewardsGranted: const [],
    );
  }

  @override
  Future<BossRushSession> start(RunConfiguration configuration) =>
      throw UnimplementedError();
}
