import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../game/audio/app_audio_manager.dart';

class GameSettings {
  const GameSettings({
    required this.audioEnabled,
    required this.reduceMotion,
    this.musicEnabled = true,
    this.sfxEnabled = true,
  });

  final bool audioEnabled;
  final bool reduceMotion;
  final bool musicEnabled;
  final bool sfxEnabled;

  GameSettings copyWith({
    bool? audioEnabled,
    bool? reduceMotion,
    bool? musicEnabled,
    bool? sfxEnabled,
  }) {
    final nextMusic = musicEnabled ?? this.musicEnabled;
    final nextSfx = sfxEnabled ?? this.sfxEnabled;
    return GameSettings(
      audioEnabled: audioEnabled ?? (nextMusic || nextSfx),
      reduceMotion: reduceMotion ?? this.reduceMotion,
      musicEnabled: nextMusic,
      sfxEnabled: nextSfx,
    );
  }
}

final gameSettingsControllerProvider =
    NotifierProvider<GameSettingsController, GameSettings>(
      GameSettingsController.new,
    );

class GameSettingsController extends Notifier<GameSettings> {
  static const _audioKey = 'settings.audio_enabled';
  static const _musicKey = 'settings.music_enabled';
  static const _sfxKey = 'settings.sfx_enabled';
  static const _reduceMotionKey = 'settings.reduce_motion';

  @override
  GameSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    final legacyAudio = preferences.getBool(_audioKey) ?? true;
    final music = preferences.getBool(_musicKey) ?? legacyAudio;
    final sfx = preferences.getBool(_sfxKey) ?? legacyAudio;
    return GameSettings(
      audioEnabled: music || sfx,
      musicEnabled: music,
      sfxEnabled: sfx,
      reduceMotion: preferences.getBool(_reduceMotionKey) ?? false,
    );
  }

  Future<void> setMusicEnabled(bool enabled) async {
    state = state.copyWith(musicEnabled: enabled);
    await ref.read(sharedPreferencesProvider).setBool(_musicKey, enabled);
    if (!enabled) {
      await AppAudioManager.stopBgm();
    } else if (AppAudioManager.isGameActive) {
      await AppAudioManager.playBgm();
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    state = state.copyWith(sfxEnabled: enabled);
    await ref.read(sharedPreferencesProvider).setBool(_sfxKey, enabled);
  }

  Future<void> setAudioEnabled(bool enabled) async {
    state = state.copyWith(
      audioEnabled: enabled,
      musicEnabled: enabled,
      sfxEnabled: enabled,
    );
    await ref.read(sharedPreferencesProvider).setBool(_audioKey, enabled);
    await ref.read(sharedPreferencesProvider).setBool(_musicKey, enabled);
    await ref.read(sharedPreferencesProvider).setBool(_sfxKey, enabled);
    if (!enabled) {
      await AppAudioManager.stopBgm();
    } else if (AppAudioManager.isGameActive) {
      await AppAudioManager.playBgm();
    }
  }

  Future<void> setReduceMotion(bool enabled) async {
    state = state.copyWith(reduceMotion: enabled);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_reduceMotionKey, enabled);
  }
}
