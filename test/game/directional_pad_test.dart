import 'package:dino_run_flame/game/dino_run_game.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:dino_run_flame/game/hud/directional_pad.dart';
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectionalPad platform visibility', () {
    test('isMobileOrTablet respects explicit override', () {
      final mobileGame = DinoRunGame(
        configuration: RunConfiguration.legacy(characterId: CharacterId.jano),
        isMobileOrTablet: true,
      );
      expect(mobileGame.isMobileOrTablet, isTrue);

      final desktopGame = DinoRunGame(
        configuration: RunConfiguration.legacy(characterId: CharacterId.jano),
        isMobileOrTablet: false,
      );
      expect(desktopGame.isMobileOrTablet, isFalse);
    });

    test('DirectionalPad has appropriate size and hit target boundaries', () {
      final pad = DirectionalPad();
      expect(pad.size.x, 136);
      expect(pad.size.y, 60);

      pad.position = Vector2(16, 300);

      // Left boundary (pad.position.x = 16, width = 136, height = 60, bottom = 300, top = 240)
      // containsPoint checks point within [16 - 8, 16 + 136 + 8] x [240 - 8, 300 + 8]
      expect(pad.containsPoint(Vector2(20, 260)), isTrue);
      expect(pad.containsPoint(Vector2(100, 260)), isTrue);
      expect(pad.containsPoint(Vector2(0, 0)), isFalse);
      expect(pad.containsPoint(Vector2(500, 500)), isFalse);
    });
  });
}
