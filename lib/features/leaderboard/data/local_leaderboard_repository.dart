import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/app_database.dart';
import '../../../game/domain/character_id.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/leaderboard_models.dart';
import '../domain/leaderboard_repository.dart';

class LocalLeaderboardRepository implements LeaderboardRepository {
  LocalLeaderboardRepository({
    required AppDatabase database,
    required AuthRepository authRepository,
    SharedPreferences? preferences,
  }) : _database = database,
       _authRepository = authRepository,
       _preferences = preferences;

  final AppDatabase _database;
  final AuthRepository _authRepository;
  final SharedPreferences? _preferences;

  static const _endlessKey = 'janosos.leaderboard.v6.endless';
  static const _bossRushKey = 'janosos.leaderboard.v6.boss_rush';

  // In-memory cache in case SharedPreferences is null in tests
  final Map<String, Map<String, Object?>> _memoryEndless = {};
  final Map<String, Map<String, Object?>> _memoryBossRush = {};

  @override
  Future<List<EndlessLeaderboardEntry>> fetchEndlessLeaderboard({
    int limit = 50,
  }) async {
    final raw = _loadMap(_endlessKey, _memoryEndless);

    // Auto-migrate historical scores from local SQLite database if cache is empty
    if (raw.isEmpty) {
      try {
        final allProjections =
            await _database.select(_database.resultProjections).get();
        final currentUser = _authRepository.currentSession.user;
        for (final p in allProjections) {
          if (p.mode == 'standard' || p.mode == 'endless') {
            final existing = raw[p.userId];
            final existingScore = (existing?['score'] as num?)?.toInt() ?? -1;
            if (p.score > existingScore) {
              final dName = (p.userId == currentUser?.id && currentUser != null)
                  ? currentUser.displayName
                  : 'Jugador';
              raw[p.userId] = {
                'display_name': dName,
                'character_id': p.characterId,
                'score': p.score,
                'duration_ms': p.durationMs,
                'updated_at': p.endedAt.toIso8601String(),
              };
            }
          }
        }
        if (raw.isNotEmpty) {
          _saveMap(_endlessKey, raw, _memoryEndless);
        }
      } catch (_) {}
    }
    final list = <EndlessLeaderboardEntry>[];
    for (final entry in raw.entries) {
      final map = entry.value;
      try {
        list.add(
          EndlessLeaderboardEntry(
            position: 0,
            userId: entry.key,
            displayName: (map['display_name'] as String?)?.trim().isNotEmpty ==
                    true
                ? map['display_name'] as String
                : 'Jugador',
            characterId: CharacterIdSerialization.parse(
              map['character_id'] as String? ?? 'jano',
            ),
            score: (map['score'] as num?)?.toInt() ?? 0,
            durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
            updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      } catch (_) {}
    }

    list.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return b.durationMs.compareTo(a.durationMs);
    });

    final paged = list.take(limit).toList();
    for (var i = 0; i < paged.length; i++) {
      paged[i] = EndlessLeaderboardEntry(
        position: i + 1,
        userId: paged[i].userId,
        displayName: paged[i].displayName,
        characterId: paged[i].characterId,
        score: paged[i].score,
        durationMs: paged[i].durationMs,
        updatedAt: paged[i].updatedAt,
      );
    }
    return paged;
  }

