import 'package:dino_run_flame/core/platform/device_input_detector.dart';
import 'package:dino_run_flame/game/dino_run_game.dart';
import 'package:dino_run_flame/game/domain/character_id.dart';
import 'package:dino_run_flame/game/domain/run_configuration.dart';
import 'package:dino_run_flame/game/hud/directional_pad.dart';
import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectionalPad platform visibility and web mobile support', () {
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

    test(
      'isMobileOrTabletDevice returns a valid boolean on current platform',
      () {
        expect(isMobileOrTabletDevice(), isA<bool>());
      },
    );

    test(
      'DirectionalPad adjusts layout adaptively for thin landscape screens',
      () {
        final pad = DirectionalPad();
        expect(pad.size.x, 136);
        expect(pad.size.y, 60);

        // Simulate a thin landscape mobile screen (e.g. 740x360)
        pad.onGameResize(Vector2(740, 360));
        expect(pad.size.x, 116);
        expect(pad.size.y, 52);
        expect(pad.position.x, 12);
        expect(pad.position.y, 350);

        // Simulate a desktop landscape screen (e.g. 1280x720)
        pad.onGameResize(Vector2(1280, 720));
        expect(pad.size.x, 136);
        expect(pad.size.y, 60);
        expect(pad.position.x, 16);
        expect(pad.position.y, 704);
      },
    );

    test('DirectionalPad has appropriate hit target boundaries', () {
      final pad = DirectionalPad();
      pad.position = Vector2(16, 300);

      expect(pad.containsPoint(Vector2(20, 260)), isTrue);
      expect(pad.containsPoint(Vector2(100, 260)), isTrue);
      expect(pad.containsPoint(Vector2(0, 0)), isFalse);
      expect(pad.containsPoint(Vector2(500, 500)), isFalse);
    });
  });
}
