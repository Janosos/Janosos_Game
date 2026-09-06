import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../game/domain/hud_settings.dart';

final hudSettingsControllerProvider =
    NotifierProvider<HudSettingsController, HudSettings>(
      HudSettingsController.new,
    );

class HudSettingsController extends Notifier<HudSettings> {
  static const _storageKey = 'settings.hud_customization_v1';

  @override
  HudSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return HudSettings.defaults;
    }
    return HudSettings.fromJson(raw);
  }

  Future<void> updateSettings(HudSettings newSettings) async {
    state = newSettings;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_storageKey, newSettings.toJson());
  }

  Future<void> resetToDefaults() async {
    state = HudSettings.defaults;
    await ref.read(sharedPreferencesProvider).remove(_storageKey);
  }
}
