import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';
import 'obstacle.dart';

class Projectile extends SpriteComponent with HasGameRef<DinoRunGame>, CollisionCallbacks {
  final double speed = 800.0;

  Projectile({required Vector2 position}) : super(position: position, size: Vector2(32, 16), priority: 20);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('bullet.png');
    add(RectangleHitbox());
  }
  
  // render is handled by SpriteComponent

  @override
  void update(double dt) {
    super.update(dt);
    x += speed * dt;

    if (x > gameRef.size.x + 100) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Obstacle) {
      other.removeFromParent();
      removeFromParent();
      // Optional: Add score or explosion effect
    }
  }
}
