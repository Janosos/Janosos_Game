import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/widgets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/app_audio_manager.dart';
import '../dino_run_game.dart';
import '../domain/character_definition.dart';
import '../domain/character_id.dart';
import '../domain/run_configuration.dart';

class CharacterSelectionOverlay extends StatefulWidget {
  final DinoRunGame game;
  final RunConfiguration Function(CharacterId characterId)
  configurationForCharacter;

  const CharacterSelectionOverlay({
    super.key,
    required this.game,
    required this.configurationForCharacter,
  });

  @override
  State<CharacterSelectionOverlay> createState() =>
      _CharacterSelectionOverlayState();
}

class _CharacterSelectionOverlayState extends State<CharacterSelectionOverlay> {
  CharacterId? selectedCharacter;

  // Colors from HTML
  static const Color frameBorderColor = Color(0xFF2affff);
  static const Color frameBgColor = Color(0xF2050a10); // 0.95 opacity
  static const Color titleColor = Color(0xFF29ffe4);
  static const Color charBorderColor = Color(0xFF333333);
  static const Color charBgColor = Color(0xFF0f1520);
  static const Color selectedBorderColor = Color(0xFF29ffe4);
  static const Color textColor = Color(0xFFd4ffea);

  String getAssetPath(CharacterId id) =>
      'assets/images/${id.definition.assetName}';

  Widget _buildCharacterGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10, // Adjusted spacing for tighter grid
        mainAxisSpacing: 10,
        childAspectRatio: 0.85, // Slightly taller for name text
      ),
      itemCount: CharacterId.values.length,
      itemBuilder: (context, index) {
        final type = CharacterId.values[index];
        final isSelected = selectedCharacter == type;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              AppAudioManager.playSfx(
                'Select.wav',
                audioEnabled:
                    widget.game.runConfiguration.sfxEnabled &&
                    widget.game.runConfiguration.audioEnabled,
              );
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
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedBorderColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: selectedBorderColor.withValues(alpha: 0.1),
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: Offset.zero,
                          blurStyle: BlurStyle.inner,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4, // More space for image
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildCharacterImage(
                        type,
                        animated: false,
                      ), // Static icon
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          type.definition.displayName.toUpperCase(),
                          maxLines: 1,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 9,
                            color: isSelected
                                ? selectedBorderColor
                                : const Color(0xFF888888),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Modified to handle both Static (Cropped) and Animated
  Widget _buildCharacterImage(CharacterId type, {required bool animated}) {
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
            final animation = spriteSheet.createAnimation(
              row: 0,
              stepTime: 0.15,
              to: 4,
            ); // Run is row 0 commonly

            return FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: SpriteAnimationWidget(
                  animation: animation,
                  animationTicker: animation.createTicker(),
                  playing: !widget.game.runConfiguration.reduceMotion,
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
                child: SpriteWidget(sprite: sprite),
              ),
            );
          }
        }
        return const SizedBox();
      },
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
          final bool isShortScreen = constraints.maxHeight < 520;

          return Container(
            // Dynamic width/height constraints
            width: math.min(constraints.maxWidth * 0.95, 900),
            height: isPortrait
                ? constraints.maxHeight * 0.95
                : math.min(constraints.maxHeight * 0.94, 600),
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: isPortrait ? double.infinity : 600,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 24,
              vertical: isShortScreen ? 10 : (isSmallScreen ? 16 : 24),
            ),
            decoration: BoxDecoration(
              color: frameBgColor,
              border: Border.all(
                color: frameBorderColor,
                width: isSmallScreen ? 2 : 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: frameBorderColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'SELECCIONA TU PERSONAJE',
                      style: GoogleFonts.pressStart2p(
                        fontSize: isSmallScreen ? 14 : 22,
                        color: titleColor,
                        shadows: [
                          const Shadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                          const Shadow(
                            color: Color(0x8029ffe4),
                            offset: Offset(0, 0),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Main Content
                Expanded(
                  child: isPortrait
                      ? _buildPortraitLayout()
                      : _buildLandscapeLayout(),
                ),

                SizedBox(height: isShortScreen ? 6 : (isSmallScreen ? 10 : 20)),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: isShortScreen ? 38 : (isSmallScreen ? 46 : 60),
                  child: ElevatedButton(
                    onPressed: selectedCharacter != null
                        ? () {
                            AppAudioManager.playSfx(
                              'Select.wav',
                              audioEnabled:
                                  widget.game.runConfiguration.sfxEnabled &&
                                  widget.game.runConfiguration.audioEnabled,
                            );
                            widget.game.startGame(
                              widget.configurationForCharacter(
                                selectedCharacter!,
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: titleColor,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white30,
                      elevation: 10,
                      shadowColor: titleColor.withValues(alpha: 0.4),
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CONFIRMAR SELECCIÓN',
                        style: GoogleFonts.pressStart2p(
                          fontSize: isShortScreen
                              ? 10
                              : (isSmallScreen ? 12 : 14),
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: Grid
        Expanded(flex: 5, child: _buildScrollableGrid()),

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
        Expanded(flex: 4, child: _buildScrollableGrid()),

        const SizedBox(height: 10),

        // Middle: Large Preview (Full Width)
        Expanded(
          flex: 3,
          child:
              _buildPreviewBox(), // Now takes full width, allowing larger sprite
        ),

        const SizedBox(height: 10),

        // Bottom: Description
        Expanded(flex: 2, child: _buildDescriptionBox()),
      ],
    );
  }

  // Helper for scrolling grid
  Widget _buildScrollableGrid() {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        dragDevices: {ui.PointerDeviceKind.touch, ui.PointerDeviceKind.mouse},
      ),
      child: _buildCharacterGrid(),
    );
  }

  Widget _buildPreviewBox() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 140;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0x4D000000),
            border: Border.all(color: const Color(0xFF333333), width: 2),
          ),
          padding: EdgeInsets.all(isShort ? 8 : 16),
          child: selectedCharacter != null
              ? _buildCharacterImage(selectedCharacter!, animated: true)
              : Center(
                  child: Text(
                    "?",
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white24,
                      fontSize: isShort ? 26 : 40,
                    ),
                  ),
                ),
        );
      },
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
                border: Border(bottom: BorderSide(color: titleColor, width: 2)),
              ),
              margin: const EdgeInsets.only(bottom: 10), // tighter
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                selectedCharacter!.definition.displayName.toUpperCase(),
                style: GoogleFonts.pressStart2p(
                  color: titleColor,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  dragDevices: {
                    ui.PointerDeviceKind.touch,
                    ui.PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(
                  child: Text(
                    selectedCharacter!.definition.description,
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
            Text(
              "Selecciona un personaje...",
              style: GoogleFonts.pressStart2p(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
