import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/domain/components/audio_component.dart';

/// Audio system for managing game sounds and music
class AudioSystem extends GameSystem implements IAudioSystem {
  late EntityManager _entityManager;
  
  // Audio state
  bool _isEnabled = true;
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  
  // Currently playing music
  String? _currentMusic;
  
  // Audio registry for sound effects
  static const Map<String, String> _soundEffects = {
    'jump': 'sfx/jump.wav',
    'land': 'sfx/land.wav',
    'hit': 'sfx/hit.wav',
    'break': 'sfx/break.wav',
    'strike': 'sfx/strike.wav',
    'fizzle': 'sfx/fizzle.wav',
    'boing': 'sfx/boing.wav',
    'death': 'sfx/death.wav',
  };
  
  // Music registry
  static const Map<String, String> _music = {
    'menu': 'music/menu.mp3',
    'game': 'music/game.mp3',
    'victory': 'music/victory.mp3',
  };
  
  @override
  int get priority => 8; // Process late to respond to game events

  @override
  Future<void> initialize() async {
    // Preload commonly used sound effects
    await _preloadSounds();
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }

  @override
  void update(double dt) {
    // Audio system doesn't need regular updates
    // Sound effects are triggered by events
  }
  
  @override
  void playSound(String soundId) {
    playSoundEffect(soundId);
  }
  
  @override
  void stopSound(String soundId) {
    // FlameAudio doesn't provide easy sound stopping by ID
    // This would need a more sophisticated implementation
  }
  
  @override
  void pauseAudio() {
    pauseAll();
  }
  
  @override
  void resumeAudio() {
    resumeAll();
  }
  
  @override
  void setVolume(double volume) {
    setMasterVolume(volume);
  }
  
  /// Preload sound effects for better performance
  Future<void> _preloadSounds() async {
    try {
      // Preload critical sound effects
      await FlameAudio.audioCache.load(_soundEffects['jump']!);
      await FlameAudio.audioCache.load(_soundEffects['hit']!);
      await FlameAudio.audioCache.load(_soundEffects['break']!);
    } catch (e) {
      // Handle missing audio files gracefully
      print('Warning: Could not preload some audio files: $e');
    }
  }
  
  /// Play a sound effect
  void playSoundEffect(String soundName, {Vector2? position, double volume = 1.0}) {
    if (!_isEnabled) return;
    
    final soundPath = _soundEffects[soundName];
    if (soundPath == null) {
      print('Warning: Sound effect "$soundName" not found');
      return;
    }
    
    try {
      final effectiveVolume = _masterVolume * _sfxVolume * volume;
      
      if (position != null) {
        // Spatial audio (simplified - would need proper 3D audio in real implementation)
        _playSpatialSound(soundPath, position, effectiveVolume);
      } else {
        FlameAudio.play(soundPath, volume: effectiveVolume);
      }
    } catch (e) {
      print('Warning: Could not play sound effect "$soundName": $e');
    }
  }
  
  /// Play spatial audio at a specific position
  void _playSpatialSound(String soundPath, Vector2 position, double volume) {
    // Simplified spatial audio - calculate volume based on distance from player
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    if (players.isEmpty) {
      FlameAudio.play(soundPath, volume: volume);
      return;
    }
    
    final player = players.first;
    final playerPosition = player.positionComponent.position;
    final distance = (position - playerPosition).length;
    
    // Reduce volume based on distance (max distance of 500 pixels)
    final spatialVolume = (1.0 - (distance / 500.0).clamp(0.0, 1.0)) * volume;
    
    if (spatialVolume > 0.01) {
      FlameAudio.play(soundPath, volume: spatialVolume);
    }
  }
  
  /// Play a sound effect with volume parameter
  void playSfx(String soundPath, {double volume = 1.0}) {
    if (!_isEnabled) return;
    
    try {
      final effectiveVolume = _masterVolume * _sfxVolume * volume;
      FlameAudio.play(soundPath, volume: effectiveVolume);
    } catch (e) {
      print('Warning: Could not play sound effect "$soundPath": $e');
    }
  }
  
  /// Play spatial sound effect at a specific position
  void playSpatialSfx(String soundPath, Vector2 position, {double volume = 1.0}) {
    if (!_isEnabled) return;
    
    try {
      final effectiveVolume = _masterVolume * _sfxVolume * volume;
      _playSpatialSound(soundPath, position, effectiveVolume);
    } catch (e) {
      print('Warning: Could not play spatial sound effect "$soundPath": $e');
    }
  }
  
  /// Stop all audio
  void stopAll() {
    try {
      FlameAudio.bgm.stop();
      _currentMusic = null;
    } catch (e) {
      print('Warning: Could not stop all audio: $e');
    }
  }
  
