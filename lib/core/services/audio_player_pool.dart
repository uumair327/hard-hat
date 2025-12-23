import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import '../../features/game/domain/components/audio_component.dart';
import 'object_pool.dart';

/// Pooled audio player for managing audio playback instances
class PooledAudioPlayer {
  PooledAudioPlayer({
    required this.id,
  });
  
  final String id;
  
  // Audio state
  String? _currentSoundId;
  bool _isPlaying = false;
  bool _isLooping = false;
  double _volume = 1.0;
  Vector2? _spatialPosition;
  
  // Playback control
  AudioPlayer? _audioPlayer;
  
  /// Play a sound with this audio player
  Future<void> play({
    required String soundId,
    double volume = 1.0,
    bool loop = false,
    Vector2? spatialPosition,
  }) async {
    // Stop current sound if playing
    await stop();
    
    _currentSoundId = soundId;
    _volume = volume;
    _isLooping = loop;
    _spatialPosition = spatialPosition;
    
    try {
      // Use FlameAudio to play the sound
      if (loop) {
        _audioPlayer = await FlameAudio.loop(soundId, volume: volume);
      } else {
        await FlameAudio.play(soundId, volume: volume);
      }
      _isPlaying = true;
    } catch (e) {
      // Handle audio loading/playing errors
      _isPlaying = false;
      _currentSoundId = null;
    }
  }
  
  /// Stop the current sound
  Future<void> stop() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
      _audioPlayer = null;
    }
    _isPlaying = false;
    _currentSoundId = null;
  }
  
  /// Pause the current sound
  Future<void> pause() async {
    if (_audioPlayer != null && _isPlaying) {
      await _audioPlayer!.pause();
    }
  }
  
  /// Resume the current sound
  Future<void> resume() async {
    if (_audioPlayer != null && !_isPlaying) {
      await _audioPlayer!.resume();
    }
  }
  
  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }
  }
  
  /// Update spatial position (for future 3D audio implementation)
  void updateSpatialPosition(Vector2 position) {
    _spatialPosition = position;
    // TODO: Implement spatial audio positioning when available
  }
  
  /// Reset the audio player for reuse
  void reset() {
    stop();
    _currentSoundId = null;
    _isPlaying = false;
    _isLooping = false;
    _volume = 1.0;
    _spatialPosition = null;
  }
  
  // Getters
  String? get currentSoundId => _currentSoundId;
  bool get isPlaying => _isPlaying;
  bool get isLooping => _isLooping;
  double get volume => _volume;
  Vector2? get spatialPosition => _spatialPosition;
  bool get isAvailable => !_isPlaying;
}

/// Object pool for audio players
class AudioPlayerPool extends GenericObjectPool<PooledAudioPlayer> {
  AudioPlayerPool({
    int initialSize = 10,
    int maxSize = 50,
  }) : super(
    factory: () => PooledAudioPlayer(
      id: 'audio_player_${DateTime.now().millisecondsSinceEpoch}_${_playerCounter++}',
    ),
    reset: (player) => player.reset(),
    initialSize: initialSize,
    maxSize: maxSize,
    autoExpand: true,
  );
  
  static int _playerCounter = 0;
  
  /// Play a sound effect using a pooled audio player
  Future<PooledAudioPlayer?> playSfx({
    required String soundId,
    double volume = 1.0,
    Vector2? spatialPosition,
  }) async {
    final player = acquire();
    await player.play(
      soundId: soundId,
      volume: volume,
      spatialPosition: spatialPosition,
    );
    return player;
  }
  
  /// Play a looping sound using a pooled audio player
  Future<PooledAudioPlayer?> playLoop({
    required String soundId,
    double volume = 1.0,
    Vector2? spatialPosition,
  }) async {
    final player = acquire();
    await player.play(
      soundId: soundId,
      volume: volume,
      loop: true,
      spatialPosition: spatialPosition,
    );
    return player;
  }
  
  /// Update all active audio players and recycle finished ones
  void updateActivePlayers(double dt) {
    final playersToRecycle = <PooledAudioPlayer>[];
    
    for (final player in activeObjects) {
      // Check if non-looping sounds have finished
      if (!player.isLooping && !player.isPlaying && player.currentSoundId != null) {
        playersToRecycle.add(player);
      }
    }
    
    // Recycle finished players
    releaseAll(playersToRecycle);
  }
  
  /// Stop all active audio players
  Future<void> stopAll() async {
    final activePlayers = List<PooledAudioPlayer>.from(activeObjects);
    for (final player in activePlayers) {
      await player.stop();
    }
    releaseAll(activePlayers);
  }
  
  /// Pause all active audio players
  Future<void> pauseAll() async {
    for (final player in activeObjects) {
      await player.pause();
    }
  }
  
