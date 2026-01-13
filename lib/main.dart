import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/dino_run_game.dart';
import 'game/hud/character_selection_overlay.dart';

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
    return GameWidget(
      game: DinoRunGame(),
      overlayBuilderMap: {
        'StartMenu': (BuildContext context, DinoRunGame game) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              // Optional: Transparent background or remove decoration
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Title
                   Image.asset(
                     'assets/images/title_retro.png',
                     width: MediaQuery.of(context).size.width * 0.8, // Responsive width
                     height: 150,
                     fit: BoxFit.contain,
                   ),
                  const SizedBox(height: 50),
                  // Retro Button
                  GestureDetector(
                    onTap: () {
                      game.overlays.remove('StartMenu');
                      game.overlays.add('CharacterSelection');
                    },
                    child: MouseRegion( // Optional hover effect helper if needed
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
          );
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
    ); 
  }
}
