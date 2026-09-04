import 'dart:collection';
import 'dart:convert';

import '../../../game/domain/run_configuration.dart';
import 'progression_models.dart';

enum SkillTrigger {
  activePressed,
  projectileHit,
  playerDamaged,
  lifeLost,
  shieldRecovered,
  shieldBroken,
  phaseStarted,
  phaseEnded,
  airborne,
  landed,
  gliding,
  glideEnded,
  orbCollected,
  energyDischarged,
}

class ResolvedSkillEffect {
  ResolvedSkillEffect({
    required this.skillId,
    required this.trigger,
    required this.applied,
    required Map<String, Object?> parameters,
  }) : parameters = UnmodifiableMapView(
         SplayTreeMap<String, Object?>.from(parameters),
       );

  final String skillId;
  final SkillTrigger trigger;
  final bool applied;
  final Map<String, Object?> parameters;

  String get deterministicSignature => jsonEncode({
    'skill_id': skillId,
    'trigger': trigger.name,
    'applied': applied,
    'parameters': parameters,
  });
}

class SkillEffectEngine {
  const SkillEffectEngine._();

  static ResolvedSkillEffect resolve({
    required ProgressionSkill skill,
    required RunMode mode,
  }) {
    final trigger = _triggerFor(skill.effectCode);
    if (mode == RunMode.standard || !skill.worksIn(mode)) {
      return ResolvedSkillEffect(
        skillId: skill.id,
        trigger: trigger,
        applied: false,
        parameters: const {},
      );
    }
    _validateSlot(skill, trigger);
    _validateParameters(skill.effectParameters);
    return ResolvedSkillEffect(
      skillId: skill.id,
      trigger: trigger,
      applied: true,
      parameters: skill.effectParameters,
    );
  }

  static void _validateSlot(ProgressionSkill skill, SkillTrigger trigger) {
    final isActivation = trigger == SkillTrigger.activePressed;
    if ((skill.slot == SkillSlot.active) != isActivation) {
      throw StateError('Skill slot does not match effect trigger: ${skill.id}');
    }
  }

  static void _validateParameters(Map<String, Object?> parameters) {
    if (parameters.isEmpty) {
      throw const FormatException(
        'A skill effect requires bounded parameters.',
      );
    }
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value is int) {
        if (value < 0 || value > _maximumFor(entry.key)) {
          throw FormatException('Unsafe ${entry.key} value.');
        }
      } else if (value is String) {
        if (!RegExp(r'^[a-z][a-z0-9_]{1,47}$').hasMatch(value)) {
          throw FormatException('Unsafe ${entry.key} identifier.');
        }
      } else {
        throw FormatException('Unsupported ${entry.key} value.');
      }
    }
  }

  static int _maximumFor(String key) {
    if (key.endsWith('_ms')) return 60000;
    if (key.endsWith('_basis_points')) return 10000;
    if (key == 'uses_per_stage' ||
        key == 'targets' ||
        key == 'projectiles' ||
        key == 'max_bounces') {
      return 5;
    }
    if (key == 'radius' || key == 'distance') return 1000;
    if (key.endsWith('_cap') || key == 'stage_cap') return 5000;
    return 100000;
  }

  static SkillTrigger _triggerFor(String effectCode) => switch (effectCode) {
    'ricochet_projectile' ||
    'projectile_burst' ||
    'guard_dash' ||
    'last_life_rally' ||
    'shield_pulse' ||
    'penalty_discharge' ||
    'phase_dash' ||
    'spectral_decoy' ||
    'aerial_stomp' ||
    'vertical_burst' ||
    'glide_tailwind' ||
    'glide_projectile_guard' ||
    'electric_chain' ||
    'energy_overclock' => SkillTrigger.activePressed,
    'cooldown_reduction' ||
    'precision_score_bonus' => SkillTrigger.projectileHit,
    'post_hit_invulnerability' => SkillTrigger.playerDamaged,
    'recovery_after_life_loss' => SkillTrigger.lifeLost,
    'shield_regeneration' => SkillTrigger.shieldRecovered,
    'shield_penalty_reduction' => SkillTrigger.shieldBroken,
    'intangibility_duration' => SkillTrigger.phaseStarted,
    'phase_exit_grace' => SkillTrigger.phaseEnded,
    'double_jump_control' => SkillTrigger.airborne,
    'precision_landing_cooldown' => SkillTrigger.landed,
    'glide_fall_reduction' => SkillTrigger.gliding,
    'glide_landing_recovery' => SkillTrigger.glideEnded,
    'first_orb_double_charge' => SkillTrigger.orbCollected,
    'discharge_grace' => SkillTrigger.energyDischarged,
    _ => throw FormatException('Unknown skill effect: $effectCode'),
  };
}
