import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/features/leaderboard/data/local_leaderboard_repository.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late AppDatabase database;
  late FakeAuthRepository authRepository;
  late LocalLeaderboardRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    authRepository = FakeAuthRepository.signedIn(
      userId: 'user-a',
      displayName: 'Player A',
    );
    repository = LocalLeaderboardRepository(
      database: database,
      authRepository: authRepository,
    );
  });

  tearDown(() async {
    await database.close();
    await authRepository.dispose();
  });

  test('endless keeps single record per user and updates on higher score', () async {
    // 1st run
    await repository.recordEndlessRun(
      characterId: CharacterId.jano,
      score: 500,
      duration: const Duration(seconds: 45),
    );

    var endless = await repository.fetchEndlessLeaderboard();
    expect(endless, hasLength(1));
    expect(endless.first.displayName, 'Player A');
    expect(endless.first.score, 500);
    expect(endless.first.characterId, CharacterId.jano);

    // 2nd run with LOWER score - should not decrease
    await repository.recordEndlessRun(
      characterId: CharacterId.parker,
      score: 300,
      duration: const Duration(seconds: 20),
    );

    endless = await repository.fetchEndlessLeaderboard();
    expect(endless, hasLength(1)); // Still only 1 record, no duplicates!
    expect(endless.first.score, 500);
    expect(endless.first.characterId, CharacterId.jano);

    // 3rd run with HIGHER score - should update record
    await repository.recordEndlessRun(
      characterId: CharacterId.chema,
      score: 1200,
      duration: const Duration(seconds: 90),
    );

    endless = await repository.fetchEndlessLeaderboard();
    expect(endless, hasLength(1)); // Still only 1 record
    expect(endless.first.score, 1200);
    expect(endless.first.characterId, CharacterId.chema);
    expect(endless.first.durationMs, 90000);
  });

  test('boss rush increments completions without duplicate records', () async {
    // 1st clear
    await repository.recordBossRushCompletion();

    var bossRush = await repository.fetchBossRushLeaderboard();
    expect(bossRush, hasLength(1));
    expect(bossRush.first.displayName, 'Player A');
    expect(bossRush.first.completionsCount, 1);

    // 2nd clear tomorrow
    await repository.recordBossRushCompletion();

    bossRush = await repository.fetchBossRushLeaderboard();
    expect(bossRush, hasLength(1)); // Still only 1 record for this player
    expect(bossRush.first.completionsCount, 2);

    // 3rd clear
    await repository.recordBossRushCompletion();

    bossRush = await repository.fetchBossRushLeaderboard();
    expect(bossRush, hasLength(1));
    expect(bossRush.first.completionsCount, 3);
  });
}
