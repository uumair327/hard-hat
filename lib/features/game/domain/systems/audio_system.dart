import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';
import 'package:hard_hat/features/game/domain/components/audio_component.dart';
import 'package:hard_hat/core/services/asset_manager.dart';

/// System for handling spatial audio and entity-based sound effects
class AudioSystem extends GameSystem {
  /// Asset manager for loading audio paths
  final AssetManager _assetManager;
  
  /// Game state manager for state-aware audio behavior
  GameStateManager? _gameStateManager;
  
  /// Current listener position for spatial audio calculations
  Vector2 _listenerPosition = Vector2.zero();
  
  /// Master volume levels for different categories
  final Map<AudioCategory, double> _categoryVolumes = {
    AudioCategory.sfx: 1.0,
    AudioCategory.music: 0.7,
    AudioCategory.voice: 1.0,
    AudioCategory.ambient: 0.5,
  };
  
  /// Whether audio is globally muted
  bool _isMuted = false;
  
  /// Currently playing audio instances for management
  final Map<String, String> _activeAudioPlayers = {};
  
  /// Background music tracking
  String? _currentMusicId;
  
  /// Audio mixing - maximum simultaneous sounds per category
  final Map<AudioCategory, int> _maxSimultaneousSounds = {
    AudioCategory.sfx: 8,
    AudioCategory.music: 1,
    AudioCategory.voice: 2,
    AudioCategory.ambient: 4,
  };
  
  /// Currently playing sounds count per category
  final Map<AudioCategory, int> _currentSoundCount = {
    AudioCategory.sfx: 0,
    AudioCategory.music: 0,
    AudioCategory.voice: 0,
    AudioCategory.ambient: 0,
  };
  
  /// State-specific audio behaviors
  final Map<GameState, AudioBehavior> _stateBehaviors = {};
  
  /// Saved audio state for pause/resume
  Map<AudioCategory, double>? _savedVolumes;
  bool _wasMusicPlaying = false;

  AudioSystem(this._assetManager);

  @override
  int get priority => 100; // Audio system runs after most other systems

  @override
  Future<void> initialize() async {
    super.initialize();
    // Preload commonly used audio assets
    await _preloadAudioAssets();
    
    // Initialize state-specific audio behaviors
    _initializeAudioBehaviors();
  }
  
  /// Set the game state manager for state-aware audio behavior
  void setGameStateManager(GameStateManager gameStateManager) {
    _gameStateManager = gameStateManager;
    
    // Register for state change callbacks
    _gameStateManager?.addStateChangeCallback(_onGameStateChanged);
  }
  
  /// Initialize state-specific audio behaviors
  void _initializeAudioBehaviors() {
    _stateBehaviors[GameState.playing] = AudioBehavior(
      allowSfx: true,
      allowMusic: true,
      allowVoice: true,
      allowAmbient: true,
      volumeMultiplier: 1.0,
    );
    
    _stateBehaviors[GameState.paused] = AudioBehavior(
      allowSfx: false,
      allowMusic: true,
      allowVoice: false,
      allowAmbient: false,
      volumeMultiplier: 0.3, // Reduced volume when paused
    );
    
    _stateBehaviors[GameState.menu] = AudioBehavior(
      allowSfx: true,
      allowMusic: true,
      allowVoice: true,
      allowAmbient: false,
      volumeMultiplier: 1.0,
    );
    
    _stateBehaviors[GameState.levelComplete] = AudioBehavior(
      allowSfx: true,
      allowMusic: true,
      allowVoice: true,
      allowAmbient: false,
      volumeMultiplier: 1.0,
    );
    
    _stateBehaviors[GameState.gameOver] = AudioBehavior(
      allowSfx: true,
      allowMusic: true,
      allowVoice: true,
      allowAmbient: false,
      volumeMultiplier: 1.0,
    );
    
    _stateBehaviors[GameState.loading] = AudioBehavior(
      allowSfx: false,
      allowMusic: true,
      allowVoice: false,
      allowAmbient: false,
      volumeMultiplier: 0.5,
    );
    
    _stateBehaviors[GameState.settings] = AudioBehavior(
      allowSfx: true,
      allowMusic: true,
      allowVoice: false,
      allowAmbient: false,
      volumeMultiplier: 1.0,
    );
    
    _stateBehaviors[GameState.error] = AudioBehavior(
      allowSfx: false,
      allowMusic: false,
      allowVoice: false,
      allowAmbient: false,
      volumeMultiplier: 0.0,
    );
  }
  
