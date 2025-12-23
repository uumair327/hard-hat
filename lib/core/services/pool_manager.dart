import 'dart:async';
import 'object_pool.dart';
import 'ball_pool.dart';
import 'audio_player_pool.dart';
import '../../features/game/domain/services/particle_pool.dart';

/// Configuration for object pool initialization
class PoolConfiguration {
  const PoolConfiguration({
    this.ballPoolSize = 20,
    this.particlePoolSize = 500,
    this.particleEmitterPoolSize = 50,
    this.audioPlayerPoolSize = 30,
    this.audioComponentPoolSize = 50,
    this.enableAutoOptimization = true,
    this.optimizationInterval = const Duration(seconds: 30),
  });
  
  final int ballPoolSize;
  final int particlePoolSize;
  final int particleEmitterPoolSize;
  final int audioPlayerPoolSize;
  final int audioComponentPoolSize;
  final bool enableAutoOptimization;
  final Duration optimizationInterval;
}

/// Comprehensive pool manager for all game object pools
class GamePoolManager {
  static final GamePoolManager _instance = GamePoolManager._internal();
  factory GamePoolManager() => _instance;
  GamePoolManager._internal();
  
  // Pool managers
  GlobalBallPoolManager? _ballPoolManager;
  GlobalParticlePoolManager? _particlePoolManager;
  GlobalAudioPoolManager? _audioPoolManager;
  
  // Configuration
  PoolConfiguration? _config;
  
  // Optimization timer
  Timer? _optimizationTimer;
  
  // Performance tracking
  final Map<String, List<double>> _performanceHistory = {};
  static const int maxHistoryLength = 100;
  
  /// Initialize all object pools with configuration
  void initialize({
    PoolConfiguration? config,
    void Function(dynamic ball)? onBallRecycled,
    void Function(dynamic ball, String tileId)? onTileDestroyed,
  }) {
    _config = config ?? const PoolConfiguration();
    
    // Initialize ball pool
    _ballPoolManager = GlobalBallPoolManager();
    _ballPoolManager!.initialize(
      initialSize: _config!.ballPoolSize ~/ 4,
      maxSize: _config!.ballPoolSize,
      onBallRecycled: onBallRecycled,
      onTileDestroyed: onTileDestroyed,
    );
    
    // Initialize particle pools
    _particlePoolManager = GlobalParticlePoolManager();
    _particlePoolManager!.initialize(
      particlePoolSize: _config!.particlePoolSize,
      emitterPoolSize: _config!.particleEmitterPoolSize,
    );
    
    // Initialize audio pools
    _audioPoolManager = GlobalAudioPoolManager();
    _audioPoolManager!.initialize(
      playerPoolSize: _config!.audioPlayerPoolSize,
      componentPoolSize: _config!.audioComponentPoolSize,
    );
    
    // Start optimization timer if enabled
    if (_config!.enableAutoOptimization) {
      _startOptimizationTimer();
    }
  }
  
  /// Update all pools (should be called every frame)
  void update(double dt) {
    _ballPoolManager?.update(dt);
    _particlePoolManager?.update(dt);
    _audioPoolManager?.update(dt);
    
    // Track performance
    _trackPerformance('update_time', dt);
  }
  
  /// Get ball pool manager
  GlobalBallPoolManager get ballPool {
    if (_ballPoolManager == null) {
      throw StateError('GamePoolManager not initialized. Call initialize() first.');
    }
    return _ballPoolManager!;
  }
  
  /// Get particle pool manager
  GlobalParticlePoolManager get particlePool {
    if (_particlePoolManager == null) {
      throw StateError('GamePoolManager not initialized. Call initialize() first.');
    }
    return _particlePoolManager!;
  }
  
  /// Get audio pool manager
  GlobalAudioPoolManager get audioPool {
    if (_audioPoolManager == null) {
      throw StateError('GamePoolManager not initialized. Call initialize() first.');
    }
    return _audioPoolManager!;
  }
  
  /// Check if all pools are initialized
  bool get isInitialized => 
    _ballPoolManager?.isInitialized == true &&
    _particlePoolManager != null &&
    _audioPoolManager?.isInitialized == true;
  
