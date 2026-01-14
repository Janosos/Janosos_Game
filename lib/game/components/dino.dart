import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../dino_run_game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'projectile.dart';
import '../hud/character_selection_overlay.dart';
import 'obstacle.dart';

enum DinoState { idle, running, jumping, hit, shooting }

class DinoComponent extends SpriteAnimationGroupComponent<DinoState>
    with HasGameRef<DinoRunGame>, CollisionCallbacks {
  // Constants
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
  double abilityDurationTimer = 0.0; // For Fantasma transparency / Vitalista blink
  
  // Specific State
  bool hasShield = false; // Vitalista (1 hit), Tanque (regen)
  bool isIntangible = false; // Fantasma
  bool canDoubleJump = false; // Atleta
  bool hasDoubleJumped = false; // Atleta
  bool isGliding = false; // Gravedad-Zero

  // Cooldowns
  // Cooldowns
  final double pistoleroCooldown = 10.0;
  final double tanqueShieldRegenTime = 15.0;
  final double fantasmaDuration = 3.0;
  final double fantasmaCooldown = 10.0; // Reduced to 10s

  @override
  Future<void> onLoad() async {
    // Initial load with default
    await _loadCharacterSprite();
    
    anchor = Anchor.bottomLeft;
    position = Vector2(50, gameRef.size.y * 0.75); 
    size = Vector2(88, 88); 
    
    add(RectangleHitbox(
      position: Vector2(20, 20),
      size: Vector2(48, 58),
    ));
  }
  
  Future<void> setCharacter(CharacterType type) async {
    characterType = type;
    characterName = getCharacterNameAsset(type); // Helper to get string name
    await _loadCharacterSprite();
    _resetAbilities();
  }

  String getCharacterNameAsset(CharacterType type) {
    switch (type) {
      case CharacterType.pistolero: return 'jano';
      case CharacterType.vitalista: return 'parker';
      case CharacterType.tanque: return 'chema';
      case CharacterType.fantasma: return 'conra';
      case CharacterType.atleta: return 'shyno';
      case CharacterType.gravedadZero: return 'nakama';
    }
  }

  void _resetAbilities() {
    cooldownTimer = 0;
    abilityDurationTimer = 0;
    isIntangible = false;
    isGliding = false;
    hasDoubleJumped = false;
    
    // Passives
    if (characterType == CharacterType.vitalista) {
      hasShield = true; // Extra life
    } else if (characterType == CharacterType.tanque) {
      hasShield = true; // Shield
    } else {
      hasShield = false;
    }
  }

  // Helper to load sprite (mostly unchanged logic, just moved name mapping)
  Future<void> _loadCharacterSprite() async {
    // Note: Assuming assets are named accordingly: jano_clean.png, etc.
    final spriteSheet = await gameRef.images.load('${characterName}_clean.png');
    
    final double fw = spriteSheet.width / 2;
    final double fh = spriteSheet.height / 2;
    
    final Sprite frame0 = Sprite(spriteSheet, srcPosition: Vector2(0, 0), srcSize: Vector2(fw, fh));
    final Sprite frame1 = Sprite(spriteSheet, srcPosition: Vector2(fw, 0), srcSize: Vector2(fw, fh));
    final Sprite frame2 = Sprite(spriteSheet, srcPosition: Vector2(0, fh), srcSize: Vector2(fw, fh));
    final Sprite frame3 = Sprite(spriteSheet, srcPosition: Vector2(fw, fh), srcSize: Vector2(fw, fh));

    final runAnimation = SpriteAnimation.spriteList(
      [frame0, frame1, frame2, frame3],
      stepTime: 0.15,
    );
    
    final jumpAnimation = SpriteAnimation.spriteList([frame1], stepTime: 1);
    final hitAnimation = SpriteAnimation.spriteList([frame3], stepTime: 1);
    
    // Add transparency for Fantasma/Vitalista hit
    
    // Shooting Animation
    SpriteAnimation? shootAnimation;


    animations = {
      DinoState.idle: runAnimation,
      DinoState.running: runAnimation,
      DinoState.jumping: jumpAnimation, 
      DinoState.hit: hitAnimation,
      DinoState.shooting: shootAnimation ?? runAnimation,
    };
    
    current = DinoState.running;

    // Size Adjustments
    if (characterType == CharacterType.vitalista) { // Parker
      size = Vector2(75, 75); 
    } else if (characterType == CharacterType.fantasma) { // Conra
      size = Vector2(80, 80); 
    } else {
      size = Vector2(88, 88);
    }
  }

  @override
  void update(double dt) {
    if (gameRef.isMounted) {
       super.update(dt);
       
       // Timer updates
       if (cooldownTimer > 0) {
         cooldownTimer -= dt;
         if (cooldownTimer <= 0 && characterType == CharacterType.tanque) {
           // Tanque regenerates shield
           hasShield = true;
           // Visual feedback?
         }
       }
       
       if (abilityDurationTimer > 0) {
         abilityDurationTimer -= dt;
         
         // Blink effect
         if (abilityDurationTimer % 0.2 < 0.1) {
           opacity = 0.5;
         } else {
           opacity = 1.0;
         }

         if (abilityDurationTimer <= 0) {
           // End Effects
           opacity = 1.0;
           isIntangible = false; // Reset for all
           
           if (current == DinoState.shooting) {
             current = DinoState.running;
           }
         }
       } else {
         opacity = 1.0;
       }
       
       // Physic Updates
       _yVelocity += gravity * dt;
       
       // Glide logic
       if (isGliding && _yVelocity > 0) {
         _yVelocity = 100; // Const fall speed
       }
       
       y += _yVelocity * dt;
       
       double groundY = gameRef.size.y * 0.75;
       
       if (y > groundY) {
         y = groundY;
         _yVelocity = 0;
         _isJumping = false;
         isGliding = false;
         hasDoubleJumped = false;
         if (current != DinoState.hit) {
            current = DinoState.running;
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
    } else {
      // Access Double Jump or Glide trigger
      if (characterType == CharacterType.atleta && !hasDoubleJumped) {
         _yVelocity = jumpForce; // Double jump
         hasDoubleJumped = true;
      } else if (characterType == CharacterType.gravedadZero) {
        // Handled by holding button, but maybe jump press toggles?
        // Usually glide is holding.
        isGliding = true;
      }
    }
  }
  
  void stopGlide() {
    isGliding = false;
  }
  
  void activateAbility() {
    if (characterType == CharacterType.pistolero) {
      if (cooldownTimer <= 0) {
        // Shoot
        // Spawning at center height relative to position (bottom-left)
        gameRef.add(Projectile(position: position + Vector2(size.x, -size.y / 2)));
        cooldownTimer = pistoleroCooldown;
        
        // Trigger animation
        current = DinoState.shooting;
        abilityDurationTimer = 0.5; // Pose duration
      }
    } else if (characterType == CharacterType.fantasma) {
       if (cooldownTimer <= 0) {
         isIntangible = true;
         abilityDurationTimer = fantasmaDuration;
         cooldownTimer = fantasmaCooldown; // Or duration + cooldown?
       }
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Obstacle) {
      print("Collision! Type: $characterType, Shield: $hasShield, Intangible: $isIntangible");
      if (isIntangible) return; // Pass through

      if (hasShield) {
        // Absorb hit
        hasShield = false; 
        print("Shield absorbed hit! Lives remaining: 1");
        
        // Tanque penalty
        if (characterType == CharacterType.tanque) {
          gameRef.scoreSystem.score -= 500;
          if (gameRef.scoreSystem.score < 0) gameRef.scoreSystem.score = 0;
          cooldownTimer = tanqueShieldRegenTime;
          abilityDurationTimer = 1.0; // Mercy invincibility
          isIntangible = true;
        }
        
        // Vitalista invuln frames
        if (characterType == CharacterType.vitalista) {
          abilityDurationTimer = 2.0; 
          isIntangible = true; 
        }
        
        return; // Survived
      }

      print("Hit! Game Over.");
      hit();
    }
  }

  @override
  void hit() {
      current = DinoState.hit;
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
