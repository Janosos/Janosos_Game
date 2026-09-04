import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_id.dart';
import '../../auth/domain/auth_repository.dart';

/// Persistent, account-scoped state for the fully playable local backend.
///
/// Supabase remains authoritative in cloud builds. This store mirrors the
/// single-player rules so Windows/Web local releases do not degrade the
/// campaign, economy, or Boss Rush into a catalog-only demo.
class LocalGameStateStore {
  LocalGameStateStore({
    required SharedPreferences preferences,
    required AuthRepository authRepository,
  }) : _preferences = preferences,
       _authRepository = authRepository;

  static const _schemaVersion = 1;
  static const _keyPrefix = 'janosos.v6.local_game_state.';

  final SharedPreferences _preferences;
  final AuthRepository _authRepository;
  Future<void> _tail = Future<void>.value();

  Future<T> read<T>(T Function(LocalGameState state) operation) {
    return _synchronized(() async => operation(_load()));
  }

  Future<T> mutate<T>(T Function(LocalGameState state) operation) {
    return _synchronized(() async {
      final state = _load();
      final result = operation(state);
      final saved = await _preferences.setString(
        _storageKey,
        jsonEncode(state.toJson()),
      );
      if (!saved) {
        throw const AppFailure(
          AppFailureCode.unavailable,
          'No se pudo guardar el progreso local. Inténtalo de nuevo.',
        );
      }
      return result;
    });
  }

  Future<T> _synchronized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  String get _storageKey {
    final userId = _authRepository.currentSession.user?.id;
    if (userId == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Inicia sesión para cargar tu progreso local.',
      );
    }
    return '$_keyPrefix$userId';
  }

  LocalGameState _load() {
    final encoded = _preferences.getString(_storageKey);
    if (encoded == null) return LocalGameState.empty();
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, Object?> ||
          value['version'] != _schemaVersion) {
        throw const FormatException('unsupported local state');
      }
      return LocalGameState.fromJson(value);
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.unavailable,
        'El progreso local está dañado. No se modificó para evitar perder datos.',
        cause: error,
      );
    }
  }
}

class LocalGameState {
  LocalGameState({
    required this.characters,
    required this.receipts,
    this.campaign,
    this.bossRush,
  });

  factory LocalGameState.empty() => LocalGameState(
    characters: <CharacterId, LocalCharacterProgress>{},
    receipts: <String, Map<String, Object?>>{},
  );

  factory LocalGameState.fromJson(Map<String, Object?> json) {
    final charactersJson = _stringMap(json['characters']);
    final receiptsJson = _stringMap(json['receipts']);
    return LocalGameState(
      characters: {
        for (final entry in charactersJson.entries)
          CharacterIdSerialization.parse(
            entry.key,
          ): LocalCharacterProgress.fromJson(
            _stringMap(entry.value),
            CharacterIdSerialization.parse(entry.key),
          ),
      },
      campaign: json['campaign'] == null
          ? null
          : LocalCampaignState.fromJson(_stringMap(json['campaign'])),
      bossRush: json['bossRush'] == null
          ? null
          : LocalBossRushState.fromJson(_stringMap(json['bossRush'])),
      receipts: {
        for (final entry in receiptsJson.entries)
          entry.key: Map<String, Object?>.from(_stringMap(entry.value)),
      },
    );
  }

  final Map<CharacterId, LocalCharacterProgress> characters;
  final Map<String, Map<String, Object?>> receipts;
  LocalCampaignState? campaign;
  LocalBossRushState? bossRush;

  LocalCharacterProgress character(CharacterId id) =>
      characters.putIfAbsent(id, () => LocalCharacterProgress.empty(id));

  Map<String, Object?>? receipt(String type, String idempotencyKey) =>
      receipts['$type:$idempotencyKey'];

  void saveReceipt(
    String type,
    String idempotencyKey,
    Map<String, Object?> response,
  ) {
    receipts['$type:$idempotencyKey'] = Map<String, Object?>.from(response);
    while (receipts.length > 100) {
      receipts.remove(receipts.keys.first);
    }
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'characters': {
      for (final entry in characters.entries)
        entry.key.serialized: entry.value.toJson(),
    },
    'campaign': campaign?.toJson(),
    'bossRush': bossRush?.toJson(),
    'receipts': receipts,
  };
}

class LocalCharacterProgress {
  LocalCharacterProgress({
    required this.statRanks,
    required this.ownedSkillIds,
    required this.ownedPaletteIds,
    required this.passiveSkillIds,
    required this.uniqueRewardIds,
    required this.equippedPaletteId,
    this.masteryXp = 0,
    this.bankedCurrency = 0,
    this.storeUnlocked = false,
    this.activeSkillId,
  });

