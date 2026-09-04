import 'package:dino_run_flame/app/app_providers.dart';
import 'package:dino_run_flame/features/settings/application/game_settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'audio and reduced-motion preferences persist across containers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );

      expect(first.read(gameSettingsControllerProvider).audioEnabled, isTrue);
      expect(first.read(gameSettingsControllerProvider).reduceMotion, isFalse);
      await first
          .read(gameSettingsControllerProvider.notifier)
          .setAudioEnabled(false);
      await first
          .read(gameSettingsControllerProvider.notifier)
          .setReduceMotion(true);
      first.dispose();

      final restored = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(restored.dispose);
      expect(
        restored.read(gameSettingsControllerProvider).audioEnabled,
        isFalse,
      );
      expect(
        restored.read(gameSettingsControllerProvider).reduceMotion,
        isTrue,
      );
    },
  );
}
