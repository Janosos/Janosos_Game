import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dino_run_game.dart';

class AbilityButton extends HudButtonComponent {
  final DinoRunGame game;
  
  AbilityButton({required this.game}) 
      : super(
          margin: const EdgeInsets.only(right: 20, bottom: 20),
          anchor: Anchor.bottomRight,
          priority: 100,
        );
        
  @override
  Future<void> onLoad() async {
    // Load image asynchronously
    final spriteImg = await game.images.load('ability_button.png');
    button = SpriteComponent(sprite: Sprite(spriteImg), size: Vector2(80, 80)); 
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    print("Ability Button Tapped!");
    super.onTapDown(event);
    game.dino.activateAbility();
    event.handled = true; // Stop propagation to game tap detector
  }
}
