import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../domain/progression_models.dart';
import '../domain/progression_repository.dart';

class SupabaseProgressionRepository implements ProgressionRepository {
  const SupabaseProgressionRepository({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;
  static const _uuid = Uuid();

  @override
  Future<ProgressionSnapshot> loadSnapshot({
    required CharacterId characterId,
    required String contentVersion,
  }) async {
    try {
      final response = await _client.rpc(
        'get_progression_snapshot',
        params: {
          'p_character_id': characterId.serialized,
          'p_content_version': contentVersion,
        },
      );
      if (response is! Map) {
        throw const FormatException('Invalid progression snapshot.');
      }
      return _parseSnapshot(Map<String, Object?>.from(response));
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.unavailable,
        'No se pudo recuperar la progresión del personaje.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw AppFailure(
        AppFailureCode.configuration,
        'El catálogo recibido no coincide con esta versión del juego.',
        cause: error,
      );
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo conectar con la progresión guardada.',
        cause: error,
      );
    }
  }

  @override
  Future<void> purchaseUpgrade({
    required ProgressionSnapshot snapshot,
    required ProgressionStat stat,
  }) {
    return _invoke('purchase-upgrade', {
      'character_id': snapshot.characterId.serialized,
      'stat_id': stat.id,
      'expected_rank': stat.rank,
      'content_version': snapshot.contentVersion,
      'catalog_digest': snapshot.contentDigest,
      'idempotency_key': _uuid.v4(),
    });
  }

  @override
  Future<void> purchaseSkill({
    required ProgressionSnapshot snapshot,
    required ProgressionSkill skill,
  }) {
    return _invoke('purchase-skill', {
      'character_id': snapshot.characterId.serialized,
      'skill_id': skill.id,
      'content_version': snapshot.contentVersion,
      'catalog_digest': snapshot.contentDigest,
      'idempotency_key': _uuid.v4(),
    });
  }

  @override
  Future<void> purchasePalette({
    required ProgressionSnapshot snapshot,
    required PaletteVariant palette,
  }) {
    return _invoke('purchase-skin', {
      'character_id': snapshot.characterId.serialized,
      'skin_id': palette.id,
      'content_version': snapshot.contentVersion,
      'catalog_digest': snapshot.contentDigest,
      'idempotency_key': _uuid.v4(),
    });
  }

  @override
  Future<void> equipLoadout({
    required ProgressionSnapshot snapshot,
    required LoadoutSelection selection,
  }) {
    return _invoke('equip-loadout', {
      'character_id': snapshot.characterId.serialized,
      'active_skill_id': selection.activeSkillId,
      'passive_skill_ids': selection.passiveSkillIds,
      'skin_id': selection.skinId,
      'content_version': snapshot.contentVersion,
      'catalog_digest': snapshot.contentDigest,
      'idempotency_key': _uuid.v4(),
    });
  }

