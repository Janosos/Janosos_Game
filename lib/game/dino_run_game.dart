
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/camera.dart';
import 'components/dino.dart';
import 'components/ground.dart';
import 'components/sky.dart';
import 'components/obstacle_manager.dart';
import 'hud/score.dart';
import 'hud/character_selection_overlay.dart';
import 'hud/ability_button.dart';
import 'hud/hud_indicators.dart';

class DinoRunGame extends FlameGame with TapDetector, HasCollisionDetection {
  late DinoComponent _dino;
  late GroundComponent _ground;
  late SkyComponent _sky;
  late ObstacleManager _obstacleManager;
  late ScoreSystem _scoreSystem;
  AbilityButton? _abilityButton;
  HudIndicators? _hudIndicators;
  
  DinoComponent get dino => _dino;
  ScoreSystem get scoreSystem => _scoreSystem;

  // Game Speed
  double currentSpeed = 200.0;
  final double startSpeed = 200.0;
  final double maxSpeed = 600.0;
  
  // Character Selection
  CharacterType selectedCharacter = CharacterType.pistolero;



  @override
  Future<void> onLoad() async {
    // Dynamic resolution based on window size
    // camera.viewport = FixedResolutionViewport(resolution: Vector2(960, 540));
    
    // Debug mode
    // debugMode = true;
    
    // Initialize BGM
    FlameAudio.bgm.initialize();

    // Add background/sky
    _sky = SkyComponent();
    add(_sky);


    // Add ground
    _ground = GroundComponent();
    add(_ground);

    // Add dino
    _dino = DinoComponent();
    _dino.priority = 10; // Above ground
    add(_dino);

    // Add obstacle manager
    _obstacleManager = ObstacleManager();
    _obstacleManager.priority = 10; // Ensure obstacles are above ground (5)
    add(_obstacleManager);
    
    // Add Score System
    _scoreSystem = ScoreSystem();
    _scoreSystem.priority = 100; // Always on top
    add(_scoreSystem);

    // Preload Assets
    await images.loadAll([
      'ability_button.png',
      'heart_indicator.png',
      'tank_shield_icon.png',

      'jano_clean.png',
      'parker_clean.png',
      'chema_clean.png',
      'conra_clean.png',
      'shyno_clean.png',
      'nakama_clean.png',
      'bullet.png' // just in case
    ]);

    // Preload Audio
    await FlameAudio.audioCache.loadAll([
      'Jump.wav',
      'Select.wav',
      'Shoot.wav',
      'Invisibility.wav',
      'Hit.wav',
      'Hit.wav',
      'LoopSong.wav',
    ]);

    // Initialize Game State
    pauseEngine();
    overlays.add('StartMenu');
  }

  void startGame(CharacterType character) async {
    // 1. Critical Game Logic (UI & State)
    selectedCharacter = character;
    overlays.remove('StartMenu');
    overlays.remove('CharacterSelection'); // Ensure this is removed
    overlays.remove('GameOverMenu');
    resumeEngine();
    
    // Set character
    _dino.setCharacter(selectedCharacter);
    
    // Cleanup HUD
    if (_abilityButton != null) {
      camera.viewport.remove(_abilityButton!);
      _abilityButton = null;
    }
    if (_hudIndicators != null) {
      camera.viewport.remove(_hudIndicators!);
      _hudIndicators = null;
    }

    // Add HUD Indicators
    _hudIndicators = HudIndicators();
    camera.viewport.add(_hudIndicators!);
    
    // Ability Button Management
    if (selectedCharacter == CharacterType.pistolero || selectedCharacter == CharacterType.fantasma) {
      _abilityButton = AbilityButton(game: this);
      camera.viewport.add(_abilityButton!);
    }
    
    _dino.reset();
    _obstacleManager.reset();
    _scoreSystem.reset();
    currentSpeed = startSpeed;

    // 2. Audio Logic
    print("Starting BGM (FlameAudio.bgm)...");
    try {
      // Ensure any previous bgm is stopped
      if (FlameAudio.bgm.isPlaying) {
         await FlameAudio.bgm.stop();
      }
      FlameAudio.bgm.play('LoopSong.wav', volume: 0.5);
      print("BGM command sent.");
    } catch (e) {
      print("Error setup BGM: $e");
    }
  }

  void gameOver() {
    try {
      FlameAudio.bgm.stop();
    } catch(e) {
      print("Error stopping BGM: $e");
    }
    
    _scoreSystem.saveHighScore();
    pauseEngine();
    overlays.add('GameOverMenu');
  }

  void resetGame() {
    overlays.remove('GameOverMenu');
    overlays.add('StartMenu');
    _dino.reset();
    _obstacleManager.reset();
    _scoreSystem.reset();
    currentSpeed = startSpeed;
    if (_abilityButton != null) {
      camera.viewport.remove(_abilityButton!);
      _abilityButton = null;
    }
    if (_hudIndicators != null) {
      camera.viewport.remove(_hudIndicators!);
      _hudIndicators = null;
    }
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Increase speed based on score
    // Every 500 points, increase speed by 10% or additive
    if (isMounted) {
      double score = _scoreSystem.currentScore;
      double newSpeed = startSpeed + (score / 10); // +10 speed per 100 points
      if (newSpeed > maxSpeed) newSpeed = maxSpeed;
      currentSpeed = newSpeed;
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (overlays.isActive('StartMenu')) {
      return; 
    } 
    
    // Check collision with Ability Button manually to be safe
    // Since we are using TapDetector which is global.
    if (_abilityButton != null) {
       // Check if point is inside button
       if (_abilityButton!.containsPoint(info.eventPosition.widget)) {
         return; // Do not jump
       }
    }

    if (overlays.isActive('GameOverMenu')) {
      resetGame();
    } else {
      _dino.jump();
    }
  }
  
  @override
  void onTapUp(TapUpInfo info) {
    _dino.stopGlide();
  }
  
  @override
  void onRemove() {
    FlameAudio.bgm.dispose();
    super.onRemove();
  }
}
