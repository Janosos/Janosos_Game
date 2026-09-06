import 'dart:async';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Centralized manager for background music (BGM) and sound effects (SFX)
/// using a bounded, recycled [AudioPool] system to eliminate native AudioTrack
/// exhaustion, audio distortion, and FPS drops during extended gameplay and boss fights.
class AppAudioManager {
  static const String bgmTrack = 'LoopSong.wav';

  static const List<String> sfxAssets = [
    'Jump.wav',
    'Select.wav',
    'Shoot.wav',
    'Invisibility.wav',
    'Hit.wav',
  ];

  /// Tracks whether the game screen/route is currently mounted and active.
  static bool isGameActive = false;

  /// Recycled audio pools for each sound effect (strictly bounds native players).
  static final Map<String, AudioPool> _pools = {};
  static final Map<String, int> _lastPlayTimeMs = {};
  static bool _poolsInitialized = false;

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

  /// Initialize BGM and pre-warmed audio pools for all sound effects.
  static Future<void> initialize() async {
    ensureBgmPlayer();
    try {
      await FlameAudio.bgm.initialize();
    } catch (e) {
      debugPrint('AppAudioManager.initialize bgm notice: $e');
    }
    await _initPools();
  }

  /// Pre-creates a bounded AudioPool for each SFX to prevent creating unbounded
  /// native AudioPlayer/AudioTrack instances that crash or lag Android on extended play.
  static Future<void> _initPools() async {
    if (_poolsInitialized) return;
    _poolsInitialized = true;

    for (final sfx in sfxAssets) {
      try {
        // maxPlayers: 2 per sound is ideal: allows overlapping impacts or jumps
        // while strictly capping total active native audio players to <= 10.
        final pool = await FlameAudio.createPool(
          sfx,
          minPlayers: 1,
          maxPlayers: sfx == 'Invisibility.wav' ? 1 : 2,
        );
        _pools[sfx] = pool;
      } catch (e) {
        debugPrint('AppAudioManager error creating pool for "$sfx": $e');
      }
    }
  }

  /// Preload SFX and BGM assets safely.
  static Future<void> preloadAssets() async {
    ensureBgmPlayer();
    await _initPools();
    try {
      await FlameAudio.audioCache.load(bgmTrack);
    } catch (e) {
      debugPrint('AppAudioManager preload defer "$bgmTrack": $e');
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

  /// Minimum interval between plays of the same sound (in ms).
  /// Prevents audio clipping, crackling, and native track thrashing when rapid hits occur.
  static int _minIntervalFor(String sfx) {
    switch (sfx) {
      case 'Hit.wav':
        return 70;
      case 'Shoot.wav':
        return 60;
      case 'Jump.wav':
        return 90;
      case 'Select.wav':
        return 60;
      case 'Invisibility.wav':
        return 200;
      default:
        return 50;
    }
  }

  /// Plays SFX safely using the bounded recycled [AudioPool] system.
  /// Completely non-blocking and safe from native AudioTrack leaks.
  static void playSfx(
    String sfx, {
    required bool audioEnabled,
    double volume = 1.0,
  }) {
    if (!audioEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastPlayTimeMs[sfx] ?? 0;
    final minInterval = _minIntervalFor(sfx);

    if (now - lastTime < minInterval) {
      // Throttle rapid repeated triggers of the same sound
      return;
    }
    _lastPlayTimeMs[sfx] = now;

    unawaited(_playSfxAsync(sfx, volume));
  }

  static Future<void> _playSfxAsync(String sfx, double volume) async {
    try {
      var pool = _pools[sfx];
      if (pool == null) {
        pool = await FlameAudio.createPool(
          sfx,
          minPlayers: 1,
          maxPlayers: sfx == 'Invisibility.wav' ? 1 : 2,
        );
        _pools[sfx] = pool;
      }
      await pool.start(volume: volume);
    } catch (error) {
      debugPrint('AppAudioManager.playSfx error for "$sfx": $error');
    }
  }

  /// Clean up pools on application shutdown if needed.
  static Future<void> dispose() async {
    for (final pool in _pools.values) {
      try {
        await pool.dispose();
      } catch (_) {}
    }
    _pools.clear();
    _poolsInitialized = false;
  }
}
