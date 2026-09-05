import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';

class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            isMobile ? 12 : 20,
            isMobile ? 16 : 24,
            8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'SELECCIÓN DE HÉROES',
                        style: GoogleFonts.pressStart2p(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: RetroColors.cyan,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catálogo de personajes y habilidades.',
                      style: GoogleFonts.vt323(
                        fontSize: isMobile ? 16 : 18,
                        color: RetroColors.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RetroBadge(
                text: '${CharacterId.values.length} HÉROES',
                color: RetroColors.gold,
                fontSize: 8,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isMobile ? 500 : 380,
              mainAxisExtent: isMobile ? 290 : 310,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: CharacterId.values.length,
            itemBuilder: (context, index) {
              final id = CharacterId.values[index];
              final definition = id.definition;
              return RetroArcadeCard(
                borderColor: const Color(0xFF1E354F),
                accentHeaderColor: index == 0 ? RetroColors.cyan : null,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RetroBadge(
                          text: 'P${index + 1}',
                          color: RetroColors.cyan,
                          fontSize: 8,
                        ),
                        Row(
                          children: [
                            const PixelIconAsset(
                              assetName: PixelIconAsset.heart,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'x${definition.baseLives}',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 9,
                                color: RetroColors.magenta,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF070B12),
                          border: Border.all(
                            color: const Color(0xFF162537),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CharacterRunningSprite(
                              assetName: definition.assetName,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      definition.displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vt323(
                        fontSize: 15,
                        color: RetroColors.textMuted,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CharacterRunningSprite extends StatefulWidget {
  const CharacterRunningSprite({super.key, required this.assetName});

  final String assetName;

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
      ], stepTime: 0.15);

      setState(() {
        _animation = anim;
        _fw = fw;
        _fh = fh;
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
      return Image.asset(
        'assets/images/${widget.assetName}',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    }

    if (_animation == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: RetroColors.cyan,
          ),
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
          playing: true,
          anchor: Anchor.center,
        ),
      ),
    );
  }
}
