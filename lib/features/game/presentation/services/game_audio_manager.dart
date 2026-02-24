import 'package:flame_audio/flame_audio.dart';

/// Audio manager — replicates Godot audio_manager.gd + audio_registry.gd
/// Plays sound effects and music. Audio files located at assets/audio/.
///
/// FlameAudio path convention: paths relative to assets/audio/
/// So 'sfx/sfx_hit.mp3' loads 'assets/audio/sfx/sfx_hit.mp3'
class GameAudioManager {
  // Music state
  static bool _musicPlaying = false;
  static double _musicVolume = 0.5;
  static String _currentMusicTrack = '';

  /// Initialize audio system — pre-cache all sounds
  static Future<void> initialize() async {
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
      ]);
    } catch (e) {
      // Silently fail if audio files are missing
    }
  }

  /// Play a one-shot sound effect
  static Future<void> playSound(String path) async {
    try {
      await FlameAudio.play(path, volume: 0.7);
    } catch (e) {
      // Silently fail
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
    // Simple restore — for full tween we'd need a timer
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
    _musicPlaying = false;
  }
}
