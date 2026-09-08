import '../../../game/domain/character_id.dart';
import 'leaderboard_models.dart';

abstract interface class LeaderboardRepository {
  Future<List<EndlessLeaderboardEntry>> fetchEndlessLeaderboard({
    int limit = 50,
  });

  Future<List<BossRushLeaderboardEntry>> fetchBossRushLeaderboard({
    int limit = 50,
  });

  Future<void> recordEndlessRun({
    required CharacterId characterId,
    required int score,
    required Duration duration,
  });

  Future<void> recordBossRushCompletion();
}