  /// Handle game state changes
  void _onGameStateChanged(GameState newState, GameState? previousState) {
    final behavior = _stateBehaviors[newState];
    if (behavior != null) {
      _applyAudioBehavior(behavior, newState, previousState);
    }
  }
  
  /// Apply audio behavior based on current state
  void _applyAudioBehavior(AudioBehavior behavior, GameState newState, GameState? previousState) {
    switch (newState) {
      case GameState.paused:
        _saveAudioState();
        _pauseAudio();
        break;
      case GameState.playing:
        if (previousState == GameState.paused) {
          _resumeAudio();
        }
        break;
      case GameState.menu:
        if (previousState == GameState.playing) {
          _fadeOutGameplayAudio();
        }
        break;
      case GameState.levelComplete:
      case GameState.gameOver:
        _stopCategory(AudioCategory.sfx);
        break;
      case GameState.loading:
        _stopCategory(AudioCategory.sfx);
        _stopCategory(AudioCategory.voice);
        break;
      case GameState.error:
        stopAll();
        break;
      default:
        break;
    }
  }
  
  /// Get current audio behavior based on game state
  AudioBehavior _getCurrentAudioBehavior() {
    final currentState = _gameStateManager?.currentState ?? GameState.playing;
    return _stateBehaviors[currentState] ?? _stateBehaviors[GameState.playing]!;
  }
  
  /// Save current audio state for pause/resume
  void _saveAudioState() {
    _savedVolumes = Map.from(_categoryVolumes);
    _wasMusicPlaying = _currentMusicId != null;
  }
  
  /// Pause audio for pause state
  void _pauseAudio() {
    FlameAudio.bgm.pause();
    
    // Reduce volume for all categories
    final behavior = _getCurrentAudioBehavior();
    for (final category in AudioCategory.values) {
      final originalVolume = _categoryVolumes[category] ?? 1.0;
      _categoryVolumes[category] = originalVolume * behavior.volumeMultiplier;
    }
  }
  
  /// Resume audio from pause state
  void _resumeAudio() {
    if (_savedVolumes != null) {
      _categoryVolumes.addAll(_savedVolumes!);
      _savedVolumes = null;
    }
    
    if (_wasMusicPlaying) {
      FlameAudio.bgm.resume();
    }
  }
  
  /// Fade out gameplay audio when transitioning to menu
  void _fadeOutGameplayAudio() {
    // This would ideally use a tween to fade out over time
    // For now, we'll just reduce the volume
    _categoryVolumes[AudioCategory.sfx] = (_categoryVolumes[AudioCategory.sfx] ?? 1.0) * 0.3;
    _categoryVolumes[AudioCategory.ambient] = (_categoryVolumes[AudioCategory.ambient] ?? 1.0) * 0.3;
  }

  @override
  void updateSystem(double dt) {
    super.updateSystem(dt);
    
    final behavior = _getCurrentAudioBehavior();
    
    // Update all audio components
    final audioComponents = getComponents<AudioComponent>();
    
    for (final audioComponent in audioComponents) {
      // Only update audio if the category is allowed in current state
      if (_isCategoryAllowed(audioComponent.category, behavior)) {
        _updateAudioComponent(audioComponent, dt, behavior);
      } else {
        // Stop audio that's not allowed in current state
        audioComponent.stop();
      }
    }
    
    // Clean up finished one-shot audio components
    _cleanupFinishedAudio();
  }
  
