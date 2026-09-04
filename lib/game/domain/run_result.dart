import 'character_id.dart';
import 'run_configuration.dart';

enum RunOutcome { victory, defeat, abandoned }

class RunResult {
  const RunResult({
    required this.characterId,
    required this.mode,
    required this.outcome,
    required this.score,
    required this.duration,
    required this.levelReached,
    required this.contentVersion,
    required this.protocolVersion,
  });

  final CharacterId characterId;
  final RunMode mode;
  final RunOutcome outcome;
  final int score;
  final Duration duration;
  final int levelReached;
  final String contentVersion;
  final int protocolVersion;
}
