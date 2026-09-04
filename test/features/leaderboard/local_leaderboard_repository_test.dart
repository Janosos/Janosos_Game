import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/features/leaderboard/data/local_leaderboard_repository.dart';
import 'package:dino_run_flame/features/leaderboard/domain/leaderboard_models.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late AppDatabase database;
  late FakeAuthRepository authRepository;
  late LocalLeaderboardRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    authRepository = FakeAuthRepository.signedIn(userId: 'user-a');
    repository = LocalLeaderboardRepository(
      database: database,
      authRepository: authRepository,
    );
  });

  tearDown(() async {
    await database.close();
    await authRepository.dispose();
  });

  test('local history is isolated by user, character, and mode', () async {
    final now = DateTime.utc(2026, 8, 31, 12);
    await database.saveResultProjection(
      id: 'matching',
      userId: 'user-a',
      characterId: 'jano',
      mode: 'progression',
      outcome: 'defeat',
      validationStatus: 'pending',
      contentVersion: 'v6-preview-1',
      score: 120,
      durationMs: 5000,
      levelReached: 1,
      endedAt: now,
      isSynced: false,
    );
    await database.saveResultProjection(
      id: 'other-character',
      userId: 'user-a',
      characterId: 'parker',
      mode: 'progression',
      outcome: 'defeat',
      validationStatus: 'pending',
      contentVersion: 'v6-preview-1',
      score: 900,
      durationMs: 1000,
      levelReached: 1,
      endedAt: now,
      isSynced: false,
    );
    await database.saveResultProjection(
      id: 'other-user',
      userId: 'user-b',
      characterId: 'jano',
      mode: 'progression',
      outcome: 'defeat',
      validationStatus: 'pending',
      contentVersion: 'v6-preview-1',
      score: 800,
      durationMs: 1000,
      levelReached: 1,
      endedAt: now,
      isSynced: false,
    );

    final history = await repository.fetchPersonalHistory(
      filter: const LeaderboardFilter(
        characterId: CharacterId.jano,
        mode: RunMode.progression,
        contentVersion: 'v6-preview-1',
      ),
    );

    expect(history, hasLength(1));
    expect(history.single.id, 'matching');
    expect(history.single.validation, ResultValidation.pending);
    expect(history.single.contentVersion, 'v6-preview-1');
    expect(history.single.isLocalOnly, isTrue);
  });

  test('local mode never presents pending data as a global ranking', () async {
    final page = await repository.fetchGlobalPage(
      filter: const LeaderboardFilter(
        characterId: CharacterId.jano,
        mode: RunMode.progression,
        contentVersion: 'v6-preview-1',
      ),
    );

    expect(page.entries, isEmpty);
    expect(page.nextCursor, isNull);
    expect(page.availabilityMessage, contains('Supabase'));
  });
}
