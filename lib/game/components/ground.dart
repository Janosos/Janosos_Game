import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';

class GroundComponent extends ParallaxComponent<DinoRunGame> with HasGameRef<DinoRunGame> {
  @override
  Future<void> onLoad() async {
    // Parallax logic prevents compression by repeating the texture
    parallax = await gameRef.loadParallax(
      [
        ParallaxImageData('layer_3_ground_modern.png'),
      ],
      baseVelocity: Vector2(200, 0), // Match dino speed roughly
      fill: LayerFill.none, // Don't stretch! Use actual image size
      alignment: Alignment.bottomLeft,
      repeat: ImageRepeat.repeatX,
    );
    
    priority = 5; 
    
    // Explicitly size and position
    // We want it at the bottom. The image is "Seamless city street".
    // Let's assume height is sufficient or we let it tile.
    anchor = Anchor.bottomLeft;
    position = Vector2(0, gameRef.size.y);
    size = Vector2(gameRef.size.x, gameRef.size.y * 0.25); // 25% height area
  }
  
  @override
  void update(double dt){
    super.update(dt);
    parallax?.baseVelocity = Vector2(gameRef.currentSpeed, 0);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update position and size when window resizes
    position = Vector2(0, size.y);
    this.size = Vector2(size.x, size.y * 0.25);
  }
}
