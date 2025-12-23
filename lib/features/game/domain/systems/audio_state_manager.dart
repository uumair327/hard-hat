import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/systems/audio_system.dart';
import 'package:hard_hat/features/game/domain/components/audio_component.dart';
import 'package:hard_hat/core/services/audio_manager.dart';

/// Manages audio state for pause/resume and settings persistence
@lazySingleton
class AudioStateManager {
  final AudioSystem _audioSystem;
  final AudioManager _audioManager;
  
  /// Current game state
  GameAudioState _currentState = GameAudioState.playing;
  
  /// Audio settings that persist across sessions
  AudioSettings _settings = AudioSettings();
  
  /// Fade controller for smooth transitions
  Timer? _fadeTimer;
  
  /// Callbacks for state changes
  final List<Function(GameAudioState)> _stateChangeCallbacks = [];

  AudioStateManager(this._audioSystem, this._audioManager) {
    // Connect audio manager to audio system
    _audioManager.setAudioSystem(_audioSystem);
    
    // Apply initial settings
    _applySettings();
  }

  /// Current audio state
  GameAudioState get currentState => _currentState;
  
  /// Current audio settings
  AudioSettings get settings => _settings;

  /// Pause all audio (for game pause)
  void pauseAudio() {
    if (_currentState == GameAudioState.paused) return;
    
    _currentState = GameAudioState.paused;
    _audioSystem.setMuted(true);
    _audioManager.pauseAll();
    
    _notifyStateChange();
  }

  /// Resume all audio (for game resume)
  void resumeAudio() {
    if (_currentState != GameAudioState.paused) return;
    
    _currentState = GameAudioState.playing;
    
    if (!_settings.isMuted) {
      _audioSystem.setMuted(false);
      _audioManager.resumeAll();
    }
    
    _notifyStateChange();
  }
  /// Mute all audio
  void muteAudio() {
    _settings.isMuted = true;
    _audioSystem.setMuted(true);
    _audioManager.setMuted(true);
    _notifyStateChange();
  }

  /// Unmute all audio
  void unmuteAudio() {
    _settings.isMuted = false;
    
    if (_currentState == GameAudioState.playing) {
      _audioSystem.setMuted(false);
      _audioManager.setMuted(false);
    }
    
    _notifyStateChange();
  }

  /// Set SFX volume (0.0 to 1.0)
  void setSfxVolume(double volume) {
    _settings.sfxVolume = volume.clamp(0.0, 1.0);
    _audioSystem.setCategoryVolume(AudioCategory.sfx, _settings.sfxVolume);
    _audioManager.setSfxVolume(_settings.sfxVolume);
    _notifyStateChange();
  }

  /// Set music volume (0.0 to 1.0)
  void setMusicVolume(double volume) {
    _settings.musicVolume = volume.clamp(0.0, 1.0);
    _audioSystem.setCategoryVolume(AudioCategory.music, _settings.musicVolume);
    _audioManager.setMusicVolume(_settings.musicVolume);
    _notifyStateChange();
  }

  /// Fade music volume for smooth transitions
  Future<void> fadeMusicVolume(double targetVolume, Duration duration) async {
    _fadeTimer?.cancel();
    
    final startVolume = _settings.musicVolume;
    final volumeDiff = targetVolume - startVolume;
    const steps = 20;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);
    final volumeStep = volumeDiff / steps;
    
    for (int i = 1; i <= steps; i++) {
      final newVolume = startVolume + (volumeStep * i);
      _audioSystem.setCategoryVolume(AudioCategory.music, newVolume);
      
      await Future.delayed(stepDuration);
      
      // Check if fade was cancelled
      if (_fadeTimer?.isActive == false) break;
    }
    
    // Ensure final volume is set
    _settings.musicVolume = targetVolume;
    _audioSystem.setCategoryVolume(AudioCategory.music, targetVolume);
    _audioManager.setMusicVolume(targetVolume);
  }

  /// Apply fade in effect
  Future<void> fadeIn({Duration duration = const Duration(seconds: 1)}) async {
    await fadeMusicVolume(_settings.musicVolume, duration);
  }

  /// Apply fade out effect
  Future<void> fadeOut({Duration duration = const Duration(seconds: 1)}) async {
    await fadeMusicVolume(0.0, duration);
  }
  /// Load audio settings from persistent storage
  Future<void> loadSettings(Map<String, dynamic> settingsData) async {
    _settings = AudioSettings.fromJson(settingsData);
    _applySettings();
  }

  /// Save audio settings to persistent storage
  Map<String, dynamic> saveSettings() {
    return _settings.toJson();
  }

  /// Apply current settings to audio systems
  void _applySettings() {
    _audioSystem.setCategoryVolume(AudioCategory.sfx, _settings.sfxVolume);
    _audioSystem.setCategoryVolume(AudioCategory.music, _settings.musicVolume);
    _audioSystem.setMuted(_settings.isMuted);
    
    _audioManager.setSfxVolume(_settings.sfxVolume);
    _audioManager.setMusicVolume(_settings.musicVolume);
    _audioManager.setMuted(_settings.isMuted);
  }

  /// Add a callback for state changes
  void addStateChangeCallback(Function(GameAudioState) callback) {
    _stateChangeCallbacks.add(callback);
  }

  /// Remove a state change callback
  void removeStateChangeCallback(Function(GameAudioState) callback) {
    _stateChangeCallbacks.remove(callback);
  }

  /// Notify all callbacks of state change
  void _notifyStateChange() {
    for (final callback in _stateChangeCallbacks) {
      callback(_currentState);
    }
  }

  /// Dispose resources
  void dispose() {
    _fadeTimer?.cancel();
    _stateChangeCallbacks.clear();
  }
}

/// Audio state enumeration
enum GameAudioState {
  playing,
  paused,
  muted,
}

/// Audio settings data class
class AudioSettings {
  double sfxVolume;
  double musicVolume;
  bool isMuted;

  AudioSettings({
    this.sfxVolume = 1.0,
    this.musicVolume = 0.7,
    this.isMuted = false,
  });

  /// Create from JSON data
  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.7,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  /// Convert to JSON data
  Map<String, dynamic> toJson() {
    return {
      'sfxVolume': sfxVolume,
      'musicVolume': musicVolume,
      'isMuted': isMuted,
    };
  }

  /// Create a copy with modified values
  AudioSettings copyWith({
    double? sfxVolume,
    double? musicVolume,
    bool? isMuted,
  }) {
    return AudioSettings(
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}