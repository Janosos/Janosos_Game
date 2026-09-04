import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/run_configuration.dart';
import '../domain/boss_rush_repository.dart';

class SupabaseBossRushRepository implements BossRushRepository {
  const SupabaseBossRushRepository({required SupabaseClient client})
    : _client = client;

  static const _uuid = Uuid();
  final SupabaseClient _client;

  @override
  Future<BossRushSession> start(RunConfiguration configuration) async {
    final loadoutDigest = await _digest(_loadout(configuration));
    final attempt = await _invoke('start-boss-rush', {
      'character_id': configuration.characterId.serialized,
      'content_version': configuration.contentVersion,
      'protocol_version': configuration.protocolVersion,
      'loadout_digest': loadoutDigest,
      'idempotency_key': _uuid.v4(),
    });
    final campaignId = _string(attempt, 'campaign_id');
    final configurationDigest = await _digest(_configuration(configuration));
    final stage = await _invoke('start-stage', {
      'campaign_id': campaignId,
      'configuration_digest': configurationDigest,
      'idempotency_key': _uuid.v4(),
    });
    final expiresAt = DateTime.parse(_string(stage, 'expires_at')).toUtc();
    return BossRushSession(
      eligibility: BossRushEligibility.verified,
      configuration: configuration.copyWith(stageExpiresAt: expiresAt),
      campaignId: campaignId,
      attemptToken: _string(stage, 'stage_token'),
      expiresAt: expiresAt,
    );
  }

  @override
  Future<BossRushFinishReceipt> finish(Map<String, Object?> payload) async {
    final data = await _invoke('finish-boss-rush', payload);
    return BossRushFinishReceipt(
      accepted: data['status'] == 'accepted',
      ranked: data['ranked'] == true,
      masteryXpGranted: _integer(data['mastery_xp_granted']),
      bossesDefeated: _integer(data['bosses_defeated']),
      uniqueRewardsGranted:
          (data['unique_rewards_granted'] as List? ?? const [])
              .map((value) => value.toString())
              .toList(growable: false),
    );
  }

  @override
  Future<void> abandon(BossRushSession session) async {
    final campaignId = session.campaignId;
    if (campaignId == null) return;
    await _invoke('fail-campaign', {
      'campaign_id': campaignId,
      'idempotency_key': _uuid.v4(),
    });
  }

  @override
  Future<void> fail(Map<String, Object?> payload) async {
    await _invoke('fail-campaign', payload);
  }

  Future<Map<String, Object?>> _invoke(
    String name,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _client.functions.invoke(name, body: body);
      if (response.data is! Map) throw const FormatException('Invalid result');
      final data = Map<String, Object?>.from(response.data as Map);
      if (response.status < 200 ||
          response.status >= 300 ||
          data['status'] != 'accepted') {
        throw AppFailure(AppFailureCode.conflict, switch (data['code']) {
          'boss_rush_locked' =>
            'Completa los diez niveles con este personaje para desbloquear Boss Rush.',
          'campaign_active' =>
            'Termina o abandona la campaña activa antes de iniciar Boss Rush.',
          _ => 'No se pudo autorizar Boss Rush.',
        });
      }
      return data;
    } on AppFailure {
      rethrow;
    } on FunctionException catch (error) {
      throw AppFailure(
        error.status == 409 ? AppFailureCode.conflict : AppFailureCode.network,
        'No se pudo confirmar Boss Rush con el servidor.',
        cause: error,
      );
    }
  }

  static Map<String, Object?> _configuration(RunConfiguration value) => {
    'character_id': value.characterId.serialized,
    'mode': value.mode.serialized,
    'stats': {
      'speed_multiplier': value.stats.speedMultiplier,
      'jump_multiplier': value.stats.jumpMultiplier,
      'damage_multiplier': value.stats.damageMultiplier,
      'fortune_multiplier': value.stats.fortuneMultiplier,
      'max_lives': value.stats.maxLives,
    },
    'loadout': _loadout(value),
    'palette': {
      'hue_shift': value.palette.hueShift,
      'saturation_basis_points': value.palette.saturationBasisPoints,
      'value_basis_points': value.palette.valueBasisPoints,
    },
    'level': value.level,
    'content_version': value.contentVersion,
    'protocol_version': value.protocolVersion,
    'seed': value.seed,
  };

  static Map<String, Object?> _loadout(RunConfiguration value) => {
    'active_ability': value.loadout.activeAbility?.name,
    'active_skill_id': value.loadout.activeSkillId,
    'passive_skill_ids': value.loadout.passiveSkillIds,
    'skill_effects': [
      for (final effect in value.loadout.skillEffects)
        {
          'skill_id': effect.skillId,
          'effect_code': effect.effectCode,
          'parameters': effect.parameters,
        },
    ],
  };

  static Future<String> _digest(Object? payload) async {
    final hash = await Sha256().hash(utf8.encode(_canonicalJson(payload)));
    return hash.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    if (value is List) return '[${value.map(_canonicalJson).join(',')}]';
    return jsonEncode(value);
  }

  static String _string(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static int _integer(Object? value) => switch (value) {
    num number => number.toInt(),
    String string => int.parse(string),
    _ => 0,
  };
}
