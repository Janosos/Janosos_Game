import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';

enum ResultValidation { pending, verified, limited, rejected }

enum HistoryOutcome { victory, defeat, abandoned }

class LeaderboardFilter {
  const LeaderboardFilter({
    required this.characterId,
    required this.mode,
    required this.contentVersion,
  });

  final CharacterId characterId;
  final RunMode mode;
  final String contentVersion;

  LeaderboardFilter copyWith({
    CharacterId? characterId,
    RunMode? mode,
    String? contentVersion,
  }) {
    return LeaderboardFilter(
      characterId: characterId ?? this.characterId,
      mode: mode ?? this.mode,
      contentVersion: contentVersion ?? this.contentVersion,
    );
  }
}

class LeaderboardCursor {
  const LeaderboardCursor({
    required this.completed,
    required this.levelReached,
    required this.totalScore,
    required this.durationMs,
    required this.endedAt,
    required this.id,
  });

  final bool completed;
  final int levelReached;
  final int totalScore;
  final int durationMs;
  final DateTime endedAt;
  final String id;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.position,
    required this.id,
    required this.displayName,
    required this.characterId,
    required this.mode,
    required this.contentVersion,
    required this.completed,
    required this.levelReached,
    required this.totalScore,
    required this.durationMs,
    required this.endedAt,
  });

  final int position;
  final String id;
  final String displayName;
  final CharacterId characterId;
  final RunMode mode;
  final String contentVersion;
  final bool completed;
  final int levelReached;
  final int totalScore;
  final int durationMs;
  final DateTime endedAt;

  LeaderboardCursor get cursor => LeaderboardCursor(
    completed: completed,
    levelReached: levelReached,
    totalScore: totalScore,
    durationMs: durationMs,
    endedAt: endedAt,
    id: id,
  );
}

class RunHistoryEntry {
  const RunHistoryEntry({
    required this.id,
    required this.characterId,
    required this.mode,
    required this.outcome,
    required this.validation,
    required this.completed,
    required this.levelReached,
    required this.totalScore,
    required this.durationMs,
    required this.endedAt,
    required this.contentVersion,
    this.rejectionCode,
    this.isLocalOnly = false,
  });

  final String id;
  final CharacterId characterId;
  final RunMode mode;
  final HistoryOutcome outcome;
  final ResultValidation validation;
  final bool completed;
  final int levelReached;
  final int totalScore;
  final int durationMs;
  final DateTime endedAt;
  final String contentVersion;
  final String? rejectionCode;
  final bool isLocalOnly;
}

class LeaderboardPage {
  const LeaderboardPage({
    required this.entries,
    required this.nextCursor,
    this.availabilityMessage,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardCursor? nextCursor;
  final String? availabilityMessage;
}

extension ResultValidationPresentation on ResultValidation {
  String get label => switch (this) {
    ResultValidation.pending => 'Pendiente',
    ResultValidation.verified => 'Verificado',
    ResultValidation.limited => 'Limitado',
    ResultValidation.rejected => 'Rechazado',
  };

  String get explanation => switch (this) {
    ResultValidation.pending =>
      'Guardado en este dispositivo; todavía no aparece en el ranking global.',
    ResultValidation.verified =>
      'El servidor aceptó este resultado y puede clasificarlo.',
    ResultValidation.limited =>
      'El servidor aceptó parte del progreso, pero no lo publica globalmente.',
    ResultValidation.rejected =>
      'El servidor no pudo aceptar el resultado; no otorgó recompensas.',
  };
}

extension HistoryOutcomePresentation on HistoryOutcome {
  String get label => switch (this) {
    HistoryOutcome.victory => 'Completada',
    HistoryOutcome.defeat => 'Fallida',
    HistoryOutcome.abandoned => 'Abandonada',
  };
}
