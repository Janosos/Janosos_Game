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
    final userId = _authRepository.currentSession.user?.id;
    if (userId != null) {
      final rows = await _database.personalResultHistory(
        userId: userId,
        characterId: filter.characterId.serialized,
        mode: filter.mode.serialized,
        limit: 100,
      );
      if (rows.isNotEmpty) {
        final sorted = [...rows]..sort((a, b) => b.score.compareTo(a.score));
        final paged = sorted.take(pageSize).toList();
        final entries = <LeaderboardEntry>[];
        for (var i = 0; i < paged.length; i++) {
          final row = paged[i];
          entries.add(
            LeaderboardEntry(
              id: row.id,
              position: i + 1,
              displayName:
                  _authRepository.currentSession.user?.displayName ?? 'Jugador',
              characterId: filter.characterId,
              mode: filter.mode,
              completed: row.outcome == 'victory',
              levelReached: row.levelReached,
              totalScore: row.score,
              durationMs: row.durationMs,
              endedAt: row.endedAt,
              contentVersion: row.contentVersion,
            ),
          );
        }
        return LeaderboardPage(
          entries: entries,
          nextCursor: null,
          availabilityMessage:
              'Modo Local: mostrando mejores puntuaciones de este dispositivo.',
        );
      }
    }
    return const LeaderboardPage(
      entries: [],
      nextCursor: null,
      availabilityMessage:
          'El ranking global requiere iniciar sesión con una cuenta. '
          'Tus partidas locales se registrarán aquí automáticamente.',
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
