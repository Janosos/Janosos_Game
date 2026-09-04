import 'package:dino_run_flame/core/persistence/app_database.dart';
import 'package:dino_run_flame/features/campaign/application/run_result_recorder.dart';
import 'package:dino_run_flame/features/leaderboard/domain/leaderboard_models.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:dino_run_flame/game/domain/run_result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  test(
    'terminal fixture result is sealed pending before any publication',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final authRepository = FakeAuthRepository.signedIn(userId: 'user-a');
      addTearDown(database.close);
      addTearDown(authRepository.dispose);
      final recorder = RunResultRecorder(
        database: database,
        authRepository: authRepository,
      );

      final id = await recorder.sealPending(
        const RunResult(
          characterId: CharacterId.chema,
          mode: RunMode.progression,
          outcome: RunOutcome.defeat,
          score: 321,
          duration: Duration(seconds: 12),
          levelReached: 1,
          contentVersion: 'v6-preview-1',
          protocolVersion: 1,
        ),
      );

      final rows = await database.personalResultHistory(
        userId: 'user-a',
        characterId: 'chema',
        mode: 'progression',
      );
      expect(id, isNotEmpty);
      expect(rows, hasLength(1));
      expect(rows.single.validationStatus, ResultValidation.pending.name);
      expect(rows.single.isSynced, isFalse);
      expect(rows.single.contentVersion, 'v6-preview-1');
      expect(rows.single.score, 321);
      expect(rows.single.durationMs, 12000);
    },
  );
}
