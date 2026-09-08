import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/widgets/character_sprite_preview.dart';
import '../../../app/widgets/retro_pixel_widgets.dart';
import '../../../game/domain/character_definition.dart';
import '../../../game/domain/character_id.dart';

class CharactersScreen extends StatelessWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isCompactHeight = media.height < 500;
    final isMobile = media.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 14 : 24,
            isCompactHeight ? 8 : (isMobile ? 12 : 18),
            isMobile ? 14 : 24,
            isCompactHeight ? 4 : 8,
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
                          fontSize: isCompactHeight ? 11 : (isMobile ? 12 : 14),
                          fontWeight: FontWeight.bold,
                          color: RetroColors.cyan,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Catálogo de personajes, atributos y habilidades únicas.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.vt323(
                        fontSize: isCompactHeight ? 15 : (isMobile ? 16 : 18),
                        color: RetroColors.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RetroBadge(
                text: '${CharacterId.values.length} HÉROES',
                color: RetroColors.gold,
                fontSize: isCompactHeight ? 7.5 : 8.5,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(isCompactHeight ? 10 : (isMobile ? 14 : 20)),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isCompactHeight ? 360 : (isMobile ? 500 : 380),
              mainAxisExtent: isCompactHeight ? 250 : (isMobile ? 320 : 330),
              crossAxisSpacing: isCompactHeight ? 10 : 14,
              mainAxisSpacing: isCompactHeight ? 10 : 14,
            ),
            itemCount: CharacterId.values.length,
            itemBuilder: (context, index) {
              final id = CharacterId.values[index];
              final definition = id.definition;
              return RetroArcadeCard(
                borderColor: const Color(0xFF1E354F),
                accentHeaderColor: index == 0 ? RetroColors.cyan : null,
                padding: EdgeInsets.all(isCompactHeight ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RetroBadge(
                          text: 'P${index + 1} · ${definition.displayName.toUpperCase()}',
                          color: RetroColors.cyan,
                          fontSize: isCompactHeight ? 7.5 : 8,
                        ),
                        Row(
                          children: [
                            PixelIconAsset(
                              assetName: PixelIconAsset.heart,
                              size: isCompactHeight ? 14 : 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'x${definition.baseLives}',
                              style: GoogleFonts.pressStart2p(
                                fontSize: isCompactHeight ? 8.5 : 9,
                                color: RetroColors.magenta,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: isCompactHeight ? 6 : 10),
                    Container(
                      height: isCompactHeight ? 70 : 88,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B12),
                        border: Border.all(
                          color: const Color(0xFF162537),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CharacterRunningSprite(
                            assetName: definition.assetName,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 6 : 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070B12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF162537),
                          ),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            definition.description,
                            style: GoogleFonts.vt323(
                              fontSize: isCompactHeight ? 14 : 16,
                              color: RetroColors.textBright,
                              height: 1.15,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
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