  /// Get comprehensive statistics for all pools
  Map<String, dynamic> getAllStats() {
    final stats = <String, dynamic>{};
    
    // Ball pool stats
    if (_ballPoolManager?.isInitialized == true) {
      stats['balls'] = _ballPoolManager!.stats?.toString() ?? 'Not available';
    }
    
    // Particle pool stats
    if (_particlePoolManager != null) {
      stats['particles'] = _particlePoolManager!.getStats();
    }
    
    // Audio pool stats
    if (_audioPoolManager?.isInitialized == true) {
      stats['audio'] = _audioPoolManager!.getStats();
    }
    
    // Performance stats
    stats['performance'] = _getPerformanceStats();
    
    return stats;
  }
  
  /// Get performance statistics
  Map<String, dynamic> _getPerformanceStats() {
    final perfStats = <String, dynamic>{};
    
    for (final entry in _performanceHistory.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        final max = values.reduce((a, b) => a > b ? a : b);
        final min = values.reduce((a, b) => a < b ? a : b);
        
        perfStats[entry.key] = {
          'average': avg,
          'max': max,
          'min': min,
          'samples': values.length,
        };
      }
    }
    
    return perfStats;
  }
  
  /// Track performance metrics
  void _trackPerformance(String metric, double value) {
    _performanceHistory.putIfAbsent(metric, () => <double>[]);
    final history = _performanceHistory[metric]!;
    
    history.add(value);
    
    // Limit history length
    if (history.length > maxHistoryLength) {
      history.removeAt(0);
    }
  }
  
  /// Start automatic pool optimization
  void _startOptimizationTimer() {
    _optimizationTimer?.cancel();
    _optimizationTimer = Timer.periodic(_config!.optimizationInterval, (_) {
      _optimizePools();
    });
  }
  
  /// Optimize pool sizes based on usage patterns
  void _optimizePools() {
    // This is a placeholder for pool optimization logic
    // In a real implementation, this would analyze usage patterns
    // and adjust pool sizes accordingly
    
    final stats = getAllStats();
    
    // Log optimization data (in a real app, this would use a proper logger)
    print('Pool optimization check: $stats');
    
    // Example optimization: if hit rate is low, consider reducing pool size
    // if miss rate is high, consider increasing pool size
    // This would require more sophisticated analysis in a production system
  }
  
  /// Force optimization of all pools
  void optimizeNow() {
    _optimizePools();
  }
  
  /// Clear all pools
  void clearAll() {
    _ballPoolManager?.clear();
    _particlePoolManager?.clear();
    _audioPoolManager?.clear();
  }
  
  /// Pause all pool operations (for game pause)
  Future<void> pauseAll() async {
    await _audioPoolManager?.pauseAll();
    // Balls and particles don't need pausing, they're managed by game systems
  }
  
  /// Resume all pool operations (for game resume)
  Future<void> resumeAll() async {
    await _audioPoolManager?.resumeAll();
  }
  
  /// Stop all active objects in pools
  Future<void> stopAll() async {
    _ballPoolManager?.ballPool.recycleAllBalls();
    _particlePoolManager?.clear();
    await _audioPoolManager?.stopAll();
  }
  
  /// Dispose all pools and cleanup resources
  void dispose() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    
    _ballPoolManager?.dispose();
    _particlePoolManager?.dispose();
    _audioPoolManager?.dispose();
    
    _ballPoolManager = null;
    _particlePoolManager = null;
    _audioPoolManager = null;
    
    _performanceHistory.clear();
    _config = null;
  }
  
  /// Get current configuration
  PoolConfiguration? get configuration => _config;
  
  /// Update configuration (requires reinitialization)
  void updateConfiguration(PoolConfiguration newConfig) {
    if (_config != newConfig) {
      final wasInitialized = isInitialized;
      dispose();
      
      if (wasInitialized) {
        initialize(config: newConfig);
      }
    }
  }
}

/// Extension methods for easier pool access
extension GamePoolManagerExtensions on GamePoolManager {
  /// Quick access to launch a ball
  dynamic launchBall({
    required dynamic position,
    required dynamic direction,
    double? speed,
  }) {
    return ballPool.ballPool.launchBall(
      position: position,
      direction: direction,
      speed: speed,
    );
  }
  
  /// Quick access to play spatial audio
  Future<dynamic> playSpatialAudio({
    required String soundId,
    required dynamic position,
    double volume = 1.0,
  }) async {
    return await audioPool.playerPool.playSfx(
      soundId: soundId,
      volume: volume,
      spatialPosition: position,
    );
  }
  
  /// Quick access to spawn particles
  dynamic spawnParticles({
    required dynamic config,
    required dynamic position,
    int? maxParticles,
  }) {
    return particlePool.emitterPool.getEmitter(
      config: config,
      position: position,
      maxBurstParticles: maxParticles,
    );
  }
}