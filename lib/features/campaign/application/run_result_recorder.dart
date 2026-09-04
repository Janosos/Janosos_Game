import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/persistence/app_database.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../../../game/domain/run_result.dart';
import '../../auth/domain/auth_repository.dart';

class RunResultRecorder {
  const RunResultRecorder({
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _database = database,
       _authRepository = authRepository;

  static const _uuid = Uuid();

  final AppDatabase _database;
  final AuthRepository _authRepository;

  Future<String> sealPending(RunResult result) async {
    return save(result, validationStatus: 'pending', isSynced: false);
  }

  Future<String> save(
    RunResult result, {
    String? id,
    required String validationStatus,
    required bool isSynced,
  }) async {
    final userId = _authRepository.currentSession.user?.id;
    if (userId == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Inicia sesión para guardar el resultado.',
      );
    }
    final resultId = id ?? _uuid.v4();
    await _database.saveResultProjection(
      id: resultId,
      userId: userId,
      characterId: result.characterId.serialized,
      mode: result.mode.serialized,
      outcome: result.outcome.name,
      validationStatus: validationStatus,
      contentVersion: result.contentVersion,
      score: result.score,
      durationMs: result.duration.inMilliseconds,
      levelReached: result.levelReached,
      endedAt: DateTime.now().toUtc(),
      isSynced: isSynced,
    );
    return resultId;
  }
}
