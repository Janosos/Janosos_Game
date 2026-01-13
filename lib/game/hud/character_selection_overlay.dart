import 'package:flutter/material.dart';
import 'package:flame/widgets.dart';
import 'package:flame/components.dart';
import '../dino_run_game.dart';

enum CharacterType {
  pistolero('Jano', 'Disparo Destructor: Dispara un proyectil recto que destruye obstáculos. (Cooldown: 10s)'),
  vitalista('Parker', 'Vida Extra: Tiene una vida adicional. El primer choque no lo mata.'),
  tanque('Chema', 'Escudo con Costo: Absorbe un golpe (regenera 15s). Penalización: -500 puntos al impactar.'),
  fantasma('Conra', 'Intangibilidad: se vuelve invisible por 3 seg. (Cooldown: 10s)'),
  atleta('Shyno', 'Doble Salto: Permite realizar un segundo salto en el aire.'),
  gravedadZero('Nakama', 'Planeo: Mantén presionado el salto para reducir la velocidad de caída.');

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

  // Mapping enums to assets (assuming basic mapping for now, user can adjust)
  String getAssetPath(CharacterType type) {
    switch (type) {
      case CharacterType.pistolero: return 'assets/images/jano_clean.png'; // Jano as Pistolero
      case CharacterType.vitalista: return 'assets/images/parker_clean.png'; // Parker as Vitalista
      case CharacterType.tanque: return 'assets/images/chema_clean.png'; // Chema as Tanque
      case CharacterType.fantasma: return 'assets/images/conra_clean.png'; // Conra as Fantasma
      case CharacterType.atleta: return 'assets/images/shyno_clean.png'; // Shyno as Atleta
      case CharacterType.gravedadZero: return 'assets/images/nakama_clean.png'; // Nakama as Gravedad Zero
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          children: [
            const Text(
              'SELECCIONA TU PERSONAJE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: CharacterType.values.map((type) {
                    final bool isSelected = selectedCharacter == type;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCharacter = type;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: isSelected ? 180 : 140,
                        height: isSelected ? 240 : 180,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? Colors.cyanAccent : Colors.grey.withOpacity(0.5),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Builder(
                                  builder: (context) {
                                    final assetName = getAssetPath(type).replaceAll('assets/images/', '');
                                    try {
                                      final image = widget.game.images.fromCache(assetName);
                                      final frameWidth = image.width / 2;
                                      final frameHeight = image.height / 2;
                                      final sprite = Sprite(
                                        image,
                                        srcPosition: Vector2(0, 0),
                                        srcSize: Vector2(frameWidth, frameHeight),
                                      );
                                      return SpriteWidget(sprite: sprite);
                                    } catch (e) {
                                      return const Icon(Icons.error, color: Colors.red);
                                    }
                                  },
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                              width: double.infinity,
                              color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
                              child: Text(
                                type.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.cyanAccent : Colors.white, // Changed to white for better visibility
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  shadows: const [
                                    Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Description Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    selectedCharacter?.name ?? 'Selecciona un personaje',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedCharacter?.description ?? 'Toca un personaje para ver sus habilidades.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: selectedCharacter != null ? () {
                widget.game.startGame(selectedCharacter!);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'JUGAR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
