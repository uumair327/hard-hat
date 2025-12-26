import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Render performance optimization settings
class RenderOptimizationSettings {
  const RenderOptimizationSettings({
    this.enableSpriteBatching = true,
    this.maxBatchSize = 100,
    this.enableFrustumCulling = true,
    this.enableDepthSorting = true,
    this.maxRenderDistance = 1000.0,
    this.particleRenderLimit = 500,
    this.enableLevelOfDetail = false,
    this.lodDistanceThreshold = 500.0,
  });
  
  final bool enableSpriteBatching;
  final int maxBatchSize;
  final bool enableFrustumCulling;
  final bool enableDepthSorting;
  final double maxRenderDistance;
  final int particleRenderLimit;
  final bool enableLevelOfDetail;
  final double lodDistanceThreshold;
  
  RenderOptimizationSettings copyWith({
    bool? enableSpriteBatching,
    int? maxBatchSize,
    bool? enableFrustumCulling,
    bool? enableDepthSorting,
    double? maxRenderDistance,
    int? particleRenderLimit,
    bool? enableLevelOfDetail,
    double? lodDistanceThreshold,
  }) {
    return RenderOptimizationSettings(
      enableSpriteBatching: enableSpriteBatching ?? this.enableSpriteBatching,
      maxBatchSize: maxBatchSize ?? this.maxBatchSize,
      enableFrustumCulling: enableFrustumCulling ?? this.enableFrustumCulling,
      enableDepthSorting: enableDepthSorting ?? this.enableDepthSorting,
      maxRenderDistance: maxRenderDistance ?? this.maxRenderDistance,
      particleRenderLimit: particleRenderLimit ?? this.particleRenderLimit,
      enableLevelOfDetail: enableLevelOfDetail ?? this.enableLevelOfDetail,
      lodDistanceThreshold: lodDistanceThreshold ?? this.lodDistanceThreshold,
    );
  }
}

/// Render performance metrics
class RenderPerformanceMetrics {
  const RenderPerformanceMetrics({
    required this.entitiesRendered,
    required this.batchesUsed,
    required this.particlesRendered,
    required this.entitiesCulled,
    required this.renderTime,
    required this.batchingEfficiency,
    required this.cullingEfficiency,
    required this.timestamp,
  });
  
  final int entitiesRendered;
  final int batchesUsed;
  final int particlesRendered;
  final int entitiesCulled;
  final double renderTime; // in milliseconds
  final double batchingEfficiency; // 0.0 to 1.0
  final double cullingEfficiency; // 0.0 to 1.0
  final DateTime timestamp;
  
  @override
  String toString() {
    return 'RenderMetrics(entities: $entitiesRendered, batches: $batchesUsed, '
           'particles: $particlesRendered, culled: $entitiesCulled, '
           'renderTime: ${renderTime.toStringAsFixed(2)}ms, '
           'batchEff: ${(batchingEfficiency * 100).toStringAsFixed(1)}%, '
           'cullEff: ${(cullingEfficiency * 100).toStringAsFixed(1)}%)';
  }
}

/// Render performance optimizer
class RenderPerformanceOptimizer {
  static final RenderPerformanceOptimizer _instance = RenderPerformanceOptimizer._internal();
  factory RenderPerformanceOptimizer() => _instance;
  RenderPerformanceOptimizer._internal();
  
  // Configuration
  RenderOptimizationSettings _settings = const RenderOptimizationSettings();
  bool _isEnabled = false;
  
  // Performance tracking
  final Queue<RenderPerformanceMetrics> _metricsHistory = Queue<RenderPerformanceMetrics>();
  static const int maxHistoryLength = 300; // 5 seconds at 60 FPS
  
  // Render statistics
  int _currentFrameEntities = 0;
  int _currentFrameBatches = 0;
  int _currentFrameParticles = 0;
  int _currentFrameCulled = 0;
  double _currentFrameRenderTime = 0.0;
  
  // Optimization state
  bool _adaptiveOptimizationEnabled = true;
  double _targetFrameTime = 16.67; // 60 FPS target
  
  // Callbacks
  void Function(RenderPerformanceMetrics metrics)? onMetricsUpdated;
  void Function(RenderOptimizationSettings settings)? onSettingsChanged;
  
  /// Initialize the render performance optimizer
  void initialize({
    RenderOptimizationSettings? settings,
    bool? adaptiveOptimizationEnabled,
    double? targetFrameTime,
    void Function(RenderPerformanceMetrics metrics)? onMetricsUpdated,
    void Function(RenderOptimizationSettings settings)? onSettingsChanged,
  }) {
    _settings = settings ?? const RenderOptimizationSettings();
    _adaptiveOptimizationEnabled = adaptiveOptimizationEnabled ?? true;
    _targetFrameTime = targetFrameTime ?? 16.67;
    this.onMetricsUpdated = onMetricsUpdated;
    this.onSettingsChanged = onSettingsChanged;
  }
  
