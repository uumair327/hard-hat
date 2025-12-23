import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Enhanced AudioManager that works with the AudioSystem for spatial audio
/// and provides a high-level interface for audio management
@lazySingleton
class AudioManager {
  AudioSystem? _audioSystem;
  
  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  bool _isMuted = false;
  
  /// Current background music tracking
  bool _isMusicPlaying = false;

  // Getters
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;
  bool get isMuted => _isMuted;

  /// Set the audio system reference for advanced features
  void setAudioSystem(AudioSystem audioSystem) {
    _audioSystem = audioSystem;
    
    // Sync settings with audio system
    _audioSystem?.setCategoryVolume(AudioCategory.sfx, _sfxVolume);
    _audioSystem?.setCategoryVolume(AudioCategory.music, _musicVolume);
    _audioSystem?.setMuted(_isMuted);
  }

  /// Play sound effect using AudioSystem if available, fallback to FlameAudio
  Future<void> playSfx(String soundPath, {double? volume}) async {
    if (_isMuted) return;
    
    if (_audioSystem != null) {
      // Use AudioSystem for better management
      _audioSystem!.playSfx(soundPath, volume: volume ?? 1.0);
    } else {
      // Fallback to direct FlameAudio
      final effectiveVolume = (volume ?? 1.0) * _sfxVolume;
      await FlameAudio.play(soundPath, volume: effectiveVolume);
    }
  }

  /// Play spatial sound effect at a specific position
  void playSpatialSfx(String soundPath, double x, double y, {double? volume}) {
    if (_isMuted) return;
    
    if (_audioSystem != null) {
      _audioSystem!.playSpatialSfx(
        soundPath, 
        Vector2(x, y), 
        volume: volume ?? 1.0
      );
    } else {
      // Fallback to non-spatial audio
      playSfx(soundPath, volume: volume);
    }
  }

  /// Play background music using AudioSystem if available
  Future<void> playMusic(String musicPath, {bool loop = true}) async {
    if (_isMuted) return;
    
    if (_audioSystem != null) {
      // Use AudioSystem for better management
      _audioSystem!.playMusic(musicPath, volume: _musicVolume, loop: loop);
    } else {
      // Fallback to FlameAudio
      try {
        await FlameAudio.bgm.stop();
        await FlameAudio.bgm.play(musicPath, volume: _musicVolume);
        _isMusicPlaying = true;
      } catch (e) {
        print('Failed to play music: $e');
      }
    }
  }

  /// Stop all audio
  Future<void> stopAll() async {
    if (_audioSystem != null) {
      _audioSystem!.stopAll();
    } else {
      FlameAudio.bgm.stop();
      await FlameAudio.audioCache.clearAll();
      _isMusicPlaying = false;
    }
  }

  /// Stop music only
  void stopMusic() {
    if (_audioSystem != null) {
      _audioSystem!.stopCategory(AudioCategory.music);
    } else {
      FlameAudio.bgm.stop();
      _isMusicPlaying = false;
    }
  }

  /// Pause all audio (for game pause)
  void pauseAll() {
    if (_audioSystem != null) {
      _audioSystem!.setMuted(true);
    } else {
      FlameAudio.bgm.pause();
    }
  }

  /// Resume all audio (for game resume)
  void resumeAll() {
    if (_audioSystem != null && _isMuted == false) {
      _audioSystem!.setMuted(false);
    } else if (!_isMuted) {
      FlameAudio.bgm.resume();
    }
  }

  /// Update volume settings
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
    _audioSystem?.setCategoryVolume(AudioCategory.sfx, _sfxVolume);
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _audioSystem?.setCategoryVolume(AudioCategory.music, _musicVolume);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    _audioSystem?.setMuted(muted);
    
    if (muted) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
    }
  }

  /// Set listener position for spatial audio
  void setListenerPosition(double x, double y) {
    _audioSystem?.setListenerPosition(Vector2(x, y));
  }

  /// Preload audio assets
  Future<void> preloadAudio() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'audio/sfx/jump.mp3',
        'audio/sfx/ball_launch.mp3',
        'audio/sfx/ball_bounce.mp3',
        'audio/sfx/tile_break.mp3',
        'audio/sfx/tile_hit.mp3',
        'audio/music/gameplay.mp3',
        'audio/music/menu.mp3',
      ]);
    } catch (e) {
      print('Failed to preload audio: $e');
    }
  }

  /// Apply fade effect to music (for transitions)
  Future<void> fadeMusicVolume(double targetVolume, Duration duration) async {
    if (!_isMusicPlaying && _audioSystem == null) return;
    
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final currentVolume = _musicVolume;
    final volumeStep = (targetVolume - currentVolume) / steps;
    
    for (int i = 0; i < steps; i++) {
      final newVolume = currentVolume + (volumeStep * (i + 1));
      
      if (_audioSystem != null) {
        _audioSystem!.setCategoryVolume(AudioCategory.music, newVolume);
      }
      // Note: FlameAudio.bgm doesn't support real-time volume changes
      // This is a limitation we'll document
      
      await Future.delayed(stepDuration);
    }
    
    // Ensure final volume is set
    if (_audioSystem != null) {
      _audioSystem!.setCategoryVolume(AudioCategory.music, targetVolume);
    }
    
    _musicVolume = targetVolume;
  }

  /// Dispose resources
  void dispose() {
    FlameAudio.bgm.stop();
    _audioSystem = null;
    _isMusicPlaying = false;
  }
}