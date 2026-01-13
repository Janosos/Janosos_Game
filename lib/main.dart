import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/dino_run_game.dart';
import 'game/hud/character_selection_overlay.dart';
import 'game/hud/start_menu_overlay.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: DinoRunApp(),
      ),
    )
  );
}

class DinoRunApp extends StatelessWidget {
  const DinoRunApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(
          game: DinoRunGame(),
          overlayBuilderMap: {
            'StartMenu': (BuildContext context, DinoRunGame game) {
              return StartMenuOverlay(game: game);
            },
            'GameOverMenu': (BuildContext context, DinoRunGame game) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       const Text(
                        'Game Over',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                       const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          game.resetGame();
                        },
                        child: const Text('Restart', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                ),
              );
            },
            'CharacterSelection': (BuildContext context, DinoRunGame game) {
              return CharacterSelectionOverlay(game: game);
            },
          },
        ),
        // Static Version Label (Bottom Left)
        Positioned(
          left: 20,
          bottom: 20,
          child: IgnorePointer( // Ensure it doesn't block clicks
            child: Image.asset(
              'assets/images/version_v3_retro.png',
              width: 50, // Small retro size
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ); 
  }
}
