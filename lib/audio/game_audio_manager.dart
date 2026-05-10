
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Audio manager — replicates Godot audio_manager.gd + audio_registry.gd
/// Uses a fixed pool of reusable AudioPlayers to prevent the Windows
/// non-platform-thread crash caused by unlimited player creation.
///
/// FlameAudio path convention: paths relative to assets/audio/
/// So 'sfx/sfx_hit.mp3' loads 'assets/audio/sfx/sfx_hit.mp3'
class GameAudioManager {
  // Music state
  static bool _musicPlaying = false;
  static double _musicVolume = 0.5;
  static String _currentMusicTrack = '';
  static AudioPlayer? _elevatorLoop;

  // === SFX PLAYER POOL ===
  // Fixed pool of AudioPlayers reused round-robin to prevent unbounded
  // player creation which causes Windows threading crashes.
  static const int _poolSize = 8;
  static final List<AudioPlayer> _sfxPool = [];
  static int _nextPoolIndex = 0;
  static bool _poolInitialized = false;

  /// Initialize audio system — set up player pool and pre-cache sounds
  static Future<void> initialize() async {
    // Create the fixed SFX pool once
    if (!_poolInitialized) {
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        // Suppress event listener errors on Windows
        player.setReleaseMode(ReleaseMode.stop);
        _sfxPool.add(player);
      }
      _poolInitialized = true;
    }

