import 'package:flutter/material.dart';
import '../audio/app_audio_manager.dart';
import '../dino_run_game.dart';
import '../domain/run_configuration.dart';

class StartMenuOverlay extends StatefulWidget {
  final DinoRunGame game;
  const StartMenuOverlay({super.key, required this.game});

  @override
  State<StartMenuOverlay> createState() => _StartMenuOverlayState();
}

class _StartMenuOverlayState extends State<StartMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 20s for a slow, smooth loop.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (!widget.game.runConfiguration.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Moving Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Diagonal scroll
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/intro_bg_checkerboard.png',
                    repeat: ImageRepeat.repeat,
                    alignment: Alignment(
                      // Loop from -1.0 to 1.0 isn't enough for seamless wrap without careful math.
                      // Easier way: Use Container with DecorationImage and Alignment.
                      // Alignment(x, y): As x changes, it shifts visible window.
                      // If image is "repeat", alignment shifts the phase.
                      _controller.value * 2 - 1, // -1 to 1
                      _controller.value * 2 - 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // 2. Dark Overlay for better legibility
        Container(color: Colors.black.withValues(alpha: 0.3)),

        // 3. Content (responsive to thin landscape Android screens)
        SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactHeight = constraints.maxHeight < 460;
                final isUltraThin = constraints.maxHeight < 360;

                final titleHeight = isUltraThin
                    ? 68.0
                    : (isCompactHeight ? 90.0 : 140.0);
                final spacing = isUltraThin
                    ? 10.0
                    : (isCompactHeight ? 16.0 : 36.0);
                final buttonWidth = isUltraThin
                    ? 150.0
                    : (isCompactHeight ? 175.0 : 210.0);

                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/title_retro.png',
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: titleHeight,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            '★ JANOSOS ARCADE ★',
                            style: TextStyle(
                              color: Color(0xFF29FFE4),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing),
                        GestureDetector(
                          onTap: () async {
                            AppAudioManager.playSfx(
                              'Select.wav',
                              audioEnabled:
                                  widget.game.runConfiguration.sfxEnabled &&
                                  widget.game.runConfiguration.audioEnabled,
                            );
                            if (widget.game.runConfiguration.experience !=
                                RunExperience.endlessRunner) {
                              await widget.game.startGame(
                                widget.game.runConfiguration,
                              );
                              return;
                            }
                            widget.game.overlays.remove('StartMenu');
                            widget.game.overlays.add('CharacterSelection');
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Image.asset(
                              'assets/images/start_button_retro.png',
                              width: buttonWidth,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF29FFE4),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                child: const Text(
                                  'PRESS START',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