  @override
  Future<List<BossRushLeaderboardEntry>> fetchBossRushLeaderboard({
    int limit = 50,
  }) async {
    final raw = _loadMap(_bossRushKey, _memoryBossRush);

    // Auto-migrate historical boss rush clears from local SQLite database if cache is empty
    if (raw.isEmpty) {
      try {
        final allProjections =
            await _database.select(_database.resultProjections).get();
        final currentUser = _authRepository.currentSession.user;
        final countByUser = <String, int>{};
        final lastEndedByUser = <String, DateTime>{};
        for (final p in allProjections) {
          if (p.mode == 'boss_rush' && p.outcome == 'victory') {
            countByUser[p.userId] = (countByUser[p.userId] ?? 0) + 1;
            final prev = lastEndedByUser[p.userId];
            if (prev == null || p.endedAt.isAfter(prev)) {
              lastEndedByUser[p.userId] = p.endedAt;
            }
          }
        }
        for (final entry in countByUser.entries) {
          final uid = entry.key;
          final dName = (uid == currentUser?.id && currentUser != null)
              ? currentUser.displayName
              : 'Jugador';
          raw[uid] = {
            'display_name': dName,
            'completions_count': entry.value,
            'updated_at':
                (lastEndedByUser[uid] ?? DateTime.now()).toIso8601String(),
          };
        }
        if (raw.isNotEmpty) {
          _saveMap(_bossRushKey, raw, _memoryBossRush);
        }
      } catch (_) {}
    }
    final list = <BossRushLeaderboardEntry>[];
    for (final entry in raw.entries) {
      final map = entry.value;
      try {
        list.add(
          BossRushLeaderboardEntry(
            position: 0,
            userId: entry.key,
            displayName: (map['display_name'] as String?)?.trim().isNotEmpty ==
                    true
                ? map['display_name'] as String
                : 'Jugador',
            completionsCount: (map['completions_count'] as num?)?.toInt() ?? 1,
            updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      } catch (_) {}
    }

    list.sort((a, b) {
      final countCmp = b.completionsCount.compareTo(a.completionsCount);
      if (countCmp != 0) return countCmp;
      return a.updatedAt.compareTo(b.updatedAt);
    });

    final paged = list.take(limit).toList();
    for (var i = 0; i < paged.length; i++) {
      paged[i] = BossRushLeaderboardEntry(
        position: i + 1,
        userId: paged[i].userId,
        displayName: paged[i].displayName,
        completionsCount: paged[i].completionsCount,
        updatedAt: paged[i].updatedAt,
      );
    }
    return paged;
  }

  @override
  Future<void> recordEndlessRun({
    required CharacterId characterId,
    required int score,
    required Duration duration,
  }) async {
    final user = _authRepository.currentSession.user;
    if (user == null || user.isGuest) return;

    final map = _loadMap(_endlessKey, _memoryEndless);
    final existing = map[user.id];
    final currentScore = (existing?['score'] as num?)?.toInt() ?? -1;

    if (score > currentScore) {
      map[user.id] = {
        'display_name': user.displayName,
        'character_id': characterId.serialized,
        'score': score,
        'duration_ms': duration.inMilliseconds,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _saveMap(_endlessKey, map, _memoryEndless);
    }
  }

  @override
  Future<void> recordBossRushCompletion() async {
    final user = _authRepository.currentSession.user;
    if (user == null || user.isGuest) return;

    final map = _loadMap(_bossRushKey, _memoryBossRush);
    final existing = map[user.id];
    final currentCount =
        (existing?['completions_count'] as num?)?.toInt() ?? 0;

    map[user.id] = {
      'display_name': user.displayName,
      'completions_count': currentCount + 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _saveMap(_bossRushKey, map, _memoryBossRush);
  }

  Map<String, Map<String, Object?>> _loadMap(
    String key,
    Map<String, Map<String, Object?>> fallback,
  ) {
    final prefs = _preferences;
    if (prefs == null) return Map.from(fallback);
    final str = prefs.getString(key);
    if (str == null) return Map.from(fallback);
    try {
      final decoded = jsonDecode(str) as Map;
      return decoded.map(
        (k, v) => MapEntry(
          k.toString(),
          Map<String, Object?>.from(v as Map),
        ),
      );
    } catch (_) {
      return Map.from(fallback);
    }
  }

  Future<void> _saveMap(
    String key,
    Map<String, Map<String, Object?>> data,
    Map<String, Map<String, Object?>> fallback,
  ) async {
    fallback.clear();
    fallback.addAll(data);
    final prefs = _preferences;
    if (prefs != null) {
      await prefs.setString(key, jsonEncode(data));
    }
  }
}