    try {
      await FlameAudio.audioCache.loadAll([
        'sfx/sfx_hit.mp3',
        'sfx/sfx_break.mp3',
        'sfx/sfx_strike.mp3',
        'sfx/sfx_fizzle.mp3',
        'sfx/sfx_boing.mp3',
        'sfx/sfx_land.mp3',
        'sfx/sfx_death.mp3',
        'sfx/sfx_confirm.mp3',
        'sfx/sfx_tick.mp3',
        'sfx/sfx_ding.mp3',
        'sfx/sfx_elevator.mp3',
        'sfx/sfx_blueprints.mp3',
        'sfx/sfx_transition_pop_in.mp3',
        'sfx/sfx_transition_pop_out.mp3',
        'sfx/sfx_comic_load.mp3',
        'loop/loop_step.mp3',
      ]);
    } catch (e) {
      debugPrint('GameAudioManager: Failed to pre-cache audio: $e');
    }
  }

  /// Play a one-shot sound effect using pooled players
  static Future<void> playSound(String path) async {
    if (!_poolInitialized || _sfxPool.isEmpty) return;

    try {
      // Round-robin through the pool
      final player = _sfxPool[_nextPoolIndex];
      _nextPoolIndex = (_nextPoolIndex + 1) % _poolSize;

      // Stop current sound on this player and play the new one
      await player.stop();
      await player.setVolume(0.7);
      await player.play(AssetSource('audio/$path'));
    } catch (e) {
      // Silently fail — audio should never crash the game
    }
  }

  // === SFX shortcuts (matching Godot AudioRegistry) ===
  static Future<void> playHit() => playSound('sfx/sfx_hit.mp3');
  static Future<void> playBreak() => playSound('sfx/sfx_break.mp3');
  static Future<void> playStrike() => playSound('sfx/sfx_strike.mp3');
  static Future<void> playFizzle() => playSound('sfx/sfx_fizzle.mp3');
  static Future<void> playBoing() => playSound('sfx/sfx_boing.mp3');
  static Future<void> playLand() => playSound('sfx/sfx_land.mp3');
  static Future<void> playDeath() => playSound('sfx/sfx_death.mp3');
  static Future<void> playConfirm() => playSound('sfx/sfx_confirm.mp3');
  static Future<void> playTick() => playSound('sfx/sfx_tick.mp3');
  static Future<void> playDing() => playSound('sfx/sfx_ding.mp3');
  static Future<void> playElevator() => playSound('sfx/sfx_elevator.mp3');

  static Future<void> playElevatorLoop() async {
    try {
      if (_elevatorLoop == null) {
        _elevatorLoop = AudioPlayer();
        await _elevatorLoop!.setSource(AssetSource('audio/loop/loop_elevator.mp3'));
        await _elevatorLoop!.setReleaseMode(ReleaseMode.loop);
        await _elevatorLoop!.setVolume(0.7);
      }
      if (_elevatorLoop!.state != PlayerState.playing) {
        await _elevatorLoop!.resume();
      }
    } catch (e) {
      // Silently fail
    }
  }

  static void stopElevatorLoop() {
    _elevatorLoop?.pause();
  }

  static AudioPlayer? _stepLoop;

  static Future<void> playStepLoop() async {
    try {
      if (_stepLoop == null) {
        _stepLoop = AudioPlayer();
        await _stepLoop!.setSource(AssetSource('audio/loop/loop_step.mp3'));
        await _stepLoop!.setReleaseMode(ReleaseMode.loop);
        await _stepLoop!.setVolume(0.6);
      }
      if (_stepLoop!.state != PlayerState.playing) {
        await _stepLoop!.resume();
      }
    } catch (e) {
      // Silently fail
    }
  }

  static void stopStepLoop() {
    _stepLoop?.pause();
  }

  static Future<void> playBlueprints() => playSound('sfx/sfx_blueprints.mp3');
  static Future<void> playTransitionIn() =>
      playSound('sfx/sfx_transition_pop_in.mp3');
  static Future<void> playTransitionOut() =>
      playSound('sfx/sfx_transition_pop_out.mp3');
  static Future<void> playComicLoad() => playSound('sfx/sfx_comic_load.mp3');

  // === Music controls ===

  /// Play the title screen music
  static Future<void> playTitleMusic() async {
    await _playMusic('music/mus_title.mp3');
  }

  /// Play the gameplay music
  static Future<void> playGameplayMusic() async {
    await _playMusic('music/mus_gameplay.mp3');
  }

  /// Play outro music
  static Future<void> playOutroMusic() async {
    // If we had a specific track: await _playMusic('music/mus_outro.mp3');
    // Using title music as fallback for now
    await _playMusic('music/mus_title.mp3');
  }

  static Future<void> _playMusic(String track) async {
    if (_musicPlaying && _currentMusicTrack == track) return;
    try {
      if (_musicPlaying) {
        await FlameAudio.bgm.stop();
      }
      await FlameAudio.bgm.play(track, volume: _musicVolume);
      _musicPlaying = true;
      _currentMusicTrack = track;
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
      _musicPlaying = false;
      _currentMusicTrack = '';
    } catch (e) {
      // Silently fail
    }
  }

  /// Duck audio for pause (matching Godot -40dB)
  static void duckForPause() {
    _musicVolume = 0.05; // ~-40dB equivalent
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    } catch (e) {
      // Silently fail
    }
  }

  /// Restore audio after unpause (matching Godot -20dB over 2.25s)
  static void restoreFromPause() {
    // Staged volume restore matching Godot's tween
    _musicVolume = 0.3; // ~-20dB equivalent
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    } catch (e) {
      // Silently fail
    }
    // Gradually restore full volume
    Future.delayed(const Duration(milliseconds: 750), () {
      _musicVolume = 0.4;
      try {
        FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
      } catch (_) {}
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      _musicVolume = 0.5;
      try {
        FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
      } catch (_) {}
    });
  }

  /// Fade out for quit/transition (matching Godot -60dB over 0.5s)
  static Future<void> fadeOutForTransition() async {
    _musicVolume = 0.1;
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 250));
    _musicVolume = 0.02;
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 250));
    await stopMusic();
  }

  static void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    } catch (_) {}
  }

  static void dispose() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
    // Clean up pooled players
    for (final player in _sfxPool) {
      try {
        player.dispose();
      } catch (_) {}
    }
    _sfxPool.clear();
    _poolInitialized = false;
    _nextPoolIndex = 0;

    // Clean up loop players
    try {
      _elevatorLoop?.dispose();
      _elevatorLoop = null;
    } catch (_) {}
    try {
      _stepLoop?.dispose();
      _stepLoop = null;
    } catch (_) {}

    _musicPlaying = false;
  }
}