  /// Check if an audio category is allowed in current behavior
  bool _isCategoryAllowed(AudioCategory category, AudioBehavior behavior) {
    switch (category) {
      case AudioCategory.sfx:
        return behavior.allowSfx;
      case AudioCategory.music:
        return behavior.allowMusic;
      case AudioCategory.voice:
        return behavior.allowVoice;
      case AudioCategory.ambient:
        return behavior.allowAmbient;
    }
  }

  /// Update a single audio component
  void _updateAudioComponent(AudioComponent audioComponent, double dt, AudioBehavior behavior) {
    if (!audioComponent.isPlaying || audioComponent.soundId == null) {
      return;
    }
    
    // Calculate spatial volume if position is set
    double effectiveVolume = audioComponent.volume;
    if (audioComponent.spatialPosition != null) {
      effectiveVolume = audioComponent.calculateSpatialVolume(_listenerPosition);
    }
    
    // Apply category volume, behavior multiplier, and mute state
    effectiveVolume *= _categoryVolumes[audioComponent.category] ?? 1.0;
    effectiveVolume *= behavior.volumeMultiplier;
    if (_isMuted) effectiveVolume = 0.0;
    
    // Play or update the audio
    _playAudioComponent(audioComponent, effectiveVolume);
  }

  /// Play audio for a component
  void _playAudioComponent(AudioComponent audioComponent, double volume) {
    if (audioComponent.soundId == null) return;
    
    final audioId = audioComponent.soundId!;
    final category = audioComponent.category;
    
    // Check if we can play more sounds in this category
    if ((_currentSoundCount[category] ?? 0) >= (_maxSimultaneousSounds[category] ?? 1)) {
      return; // Skip if too many sounds are playing
    }
    
    try {
      final audioPath = _assetManager.getAudioPath(audioId);
      
      if (audioComponent.isLooping && category == AudioCategory.music) {
        _playBackgroundMusic(audioPath, volume);
      } else {
        _playSoundEffect(audioId, audioPath, volume, category);
      }
      
      // Increment sound count
      _currentSoundCount[category] = (_currentSoundCount[category] ?? 0) + 1;
      
    } catch (e) {
      // Handle audio loading errors gracefully
      if (kDebugMode) {
        print('Failed to play audio: $audioId, error: $e');
      }
    }
  }

  /// Play a sound effect
  void _playSoundEffect(String audioId, String audioPath, double volume, AudioCategory category) {
    FlameAudio.play(audioPath, volume: volume).then((_) {
      // Decrement sound count when finished
      _currentSoundCount[category] = math.max(0, (_currentSoundCount[category] ?? 1) - 1);
    }).catchError((error) {
      if (kDebugMode) {
        print('Error playing sound effect $audioId: $error');
      }
      _currentSoundCount[category] = math.max(0, (_currentSoundCount[category] ?? 1) - 1);
    });
  }

