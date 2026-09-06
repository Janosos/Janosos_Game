import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dino_run_game.dart';
import '../domain/hud_settings.dart';

/// On-screen retro directional controls allowing the player to move left and right.
class DirectionalPad extends PositionComponent
    with HasGameReference<DinoRunGame>, TapCallbacks {
  DirectionalPad({this.settings = HudSettings.defaults})
    : super(
        size: Vector2(136 * settings.dpadScale, 60 * settings.dpadScale),
        anchor: settings.dpadInvertSide
            ? Anchor.bottomRight
            : Anchor.bottomLeft,
        priority: 120,
      );

  final HudSettings settings;

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _spritesLoaded = false;

  late final Sprite _leftNormal;
  late final Sprite _leftPressedSprite;
  late final Sprite _rightNormal;
  late final Sprite _rightPressedSprite;

  void _updateLayout(Vector2 size) {
    final isCompact = size.y < 500;
    final scale = settings.dpadScale;
    this.size = isCompact
        ? Vector2(116 * scale, 52 * scale)
        : Vector2(136 * scale, 60 * scale);
    anchor = settings.dpadInvertSide ? Anchor.bottomRight : Anchor.bottomLeft;
    position = Vector2(
      settings.dpadInvertSide
          ? size.x - (isCompact ? 12 : 16)
          : (isCompact ? 12 : 16),
      size.y - (isCompact ? 10 : 16),
    );
  }

  @override
  Future<void> onLoad() async {
    _updateLayout(game.size);

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
    _updateLayout(size);
  }

  @override
  bool containsPoint(Vector2 point) {
    final left = settings.dpadInvertSide ? position.x - width : position.x;
    final top = position.y - height;
    final right = settings.dpadInvertSide ? position.x : position.x + width;
    final bottom = position.y;
    return point.x >= left - 8 &&
        point.x <= right + 8 &&
        point.y >= top - 8 &&
        point.y <= bottom + 8;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final localX = event.localPosition.x;
    final btnSize = height;
    final rightBtnX = width - btnSize;
    if (localX <= btnSize + 4) {
      _leftPressed = true;
      _rightPressed = false;
      game.dino.moveLeft();
    } else if (localX >= rightBtnX - 4) {
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
    if (!_spritesLoaded) return;

    if (settings.dpadOpacity < 1.0) {
      canvas.saveLayer(
        null,
        Paint()
          ..color = Colors.white.withValues(alpha: settings.dpadOpacity),
      );
    }

    super.render(canvas);

    final btnSize = height;
    final rightBtnX = width - btnSize;

    final leftSprite = _leftPressed ? _leftPressedSprite : _leftNormal;
    leftSprite.render(
      canvas,
      position: Vector2(0, 0),
      size: Vector2(btnSize, btnSize),
    );

    final rightSprite = _rightPressed ? _rightPressedSprite : _rightNormal;
    rightSprite.render(
      canvas,
      position: Vector2(rightBtnX, 0),
      size: Vector2(btnSize, btnSize),
    );

    if (settings.dpadOpacity < 1.0) {
      canvas.restore();
    }
  }
}

