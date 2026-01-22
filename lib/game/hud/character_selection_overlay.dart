import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/widgets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart'; // Added import
import 'package:flame_audio/flame_audio.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../dino_run_game.dart';

enum CharacterType {
  pistolero('Jano', 'Disparo Destructor: Dispara un proyectil recto que destruye obstáculos. (Cooldown: 10s)'),
  vitalista('Parker', 'Vida Extra: Tiene una vida adicional. El primer choque no lo mata.'),
  tanque('Chema', 'Escudo con Costo: Absorbe un golpe (regenera 15s). Penalización: -500 puntos al impactar.'),
  fantasma('Conra', 'Intangibilidad: se vuelve invisible por 3 seg. (Cooldown: 10s)'),
  atleta('Shyno', 'Doble Salto: Permite realizar un segundo salto en el aire.'),
  gravedadZero('Nakama', 'Planeo: Mantén presionado el salto para reducir la velocidad de caída.'),
  nanic('Nanic', 'Recoge 5 orbes para cargar energía. Con energía llena: Velocidad+ y Puntos x2. Al usar la habilidad: vuelves a velocidad normal y activas un escudo eléctrico de 2s que destruye el próximo obstáculo.');

  final String name;
  final String description;
  const CharacterType(this.name, this.description);
}

class CharacterSelectionOverlay extends StatefulWidget {
  final DinoRunGame game;

  const CharacterSelectionOverlay({Key? key, required this.game}) : super(key: key);

  @override
  State<CharacterSelectionOverlay> createState() => _CharacterSelectionOverlayState();
}

class _CharacterSelectionOverlayState extends State<CharacterSelectionOverlay> {
  CharacterType? selectedCharacter;

  // Colors from HTML
  static const Color bgColor = Color(0xFF080b0f);
  static const Color frameBorderColor = Color(0xFF2affff);
  static const Color frameBgColor = Color(0xF2050a10); // 0.95 opacity
  static const Color titleColor = Color(0xFF29ffe4);
  static const Color charBorderColor = Color(0xFF333333);
  static const Color charBgColor = Color(0xFF0f1520);
  static const Color hoverBorderColor = Color(0xFFffd845);
  static const Color selectedBorderColor = Color(0xFF29ffe4);
  static const Color textColor = Color(0xFFd4ffea);

  String getAssetPath(CharacterType type) {
    switch (type) {
      case CharacterType.pistolero: return 'assets/images/jano_clean.png';
      case CharacterType.vitalista: return 'assets/images/parker_clean.png'; 
      case CharacterType.tanque: return 'assets/images/chema_clean.png'; 
      case CharacterType.fantasma: return 'assets/images/conra_clean.png'; 
      case CharacterType.atleta: return 'assets/images/shyno_clean.png'; 
      case CharacterType.gravedadZero: return 'assets/images/nakama_clean.png'; 
      case CharacterType.nanic: return 'assets/images/nanic_clean.png'; 
    }
  }

