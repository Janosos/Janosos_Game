import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';

/// On-screen retro directional controls allowing the player to move left and right.
class DirectionalPad extends PositionComponent
    with HasGameReference<DinoRunGame>, TapCallbacks {
  DirectionalPad()
    : super(
        size: Vector2(136, 60),
        anchor: Anchor.bottomLeft,
        priority: 120,
      );

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _spritesLoaded = false;

  late final Sprite _leftNormal;
  late final Sprite _leftPressedSprite;
  late final Sprite _rightNormal;
  late final Sprite _rightPressedSprite;

  @override
  Future<void> onLoad() async {
    position = Vector2(16, game.size.y - 16);

    final leftImg = await game.images.load('dpad_arrow_left.png');
    final leftPressedImg = await game.images.load(
      'dpad_arrow_left_pressed.png',
    );
    final rightImg = await game.images.load('dpad_arrow_right.png');
    final rightPressedImg = await game.images.load(
      'dpad_arrow_right_pressed.png',
    );

    _leftNormal = Sprite(leftImg);
    _leftPressedSprite = Sprite(leftPressedImg);
    _rightNormal = Sprite(rightImg);
    _rightPressedSprite = Sprite(rightPressedImg);
    _spritesLoaded = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(16, size.y - 16);
  }

  @override
  bool containsPoint(Vector2 point) {
    final left = position.x;
    final top = position.y - height;
    final right = position.x + width;
    final bottom = position.y;
    return point.x >= left - 8 &&
        point.x <= right + 8 &&
        point.y >= top - 8 &&
        point.y <= bottom + 8;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final localX = event.localPosition.x;
    if (localX <= 64) {
      _leftPressed = true;
      _rightPressed = false;
      game.dino.moveLeft();
    } else if (localX >= 72) {
      _rightPressed = true;
      _leftPressed = false;
      game.dino.moveRight();
    }
    event.handled = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _leftPressed = false;
    _rightPressed = false;
    game.dino.stopMoving();
    event.handled = true;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _leftPressed = false;
    _rightPressed = false;
    game.dino.stopMoving();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_spritesLoaded) return;

    final leftSprite = _leftPressed ? _leftPressedSprite : _leftNormal;
    leftSprite.render(canvas, position: Vector2(0, 0), size: Vector2(60, 60));

    final rightSprite = _rightPressed ? _rightPressedSprite : _rightNormal;
    rightSprite.render(
      canvas,
      position: Vector2(76, 0),
      size: Vector2(60, 60),
    );
  }
}