  /// Start render performance optimization
  void start() {
    _isEnabled = true;
  }
  
  /// Stop render performance optimization
  void stop() {
    _isEnabled = false;
  }
  
  /// Record render frame metrics
  void recordFrameMetrics({
    required int entitiesRendered,
    required int batchesUsed,
    required int particlesRendered,
    required int entitiesCulled,
    required double renderTime,
  }) {
    if (!_isEnabled) return;
    
    _currentFrameEntities = entitiesRendered;
    _currentFrameBatches = batchesUsed;
    _currentFrameParticles = particlesRendered;
    _currentFrameCulled = entitiesCulled;
    _currentFrameRenderTime = renderTime;
    
    final batchingEfficiency = _calculateBatchingEfficiency();
    final cullingEfficiency = _calculateCullingEfficiency();
    
    final metrics = RenderPerformanceMetrics(
      entitiesRendered: entitiesRendered,
      batchesUsed: batchesUsed,
      particlesRendered: particlesRendered,
      entitiesCulled: entitiesCulled,
      renderTime: renderTime,
      batchingEfficiency: batchingEfficiency,
      cullingEfficiency: cullingEfficiency,
      timestamp: DateTime.now(),
    );
    
    _metricsHistory.add(metrics);
    if (_metricsHistory.length > maxHistoryLength) {
      _metricsHistory.removeFirst();
    }
    
    onMetricsUpdated?.call(metrics);
    
    // Perform adaptive optimization if enabled
    if (_adaptiveOptimizationEnabled) {
      _performAdaptiveOptimization(metrics);
    }
  }
  
  /// Calculate batching efficiency
  double _calculateBatchingEfficiency() {
    if (_currentFrameEntities == 0) return 1.0;
    
    // Ideal batching would have fewer batches relative to entities
    final idealBatches = (_currentFrameEntities / _settings.maxBatchSize).ceil();
    final actualBatches = _currentFrameBatches;
    
    if (actualBatches == 0) return 0.0;
    
    return (idealBatches / actualBatches).clamp(0.0, 1.0);
  }
  
  /// Calculate culling efficiency
  double _calculateCullingEfficiency() {
    final totalEntities = _currentFrameEntities + _currentFrameCulled;
    if (totalEntities == 0) return 1.0;
    
    return _currentFrameCulled / totalEntities;
  }
  
  /// Perform adaptive optimization based on current performance
  void _performAdaptiveOptimization(RenderPerformanceMetrics metrics) {
    if (metrics.renderTime > _targetFrameTime * 1.2) {
      // Performance is poor, apply optimizations
      _applyPerformanceOptimizations();
    } else if (metrics.renderTime < _targetFrameTime * 0.8) {
      // Performance is good, can relax some optimizations
      _relaxOptimizations();
    }
  }
  
  /// Apply performance optimizations
  void _applyPerformanceOptimizations() {
    var newSettings = _settings;
    
    // Reduce batch size if batching efficiency is low
    if (_settings.enableSpriteBatching && _calculateBatchingEfficiency() < 0.7) {
      newSettings = newSettings.copyWith(
        maxBatchSize: (_settings.maxBatchSize * 0.8).round().clamp(10, 200),
      );
    }
    
    // Enable frustum culling if not already enabled
    if (!_settings.enableFrustumCulling) {
      newSettings = newSettings.copyWith(enableFrustumCulling: true);
    }
    
    // Reduce particle render limit
    if (_currentFrameParticles > _settings.particleRenderLimit * 0.8) {
      newSettings = newSettings.copyWith(
        particleRenderLimit: (_settings.particleRenderLimit * 0.8).round().clamp(50, 1000),
      );
    }
    
    // Enable level of detail if render distance is high
    if (!_settings.enableLevelOfDetail && _settings.maxRenderDistance > 800) {
      newSettings = newSettings.copyWith(
        enableLevelOfDetail: true,
        lodDistanceThreshold: _settings.maxRenderDistance * 0.6,
      );
    }
    
    if (newSettings != _settings) {
      updateSettings(newSettings);
    }
  }
  
  /// Relax optimizations when performance is good
  void _relaxOptimizations() {
    var newSettings = _settings;
    
    // Increase batch size if performance allows
    if (_settings.maxBatchSize < 150 && _calculateBatchingEfficiency() > 0.9) {
      newSettings = newSettings.copyWith(
        maxBatchSize: (_settings.maxBatchSize * 1.1).round().clamp(50, 200),
      );
    }
    
    // Increase particle limit if performance allows
    if (_settings.particleRenderLimit < 800 && _currentFrameParticles < _settings.particleRenderLimit * 0.6) {
      newSettings = newSettings.copyWith(
        particleRenderLimit: (_settings.particleRenderLimit * 1.1).round().clamp(100, 1000),
      );
    }
    
    if (newSettings != _settings) {
      updateSettings(newSettings);
    }
  }
  