  Widget _buildCharacterGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10, // Adjusted spacing for tighter grid
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // Slightly taller for name text
      ),
      itemCount: CharacterType.values.length,
      itemBuilder: (context, index) {
        final type = CharacterType.values[index];
        final isSelected = selectedCharacter == type;
        
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              FlameAudio.play('Select.wav');
              setState(() {
                selectedCharacter = type;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF121820) : charBgColor, 
                border: Border.all(
                  color: isSelected ? selectedBorderColor : charBorderColor,
                  width: 2,
                ),
                boxShadow: isSelected ? [
                   BoxShadow(color: selectedBorderColor.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                   BoxShadow(color: selectedBorderColor.withOpacity(0.1), blurRadius: 0, spreadRadius: 0, offset: Offset.zero, blurStyle: BlurStyle.inner),
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4, // More space for image
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCharacterImage(type, animated: false), // Static icon
                    ),
                  ),
                  Expanded(
                     flex: 1,
                     child: Text(
                      type.name.toUpperCase(),
                      style: GoogleFonts.pressStart2p( // RETRO FONT
                        fontSize: 10, // kept at 10, was 8 previously? Wait, in my previous edit I replaced it. 
                                      // Checking previous content: it was 8. I will make it 10.
                        color: isSelected ? selectedBorderColor : const Color(0xFF888888),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Modified to handle both Static (Cropped) and Animated
  Widget _buildCharacterImage(CharacterType type, {required bool animated}) {
      final assetName = getAssetPath(type).replaceAll('assets/images/', '');
      return FutureBuilder<ui.Image>(
        future: Future.value(widget.game.images.fromCache(assetName)),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
             final image = snapshot.data!;
             final double frameWidth = image.width / 2.0;
             final double frameHeight = image.height / 2.0;
             
             if (animated) {
               // Full Animation (running)
               final spriteSheet = SpriteSheet(
                 image: image,
                 srcSize: Vector2(frameWidth, frameHeight),
               );
               final animation = spriteSheet.createAnimation(row: 0, stepTime: 0.15, to: 4); // Run is row 0 commonly
               
               return FittedBox(
                 fit: BoxFit.contain,
                 child: SizedBox(
                   width: frameWidth,
                   height: frameHeight,
                   child: SpriteAnimationWidget(
                     animation: animation,
                     animationTicker: animation.createTicker(),
                     playing: true,
                     anchor: Anchor.center,
                   ),
                 ),
               );
             } else {
               // Static Cropped (First Frame)
               final sprite = Sprite(
                 image,
                 srcPosition: Vector2(0, 0),
                 srcSize: Vector2(frameWidth, frameHeight),
               );
               return FittedBox(
                 fit: BoxFit.contain,
                 child: SizedBox(
                    width: frameWidth,
                    height: frameHeight,
                    child: SpriteWidget(sprite: sprite)
                 ),
               );
             }
          }
          return const SizedBox();
        }
      );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine layout mode based on aspect ratio or width
          final bool isPortrait = constraints.maxHeight > constraints.maxWidth;
          final bool isSmallScreen = constraints.maxWidth < 600;

          return Container(
            // Dynamic width/height constraints
            width: isSmallScreen ? constraints.maxWidth * 0.95 : 900,
            height: isPortrait ? constraints.maxHeight * 0.95 : 600,
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: isPortrait ? double.infinity : 600,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 15 : 30, 
              vertical: isSmallScreen ? 20 : 30
            ),
            decoration: BoxDecoration(
              color: frameBgColor,
              border: Border.all(color: frameBorderColor, width: isSmallScreen ? 2 : 4),
              boxShadow: [
                 BoxShadow(
                  color: frameBorderColor.withOpacity(0.2),
                  blurRadius: 30,
                )
              ],
            ),
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'SELECCIONA TU PERSONAJE',
                    style: GoogleFonts.pressStart2p(
                      fontSize: isSmallScreen ? 16 : 24, // increased from 14
                      color: titleColor,
                      shadows: [
                        const Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                        const Shadow(color: Color(0x8029ffe4), offset: Offset(0, 0), blurRadius: 10),
                      ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: isPortrait 
                  ? _buildPortraitLayout() 
                  : _buildLandscapeLayout(), 
                ),
                
                SizedBox(height: isSmallScreen ? 10 : 20),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 50 : 60,
                  child: ElevatedButton(
                    onPressed: selectedCharacter != null ? () {
                      FlameAudio.play('Select.wav');
                      widget.game.startGame(selectedCharacter!);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: titleColor, 
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white30,
                      elevation: 10,
                      shadowColor: titleColor.withOpacity(0.4),
                      shape: const BeveledRectangleBorder(
                         borderRadius: BorderRadius.only(
                           topLeft: Radius.circular(10),
                           bottomRight: Radius.circular(10),
                         )
                      ),
                    ),
                    child: Text(
                      'CONFIRMAR SELECCIÓN',
                      style: GoogleFonts.pressStart2p(
                        fontSize: isSmallScreen ? 14 : 14, // increased from 12
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: Grid
        Expanded(
          flex: 5,
          child: _buildScrollableGrid(),
        ),
        
        const SizedBox(width: 20),
        
        // Right: Info Panel
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 4, child: _buildPreviewBox()),
              const SizedBox(height: 15),
              Expanded(flex: 5, child: _buildDescriptionBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top: Grid
        Expanded(
          flex: 4, 
          child: _buildScrollableGrid(),
        ),
        
        const SizedBox(height: 10),
        
        // Middle: Large Preview (Full Width)
        Expanded(
          flex: 3,
          child: _buildPreviewBox(), // Now takes full width, allowing larger sprite
        ),

        const SizedBox(height: 10),

        // Bottom: Description
        Expanded(
          flex: 2,
          child: _buildDescriptionBox(),
        ),
      ],
    );
  }

  // Helper for scrolling grid
  Widget _buildScrollableGrid() {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        dragDevices: { 
          ui.PointerDeviceKind.touch,
          ui.PointerDeviceKind.mouse,
        }
      ),
      child: _buildCharacterGrid(),
    );
  }

  Widget _buildPreviewBox() {
    return Container(
       decoration: BoxDecoration(
         color: const Color(0x4D000000), 
         border: Border.all(color: const Color(0xFF333333), width: 2),
       ),
       padding: const EdgeInsets.all(20),
       child: selectedCharacter != null 
         ? _buildCharacterImage(selectedCharacter!, animated: true) 
         : Center(child: Text("?", style: GoogleFonts.pressStart2p(color: Colors.white24, fontSize: 40))),
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
       decoration: BoxDecoration(
         color: const Color(0xCC0a141e),
         border: Border.all(color: titleColor, width: 2),
       ),
       padding: const EdgeInsets.all(15),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            if (selectedCharacter != null) ...[
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: titleColor, width: 2))
                ),
                margin: const EdgeInsets.only(bottom: 10), // tighter
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  selectedCharacter!.name.toUpperCase(),
                  style: GoogleFonts.pressStart2p(
                    color: titleColor,
                    fontSize: 10,
                  ),
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(dragDevices: {ui.PointerDeviceKind.touch, ui.PointerDeviceKind.mouse}),
                  child: SingleChildScrollView(
                    child: Text(
                      selectedCharacter!.description,
                      style: GoogleFonts.pressStart2p(
                        color: textColor,
                        fontSize: 10, // increased from 8
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              Text("Selecciona un personaje...", style: GoogleFonts.pressStart2p(color: Colors.white54, fontSize: 10)),
         ],
       ),
    );
  }
}