  /// Resume all active audio players
  Future<void> resumeAll() async {
    for (final player in activeObjects) {
      await player.resume();
    }
  }
  
  /// Set volume for all active players
  Future<void> setVolumeAll(double volume) async {
    for (final player in activeObjects) {
      await player.setVolume(volume);
    }
  }
  
  /// Get all active audio players
  List<PooledAudioPlayer> get activePlayers => List<PooledAudioPlayer>.from(activeObjects);
  
  /// Get count of active audio players
  int get activePlayerCount => activeObjects.length;
}

/// Audio component pool for ECS audio components
class AudioComponentPool extends GenericObjectPool<AudioComponent> {
  AudioComponentPool({
    int initialSize = 20,
    int maxSize = 100,
  }) : super(
    factory: () => AudioComponent(
      soundId: '',
      isLooping: false,
      volume: 1.0,
    ),
    reset: (component) => component.reset(),
    initialSize: initialSize,
    maxSize: maxSize,
    autoExpand: true,
  );
  
  /// Acquire an audio component with specified parameters
  AudioComponent acquireComponent({
    required String soundId,
    bool isLooping = false,
    double volume = 1.0,
    Vector2? spatialPosition,
  }) {
    final component = acquire();
    component.soundId = soundId;
    component.isLooping = isLooping;
    component.volume = volume;
    component.spatialPosition = spatialPosition;
    component.isPlaying = true;
    return component;
  }
  
  /// Update all active audio components and recycle finished ones
  void updateActiveComponents(double dt) {
    final componentsToRecycle = <AudioComponent>[];
    
    for (final component in activeObjects) {
      // Check if component should be recycled (finished playing)
      if (!component.isPlaying && component.isOneShot) {
        componentsToRecycle.add(component);
      }
    }
    
    // Recycle finished components
    releaseAll(componentsToRecycle);
  }
  
  /// Get all active audio components
  List<AudioComponent> get activeComponents => List<AudioComponent>.from(activeObjects);
}

/// Global audio pool manager
class GlobalAudioPoolManager {
  static final GlobalAudioPoolManager _instance = GlobalAudioPoolManager._internal();
  factory GlobalAudioPoolManager() => _instance;
  GlobalAudioPoolManager._internal();
  
  AudioPlayerPool? _playerPool;
  AudioComponentPool? _componentPool;
  
  /// Initialize the global audio pools
  void initialize({
    int playerPoolSize = 30,
    int componentPoolSize = 50,
  }) {
    _playerPool?.dispose();
    _componentPool?.dispose();
    
    _playerPool = AudioPlayerPool(
      initialSize: playerPoolSize ~/ 3,
      maxSize: playerPoolSize,
    );
    
    _componentPool = AudioComponentPool(
      initialSize: componentPoolSize ~/ 5,
      maxSize: componentPoolSize,
    );
  }
  
  /// Get the audio player pool
  AudioPlayerPool get playerPool {
    if (_playerPool == null) {
      throw StateError('AudioPlayerPool not initialized. Call initialize() first.');
    }
    return _playerPool!;
  }
  
  /// Get the audio component pool
  AudioComponentPool get componentPool {
    if (_componentPool == null) {
      throw StateError('AudioComponentPool not initialized. Call initialize() first.');
    }
    return _componentPool!;
  }
  
  /// Check if pools are initialized
  bool get isInitialized => _playerPool != null && _componentPool != null;
  
  /// Update all audio pools
  void update(double dt) {
    _playerPool?.updateActivePlayers(dt);
    _componentPool?.updateActiveComponents(dt);
  }
  
  /// Get combined statistics
  Map<String, PoolStats> getStats() {
    return {
      'audioPlayers': _playerPool?.stats ?? PoolStats(
        available: 0, active: 0, total: 0, maxSize: 0, hitRate: 0.0, missRate: 0.0,
      ),
      'audioComponents': _componentPool?.stats ?? PoolStats(
        available: 0, active: 0, total: 0, maxSize: 0, hitRate: 0.0, missRate: 0.0,
      ),
    };
  }
  
  /// Stop all audio
  Future<void> stopAll() async {
    await _playerPool?.stopAll();
  }
  
  /// Pause all audio
  Future<void> pauseAll() async {
    await _playerPool?.pauseAll();
  }
  
  /// Resume all audio
  Future<void> resumeAll() async {
    await _playerPool?.resumeAll();
  }
  
  /// Clear all pools
  void clear() {
    _playerPool?.clear();
    _componentPool?.clear();
  }
  
  /// Dispose all pools
  void dispose() {
    _playerPool?.dispose();
    _componentPool?.dispose();
    _playerPool = null;
    _componentPool = null;
  }
}