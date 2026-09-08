import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../audio/app_audio_manager.dart';
import '../dino_run_game.dart';
import '../domain/character_definition.dart';
import '../domain/character_id.dart';
import '../domain/palette_transform.dart';
import '../domain/run_configuration.dart';
import 'dino_skin_aura.dart';
import 'projectile.dart';
import 'obstacle.dart';
import 'orb.dart';

enum DinoState { idle, running, jumping, hit, shooting }

class DinoComponent extends SpriteAnimationGroupComponent<DinoState>
    with HasGameReference<DinoRunGame>, CollisionCallbacks {
  // Constants
  final double gravity = 1000.0;
  double get jumpForce => -500 * _configuration.stats.jumpMultiplier;

  double _yVelocity = 0.0;
  bool _isJumping = false;

  // Character Logic
  RunConfiguration _configuration = RunConfiguration.legacy(
    characterId: CharacterId.jano,
  );

  CharacterId get characterId => _configuration.characterId;

  // Ability timers & limits
  double cooldownTimer = 0.0;
  double abilityDurationTimer = 0.0;
  double _damageInvulnerabilityTimer = 0;
  double _recoveryTimer = 0;
  int _recoveryBasisPoints = 0;

  // Specific State
  bool hasShield = false;
  bool isIntangible = false;
  bool canDoubleJump = false;
  bool hasDoubleJumped = false;
  bool isGliding = false;

  // Nanic State
  double energy = 0.0;
  final double maxEnergy = 100.0;
  bool isSuperCharged = false;
  bool isDischarging = false;
  bool _firstOrbBonusUsed = false;
  bool get isDamageInvulnerable => _damageInvulnerabilityTimer > 0;
  bool get isAirborne => _isJumping;
  String? get activeSkillId => _configuration.loadout.activeSkillId;

  // Cooldowns
  final double pistoleroCooldown = 10.0;
  final double tanqueShieldRegenTime = 15.0;
  final double fantasmaDuration = 3.0;
  final double fantasmaCooldown = 10.0;
  final double dischargeDuration = 2.0;

  // Aura & Skin
  DinoSkinAuraComponent? auraComponent;
  double _rainbowHueTimer = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadCharacterSprite();

    anchor = Anchor.bottomLeft;
    position = Vector2(50, game.size.y - game.effectiveGroundHeight);
    size = Vector2(88, 88);

    _updateHitbox();
  }

  Future<void> setConfiguration(RunConfiguration configuration) async {
    _configuration = configuration;
    if (auraComponent != null) {
      auraComponent!.auraType = configuration.palette.auraType;
    }
    await _loadCharacterSprite();
    _resetAbilities();
    _updateHitbox();
  }

  // Horizontal movement
  double horizontalInput = 0.0;
  static const double baseHorizontalSpeed = 280.0;

  void moveLeft() {
    horizontalInput = -1.0;
  }

  void moveRight() {
    horizontalInput = 1.0;
  }

  void stopMoving() {
    horizontalInput = 0.0;
  }

  void _updateHitbox() {
    final hitboxesToRemove = children.whereType<RectangleHitbox>().toList();
    for (final h in hitboxesToRemove) {
      h.removeFromParent();
    }

    Vector2 hitboxSize;
    Vector2 hitboxPosition;

    if (characterId == CharacterId.nanic) {
      hitboxSize = Vector2(22, 38);
      hitboxPosition = Vector2(13, 22);
    } else {
      // Snug hitbox matching the character's core torso and legs
      // (prevents ghost damage when jumping near obstacles)
      hitboxSize = Vector2(28, 44);
      hitboxPosition = Vector2(30, 24);
    }

    add(RectangleHitbox(position: hitboxPosition, size: hitboxSize));
  }

  void _resetAbilities() {
    cooldownTimer = 0;
    abilityDurationTimer = 0;
    _damageInvulnerabilityTimer = 0;
    _recoveryTimer = 0;
    _recoveryBasisPoints = 0;
    isIntangible = false;
    isGliding = false;
    hasDoubleJumped = false;
    horizontalInput = 0;

    // Nanic Reset
    energy = 0;
    isSuperCharged = false;
    isDischarging = false;
    _firstOrbBonusUsed = false;
    if (auraComponent != null) {
      auraComponent!.isNanicDischarging = false;
      auraComponent!.opacity =
          _configuration.palette.auraType != SkinAuraType.none ? 1.0 : 0.0;
    }

    final definition = characterId.definition;
    if (definition.hasTrait(CharacterCoreTrait.regeneratingShield) ||
        (_configuration.experience == RunExperience.endlessRunner &&
            definition.hasTrait(CharacterCoreTrait.extraLife))) {
      hasShield = true;
    } else {
      hasShield = false;
    }
  }

  Future<void> _loadCharacterSprite() async {
    final spriteSheet = await game.images.load(
      characterId.definition.assetName,
    );
    final double fw = spriteSheet.width / 2;
    final double fh = spriteSheet.height / 2;

    final frame0 = Sprite(
      spriteSheet,
      srcPosition: Vector2(0, 0),
      srcSize: Vector2(fw, fh),
    );
    final frame1 = Sprite(
      spriteSheet,
      srcPosition: Vector2(fw, 0),
      srcSize: Vector2(fw, fh),
    );
    final frame2 = Sprite(
      spriteSheet,
      srcPosition: Vector2(0, fh),
      srcSize: Vector2(fw, fh),
    );
    final frame3 = Sprite(
      spriteSheet,
      srcPosition: Vector2(fw, fh),
      srcSize: Vector2(fw, fh),
    );

    final runAnimation = SpriteAnimation.spriteList([
      frame0,
      frame1,
      frame2,
      frame3,
    ], stepTime: 0.15);
    final jumpAnimation = SpriteAnimation.spriteList([frame1], stepTime: 1);
    final hitAnimation = SpriteAnimation.spriteList([frame3], stepTime: 1);
    SpriteAnimation? shootAnimation;

    animations = {
      DinoState.idle: runAnimation,
      DinoState.running: runAnimation,
      DinoState.jumping: jumpAnimation,
      DinoState.hit: hitAnimation,
      DinoState.shooting: shootAnimation ?? runAnimation,
    };
    paint.colorFilter = _configuration.palette.colorFilter;

    current = DinoState.running;

    if (characterId == CharacterId.parker) {
      size = Vector2(75, 75);
    } else if (characterId == CharacterId.conra) {
      size = Vector2(80, 80);
    } else if (characterId == CharacterId.nanic) {
      size = Vector2(48, 68);
    } else {
      size = Vector2(88, 88);
    }

    // Init Aura
    final auraDiameter = (math.max(size.x, size.y) * 1.45).clamp(90.0, 140.0);
    final hasAura = _configuration.palette.auraType != SkinAuraType.none ||
        (characterId == CharacterId.nanic && (isSuperCharged || isDischarging));
    if (auraComponent == null) {
      auraComponent = DinoSkinAuraComponent(
        auraType: _configuration.palette.auraType,
      );
      auraComponent!.size = Vector2(auraDiameter, auraDiameter);
      auraComponent!.position = size / 2;
      auraComponent!.opacity = hasAura ? 1.0 : 0.0;
      try {
        final auraSprite = await game.loadSprite('aura.png');
        auraComponent!.auraSprite = auraSprite;
      } on Object catch (error, stackTrace) {
        developer.log(
          'Unable to load aura sprite',
          name: 'DinoComponent',
          error: error,
          stackTrace: stackTrace,
        );
      }
      add(auraComponent!);
    } else {
      auraComponent!.auraType = _configuration.palette.auraType;
      auraComponent!.size = Vector2(auraDiameter, auraDiameter);
      auraComponent!.position = size / 2;
      auraComponent!.opacity = hasAura ? 1.0 : 0.0;
    }
  }

  @override
  void update(double dt) {
    if (game.isMounted) {
      super.update(dt);
      if (_recoveryTimer > 0) {
        _recoveryTimer -= dt;
      } else {
        _recoveryBasisPoints = 0;
      }
      if (cooldownTimer > 0) {
        cooldownTimer -= dt * (1 + _recoveryBasisPoints / 10000);
      }
      if (_damageInvulnerabilityTimer > 0) {
        _damageInvulnerabilityTimer -= dt;
      }

      if (cooldownTimer <= 0 && characterId == CharacterId.chema) {
        hasShield = true;
      }

      if (abilityDurationTimer > 0) {
        abilityDurationTimer -= dt;
        if (characterId != CharacterId.nanic) {
          if (abilityDurationTimer % 0.2 < 0.1) {
            opacity = 0.5;
          } else {
            opacity = 1.0;
          }
          if (abilityDurationTimer <= 0) {
            opacity = 1.0;
            isIntangible = false;
            final graceMs = game.passiveParameter(
              'phase_exit_grace',
              'duration_ms',
            );
            if (graceMs > 0) {
              _damageInvulnerabilityTimer = graceMs / 1000;
            }
            if (current == DinoState.shooting) current = DinoState.running;
          }
        } else {
          // Nanic Discharge
          if (abilityDurationTimer <= 0) {
            isDischarging = false;
          }
        }
      } else {
        opacity = 1.0;
      }

      // Rainbow palette real-time color shifting
      if (_configuration.palette.isRainbow) {
        _rainbowHueTimer += dt;
        final currentHue = ((_rainbowHueTimer * 180) % 360).toInt();
        paint.colorFilter = PaletteTransform(
          hueShift: currentHue,
          saturationBasisPoints: 12500,
          valueBasisPoints: 11000,
          isRainbow: true,
          auraType: SkinAuraType.rainbow,
        ).colorFilter;
      }

      // Aura check & update
      if (auraComponent != null) {
        final nanicActive = characterId == CharacterId.nanic &&
            (isSuperCharged || isDischarging);
        auraComponent!.isNanicDischarging = nanicActive;
        auraComponent!.auraType = _configuration.palette.auraType;
        auraComponent!.opacity =
            (nanicActive || _configuration.palette.auraType != SkinAuraType.none)
                ? 1.0
                : 0.0;
      }

      if (horizontalInput != 0 && current != DinoState.hit) {
        final speed =
            baseHorizontalSpeed * _configuration.stats.speedMultiplier;
        x += horizontalInput * speed * dt;
        const minX = 35.0;
        final maxX = (game.size.x * 0.65).clamp(240.0, 750.0);
        x = x.clamp(minX, maxX);
      }

      _yVelocity += gravity * dt;
      if (isGliding && _yVelocity > 0) {
        final reduction = game.passiveParameter(
          'glide_fall_reduction',
          'basis_points',
        );
        _yVelocity = 100 * (1 - reduction.clamp(0, 1000) / 10000);
      }
      y += _yVelocity * dt;

      double groundY = game.size.y - game.effectiveGroundHeight;
      if (y > groundY) {
        final landedFromAir = _isJumping;
        final landedFromGlide = isGliding;
        y = groundY;
        _yVelocity = 0;
        _isJumping = false;
        isGliding = false;
        hasDoubleJumped = false;
        if (current != DinoState.hit) current = DinoState.running;
        if (landedFromAir) {
          final reductionMs = game.passiveParameter(
            'precision_landing_cooldown',
            'reduction_ms',
          );
          final minimumMs = game.passiveParameter(
            'precision_landing_cooldown',
            'minimum_cooldown_ms',
          );
          if (reductionMs > 0 && cooldownTimer > minimumMs / 1000) {
            cooldownTimer = (cooldownTimer - reductionMs / 1000).clamp(
              minimumMs / 1000,
              double.infinity,
            );
          }
        }
        if (landedFromGlide) {
          applyRecovery(
            Duration(
              milliseconds: game.passiveParameter(
                'glide_landing_recovery',
                'duration_ms',
              ),
            ),
            game.passiveParameter('glide_landing_recovery', 'basis_points'),
          );
        }
      }
    }
  }

  void jump() {
    if (current == DinoState.hit) return;
    if (!_isJumping) {
      _yVelocity = jumpForce;
      _isJumping = true;
      current = DinoState.jumping;
      AppAudioManager.playSfx(
        'Jump.wav',
        audioEnabled:
            _configuration.sfxEnabled && _configuration.audioEnabled,
      );
    } else {
      if (characterId.definition.hasTrait(CharacterCoreTrait.doubleJump) &&
          !hasDoubleJumped) {
        final control = game.passiveParameter(
          'double_jump_control',
          'basis_points',
        );
        _yVelocity = jumpForce * (1 + control.clamp(0, 1000) / 10000);
        hasDoubleJumped = true;
        AppAudioManager.playSfx(
          'Jump.wav',
          audioEnabled:
              _configuration.sfxEnabled && _configuration.audioEnabled,
        );
      } else if (characterId.definition.hasTrait(CharacterCoreTrait.glide)) {
        isGliding = true;
      }
    }
  }

  void stopGlide() {
    isGliding = false;
  }

  void activateAbility() {
    final activeSkillId = _configuration.loadout.activeSkillId;
    if (activeSkillId != null && cooldownTimer <= 0) {
      cooldownTimer = game.activatePurchasedSkill(activeSkillId);
      return;
    }
    final activeAbility = _configuration.loadout.activeAbility;
    if (activeAbility == ActiveAbilityId.pistolShot && cooldownTimer <= 0) {
      game.add(Projectile(position: position + Vector2(size.x, -size.y / 2)));
      cooldownTimer = pistoleroCooldown / _configuration.stats.speedMultiplier;
      AppAudioManager.playSfx(
        'Shoot.wav',
        audioEnabled:
            _configuration.sfxEnabled && _configuration.audioEnabled,
      );
      current = DinoState.shooting;
      abilityDurationTimer = 0.5;
      game.abilityActivated(ActiveAbilityId.pistolShot);
    } else if (activeAbility == ActiveAbilityId.intangibility &&
        cooldownTimer <= 0) {
      isIntangible = true;
      final durationBonus = game.passiveParameter(
        'intangibility_duration',
        'basis_points',
      );
      abilityDurationTimer =
          fantasmaDuration * (1 + durationBonus.clamp(0, 1000) / 10000);
      cooldownTimer = fantasmaCooldown / _configuration.stats.speedMultiplier;
      AppAudioManager.playSfx(
        'Invisibility.wav',
        audioEnabled:
            _configuration.sfxEnabled && _configuration.audioEnabled,
      );
      game.abilityActivated(ActiveAbilityId.intangibility);
    } else if (activeAbility == ActiveAbilityId.electricDischarge &&
        isSuperCharged) {
      // Start Discharge (Active Aura)
      isDischarging = true;
      abilityDurationTimer = dischargeDuration;

      energy = 0;
      isSuperCharged = false;
      game.resetSpeed();

      AppAudioManager.playSfx(
        'Shoot.wav',
        audioEnabled:
            _configuration.sfxEnabled && _configuration.audioEnabled,
      );
      game.abilityActivated(ActiveAbilityId.electricDischarge);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is OrbComponent) {
      if (characterId.definition.hasTrait(CharacterCoreTrait.energyCharge) &&
          !isSuperCharged &&
          !isDischarging) {
        other.removeFromParent();
        final doubleCharge =
            game.hasPassiveEffect('first_orb_double_charge') &&
            !_firstOrbBonusUsed;
        energy += doubleCharge ? 40 : 20;
        if (doubleCharge) _firstOrbBonusUsed = true;
        AppAudioManager.playSfx(
          'Select.wav',
          audioEnabled:
              _configuration.sfxEnabled && _configuration.audioEnabled,
        );
        if (energy >= maxEnergy) {
          energy = maxEnergy;
          isSuperCharged = true;
          game.increaseSpeed();
        }
      }
      return;
    }

    if (other is Obstacle) {
      if (isDamageInvulnerable) return;
      if (characterId == CharacterId.nanic && isDischarging) {
        other.removeFromParent();
        AppAudioManager.playSfx(
          'Hit.wav',
          audioEnabled:
              _configuration.sfxEnabled && _configuration.audioEnabled,
        );
        isDischarging = false;
        abilityDurationTimer = 0;
        return;
      }

      if (isIntangible) return;

      if (hasShield) {
        hasShield = false;
        game.playerDamaged(wasAbsorbed: true);
        AppAudioManager.playSfx(
          'Hit.wav',
          audioEnabled:
              _configuration.sfxEnabled && _configuration.audioEnabled,
        );
        if (characterId == CharacterId.chema) {
          final reduction = game.passiveParameter(
            'shield_penalty_reduction',
            'basis_points',
          );
          game.scoreSystem.score -=
              500 * (1 - reduction.clamp(0, 2000) / 10000);
          final regeneration = game.passiveParameter(
            'shield_regeneration',
            'basis_points',
          );
          cooldownTimer =
              tanqueShieldRegenTime *
              (1 - regeneration.clamp(0, 1000) / 10000) /
              _configuration.stats.speedMultiplier;
          abilityDurationTimer = 1.0;
          isIntangible = true;
        }
        if (characterId == CharacterId.parker) {
          abilityDurationTimer = 2.0;
          isIntangible = true;
        }
        return;
      }
      hit();
    }
  }

  void hit() {
    current = DinoState.hit;
    AppAudioManager.playSfx(
      'Hit.wav',
      audioEnabled:
          _configuration.sfxEnabled && _configuration.audioEnabled,
    );
    game.receiveUnabsorbedHit();
  }

  void beginDamageInvulnerability(Duration duration) {
    _damageInvulnerabilityTimer = duration.inMilliseconds / 1000;
    abilityDurationTimer = _damageInvulnerabilityTimer;
    isIntangible = true;
  }

  void applyRecovery(Duration duration, int basisPoints) {
    if (duration <= Duration.zero || basisPoints <= 0) return;
    _recoveryTimer = duration.inMilliseconds / 1000;
    _recoveryBasisPoints = basisPoints.clamp(0, 2000);
  }

  void reduceCooldownBasisPoints(int basisPoints) {
    cooldownTimer *= 1 - basisPoints.clamp(0, 2000) / 10000;
  }

  void launchVertical(double impulseMultiplier) {
    _yVelocity = jumpForce * impulseMultiplier.clamp(0.1, 1);
    _isJumping = true;
    current = DinoState.jumping;
  }

  bool consumeEnergyForExclusiveSkill() {
    if (!isSuperCharged && energy < maxEnergy) return false;
    energy = 0;
    isSuperCharged = false;
    isDischarging = false;
    game.resetSpeed();
    final graceMs = game.passiveParameter('discharge_grace', 'duration_ms');
    if (graceMs > 0) {
      beginDamageInvulnerability(Duration(milliseconds: graceMs));
    }
    return true;
  }

  void reset() {
    position = Vector2(50, game.size.y - game.effectiveGroundHeight);
    _yVelocity = 0;
    _isJumping = false;
    current = DinoState.running;
    _resetAbilities();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_isJumping) {
      y = size.y - game.effectiveGroundHeight;
    }
  }
}
