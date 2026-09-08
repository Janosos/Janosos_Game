import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/persistence/app_database.dart';
import '../../../game/domain/character_id.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/leaderboard_repository.dart';
import 'local_leaderboard_repository.dart';

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  const SupabaseLeaderboardRepository({
    required SupabaseClient client,
    required AppDatabase database,
    required AuthRepository authRepository,
    required LocalLeaderboardRepository localRepository,
  }) : _client = client,
       _authRepository = authRepository,
       _localRepository = localRepository;

  final SupabaseClient _client;
  final AuthRepository _authRepository;
  final LocalLeaderboardRepository _localRepository;

  @override
  Future<List<EndlessLeaderboardEntry>> fetchEndlessLeaderboard({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('leaderboard_endless')
          .select('user_id, display_name, character_id, score, duration_ms, updated_at')
          .order('score', ascending: false)
          .order('duration_ms', ascending: false)
          .limit(limit);

      final rows = (response as List<Object?>).cast<Map<String, Object?>>();
      final entries = <EndlessLeaderboardEntry>[];
      var position = 1;
      for (final row in rows) {
        entries.add(
          EndlessLeaderboardEntry(
            position: position++,
            userId: row['user_id'] as String,
            displayName:
                (row['display_name'] as String?)?.trim().isNotEmpty == true
                    ? row['display_name'] as String
                    : 'Jugador',
            characterId: CharacterIdSerialization.parse(
              row['character_id'] as String? ?? 'jano',
            ),
            score: (row['score'] as num?)?.toInt() ?? 0,
            durationMs: (row['duration_ms'] as num?)?.toInt() ?? 0,
            updatedAt:
                DateTime.tryParse(row['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }
      return entries;
    } catch (_) {
      return _localRepository.fetchEndlessLeaderboard(limit: limit);
    }
  }

  @override
  Future<List<BossRushLeaderboardEntry>> fetchBossRushLeaderboard({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('leaderboard_boss_rush')
          .select('user_id, display_name, completions_count, updated_at')
          .order('completions_count', ascending: false)
          .order('updated_at', ascending: true)
          .limit(limit);

      final rows = (response as List<Object?>).cast<Map<String, Object?>>();
      final entries = <BossRushLeaderboardEntry>[];
      var position = 1;
      for (final row in rows) {
        entries.add(
          BossRushLeaderboardEntry(
            position: position++,
            userId: row['user_id'] as String,
            displayName:
                (row['display_name'] as String?)?.trim().isNotEmpty == true
                    ? row['display_name'] as String
                    : 'Jugador',
            completionsCount: (row['completions_count'] as num?)?.toInt() ?? 1,
            updatedAt:
                DateTime.tryParse(row['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }
      return entries;
    } catch (_) {
      return _localRepository.fetchBossRushLeaderboard(limit: limit);
    }
  }

  @override
  Future<void> recordEndlessRun({
    required CharacterId characterId,
    required int score,
    required Duration duration,
  }) async {
    final user = _authRepository.currentSession.user;
    if (user == null || user.isGuest) return;

    // Always update local cache first
    await _localRepository.recordEndlessRun(
      characterId: characterId,
      score: score,
      duration: duration,
    );

    // Try online RPC or table upsert
    try {
      await _client.rpc('record_endless_score', params: {
        'p_character_id': characterId.serialized,
        'p_score': score,
        'p_duration_ms': duration.inMilliseconds,
      });
    } catch (_) {
      try {
        final existing = await _client
            .from('leaderboard_endless')
            .select('score')
            .eq('user_id', user.id)
            .maybeSingle();

        final currentScore = (existing?['score'] as num?)?.toInt() ?? -1;
        if (score > currentScore) {
          await _client.from('leaderboard_endless').upsert({
            'user_id': user.id,
            'display_name': user.displayName,
            'character_id': characterId.serialized,
            'score': score,
            'duration_ms': duration.inMilliseconds,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      } catch (_) {
        // Fallback recorded in localRepository
      }
    }
  }

  @override
  Future<void> recordBossRushCompletion() async {
    final user = _authRepository.currentSession.user;
    if (user == null || user.isGuest) return;

    // Always update local cache first
    await _localRepository.recordBossRushCompletion();

    // Try online RPC or table upsert
    try {
      await _client.rpc('record_boss_rush_clear');
    } catch (_) {
      try {
        final existing = await _client
            .from('leaderboard_boss_rush')
            .select('completions_count')
            .eq('user_id', user.id)
            .maybeSingle();

        final count = (existing?['completions_count'] as num?)?.toInt() ?? 0;
        await _client.from('leaderboard_boss_rush').upsert({
          'user_id': user.id,
          'display_name': user.displayName,
          'completions_count': count + 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {
        // Fallback recorded in localRepository
      }
    }
  }
}
