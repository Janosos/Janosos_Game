import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/persistence/app_database.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/leaderboard_repository.dart';

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  const SupabaseLeaderboardRepository({
    required SupabaseClient client,
    required AppDatabase database,
    required AuthRepository authRepository,
  }) : _client = client,
       _database = database,
       _authRepository = authRepository;

  final SupabaseClient _client;
  final AppDatabase _database;
  final AuthRepository _authRepository;

  @override
  Future<LeaderboardPage> fetchGlobalPage({
    required LeaderboardFilter filter,
    LeaderboardCursor? after,
    int pageSize = 25,
  }) async {
    try {
      final parameters = <String, Object?>{
        'p_character_id': filter.characterId.serialized,
        'p_mode': filter.mode.serialized,
        'p_content_version': filter.contentVersion,
        'p_limit': pageSize.clamp(1, 25),
      };
      if (after != null) {
        parameters.addAll({
          'p_after_completed': after.completed,
          'p_after_level': after.levelReached,
          'p_after_score': after.totalScore,
          'p_after_duration_ms': after.durationMs,
          'p_after_ended_at': after.endedAt.toUtc().toIso8601String(),
          'p_after_id': after.id,
        });
      }
      final response = await _client.rpc(
        'get_leaderboard_page',
        params: parameters,
      );
      final rows = (response as List<Object?>).cast<Map<String, Object?>>();
      final entries = rows.map(_parseLeaderboardEntry).toList(growable: false);
      return LeaderboardPage(
        entries: entries,
        nextCursor: entries.length == pageSize && entries.last.position < 100
            ? entries.last.cursor
            : null,
      );
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.unavailable,
        'No se pudo cargar la clasificación verificada.',
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo conectar al leaderboard.',
        cause: error,
      );
    }
  }

  @override
  Future<List<RunHistoryEntry>> fetchPersonalHistory({
    required LeaderboardFilter filter,
    int limit = 100,
  }) async {
    final userId = _authRepository.currentSession.user?.id;
    final localRows = userId == null
        ? const <ResultProjection>[]
        : await _database.personalResultHistory(
            userId: userId,
            characterId: filter.characterId.serialized,
            mode: filter.mode.serialized,
            limit: limit,
          );
    final localEntries = localRows.map(_parseLocalHistoryEntry).toList();
    try {
      final response = await _client.rpc(
        'get_personal_history',
        params: <String, Object?>{
          'p_character_id': filter.characterId.serialized,
          'p_mode': filter.mode.serialized,
          'p_content_version': filter.contentVersion,
          'p_limit': limit.clamp(1, 100),
        },
      );
      final rows = (response as List<Object?>).cast<Map<String, Object?>>();
      final serverEntries = rows.map(_parseHistoryEntry);
      final merged = <RunHistoryEntry>[...serverEntries, ...localEntries]
        ..sort((left, right) => right.endedAt.compareTo(left.endedAt));
      return merged.take(limit.clamp(1, 100)).toList(growable: false);
    } on PostgrestException catch (error) {
      if (localEntries.isNotEmpty) {
        return localEntries;
      }
      throw AppFailure(
        AppFailureCode.unavailable,
        'No se pudo cargar tu historial de partidas.',
        cause: error,
      );
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo conectar para recuperar tu historial.',
        cause: error,
      );
    }
  }

  static LeaderboardEntry _parseLeaderboardEntry(Map<String, Object?> row) {
    return LeaderboardEntry(
      position: _readInt(row, 'position'),
      id: _readString(row, 'id'),
      displayName: _readString(row, 'display_name'),
      characterId: CharacterIdSerialization.parse(
        _readString(row, 'character_id'),
      ),
      mode: RunModeSerialization.parse(_readString(row, 'mode')),
      contentVersion: _readString(row, 'content_version'),
      completed: row['completed'] == true,
      levelReached: _readInt(row, 'level_reached'),
      totalScore: _readInt(row, 'total_score'),
      durationMs: _readInt(row, 'duration_ms'),
      endedAt: DateTime.parse(_readString(row, 'ended_at')).toUtc(),
    );
  }

  static RunHistoryEntry _parseHistoryEntry(Map<String, Object?> row) {
    final outcome = _parseOutcome(_readString(row, 'outcome'));
    return RunHistoryEntry(
      id: _readString(row, 'id'),
      characterId: CharacterIdSerialization.parse(
        _readString(row, 'character_id'),
      ),
      mode: RunModeSerialization.parse(_readString(row, 'mode')),
      outcome: outcome,
      validation: _parseValidation(_readString(row, 'validation')),
      completed: row['completed'] == true,
      levelReached: _readInt(row, 'level_reached'),
      totalScore: _readInt(row, 'total_score'),
      durationMs: _readInt(row, 'duration_ms'),
      endedAt: DateTime.parse(_readString(row, 'ended_at')).toUtc(),
      contentVersion: _readString(row, 'content_version'),
      rejectionCode: row['rejection_code'] as String?,
    );
  }

  static RunHistoryEntry _parseLocalHistoryEntry(ResultProjection row) {
    return RunHistoryEntry(
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
    );
  }

  static int _readInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }

  static String _readString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key in leaderboard response.');
    }
    return value;
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
