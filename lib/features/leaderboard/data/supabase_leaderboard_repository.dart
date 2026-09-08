import 'dart:async';
import 'dart:developer' as developer;

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
      if (entries.isEmpty) {
        try {
          final legacyRes = await _client
              .from('leaderboard_entries')
              .select(
                'user_id, display_name, character_id, total_score, duration_ms, ended_at',
              )
              .eq('mode', 'standard')
              .order('total_score', ascending: false)
              .order('duration_ms', ascending: true)
              .limit(limit * 2);
          final legacyRows =
              (legacyRes as List<Object?>).cast<Map<String, Object?>>();
          if (legacyRows.isNotEmpty) {
            final uniqueByUser = <String, Map<String, Object?>>{};
            for (final row in legacyRows) {
              final uid = row['user_id'] as String? ?? '';
              if (uid.isNotEmpty && !uniqueByUser.containsKey(uid)) {
                uniqueByUser[uid] = row;
              }
            }
            var pos = 1;
            for (final row in uniqueByUser.values) {
              entries.add(
                EndlessLeaderboardEntry(
                  position: pos++,
                  userId: row['user_id'] as String,
                  displayName:
                      (row['display_name'] as String?)?.trim().isNotEmpty ==
                              true
                          ? row['display_name'] as String
                          : 'Jugador',
                  characterId: CharacterIdSerialization.parse(
                    row['character_id'] as String? ?? 'jano',
                  ),
                  score: (row['total_score'] as num?)?.toInt() ?? 0,
                  durationMs: (row['duration_ms'] as num?)?.toInt() ?? 0,
                  updatedAt:
                      DateTime.tryParse(row['ended_at'] as String? ?? '') ??
                      DateTime.now(),
                ),
              );
            }
          }
        } catch (_) {}
      }

      // Merge current logged-in user's local best run if not on server yet or higher
      final user = _authRepository.currentSession.user;
      if (user != null && !user.isGuest) {
        try {
          final localList =
              await _localRepository.fetchEndlessLeaderboard(limit: 10);
          final userLocal =
              localList.where((e) => e.userId == user.id).firstOrNull;
          if (userLocal != null) {
            final existingIdx = entries.indexWhere((e) => e.userId == user.id);
            if (existingIdx == -1 || userLocal.score > entries[existingIdx].score) {
              // Automatically sync unsynced local best run to online database
              unawaited(
                recordEndlessRun(
                  characterId: userLocal.characterId,
                  score: userLocal.score,
                  duration: Duration(milliseconds: userLocal.durationMs),
                ),
              );

              if (existingIdx == -1) {
                entries.add(userLocal);
              } else {
                entries[existingIdx] = userLocal;
              }
            }
            entries.sort((a, b) {
              final cmp = b.score.compareTo(a.score);
              if (cmp != 0) return cmp;
              return b.durationMs.compareTo(a.durationMs);
            });
            for (var i = 0; i < entries.length; i++) {
              entries[i] = EndlessLeaderboardEntry(
                position: i + 1,
                userId: entries[i].userId,
                displayName: entries[i].displayName,
                characterId: entries[i].characterId,
                score: entries[i].score,
                durationMs: entries[i].durationMs,
                updatedAt: entries[i].updatedAt,
              );
            }
          }
        } catch (_) {}
      }

      if (entries.isNotEmpty) {
        return entries.take(limit).toList();
      }
      return await _localRepository.fetchEndlessLeaderboard(limit: limit);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch online endless leaderboard, falling back to local',
        name: 'leaderboard',
        error: error,
        stackTrace: stackTrace,
      );
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
      // Merge current logged-in user's local boss rush clears if higher or missing
      final user = _authRepository.currentSession.user;
      if (user != null && !user.isGuest) {
        try {
          final localList =
              await _localRepository.fetchBossRushLeaderboard(limit: 10);
          final userLocal =
              localList.where((e) => e.userId == user.id).firstOrNull;
          if (userLocal != null) {
            final existingIdx = entries.indexWhere((e) => e.userId == user.id);
            if (existingIdx == -1 ||
                userLocal.completionsCount >
                    entries[existingIdx].completionsCount) {
              // Auto-sync
              unawaited(recordBossRushCompletion());

              if (existingIdx == -1) {
                entries.add(userLocal);
              } else {
                entries[existingIdx] = userLocal;
              }
            }
            entries.sort((a, b) {
              final cmp = b.completionsCount.compareTo(a.completionsCount);
              if (cmp != 0) return cmp;
              return a.updatedAt.compareTo(b.updatedAt);
            });
            for (var i = 0; i < entries.length; i++) {
              entries[i] = BossRushLeaderboardEntry(
                position: i + 1,
                userId: entries[i].userId,
                displayName: entries[i].displayName,
                completionsCount: entries[i].completionsCount,
                updatedAt: entries[i].updatedAt,
              );
            }
          }
        } catch (_) {}
      }

      if (entries.isNotEmpty) {
        return entries.take(limit).toList();
      }
      return await _localRepository.fetchBossRushLeaderboard(limit: limit);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch online boss rush leaderboard, falling back to local',
        name: 'leaderboard',
        error: error,
        stackTrace: stackTrace,
      );
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
      developer.log('record_endless_score RPC successful', name: 'leaderboard');
    } catch (error, stackTrace) {
      developer.log(
        'record_endless_score RPC failed, attempting direct upsert',
        name: 'leaderboard',
        error: error,
        stackTrace: stackTrace,
      );
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
          developer.log(
            'leaderboard_endless direct upsert successful',
            name: 'leaderboard',
          );
        }
      } catch (error2, stackTrace2) {
        developer.log(
          'leaderboard_endless direct upsert failed',
          name: 'leaderboard',
          error: error2,
          stackTrace: stackTrace2,
        );
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
      developer.log(
        'record_boss_rush_clear RPC successful',
        name: 'leaderboard',
      );
    } catch (error, stackTrace) {
      developer.log(
        'record_boss_rush_clear RPC failed, attempting direct upsert',
        name: 'leaderboard',
        error: error,
        stackTrace: stackTrace,
      );
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
        developer.log(
          'leaderboard_boss_rush direct upsert successful',
          name: 'leaderboard',
        );
      } catch (error2, stackTrace2) {
        developer.log(
          'leaderboard_boss_rush direct upsert failed',
          name: 'leaderboard',
          error: error2,
          stackTrace: stackTrace2,
        );
      }
    }
  }
}