  factory LocalCharacterProgress.empty(CharacterId characterId) =>
      LocalCharacterProgress(
        statRanks: {
          'speed': 0,
          'jump': 0,
          'damage': 0,
          'vitality': 0,
          'fortune': 0,
        },
        ownedSkillIds: <String>{},
        ownedPaletteIds: {'${characterId.serialized}_default'},
        passiveSkillIds: <String>[],
        uniqueRewardIds: <String>{},
        equippedPaletteId: '${characterId.serialized}_default',
      );

  factory LocalCharacterProgress.fromJson(
    Map<String, Object?> json,
    CharacterId characterId,
  ) {
    final empty = LocalCharacterProgress.empty(characterId);
    final rankJson = _stringMap(json['statRanks']);
    for (final id in empty.statRanks.keys) {
      empty.statRanks[id] = _integer(rankJson[id]);
    }
    empty.masteryXp = _integer(json['masteryXp']);
    empty.bankedCurrency = _integer(json['bankedCurrency']);
    empty.storeUnlocked = json['storeUnlocked'] == true;
    empty.ownedSkillIds.addAll(_stringList(json['ownedSkillIds']));
    empty.ownedPaletteIds.addAll(_stringList(json['ownedPaletteIds']));
    empty.passiveSkillIds
      ..clear()
      ..addAll(_stringList(json['passiveSkillIds']));
    empty.uniqueRewardIds.addAll(_stringList(json['uniqueRewardIds']));
    empty.activeSkillId = _nullableString(json['activeSkillId']);
    empty.equippedPaletteId =
        _nullableString(json['equippedPaletteId']) ??
        '${characterId.serialized}_default';
    return empty;
  }

  int masteryXp;
  int bankedCurrency;
  bool storeUnlocked;
  final Map<String, int> statRanks;
  final Set<String> ownedSkillIds;
  final Set<String> ownedPaletteIds;
  String? activeSkillId;
  final List<String> passiveSkillIds;
  String equippedPaletteId;
  final Set<String> uniqueRewardIds;

  Map<String, Object?> toJson() => {
    'masteryXp': masteryXp,
    'bankedCurrency': bankedCurrency,
    'storeUnlocked': storeUnlocked,
    'statRanks': statRanks,
    'ownedSkillIds': ownedSkillIds.toList()..sort(),
    'ownedPaletteIds': ownedPaletteIds.toList()..sort(),
    'activeSkillId': activeSkillId,
    'passiveSkillIds': passiveSkillIds,
    'equippedPaletteId': equippedPaletteId,
    'uniqueRewardIds': uniqueRewardIds.toList()..sort(),
  };
}

class LocalCampaignState {
  LocalCampaignState({
    required this.id,
    required this.characterId,
    required this.level,
    required this.expectedSequence,
    required this.temporaryCurrency,
    required this.totalScore,
    required this.totalDurationMs,
    required this.startedAt,
  });

  factory LocalCampaignState.fromJson(Map<String, Object?> json) =>
      LocalCampaignState(
        id: json['id'] as String,
        characterId: CharacterIdSerialization.parse(
          json['characterId'] as String,
        ),
        level: _integer(json['level']),
        expectedSequence: _integer(json['expectedSequence']),
        temporaryCurrency: _integer(json['temporaryCurrency']),
        totalScore: _integer(json['totalScore']),
        totalDurationMs: _integer(json['totalDurationMs']),
        startedAt: DateTime.parse(json['startedAt'] as String),
      );

  final String id;
  final CharacterId characterId;
  int level;
  int expectedSequence;
  int temporaryCurrency;
  int totalScore;
  int totalDurationMs;
  final DateTime startedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'characterId': characterId.serialized,
    'level': level,
    'expectedSequence': expectedSequence,
    'temporaryCurrency': temporaryCurrency,
    'totalScore': totalScore,
    'totalDurationMs': totalDurationMs,
    'startedAt': startedAt.toIso8601String(),
  };
}

class LocalBossRushState {
  LocalBossRushState({required this.id, required this.characterId});

  factory LocalBossRushState.fromJson(Map<String, Object?> json) =>
      LocalBossRushState(
        id: json['id'] as String,
        characterId: CharacterIdSerialization.parse(
          json['characterId'] as String,
        ),
      );

  final String id;
  final CharacterId characterId;

  Map<String, Object?> toJson() => {
    'id': id,
    'characterId': characterId.serialized,
  };
}

Map<String, Object?> _stringMap(Object? value) {
  if (value is! Map) return <String, Object?>{};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<String> _stringList(Object? value) => value is List
    ? value.whereType<String>().toList(growable: false)
    : const <String>[];

String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int _integer(Object? value) => value is num ? value.toInt() : 0;