  /// Stop audio by category
  void stopCategory(AudioCategory category) {
    switch (category) {
      case AudioCategory.music:
        stopMusic();
        break;
      case AudioCategory.sfx:
        // FlameAudio doesn't provide easy SFX stopping
        // In a real implementation, you'd track active SFX
        break;
      case AudioCategory.voice:
        // Voice audio not implemented yet
        break;
      case AudioCategory.ambient:
        // Ambient audio not implemented yet
        break;
    }
  }
  
  /// Set listener position for spatial audio
  void setListenerPosition(Vector2 position) {
    // Store listener position for spatial audio calculations
    // In a real implementation, this would be used for 3D audio
  }
  
  /// Play background music
  void playMusic(String musicName, {bool loop = true, double volume = 1.0}) {
    if (!_isEnabled) return;
    
    final musicPath = _music[musicName];
    if (musicPath == null) {
      print('Warning: Music "$musicName" not found');
      return;
    }
    
    // Stop current music if different
    if (_currentMusic != musicName) {
      stopMusic();
    }
    
    try {
      final effectiveVolume = _masterVolume * _musicVolume * volume;
      
      if (loop) {
        FlameAudio.bgm.play(musicPath, volume: effectiveVolume);
      } else {
        FlameAudio.play(musicPath, volume: effectiveVolume);
      }
      
      _currentMusic = musicName;
    } catch (e) {
      print('Warning: Could not play music "$musicName": $e');
    }
  }
  
  /// Stop background music
  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
      _currentMusic = null;
    } catch (e) {
      print('Warning: Could not stop music: $e');
    }
  }
  
  /// Pause all audio
  void pauseAll() {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      print('Warning: Could not pause audio: $e');
    }
  }
  
  /// Resume all audio
  void resumeAll() {
    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      print('Warning: Could not resume audio: $e');
    }
  }
  
  /// Set master volume (0.0 to 1.0)
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    _updateMusicVolume();
  }
  
  /// Set sound effects volume (0.0 to 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }
  
  /// Set music volume (0.0 to 1.0)
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _updateMusicVolume();
  }
  
  /// Update music volume
  void _updateMusicVolume() {
    if (_currentMusic != null) {
      // Note: FlameAudio doesn't support runtime volume changes easily
      // In a real implementation, you'd need to restart the music with new volume
      // final effectiveVolume = _masterVolume * _musicVolume;
    }
  }
  
  /// Enable or disable audio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    
    if (!enabled) {
      stopMusic();
    }
  }
  
  /// Set muted state
  void setMuted(bool muted) {
    setEnabled(!muted);
  }
  
  /// Set volume for a specific audio category
  void setCategoryVolume(AudioCategory category, double volume) {
    switch (category) {
      case AudioCategory.sfx:
        setSfxVolume(volume);
        break;
      case AudioCategory.music:
        setMusicVolume(volume);
        break;
      case AudioCategory.voice:
        // Voice volume not implemented yet
        break;
      case AudioCategory.ambient:
        // Ambient volume not implemented yet
        break;
    }
  }
  
  /// Play player jump sound
  void playJumpSound(Vector2? position) {
    playSoundEffect('jump', position: position);
  }
  
  /// Play player land sound
  void playLandSound(Vector2? position) {
    playSoundEffect('land', position: position);
  }
  
  /// Play ball hit sound
  void playHitSound(Vector2? position) {
    playSoundEffect('hit', position: position);
  }
  
  /// Play tile break sound
  void playBreakSound(Vector2? position) {
    playSoundEffect('break', position: position);
  }
  
  /// Play ball strike sound
  void playStrikeSound(Vector2? position) {
    playSoundEffect('strike', position: position);
  }
  
  /// Play ball fizzle sound (when ball disappears)
  void playFizzleSound(Vector2? position) {
    playSoundEffect('fizzle', position: position);
  }
  
  /// Play spring boing sound
  void playBoingSound(Vector2? position) {
    playSoundEffect('boing', position: position);
  }
  
  /// Play death sound
  void playDeathSound() {
    playSoundEffect('death');
  }
  
  // Getters
  
  /// Check if audio is enabled
  bool get isEnabled => _isEnabled;
  
  /// Get master volume
  double get masterVolume => _masterVolume;
  
  /// Get sound effects volume
  double get sfxVolume => _sfxVolume;
  
  /// Get music volume
  double get musicVolume => _musicVolume;
  
  /// Get currently playing music
  String? get currentMusic => _currentMusic;
  
  /// Check if music is playing
  bool get isMusicPlaying => _currentMusic != null;

  @override
  void dispose() {
    stopMusic();
    super.dispose();
  }
}