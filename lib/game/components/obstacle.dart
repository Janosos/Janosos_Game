import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../dino_run_game.dart';
import 'dino.dart';

class Obstacle extends SpriteAnimationComponent with HasGameRef<DinoRunGame>, CollisionCallbacks {
  final double speed = 200.0;
  final String obstacleName;
  
  Obstacle({required this.obstacleName});

  @override
  Future<void> onLoad() async {
    // Load image (strip of 4 frames vertical)
    final image = await gameRef.images.load('${obstacleName}_clean.png');
    
    // Calculate frame size
    final frameWidth = image.width.toDouble();
    final frameHeight = image.height / 4;
    final frameSize = Vector2(frameWidth, frameHeight);
    
    // Create animation
    animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.1,
        textureSize: frameSize,
        amountPerRow: 1, // Vertical strip
      ),
    );
    
    // Visual size on screen
    // Asset is wide (2:1 ratio). Changing to 72x48 to uncompress.
    size = Vector2(72, 48); 
    anchor = Anchor.bottomLeft;
    priority = 10; 
    
    // Position on ground
    position = Vector2(gameRef.size.x, gameRef.size.y * 0.75);
    
    // Forgiving hitbox (smaller than sprite and shifted right)
    add(RectangleHitbox(
      // Much tighter hitbox to avoid invisible walls
      position: Vector2(24, 16), 
      size: Vector2(24, 20), 
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move left using dynamic game speed
    // Use gameRef.currentSpeed instead of local constant speed
    x -= gameRef.currentSpeed * dt;
    
    // Remove if off screen
    if (x < -width) {
      removeFromParent();
    }
  }


}