  Future<void> _invoke(String functionName, Map<String, Object?> body) async {
    try {
      final response = await _client.functions.invoke(functionName, body: body);
      final data = response.data;
      if (data is! Map || data['status'] != 'accepted') {
        throw _failureForCode(_readErrorCode(data));
      }
    } on FunctionException catch (error) {
      throw _failureForCode(_readErrorCode(error.details), cause: error);
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo sincronizar la acción. Inténtalo de nuevo.',
        cause: error,
      );
    }
  }

  static ProgressionSnapshot _parseSnapshot(Map<String, Object?> row) {
    final characterId = CharacterIdSerialization.parse(
      _requiredString(row, 'character_id'),
    );
    final buildRow = _requiredMap(row, 'authorized_build');
    final statsRow = _requiredMap(buildRow, 'stats');
    final loadoutRow = _requiredMap(buildRow, 'loadout');
    final stats = _requiredList(
      row,
      'stats',
    ).map((item) => _parseStat(_asMap(item))).toList(growable: false);
    final skills = _requiredList(row, 'skills')
        .map((item) => _parseSkill(characterId, _asMap(item)))
        .toList(growable: false);
    final palettes = _requiredList(row, 'skins')
        .map((item) => _parsePalette(characterId, _asMap(item)))
        .toList(growable: false);
    return ProgressionSnapshot(
      characterId: characterId,
      contentVersion: _requiredString(row, 'content_version'),
      contentDigest: _requiredDigest(row, 'content_digest'),
      masteryXp: _requiredInt(row, 'mastery_xp'),
      masteryLevel: _requiredInt(row, 'mastery_level'),
      nextLevelXp: _requiredInt(row, 'next_level_xp'),
      bankedCurrency: _requiredInt(row, 'banked_currency'),
      temporaryCurrency: _requiredInt(row, 'temporary_currency'),
      storeUnlocked: row['store_unlocked'] == true,
      authorizedBuild: AuthorizedBuild(
        speedBasisPoints: _requiredInt(statsRow, 'speed_basis_points'),
        jumpBasisPoints: _requiredInt(statsRow, 'jump_basis_points'),
        damageBasisPoints: _requiredInt(statsRow, 'damage_basis_points'),
        vitalityBasisPoints: _requiredInt(statsRow, 'vitality_basis_points'),
        fortuneBasisPoints: _requiredInt(statsRow, 'fortune_basis_points'),
        maxLives: _requiredInt(statsRow, 'max_lives'),
        activeSkillId: loadoutRow['active_skill_id'] as String?,
        defaultActiveId: loadoutRow['default_active'] as String?,
        passiveSkillIds: _requiredList(
          loadoutRow,
          'passive_skill_ids',
        ).map((value) => value.toString()).toList(),
        skinId: _requiredString(loadoutRow, 'skin_id'),
      ),
      stats: stats,
      skills: skills,
      palettes: palettes,
    );
  }

  static ProgressionStat _parseStat(Map<String, Object?> row) {
    return ProgressionStat(
      id: _requiredString(row, 'id'),
      displayName: _requiredString(row, 'display_name'),
      description: _requiredString(row, 'description'),
      rank: _requiredInt(row, 'rank'),
      maxRank: _requiredInt(row, 'max_rank'),
      effectiveBasisPoints: _requiredInt(row, 'effective_basis_points'),
      nextCost: _nullableInt(row['next_cost']),
      nextUnlockLevel: _nullableInt(row['next_unlock_level']),
      nextBonusBasisPoints: _nullableInt(row['next_bonus_basis_points']),
      nextBonusLives: _nullableInt(row['next_bonus_lives']) ?? 0,
    );
  }

  static ProgressionSkill _parseSkill(
    CharacterId characterId,
    Map<String, Object?> row,
  ) {
    final slot = switch (_requiredString(row, 'slot')) {
      'active' => SkillSlot.active,
      'passive' => SkillSlot.passive,
      _ => throw const FormatException('Invalid skill slot.'),
    };
    return ProgressionSkill(
      id: _requiredString(row, 'id'),
      characterId: characterId,
      slot: slot,
      displayName: _requiredString(row, 'display_name'),
      description: _requiredString(row, 'description'),
      unlockLevel: _requiredInt(row, 'unlock_level'),
      cost: _requiredInt(row, 'cost'),
      effectCode: _requiredString(row, 'effect_code'),
      effectParameters: _requiredMap(row, 'effect_parameters'),
      uiExplanation: _requiredString(row, 'ui_explanation'),
      compatibleModes: _requiredList(
        row,
        'compatible_modes',
      ).map((mode) => RunModeSerialization.parse(mode.toString())).toList(),
      owned: row['owned'] == true,
    );
  }

  static PaletteVariant _parsePalette(
    CharacterId characterId,
    Map<String, Object?> row,
  ) {
    final palette = _requiredMap(row, 'palette_parameters');
    final result = PaletteVariant(
      id: _requiredString(row, 'id'),
      characterId: characterId,
      displayName: _requiredString(row, 'display_name'),
      hueShift: _requiredInt(palette, 'hue_shift'),
      saturationBasisPoints: _requiredInt(palette, 'saturation_basis_points'),
      valueBasisPoints: _requiredInt(palette, 'value_basis_points'),
      unlockLevel: _requiredInt(row, 'unlock_level'),
      cost: _requiredInt(row, 'cost'),
      owned: row['owned'] == true,
      equipped: row['equipped'] == true,
    );
    try {
      result.transform;
    } on ArgumentError catch (error) {
      throw FormatException('Invalid palette parameters.', error);
    }
    return result;
  }

  static String? _readErrorCode(Object? details) {
    if (details is Map && details['code'] is String) {
      return details['code'] as String;
    }
    if (details is String) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map && decoded['code'] is String) {
          return decoded['code'] as String;
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static AppFailure _failureForCode(String? code, {Object? cause}) {
    final message = switch (code) {
      'store_locked' =>
        'Completa los 10 niveles con este personaje para habilitar sus compras.',
      'campaign_active' =>
        'Termina o abandona la campaña activa antes de cambiar el build.',
      'mastery_required' => 'Aún no alcanzas el nivel de maestría requerido.',
      'insufficient_currency' => 'No tienes suficiente moneda guardada.',
      'already_owned' => 'Este elemento ya pertenece al personaje.',
      'stale_catalog' =>
        'El catálogo cambió. Actualiza la pantalla antes de comprar.',
      'stale_rank' => 'El rango cambió. Revisa el nuevo precio.',
      'rank_capped' => 'Esta mejora ya alcanzó su rango máximo.',
      'active_not_owned' || 'passive_not_owned' || 'skin_not_owned' =>
        'El loadout contiene un elemento que este personaje no posee.',
      _ => 'No se pudo completar la acción económica.',
    };
    return AppFailure(
      code == 'stale_catalog' || code == 'stale_rank'
          ? AppFailureCode.conflict
          : AppFailureCode.unavailable,
      message,
      cause: cause,
    );
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) throw const FormatException('Expected an object.');
    return Map<String, Object?>.from(value);
  }

  static Map<String, Object?> _requiredMap(
    Map<String, Object?> row,
    String key,
  ) => _asMap(row[key]);

  static List<Object?> _requiredList(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! List) throw FormatException('Invalid $key.');
    return value.cast<Object?>();
  }

  static String _requiredString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key.');
    }
    return value;
  }

  static String _requiredDigest(Map<String, Object?> row, String key) {
    final value = _requiredString(row, key);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw FormatException('Invalid $key.');
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> row, String key) {
    final value = _nullableInt(row[key]);
    if (value == null) throw FormatException('Invalid $key.');
    return value;
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
