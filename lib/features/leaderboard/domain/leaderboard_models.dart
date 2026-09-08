import '../../../game/domain/character_id.dart';

enum LeaderboardCategory {
  endless,
  bossRush;

  String get label => switch (this) {
    LeaderboardCategory.endless => 'MODO ENDLESS',
    LeaderboardCategory.bossRush => 'BOSS RUSH',
  };
}

enum ResultValidation { pending, verified, limited, rejected }

class EndlessLeaderboardEntry {
  const EndlessLeaderboardEntry({
    required this.position,
    required this.userId,
    required this.displayName,
    required this.characterId,
    required this.score,
    required this.durationMs,
    required this.updatedAt,
  });

  final int position;
  final String userId;
  final String displayName;
  final CharacterId characterId;
  final int score;
  final int durationMs;
  final DateTime updatedAt;
}

class BossRushLeaderboardEntry {
  const BossRushLeaderboardEntry({
    required this.position,
    required this.userId,
    required this.displayName,
    required this.completionsCount,
    required this.updatedAt,
  });

  final int position;
  final String userId;
  final String displayName;
  final int completionsCount;
  final DateTime updatedAt;
}