  /// Update optimization settings
  void updateSettings(RenderOptimizationSettings newSettings) {
    _settings = newSettings;
    onSettingsChanged?.call(_settings);
    
    if (kDebugMode) {
      print('Render optimization settings updated: ${_settings.toString()}');
    }
  }
  
  /// Get current optimization settings
  RenderOptimizationSettings get settings => _settings;
  
  /// Get current render performance metrics
  RenderPerformanceMetrics? get currentMetrics => 
      _metricsHistory.isNotEmpty ? _metricsHistory.last : null;
  
  /// Get metrics history
  List<RenderPerformanceMetrics> get metricsHistory => List.unmodifiable(_metricsHistory);
  
  /// Get render performance statistics
  Map<String, dynamic> getStatistics() {
    if (_metricsHistory.isEmpty) {
      return {'error': 'No metrics available'};
    }
    
    final metrics = _metricsHistory.toList();
    
    // Calculate averages
    final avgEntities = metrics.map((m) => m.entitiesRendered).reduce((a, b) => a + b) / metrics.length;
    final avgBatches = metrics.map((m) => m.batchesUsed).reduce((a, b) => a + b) / metrics.length;
    final avgParticles = metrics.map((m) => m.particlesRendered).reduce((a, b) => a + b) / metrics.length;
    final avgRenderTime = metrics.map((m) => m.renderTime).reduce((a, b) => a + b) / metrics.length;
    final avgBatchingEff = metrics.map((m) => m.batchingEfficiency).reduce((a, b) => a + b) / metrics.length;
    final avgCullingEff = metrics.map((m) => m.cullingEfficiency).reduce((a, b) => a + b) / metrics.length;
    
    return {
      'current': currentMetrics?.toString() ?? 'No current metrics',
      'averages': {
        'entities_rendered': avgEntities.toStringAsFixed(1),
        'batches_used': avgBatches.toStringAsFixed(1),
        'particles_rendered': avgParticles.toStringAsFixed(1),
        'render_time': '${avgRenderTime.toStringAsFixed(2)}ms',
        'batching_efficiency': '${(avgBatchingEff * 100).toStringAsFixed(1)}%',
        'culling_efficiency': '${(avgCullingEff * 100).toStringAsFixed(1)}%',
      },
      'settings': {
        'sprite_batching_enabled': _settings.enableSpriteBatching,
        'max_batch_size': _settings.maxBatchSize,
        'frustum_culling_enabled': _settings.enableFrustumCulling,
        'particle_render_limit': _settings.particleRenderLimit,
        'level_of_detail_enabled': _settings.enableLevelOfDetail,
      },
      'optimization': {
        'adaptive_enabled': _adaptiveOptimizationEnabled,
        'target_frame_time': '${_targetFrameTime.toStringAsFixed(2)}ms',
        'is_enabled': _isEnabled,
      },
      'sample_count': metrics.length,
    };
  }
  
  /// Clear all metrics
  void clear() {
    _metricsHistory.clear();
  }
  
  /// Enable/disable adaptive optimization
  void setAdaptiveOptimization(bool enabled) {
    _adaptiveOptimizationEnabled = enabled;
  }
  
  /// Set target frame time for optimization
  void setTargetFrameTime(double frameTime) {
    _targetFrameTime = frameTime;
  }
  
  /// Get render performance grade
  String get performanceGrade {
    final current = currentMetrics;
    if (current == null) return 'N/A';
    
    int score = 0;
    
    // Render time score (0-40 points)
    if (current.renderTime <= _targetFrameTime) {
      score += 40;
    } else if (current.renderTime <= _targetFrameTime * 1.2) {
      score += 30;
    } else if (current.renderTime <= _targetFrameTime * 1.5) {
      score += 20;
    } else {
      score += 10;
    }
    
    // Batching efficiency score (0-30 points)
    if (current.batchingEfficiency >= 0.9) {
      score += 30;
    } else if (current.batchingEfficiency >= 0.7) {
      score += 20;
    } else if (current.batchingEfficiency >= 0.5) {
      score += 10;
    }
    
    // Culling efficiency score (0-30 points)
    if (current.cullingEfficiency >= 0.8) {
      score += 30;
    } else if (current.cullingEfficiency >= 0.6) {
      score += 20;
    } else if (current.cullingEfficiency >= 0.4) {
      score += 10;
    }
    
    // Convert to letter grade
    if (score >= 90) return 'A';
    else if (score >= 80) return 'B';
    else if (score >= 70) return 'C';
    else if (score >= 60) return 'D';
    else return 'F';
  }
  
  /// Dispose of the render performance optimizer
  void dispose() {
    stop();
    clear();
    onMetricsUpdated = null;
    onSettingsChanged = null;
  }
  
  /// Get enabled status
  bool get isEnabled => _isEnabled;
  
  /// Get adaptive optimization status
  bool get adaptiveOptimizationEnabled => _adaptiveOptimizationEnabled;
}