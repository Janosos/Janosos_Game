import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';

class SkyComponent extends ParallaxComponent<DinoRunGame> {
  @override
  Future<void> onLoad() async {
    // Parallax background using the procedurally generated city
    parallax = await game.loadParallax(
      [
        ParallaxImageData('layer_1_sky_modern.png'),
        ParallaxImageData('layer_2_city_modern.png'),
      ],
      baseVelocity: Vector2(
        10,
        0,
      ), // Slow scroll for sky, city will be faster due to parallax depth
      velocityMultiplierDelta: Vector2(1.5, 0), // City moves faster than sky
      fill: LayerFill
          .height, // Use height to determine scale (cover screen vertically)
      alignment: Alignment.center,
      repeat: ImageRepeat.repeatX,
    );

    priority = -10;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Sky moves much slower than foreground (0.1x)
    parallax?.baseVelocity = game.runConfiguration.reduceMotion
        ? Vector2.zero()
        : Vector2(game.currentSpeed * 0.1, 0);
  }
}
