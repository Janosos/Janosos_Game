import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';

class GameSettings {
  const GameSettings({required this.audioEnabled, required this.reduceMotion});

  final bool audioEnabled;
  final bool reduceMotion;

  GameSettings copyWith({bool? audioEnabled, bool? reduceMotion}) {
    return GameSettings(
      audioEnabled: audioEnabled ?? this.audioEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

final gameSettingsControllerProvider =
    NotifierProvider<GameSettingsController, GameSettings>(
      GameSettingsController.new,
    );

class GameSettingsController extends Notifier<GameSettings> {
  static const _audioKey = 'settings.audio_enabled';
  static const _reduceMotionKey = 'settings.reduce_motion';

  @override
  GameSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return GameSettings(
      audioEnabled: preferences.getBool(_audioKey) ?? true,
      reduceMotion: preferences.getBool(_reduceMotionKey) ?? false,
    );
  }

  Future<void> setAudioEnabled(bool enabled) async {
    state = state.copyWith(audioEnabled: enabled);
    await ref.read(sharedPreferencesProvider).setBool(_audioKey, enabled);
  }

  Future<void> setReduceMotion(bool enabled) async {
    state = state.copyWith(reduceMotion: enabled);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_reduceMotionKey, enabled);
  }
}
