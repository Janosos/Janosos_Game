import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/security/protected_store.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';
import '../../../game/domain/palette_transform.dart';
import '../../../game/domain/run_configuration.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/campaign_repository.dart';

class SupabaseCampaignRepository implements CampaignRepository {
  const SupabaseCampaignRepository({
    required SupabaseClient client,
    required ProtectedStore protectedStore,
    required AuthRepository authRepository,
  }) : _client = client,
       _protectedStore = protectedStore,
       _authRepository = authRepository;

  static const _uuid = Uuid();
  static const _maximumStageDuration = Duration(minutes: 10);
  final SupabaseClient _client;
  final ProtectedStore _protectedStore;
  final AuthRepository _authRepository;

  @override
  Future<CampaignProgress?> loadActiveCampaign() async {
    try {
      final data = await _client
          .from('campaign_runs')
          .select(
            'id, character_id, current_level, expected_sequence, provisional_currency, lease_expires_at',
          )
          .eq('state', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      final expiresAt = DateTime.parse(
        _requiredString(data, 'lease_expires_at'),
      ).toUtc();
      if (!DateTime.now().toUtc().isBefore(expiresAt)) return null;
      return CampaignProgress(
        campaignId: _requiredString(data, 'id'),
        characterId: CharacterIdSerialization.parse(
          _requiredString(data, 'character_id'),
        ),
        currentLevel: _int(data['current_level']),
        expectedSequence: _int(data['expected_sequence']),
        temporaryCurrency: _int(data['provisional_currency']),
        expiresAt: expiresAt,
      );
    } on PostgrestException catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo recuperar la campaña activa.',
        cause: error,
      );
    }
  }

  @override
  Future<CampaignStageSession?> loadPreparedStage(
    CharacterId characterId,
  ) async {
    if (!_protectedStore.availability.isAvailable) return null;
    final encoded = await _protectedStore.read(_cacheKey);
    if (encoded == null) return null;
    try {
      final row = Map<String, Object?>.from(jsonDecode(encoded) as Map);
      if ((row['state'] != 'prepared' && row['state'] != 'playing') ||
          row['character_id'] != characterId.serialized) {
        return null;
      }
      final session = _sessionFromJson(row);
      final expiresAt = session.expiresAt;
      if (expiresAt == null ||
          expiresAt.isBefore(
            DateTime.now().toUtc().add(_maximumStageDuration),
          )) {
        await clearPreparedStage();
        return null;
      }
      return CampaignStageSession(
        eligibility: CampaignEligibility.eligibleOffline,
        configuration: session.configuration,
        campaignId: session.campaignId,
        stageToken: session.stageToken,
        expiresAt: session.expiresAt,
        bankedCurrency: session.bankedCurrency,
        temporaryCurrency: session.temporaryCurrency,
      );
    } on Object {
      await clearPreparedStage();
      return null;
    }
  }

  @override
  Future<CampaignStageSession> startStage({
    required RunConfiguration configuration,
    required int bankedCurrency,
    required int temporaryCurrency,
  }) async {
    if (!_protectedStore.availability.isAvailable) {
      return _practice(
        configuration,
        bankedCurrency: bankedCurrency,
        temporaryCurrency: temporaryCurrency,
      );
    }
    try {
      final active = await loadActiveCampaign();
      late final String campaignId;
      var authoritativeTemporaryCurrency = temporaryCurrency;
      if (active == null) {
        if (configuration.level != 1) {
          return _practice(
            configuration,
            bankedCurrency: bankedCurrency,
            temporaryCurrency: temporaryCurrency,
          );
        }
        final loadoutDigest = await _digest(_loadoutPayload(configuration));
        final campaign = await _invoke('start-campaign', {
          'character_id': configuration.characterId.serialized,
          'mode': configuration.mode.serialized,
          'content_version': configuration.contentVersion,
          'protocol_version': configuration.protocolVersion,
          'loadout_digest': loadoutDigest,
          'idempotency_key': _uuid.v4(),
        });
        campaignId = _requiredString(campaign, 'campaign_id');
      } else {
        if (active.characterId != configuration.characterId ||
            active.expectedSequence != configuration.level ||
            active.readyToComplete) {
          throw const AppFailure(
            AppFailureCode.conflict,
            'La etapa solicitada no coincide con la campaña activa.',
          );
        }
        campaignId = active.campaignId;
        authoritativeTemporaryCurrency = active.temporaryCurrency;
      }
      final configurationDigest = await _digest(
        _configurationPayload(configuration),
      );
      final stage = await _invoke('start-stage', {
        'campaign_id': campaignId,
        'configuration_digest': configurationDigest,
        'idempotency_key': _uuid.v4(),
      });
      final expiresAt = DateTime.parse(
        _requiredString(stage, 'expires_at'),
      ).toUtc();
      if (expiresAt.isBefore(
        DateTime.now().toUtc().add(_maximumStageDuration),
      )) {
        throw const AppFailure(
          AppFailureCode.conflict,
          'La etapa no tiene tiempo suficiente para comenzar de forma elegible.',
        );
      }
      final session = CampaignStageSession(
        eligibility: CampaignEligibility.verifiedOnline,
        configuration: configuration.copyWith(stageExpiresAt: expiresAt),
        campaignId: campaignId,
        stageToken: _requiredString(stage, 'stage_token'),
        expiresAt: expiresAt,
        bankedCurrency: bankedCurrency,
        temporaryCurrency: authoritativeTemporaryCurrency,
      );
      await _writeCache(session, state: 'prepared');
      return session;
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure(
        AppFailureCode.network,
        'No se pudo preparar una etapa verificada.',
        cause: error,
      );
    }
  }

  @override
  Future<void> markStagePlaying(CampaignStageSession session) async {
    if (session.canEarnRewards && _protectedStore.availability.isAvailable) {
      await _writeCache(session, state: 'playing');
    }
  }

  @override
  Future<CampaignFinishReceipt> finishStage(
    Map<String, Object?> payload,
  ) async {
    final data = await _invoke('finish-stage', payload);
    return CampaignFinishReceipt(
      accepted: data['status'] == 'accepted',
      ranked: data['ranked'] == true,
      masteryXpGranted: _int(data['mastery_xp_granted']),
      temporaryCurrency: _int(data['temporary_currency']),
      currencyLost: _int(data['currency_lost']),
      uniqueDropGranted: data['unique_drop_granted'] == true,
      nextLevel: _int(data['next_sequence']).clamp(1, 11),
      readyToComplete: data['ready_to_complete'] == true,
      uniqueRewardId: data['unique_reward_id'] as String?,
      rejectionCode: data['code'] as String?,
    );
  }

  @override
  Future<CampaignCompletionReceipt> completeCampaign(
    Map<String, Object?> payload,
  ) async {
    final data = await _invoke('complete-campaign', payload);
    return CampaignCompletionReceipt(
      accepted: data['status'] == 'accepted',
      ranked: data['ranked'] == true,
      bankedCurrency: _int(data['banked_currency']),
      purchasePhaseUnlocked: data['purchase_phase_unlocked'] == true,
    );
  }

  @override
  Future<void> failCampaign(Map<String, Object?> payload) async {
    await _invoke('fail-campaign', payload);
  }

  @override
  Future<void> abandonCampaign(CampaignStageSession session) async {
    final campaignId = session.campaignId;
    if (campaignId != null) {
      await failCampaign({
        'campaign_id': campaignId,
        'idempotency_key': _uuid.v4(),
      });
    }
    await clearPreparedStage();
  }

  @override
  Future<void> clearPreparedStage() async {
    if (_protectedStore.availability.isAvailable) {
      await _protectedStore.delete(_cacheKey);
    }
  }

  String get _cacheKey {
    final userId = _authRepository.currentSession.user?.id;
    if (userId == null) {
      throw const AppFailure(
        AppFailureCode.unauthorized,
        'Inicia sesión para preparar la campaña.',
      );
    }
    return 'user.$userId.campaign.stage.v1';
  }

  Future<Map<String, Object?>> _invoke(
    String functionName,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _client.functions.invoke(functionName, body: body);
      if (response.data is! Map) {
        throw const FormatException('Invalid campaign response.');
      }
      final data = Map<String, Object?>.from(response.data as Map);
      if (response.status < 200 ||
          response.status >= 300 ||
          data['status'] != 'accepted') {
        throw AppFailure(
          AppFailureCode.conflict,
          _messageForCode(data['code'] as String?),
        );
      }
      return data;
    } on AppFailure {
      rethrow;
    } on FunctionException catch (error) {
      throw AppFailure(
        error.status == 409 ? AppFailureCode.conflict : AppFailureCode.network,
        'El servidor no pudo confirmar la campaña.',
        cause: error,
      );
    }
  }

  Future<void> _writeCache(
    CampaignStageSession session, {
    required String state,
  }) {
    return _protectedStore.write(
      _cacheKey,
      jsonEncode(_sessionToJson(session, state: state)),
    );
  }

  static CampaignStageSession _practice(
    RunConfiguration configuration, {
    required int bankedCurrency,
    required int temporaryCurrency,
  }) {
    return CampaignStageSession(
      eligibility: CampaignEligibility.practice,
      configuration: configuration,
      bankedCurrency: bankedCurrency,
      temporaryCurrency: temporaryCurrency,
    );
  }

  static Map<String, Object?> _sessionToJson(
    CampaignStageSession session, {
    required String state,
  }) {
    return {
      'schema_version': 1,
      'state': state,
      'campaign_id': session.campaignId,
      'stage_token': session.stageToken,
      'expires_at': session.expiresAt?.toIso8601String(),
      'banked_currency': session.bankedCurrency,
      'temporary_currency': session.temporaryCurrency,
      'character_id': session.configuration.characterId.serialized,
      'configuration': _configurationPayload(session.configuration),
    };
  }

  static CampaignStageSession _sessionFromJson(Map<String, Object?> row) {
    final configurationRow = Map<String, Object?>.from(
      row['configuration'] as Map,
    );
    final character = CharacterIdSerialization.parse(
      _requiredString(configurationRow, 'character_id'),
    );
    final stats = Map<String, Object?>.from(configurationRow['stats'] as Map);
    final loadout = Map<String, Object?>.from(
      configurationRow['loadout'] as Map,
    );
    final palette = Map<String, Object?>.from(
      configurationRow['palette'] as Map,
    );
    final activeName = loadout['active_ability'] as String?;
    final expiresAt = DateTime.parse(
      _requiredString(row, 'expires_at'),
    ).toUtc();
    return CampaignStageSession(
      eligibility: CampaignEligibility.eligibleOffline,
      configuration: RunConfiguration(
        characterId: character,
        mode: RunModeSerialization.parse(
          _requiredString(configurationRow, 'mode'),
        ),
        stats: RunStats(
          speedMultiplier: _double(stats['speed_multiplier']),
          jumpMultiplier: _double(stats['jump_multiplier']),
          damageMultiplier: _double(stats['damage_multiplier']),
          fortuneMultiplier: _double(stats['fortune_multiplier']),
          maxLives: _int(stats['max_lives']),
        ),
        loadout: RunLoadout(
          activeAbility: activeName == null
              ? null
              : ActiveAbilityId.values.byName(activeName),
          activeSkillId: loadout['active_skill_id'] as String?,
          passiveSkillIds: (loadout['passive_skill_ids'] as List)
              .map((value) => value.toString())
              .toList(),
          skillEffects: [
            for (final value in (loadout['skill_effects'] as List? ?? const []))
              RuntimeSkillEffect(
                skillId: _requiredString(
                  Map<String, Object?>.from(value as Map),
                  'skill_id',
                ),
                effectCode: _requiredString(
                  Map<String, Object?>.from(value),
                  'effect_code',
                ),
                parameters: Map<String, Object?>.from(
                  Map<String, Object?>.from(value)['parameters'] as Map,
                ),
              ),
          ],
        ),
        level: _int(configurationRow['level']),
        contentVersion: _requiredString(configurationRow, 'content_version'),
        protocolVersion: _int(configurationRow['protocol_version']),
        seed: _int(configurationRow['seed']),
        experience: RunExperience.campaignStage,
        stageExpiresAt: expiresAt,
        palette: PaletteTransform(
          hueShift: _int(palette['hue_shift']),
          saturationBasisPoints: _int(palette['saturation_basis_points']),
          valueBasisPoints: _int(palette['value_basis_points']),
        ),
      ),
      campaignId: _requiredString(row, 'campaign_id'),
      stageToken: _requiredString(row, 'stage_token'),
      expiresAt: expiresAt,
      bankedCurrency: _int(row['banked_currency']),
      temporaryCurrency: _int(row['temporary_currency']),
    );
  }

  static Map<String, Object?> _configurationPayload(
    RunConfiguration configuration,
  ) => {
    'character_id': configuration.characterId.serialized,
    'mode': configuration.mode.serialized,
    'stats': {
      'speed_multiplier': configuration.stats.speedMultiplier,
      'jump_multiplier': configuration.stats.jumpMultiplier,
      'damage_multiplier': configuration.stats.damageMultiplier,
      'fortune_multiplier': configuration.stats.fortuneMultiplier,
      'max_lives': configuration.stats.maxLives,
    },
    'loadout': _loadoutPayload(configuration),
    'palette': {
      'hue_shift': configuration.palette.hueShift,
      'saturation_basis_points': configuration.palette.saturationBasisPoints,
      'value_basis_points': configuration.palette.valueBasisPoints,
    },
    'level': configuration.level,
    'content_version': configuration.contentVersion,
    'protocol_version': configuration.protocolVersion,
    'seed': configuration.seed,
  };

  static Map<String, Object?> _loadoutPayload(RunConfiguration configuration) =>
      {
        'active_ability': configuration.loadout.activeAbility?.name,
        'active_skill_id': configuration.loadout.activeSkillId,
        'passive_skill_ids': configuration.loadout.passiveSkillIds,
        'skill_effects': [
          for (final effect in configuration.loadout.skillEffects)
            {
              'skill_id': effect.skillId,
              'effect_code': effect.effectCode,
              'parameters': effect.parameters,
            },
        ],
      };

  static Future<String> _digest(Map<String, Object?> payload) async {
    final canonical = _canonicalJson(payload);
    final hash = await Sha256().hash(utf8.encode(canonical));
    return hash.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  static String _requiredString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static int _int(Object? value) => switch (value) {
    int number => number,
    num number => number.toInt(),
    String string => int.parse(string),
    _ => 0,
  };

  static double _double(Object? value) => switch (value) {
    num number => number.toDouble(),
    String string => double.parse(string),
    _ => 1,
  };

  static String _messageForCode(String? code) => switch (code) {
    'campaign_expired' => 'La autorización de la campaña expiró.',
    'campaign_not_active' => 'La campaña ya no está activa.',
    'campaign_not_ready' => 'La campaña aún no está lista para cerrarse.',
    'stage_already_issued' =>
      'Esta etapa ya fue preparada en otro dispositivo.',
    'unsupported_client_version' => 'Actualiza el juego para iniciar campaña.',
    _ => 'No se pudo autorizar la etapa.',
  };
}
