import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Centralized manager for background music (BGM) and sound effects (SFX)
/// to ensure resilient playback and reactive muting across settings and gameplay.
class AppAudioManager {
  static const String bgmTrack = 'LoopSong.wav';

  /// Tracks whether the game screen/route is currently mounted and active.
  static bool isGameActive = false;

  /// Ensures [FlameAudio.bgm] has an active, non-disposed [AudioPlayer].
  static void ensureBgmPlayer() {
    try {
      final state = FlameAudio.bgm.audioPlayer.state;
      if (state == PlayerState.disposed) {
        FlameAudio.bgm.audioPlayer = AudioPlayer()
          ..audioCache = FlameAudio.audioCache;
      }
    } catch (_) {
      FlameAudio.bgm.audioPlayer = AudioPlayer()
        ..audioCache = FlameAudio.audioCache;
    }
  }

  /// Initialize BGM with audio focus settings.
  static Future<void> initialize() async {
    ensureBgmPlayer();
    try {
      await FlameAudio.bgm.initialize();
    } catch (e) {
      debugPrint('AppAudioManager.initialize notice: $e');
    }
  }

  /// Preload SFX and BGM assets safely.
  static Future<void> preloadAssets() async {
    ensureBgmPlayer();
    const assets = [
      'Jump.wav',
      'Select.wav',
      'Shoot.wav',
      'Invisibility.wav',
      'Hit.wav',
      bgmTrack,
    ];
    for (final sfx in assets) {
      try {
        await FlameAudio.audioCache.load(sfx);
      } catch (e) {
        debugPrint('AppAudioManager preload defer "$sfx": $e');
      }
    }
  }

  /// Start playing background music if enabled.
  static Future<void> playBgm({double volume = 0.5}) async {
    ensureBgmPlayer();
    try {
      if (FlameAudio.bgm.isPlaying &&
          FlameAudio.bgm.audioPlayer.state == PlayerState.playing) {
        return;
      }
      await FlameAudio.bgm.play(bgmTrack, volume: volume);
    } catch (e) {
      debugPrint('AppAudioManager.playBgm error: $e');
      // Recreate player once if native error occurred and retry
      try {
        FlameAudio.bgm.audioPlayer = AudioPlayer()
          ..audioCache = FlameAudio.audioCache;
        await FlameAudio.bgm.play(bgmTrack, volume: volume);
      } catch (retryError) {
        debugPrint('AppAudioManager.playBgm retry error: $retryError');
      }
    }
  }

  /// Stop background music immediately.
  static Future<void> stopBgm() async {
    try {
      ensureBgmPlayer();
      if (FlameAudio.bgm.isPlaying ||
          FlameAudio.bgm.audioPlayer.state == PlayerState.playing) {
        await FlameAudio.bgm.stop();
      }
    } catch (e) {
      debugPrint('AppAudioManager.stopBgm error: $e');
    }
  }

  /// Pause background music.
  static Future<void> pauseBgm() async {
    try {
      ensureBgmPlayer();
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.pause();
      }
    } catch (e) {
      debugPrint('AppAudioManager.pauseBgm error: $e');
    }
  }

  /// Resume background music if audio is enabled.
  static Future<void> resumeBgm({required bool audioEnabled}) async {
    if (!audioEnabled) {
      await stopBgm();
      return;
    }
    try {
      ensureBgmPlayer();
      if (FlameAudio.bgm.audioPlayer.state == PlayerState.paused) {
        await FlameAudio.bgm.resume();
      } else if (!FlameAudio.bgm.isPlaying) {
        await playBgm();
      }
    } catch (e) {
      debugPrint('AppAudioManager.resumeBgm error: $e');
    }
  }

  /// Play SFX safely checking [audioEnabled].
  static void playSfx(
    String sfx, {
    required bool audioEnabled,
    double volume = 1.0,
  }) {
    if (!audioEnabled) return;
    try {
      FlameAudio.play(sfx, volume: volume);
    } catch (e) {
      debugPrint('AppAudioManager.playSfx error: $e');
    }
  }
}
