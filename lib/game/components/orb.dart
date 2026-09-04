import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../dino_run_game.dart';

class OrbComponent extends SpriteComponent
    with HasGameReference<DinoRunGame>, CollisionCallbacks {
  final double speed;

  OrbComponent({required Vector2 position, required this.speed})
    : super(position: position, size: Vector2(40, 40));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite('orb.png');
    add(
      CircleHitbox(radius: 16, position: Vector2(4, 4)),
    ); // Adjusted for 40x40
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= speed * dt;

    if (x < -width) {
      removeFromParent();
    }
  }
}
