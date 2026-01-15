import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import '../dino_run_game.dart';

class StartMenuOverlay extends StatefulWidget {
  final DinoRunGame game;
  const StartMenuOverlay({Key? key, required this.game}) : super(key: key);

  @override
  State<StartMenuOverlay> createState() => _StartMenuOverlayState();
}

class _StartMenuOverlayState extends State<StartMenuOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 20s for a slow, smooth loop.
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
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
                      _controller.value * 2 - 1
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        
        // 2. Dark Overlay for better legibility
        Container(color: Colors.black.withOpacity(0.3)),

        // 3. Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/title_retro.png',
                width: MediaQuery.of(context).size.width * 0.8,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 50),
              GestureDetector(
                onTap: () {
                  FlameAudio.play('Select.wav');
                  widget.game.overlays.remove('StartMenu');
                  widget.game.overlays.add('CharacterSelection');
                  // Do not stop controller here; widget will be disposed.
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Image.asset(
                    'assets/images/start_button_retro.png',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
