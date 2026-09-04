import 'leaderboard_models.dart';

abstract interface class LeaderboardRepository {
  Future<LeaderboardPage> fetchGlobalPage({
    required LeaderboardFilter filter,
    LeaderboardCursor? after,
    int pageSize = 25,
  });

  Future<List<RunHistoryEntry>> fetchPersonalHistory({
    required LeaderboardFilter filter,
    int limit = 100,
  });
}