  /// Play background music
  void _playBackgroundMusic(String audioPath, double volume) async {
    try {
      // Stop current music if playing
      if (_currentMusicId != null) {
        FlameAudio.bgm.stop();
      }
      
      await FlameAudio.bgm.play(audioPath, volume: volume);
      _currentMusicId = audioPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error playing background music: $e');
      }
      _currentSoundCount[AudioCategory.music] = 0;
    }
  }

  /// Clean up finished one-shot audio components
  void _cleanupFinishedAudio() {
    final audioComponents = getComponents<AudioComponent>();
    
    for (final audioComponent in audioComponents) {
      if (audioComponent.isOneShot && !audioComponent.isPlaying) {
        audioComponent.removeFromParent();
      }
    }
  }

  /// Set the listener position for spatial audio calculations
  void setListenerPosition(Vector2 position) {
    _listenerPosition = position.clone();
  }

  /// Play a one-shot sound effect at a specific position
  void playSpatialSfx(String audioId, Vector2 position, {double volume = 1.0}) {
    final behavior = _getCurrentAudioBehavior();
    if (!behavior.allowSfx) return;
    
    final audioComponent = AudioComponent(
      soundId: audioId,
      volume: volume,
      spatialPosition: position,
      isOneShot: true,
      category: AudioCategory.sfx,
    );
    
    audioComponent.play(audioId);
    
    // Add to game temporarily
    findGame()?.add(audioComponent);
  }

  /// Play a non-spatial sound effect
  void playSfx(String audioId, {double volume = 1.0}) {
    final behavior = _getCurrentAudioBehavior();
    if (!behavior.allowSfx) return;
    
    final audioComponent = AudioComponent(
      soundId: audioId,
      volume: volume,
      isOneShot: true,
      category: AudioCategory.sfx,
    );
    
    audioComponent.play(audioId);
    
    // Add to game temporarily
    findGame()?.add(audioComponent);
  }

  /// Play background music
  void playMusic(String audioId, {double volume = 0.7, bool loop = true}) {
    final behavior = _getCurrentAudioBehavior();
    if (!behavior.allowMusic) return;
    
    final audioComponent = AudioComponent(
      soundId: audioId,
      volume: volume,
      isLooping: loop,
      category: AudioCategory.music,
    );
    
    audioComponent.play(audioId);
    
    // Add to game
    findGame()?.add(audioComponent);
  }

  /// Stop all audio of a specific category
  void stopCategory(AudioCategory category) {
    _stopCategory(category);
  }
  
  /// Internal method to stop all audio of a specific category
  void _stopCategory(AudioCategory category) {
    final audioComponents = getComponents<AudioComponent>();
    
    for (final audioComponent in audioComponents) {
      if (audioComponent.category == category) {
        audioComponent.stop();
      }
    }
    
    if (category == AudioCategory.music) {
      FlameAudio.bgm.stop();
      _currentMusicId = null;
    }
    
    _currentSoundCount[category] = 0;
  }

  /// Stop all audio
  void stopAll() {
    final audioComponents = getComponents<AudioComponent>();
    
    for (final audioComponent in audioComponents) {
      audioComponent.stop();
    }
    
    FlameAudio.bgm.stop();
    FlameAudio.audioCache.clearAll();
    _currentMusicId = null;
    
    // Reset all sound counts
    for (final category in AudioCategory.values) {
      _currentSoundCount[category] = 0;
    }
  }

  /// Set volume for a specific audio category
  void setCategoryVolume(AudioCategory category, double volume) {
    _categoryVolumes[category] = volume.clamp(0.0, 1.0);
  }

  /// Get volume for a specific audio category
  double getCategoryVolume(AudioCategory category) {
    return _categoryVolumes[category] ?? 1.0;
  }

  /// Set global mute state
  void setMuted(bool muted) {
    _isMuted = muted;
    
    if (muted) {
      // Pause all audio when muted
      FlameAudio.bgm.pause();
    } else {
      // Resume music when unmuted
      FlameAudio.bgm.resume();
    }
  }

  /// Get global mute state
  bool get isMuted => _isMuted;

  /// Preload commonly used audio assets
  Future<void> _preloadAudioAssets() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'audio/sfx/jump.mp3',
        'audio/sfx/ball_launch.mp3',
        'audio/sfx/ball_bounce.mp3',
        'audio/sfx/tile_break.mp3',
        'audio/sfx/tile_hit.mp3',
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to preload audio assets: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    
    _gameStateManager?.removeStateChangeCallback(_onGameStateChanged);
    
    // Clean up all audio resources
    FlameAudio.bgm.stop();
    _activeAudioPlayers.clear();
    FlameAudio.audioCache.clearAll();
    _currentMusicId = null;
    _stateBehaviors.clear();
    _savedVolumes = null;
  }
}

/// Defines audio behavior for different game states
class AudioBehavior {
  final bool allowSfx;
  final bool allowMusic;
  final bool allowVoice;
  final bool allowAmbient;
  final double volumeMultiplier;
  
  const AudioBehavior({
    required this.allowSfx,
    required this.allowMusic,
    required this.allowVoice,
    required this.allowAmbient,
    required this.volumeMultiplier,
  });
}