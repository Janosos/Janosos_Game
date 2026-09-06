import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

import 'retro_pixel_widgets.dart';

/// Renders a single cropped frame (top-left quadrant) of a character's 2x2 sprite sheet.
/// Ideal for small icons, dropdowns, list items, and badges.
class CharacterIcon extends StatelessWidget {
  const CharacterIcon({
    super.key,
    required this.assetName,
    this.size = 24,
    this.colorFilter,
  });

  final String assetName;
  final double size;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topLeft,
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: Image.asset(
            'assets/images/$assetName',
            width: size * 2,
            height: size * 2,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                Icons.person,
                size: size * 0.8,
                color: RetroColors.cyan,
              ),
            ),
          ),
        ),
      ),
    );

    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: colorFilter!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Renders the 4-frame running animation of a character's 2x2 sprite sheet
/// using Flame's [SpriteAnimationWidget], identical to the Characters module.
class CharacterRunningSprite extends StatefulWidget {
  const CharacterRunningSprite({
    super.key,
    required this.assetName,
    this.stepTime = 0.15,
    this.playing = true,
  });

  final String assetName;
  final double stepTime;
  final bool playing;

  @override
  State<CharacterRunningSprite> createState() => _CharacterRunningSpriteState();
}

class _CharacterRunningSpriteState extends State<CharacterRunningSprite> {
  SpriteAnimation? _animation;
  double _fw = 0;
  double _fh = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CharacterRunningSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final image = await Flame.images.load(widget.assetName);
      if (!mounted) return;
      final fw = image.width / 2.0;
      final fh = image.height / 2.0;

      final frame0 = Sprite(
        image,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(fw, fh),
      );
      final frame1 = Sprite(
        image,
        srcPosition: Vector2(fw, 0),
        srcSize: Vector2(fw, fh),
      );
      final frame2 = Sprite(
        image,
        srcPosition: Vector2(0, fh),
        srcSize: Vector2(fw, fh),
      );
      final frame3 = Sprite(
        image,
        srcPosition: Vector2(fw, fh),
        srcSize: Vector2(fw, fh),
      );

      final anim = SpriteAnimation.spriteList([
        frame0,
        frame1,
        frame2,
        frame3,
      ], stepTime: widget.stepTime);

      if (!mounted) return;
      setState(() {
        _animation = anim;
        _fw = fw;
        _fh = fh;
        _hasError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: CharacterIcon(
          assetName: widget.assetName,
          size: 48,
        ),
      );
    }

    if (_animation == null) {
      return Center(
        child: CharacterIcon(
          assetName: widget.assetName,
          size: 48,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _fw,
        height: _fh,
        child: SpriteAnimationWidget(
          animation: _animation!,
          animationTicker: _animation!.createTicker(),
          playing: widget.playing,
          anchor: Anchor.center,
        ),
      ),
    );
  }
}
