import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_audio/flame_audio.dart';
import '../dino_run_game.dart';
import 'projectile.dart';
import 'obstacle.dart';
import 'orb.dart';
import '../hud/character_selection_overlay.dart';

enum DinoState { idle, running, jumping, hit, shooting }

class DinoComponent extends SpriteAnimationGroupComponent<DinoState>
    with HasGameRef<DinoRunGame>, CollisionCallbacks {
  // Constants
  final double gravity = 1000.0;
  final double jumpForce = -500.0;
  
  double _yVelocity = 0.0;
  bool _isJumping = false;

  // Character Logic
  CharacterType characterType = CharacterType.pistolero;
  String characterName = 'jano';
  
  // Ability timers & limits
  double cooldownTimer = 0.0;
  double abilityDurationTimer = 0.0; 
  
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

  // Cooldowns
  final double pistoleroCooldown = 10.0;
  final double tanqueShieldRegenTime = 15.0;
  final double fantasmaDuration = 3.0;
  final double fantasmaCooldown = 10.0;
  final double dischargeDuration = 2.0;

  // Aura
  SpriteComponent? auraComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadCharacterSprite();
    
    anchor = Anchor.bottomLeft;
    position = Vector2(50, gameRef.size.y * 0.75); 
    size = Vector2(88, 88); 
    
    _updateHitbox();
  }
  
  Future<void> setCharacter(CharacterType type) async {
    characterType = type;
    characterName = getCharacterNameAsset(type);
    await _loadCharacterSprite();
    _resetAbilities();
    _updateHitbox();
  }

  void _updateHitbox() {
    final hitboxesToRemove = children.whereType<RectangleHitbox>().toList();
    for (final h in hitboxesToRemove) {
      h.removeFromParent();
    }

    Vector2 hitboxSize;
    Vector2 hitboxPosition;

    if (characterType == CharacterType.nanic) {
      hitboxSize = Vector2(28, 48); 
      hitboxPosition = Vector2(10, 20); 
    } else {
      hitboxSize = Vector2(48, 58);
      hitboxPosition = Vector2(20, 20);
    }

    add(RectangleHitbox(
      position: hitboxPosition,
      size: hitboxSize,
    ));
  }

  String getCharacterNameAsset(CharacterType type) {
    switch (type) {
      case CharacterType.pistolero: return 'jano';
      case CharacterType.vitalista: return 'parker';
      case CharacterType.tanque: return 'chema';
      case CharacterType.fantasma: return 'conra';
      case CharacterType.atleta: return 'shyno';
      case CharacterType.gravedadZero: return 'nakama';
      case CharacterType.nanic: return 'nanic';
    }
  }

  void _resetAbilities() {
    cooldownTimer = 0;
    abilityDurationTimer = 0;
    isIntangible = false;
    isGliding = false;
    hasDoubleJumped = false;
    
    // Nanic Reset
    energy = 0;
    isSuperCharged = false;
    isDischarging = false;
    if (auraComponent != null) auraComponent!.opacity = 0.0;
    
    if (characterType == CharacterType.vitalista || characterType == CharacterType.tanque) {
      hasShield = true; 
    } else {
      hasShield = false;
    }
  }

  Future<void> _loadCharacterSprite() async {
    final spriteSheet = await gameRef.images.load('${characterName}_clean.png');
    final double fw = spriteSheet.width / 2;
    final double fh = spriteSheet.height / 2;
    
    final frame0 = Sprite(spriteSheet, srcPosition: Vector2(0, 0), srcSize: Vector2(fw, fh));
    final frame1 = Sprite(spriteSheet, srcPosition: Vector2(fw, 0), srcSize: Vector2(fw, fh));
    final frame2 = Sprite(spriteSheet, srcPosition: Vector2(0, fh), srcSize: Vector2(fw, fh));
    final frame3 = Sprite(spriteSheet, srcPosition: Vector2(fw, fh), srcSize: Vector2(fw, fh));

    final runAnimation = SpriteAnimation.spriteList([frame0, frame1, frame2, frame3], stepTime: 0.15);
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
    
    current = DinoState.running;

    if (characterType == CharacterType.vitalista) { 
      size = Vector2(75, 75); 
    } else if (characterType == CharacterType.fantasma) {
      size = Vector2(80, 80); 
    } else if (characterType == CharacterType.nanic) {
      size = Vector2(48, 68); 
    } else {
      size = Vector2(88, 88);
    }

    // Init Aura
    if (auraComponent == null) {
        try {
            final auraSprite = await gameRef.loadSprite('aura.png');
            auraComponent = SpriteComponent(
                sprite: auraSprite,
                size: Vector2(100, 100),
                anchor: Anchor.center,
                position: size / 2, 
            );
            auraComponent!.priority = -1; // Keep behind
            auraComponent!.opacity = 0.0;
            add(auraComponent!);
        } catch (e) {
            print("Error loading aura: $e");
        }
    } else {
        auraComponent!.position = size / 2;
    }
  }

  @override
  void update(double dt) {
    if (gameRef.isMounted) {
       super.update(dt);
       if (cooldownTimer > 0) cooldownTimer -= dt;
       
       if (cooldownTimer <= 0 && characterType == CharacterType.tanque) hasShield = true;

       if (abilityDurationTimer > 0) {
         abilityDurationTimer -= dt;
         if (characterType != CharacterType.nanic) {
            if (abilityDurationTimer % 0.2 < 0.1) opacity = 0.5; else opacity = 1.0;
            if (abilityDurationTimer <= 0) {
              opacity = 1.0;
              isIntangible = false;
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
       
       // Aura check
       if (characterType == CharacterType.nanic && (isSuperCharged || isDischarging) && auraComponent != null) {
           auraComponent!.opacity = 1.0;
           auraComponent!.angle += dt * 10;
       } else if (auraComponent != null) {
           auraComponent!.opacity = 0.0;
       }

       _yVelocity += gravity * dt;
       if (isGliding && _yVelocity > 0) _yVelocity = 100;
       y += _yVelocity * dt;
       
       double groundY = gameRef.size.y * 0.75;
       if (y > groundY) {
         y = groundY;
         _yVelocity = 0;
         _isJumping = false;
         isGliding = false;
         hasDoubleJumped = false;
         if (current != DinoState.hit) current = DinoState.running;
       }
    }
  }

  void jump() {
    if (current == DinoState.hit) return;
    if (!_isJumping) {
      _yVelocity = jumpForce;
      _isJumping = true;
      current = DinoState.jumping;
      FlameAudio.play('Jump.wav');
    } else {
      if (characterType == CharacterType.atleta && !hasDoubleJumped) {
         _yVelocity = jumpForce; 
         hasDoubleJumped = true;
         FlameAudio.play('Jump.wav');
      } else if (characterType == CharacterType.gravedadZero) {
         isGliding = true;
      }
    }
  }
  
  void stopGlide() { isGliding = false; }
  
  void activateAbility() {
    if (characterType == CharacterType.pistolero && cooldownTimer <= 0) {
         gameRef.add(Projectile(position: position + Vector2(size.x, -size.y / 2)));
         cooldownTimer = pistoleroCooldown;
         FlameAudio.play('Shoot.wav');
         current = DinoState.shooting;
         abilityDurationTimer = 0.5;
    } else if (characterType == CharacterType.fantasma && cooldownTimer <= 0) {
         isIntangible = true;
         abilityDurationTimer = fantasmaDuration;
         cooldownTimer = fantasmaCooldown; 
         FlameAudio.play('Invisibility.wav');
    } else if (characterType == CharacterType.nanic && isSuperCharged) {
           // Start Discharge (Active Aura)
           isDischarging = true;
           abilityDurationTimer = dischargeDuration;
           
           energy = 0;
           isSuperCharged = false;
           gameRef.resetSpeed(); 
           
           FlameAudio.play('Shoot.wav'); // Activation sound
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is OrbComponent) {
      if (characterType == CharacterType.nanic && !isSuperCharged && !isDischarging) {
        other.removeFromParent();
        energy += 20; 
        FlameAudio.play('Select.wav'); 
        if (energy >= maxEnergy) {
          energy = maxEnergy;
          isSuperCharged = true;
          gameRef.increaseSpeed(); 
        }
      }
      return; 
    }

    if (other is Obstacle) {
      if (characterType == CharacterType.nanic && isDischarging) {
          other.removeFromParent(); 
          FlameAudio.play('Hit.wav'); 
          isDischarging = false;
          abilityDurationTimer = 0;
          return; 
      }

      if (isIntangible) return; 

      if (hasShield) {
        hasShield = false; 
        FlameAudio.play('Hit.wav'); 
        if (characterType == CharacterType.tanque) {
          gameRef.scoreSystem.score -= 500;
          if (gameRef.scoreSystem.score < 0) gameRef.scoreSystem.score = 0;
          cooldownTimer = tanqueShieldRegenTime;
          abilityDurationTimer = 1.0; 
          isIntangible = true;
        }
        if (characterType == CharacterType.vitalista) {
          abilityDurationTimer = 2.0; 
          isIntangible = true; 
        }
        return; 
      }
      hit();
    }
  }

  @override
  void hit() {
      current = DinoState.hit;
      FlameAudio.play('Hit.wav');
      gameRef.gameOver();
  }
  
  @override
  void reset() {
    position = Vector2(50, gameRef.size.y * 0.75);
    _yVelocity = 0;
    _isJumping = false;
    current = DinoState.running;
    _resetAbilities();
  }
}
