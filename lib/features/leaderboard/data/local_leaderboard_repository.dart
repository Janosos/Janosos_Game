import '../../../core/persistence/app_database.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/leaderboard_repository.dart';

class LocalLeaderboardRepository implements LeaderboardRepository {
  const LocalLeaderboardRepository({
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _database = database,
       _authRepository = authRepository;

  final AppDatabase _database;
  final AuthRepository _authRepository;

  @override
  Future<LeaderboardPage> fetchGlobalPage({
    required LeaderboardFilter filter,
    LeaderboardCursor? after,
    int pageSize = 25,
  }) async {
    return const LeaderboardPage(
      entries: [],
      nextCursor: null,
      availabilityMessage:
          'El ranking global requiere el backend de Supabase. '
          'Tus partidas locales siguen disponibles en Historial.',
    );
  }

  @override
  Future<List<RunHistoryEntry>> fetchPersonalHistory({
    required LeaderboardFilter filter,
    int limit = 100,
  }) async {
    final userId = _authRepository.currentSession.user?.id;
    if (userId == null) {
      return const [];
    }
    final rows = await _database.personalResultHistory(
      userId: userId,
      characterId: filter.characterId.serialized,
      mode: filter.mode.serialized,
      limit: limit,
    );
    return [
      for (final row in rows)
        RunHistoryEntry(
          id: row.id,
          characterId: CharacterIdSerialization.parse(row.characterId),
          mode: RunModeSerialization.parse(row.mode),
          outcome: _parseOutcome(row.outcome),
          validation: _parseValidation(row.validationStatus),
          completed: row.outcome == 'victory',
          levelReached: row.levelReached,
          totalScore: row.score,
          durationMs: row.durationMs,
          endedAt: row.endedAt,
          contentVersion: row.contentVersion,
          isLocalOnly: true,
        ),
    ];
  }

  static HistoryOutcome _parseOutcome(String value) => switch (value) {
    'victory' => HistoryOutcome.victory,
    'defeat' => HistoryOutcome.defeat,
    _ => HistoryOutcome.abandoned,
  };

  static ResultValidation _parseValidation(String value) => switch (value) {
    'verified' => ResultValidation.verified,
    'limited' => ResultValidation.limited,
    'rejected' => ResultValidation.rejected,
    _ => ResultValidation.pending,
  };
}
