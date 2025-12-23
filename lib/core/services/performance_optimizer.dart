import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'performance_monitor.dart';
import 'memory_profiler.dart';
import 'pool_manager.dart';

/// Performance optimization strategies
enum OptimizationStrategy {
  reduceRenderComplexity,
  optimizeMemoryUsage,
  adjustPoolSizes,
  reduceParticleCount,
  lowerAudioQuality,
  disableNonEssentialEffects,
}

/// Performance optimization action
class OptimizationAction {
  const OptimizationAction({
    required this.strategy,
    required this.description,
    required this.expectedImpact,
    required this.priority,
    required this.action,
  });
  
  final OptimizationStrategy strategy;
  final String description;
  final String expectedImpact;
  final int priority; // 1-10, higher is more important
  final Future<void> Function() action;
}

/// Performance optimization result
class OptimizationResult {
  const OptimizationResult({
    required this.strategy,
    required this.success,
    required this.message,
    required this.performanceImprovement,
    required this.timestamp,
  });
  
  final OptimizationStrategy strategy;
  final bool success;
  final String message;
  final double performanceImprovement; // percentage improvement
  final DateTime timestamp;
}

/// Comprehensive performance optimization service
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();
  
  // Dependencies
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final MemoryProfiler _memoryProfiler = MemoryProfiler();
  final GamePoolManager _poolManager = GamePoolManager();
  
  // Configuration
  bool _isEnabled = false;
  bool _autoOptimizationEnabled = true;
  Duration _optimizationInterval = const Duration(seconds: 30);
  
  // State tracking
  final Queue<OptimizationResult> _optimizationHistory = Queue<OptimizationResult>();
  Timer? _optimizationTimer;
  
  // Performance targets
  double _targetFrameRate = 60.0;
  double _minAcceptableFrameRate = 45.0;
  int _maxMemoryUsage = 150 * 1024 * 1024; // 150MB
  
  // Optimization state
  final Map<OptimizationStrategy, bool> _appliedOptimizations = {};
  
  // Callbacks
  void Function(OptimizationResult result)? onOptimizationApplied;
  void Function(List<OptimizationAction> actions)? onOptimizationSuggested;
  
  /// Initialize the performance optimizer
  void initialize({
    double? targetFrameRate,
    double? minAcceptableFrameRate,
    int? maxMemoryUsage,
    bool? autoOptimizationEnabled,
    Duration? optimizationInterval,
    void Function(OptimizationResult result)? onOptimizationApplied,
    void Function(List<OptimizationAction> actions)? onOptimizationSuggested,
  }) {
    _targetFrameRate = targetFrameRate ?? 60.0;
    _minAcceptableFrameRate = minAcceptableFrameRate ?? 45.0;
    _maxMemoryUsage = maxMemoryUsage ?? 150 * 1024 * 1024;
    _autoOptimizationEnabled = autoOptimizationEnabled ?? true;
    _optimizationInterval = optimizationInterval ?? const Duration(seconds: 30);
    this.onOptimizationApplied = onOptimizationApplied;
    this.onOptimizationSuggested = onOptimizationSuggested;
    
    // Initialize monitoring systems
    _performanceMonitor.initialize(
      onAlert: _handlePerformanceAlert,
    );
    
    _memoryProfiler.initialize(
      onLeaksDetected: _handleMemoryLeaks,
    );
  }
  
  /// Start performance optimization
  void start() {
    if (_isEnabled) return;
    
    _isEnabled = true;
    
    // Start monitoring systems
    _performanceMonitor.start();
    _memoryProfiler.start();
    
    // Start optimization timer if auto-optimization is enabled
    if (_autoOptimizationEnabled) {
      _optimizationTimer = Timer.periodic(_optimizationInterval, (_) {
        _performAutoOptimization();
      });
    }
  }
  
  /// Stop performance optimization
  void stop() {
    if (!_isEnabled) return;
    
    _isEnabled = false;
    
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    
    _performanceMonitor.stop();
    _memoryProfiler.stop();
  }
  
  /// Handle performance alerts
  void _handlePerformanceAlert(PerformanceAlert alert) {
    if (!_isEnabled) return;
    
    if (alert.level == PerformanceAlertLevel.critical) {
      // Apply immediate optimizations for critical alerts
      _applyEmergencyOptimizations();
    } else if (alert.level == PerformanceAlertLevel.warning) {
      // Suggest optimizations for warnings
      final suggestions = _generateOptimizationSuggestions();
      onOptimizationSuggested?.call(suggestions);
    }
  }
  
  /// Handle memory leaks
  void _handleMemoryLeaks(List<MemoryLeakInfo> leaks) {
    if (!_isEnabled) return;
    
    for (final leak in leaks) {
      if (leak.severity == MemoryLeakSeverity.critical) {
        _applyMemoryOptimizations();
        break;
      }
    }
  }
  
  /// Perform automatic optimization
  void _performAutoOptimization() {
    if (!_isEnabled || !_autoOptimizationEnabled) return;
    
    final currentMetrics = _performanceMonitor.currentMetrics;
    final currentMemory = _memoryProfiler.currentSnapshot;
    
    if (currentMetrics == null || currentMemory == null) return;
    
    // Check if optimization is needed
    final needsOptimization = _needsOptimization(currentMetrics, currentMemory);
    
    if (needsOptimization) {
      final suggestions = _generateOptimizationSuggestions();
      
      // Apply high-priority optimizations automatically
      for (final suggestion in suggestions) {
        if (suggestion.priority >= 8) {
          _applyOptimization(suggestion);
        }
      }
      
      // Suggest medium-priority optimizations
      final mediumPriorityActions = suggestions.where((s) => s.priority >= 5 && s.priority < 8).toList();
      if (mediumPriorityActions.isNotEmpty) {
        onOptimizationSuggested?.call(mediumPriorityActions);
      }
    }
  }
  
  /// Check if optimization is needed
  bool _needsOptimization(PerformanceMetrics metrics, MemorySnapshot memory) {
    return metrics.frameRate < _minAcceptableFrameRate ||
           metrics.frameTime > 25.0 || // 40 FPS threshold
           memory.usedMemory > _maxMemoryUsage ||
           memory.memoryUtilization > 0.8;
  }
  
  /// Generate optimization suggestions
  List<OptimizationAction> _generateOptimizationSuggestions() {
    final suggestions = <OptimizationAction>[];
    final currentMetrics = _performanceMonitor.currentMetrics;
    final currentMemory = _memoryProfiler.currentSnapshot;
    
    if (currentMetrics == null || currentMemory == null) return suggestions;
    
    // Frame rate optimizations
    if (currentMetrics.frameRate < _targetFrameRate) {
      if (!_appliedOptimizations[OptimizationStrategy.reduceRenderComplexity]!) {
        suggestions.add(OptimizationAction(
          strategy: OptimizationStrategy.reduceRenderComplexity,
          description: 'Reduce rendering complexity to improve frame rate',
          expectedImpact: '10-20% FPS improvement',
          priority: 8,
          action: _reduceRenderComplexity,
        ));
      }
      
      if (!_appliedOptimizations[OptimizationStrategy.reduceParticleCount]!) {
        suggestions.add(OptimizationAction(
          strategy: OptimizationStrategy.reduceParticleCount,
          description: 'Reduce particle count to improve performance',
          expectedImpact: '5-15% FPS improvement',
          priority: 6,
          action: _reduceParticleCount,
        ));
      }
    }
    
    // Memory optimizations
    if (currentMemory.memoryUtilization > 0.7) {
      if (!_appliedOptimizations[OptimizationStrategy.optimizeMemoryUsage]!) {
        suggestions.add(OptimizationAction(
          strategy: OptimizationStrategy.optimizeMemoryUsage,
          description: 'Optimize memory usage and clear caches',
          expectedImpact: '20-30% memory reduction',
          priority: 7,
          action: _optimizeMemoryUsage,
        ));
      }
      
      if (!_appliedOptimizations[OptimizationStrategy.adjustPoolSizes]!) {
        suggestions.add(OptimizationAction(
          strategy: OptimizationStrategy.adjustPoolSizes,
          description: 'Adjust object pool sizes for better memory efficiency',
          expectedImpact: '10-20% memory reduction',
          priority: 5,
          action: _adjustPoolSizes,
        ));
      }
    }
    
    // Audio optimizations
    if (currentMetrics.frameRate < _minAcceptableFrameRate) {
      if (!_appliedOptimizations[OptimizationStrategy.lowerAudioQuality]!) {
        suggestions.add(OptimizationAction(
          strategy: OptimizationStrategy.lowerAudioQuality,
          description: 'Lower audio quality to reduce CPU usage',
          expectedImpact: '5-10% CPU reduction',
          priority: 4,
          action: _lowerAudioQuality,
        ));
      }
    }
    
    // Visual effects optimizations
    if (currentMetrics.frameRate < _minAcceptableFrameRate * 0.8) {
      if (!_appliedOptimizations[OptimizationStrategy.disableNonEssentialEffects]!) {
        suggestions.add(OptimizationAction(
          strategy: OptimizationStrategy.disableNonEssentialEffects,
          description: 'Disable non-essential visual effects',
          expectedImpact: '15-25% performance improvement',
          priority: 9,
          action: _disableNonEssentialEffects,
        ));
      }
    }
    
    // Sort by priority
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    
    return suggestions;
  }
  
  /// Apply emergency optimizations for critical performance issues
  void _applyEmergencyOptimizations() {
    final emergencyActions = [
      OptimizationAction(
        strategy: OptimizationStrategy.disableNonEssentialEffects,
        description: 'Emergency: Disable non-essential effects',
        expectedImpact: 'Immediate performance boost',
        priority: 10,
        action: _disableNonEssentialEffects,
      ),
      OptimizationAction(
        strategy: OptimizationStrategy.reduceParticleCount,
        description: 'Emergency: Reduce particle count',
        expectedImpact: 'Immediate performance boost',
        priority: 10,
        action: _reduceParticleCount,
      ),
    ];
    
    for (final action in emergencyActions) {
      _applyOptimization(action);
    }
  }
  
  /// Apply memory-specific optimizations
  void _applyMemoryOptimizations() {
    final memoryActions = [
      OptimizationAction(
        strategy: OptimizationStrategy.optimizeMemoryUsage,
        description: 'Clear caches and optimize memory',
        expectedImpact: 'Immediate memory reduction',
        priority: 10,
        action: _optimizeMemoryUsage,
      ),
      OptimizationAction(
        strategy: OptimizationStrategy.adjustPoolSizes,
        description: 'Reduce pool sizes',
        expectedImpact: 'Memory usage reduction',
        priority: 9,
        action: _adjustPoolSizes,
      ),
    ];
    
    for (final action in memoryActions) {
      _applyOptimization(action);
    }
  }
  
  /// Apply a specific optimization
  Future<void> _applyOptimization(OptimizationAction action) async {
    if (_appliedOptimizations[action.strategy] == true) return;
    
    final beforeMetrics = _performanceMonitor.currentMetrics;
    
    try {
      await action.action();
      _appliedOptimizations[action.strategy] = true;
      
      // Wait a moment for the optimization to take effect
      await Future.delayed(const Duration(seconds: 2));
      
      final afterMetrics = _performanceMonitor.currentMetrics;
      double improvement = 0.0;
      
      if (beforeMetrics != null && afterMetrics != null) {
        improvement = ((afterMetrics.frameRate - beforeMetrics.frameRate) / beforeMetrics.frameRate) * 100;
      }
      
      final result = OptimizationResult(
        strategy: action.strategy,
        success: true,
        message: 'Successfully applied: ${action.description}',
        performanceImprovement: improvement,
        timestamp: DateTime.now(),
      );
      
      _optimizationHistory.add(result);
      onOptimizationApplied?.call(result);
      
      if (kDebugMode) {
        print('Applied optimization: ${action.strategy} - ${improvement.toStringAsFixed(1)}% improvement');
      }
      
    } catch (e) {
      final result = OptimizationResult(
        strategy: action.strategy,
        success: false,
        message: 'Failed to apply optimization: $e',
        performanceImprovement: 0.0,
        timestamp: DateTime.now(),
      );
      
      _optimizationHistory.add(result);
      onOptimizationApplied?.call(result);
      
      if (kDebugMode) {
        print('Failed to apply optimization: ${action.strategy} - $e');
      }
    }
  }
  
  // Optimization implementation methods
  
  Future<void> _reduceRenderComplexity() async {
    // Reduce sprite batch sizes, lower texture quality, etc.
    // This would integrate with the render system
    if (kDebugMode) {
      print('Reducing render complexity');
    }
  }
  
  Future<void> _optimizeMemoryUsage() async {
    // Clear caches, force garbage collection, etc.
    _poolManager.clearAll();
    _memoryProfiler.forceGarbageCollection();
    
    if (kDebugMode) {
      print('Optimizing memory usage');
    }
  }
  
  Future<void> _adjustPoolSizes() async {
    // Reduce pool sizes to save memory
    final newConfig = PoolConfiguration(
      ballPoolSize: 10,
      particlePoolSize: 250,
      particleEmitterPoolSize: 25,
      audioPlayerPoolSize: 15,
      audioComponentPoolSize: 25,
    );
    
    _poolManager.updateConfiguration(newConfig);
    
    if (kDebugMode) {
      print('Adjusting pool sizes');
    }
  }
  
  Future<void> _reduceParticleCount() async {
    // Reduce particle counts in active systems
    _poolManager.particlePool.clear();
    
    if (kDebugMode) {
      print('Reducing particle count');
    }
  }
  
  Future<void> _lowerAudioQuality() async {
    // Reduce audio quality settings
    // This would integrate with the audio system
    if (kDebugMode) {
      print('Lowering audio quality');
    }
  }
  
  Future<void> _disableNonEssentialEffects() async {
    // Disable particle effects, screen shake, etc.
    _poolManager.particlePool.clear();
    
    if (kDebugMode) {
      print('Disabling non-essential effects');
    }
  }
  
  /// Manually apply optimization suggestions
  Future<void> applyOptimizations(List<OptimizationAction> actions) async {
    for (final action in actions) {
      await _applyOptimization(action);
    }
  }
  
  /// Reset all applied optimizations
  Future<void> resetOptimizations() async {
    _appliedOptimizations.clear();
    
    // Reinitialize pools with default configuration
    _poolManager.updateConfiguration(const PoolConfiguration());
    
    if (kDebugMode) {
      print('Reset all optimizations');
    }
  }
  
  /// Get current performance status
  Map<String, dynamic> getPerformanceStatus() {
    final performanceStats = _performanceMonitor.getStatistics();
    final memoryStats = _memoryProfiler.getStatistics();
    final poolStats = _poolManager.getAllStats();
    
    return {
      'performance': performanceStats,
      'memory': memoryStats,
      'pools': poolStats,
      'appliedOptimizations': _appliedOptimizations.keys.map((k) => k.toString()).toList(),
      'optimizationHistory': _optimizationHistory.length,
      'isEnabled': _isEnabled,
      'autoOptimizationEnabled': _autoOptimizationEnabled,
    };
  }
  
  /// Get optimization history
  List<OptimizationResult> get optimizationHistory => List.unmodifiable(_optimizationHistory);
  
  /// Clear optimization history
  void clearHistory() {
    _optimizationHistory.clear();
  }
  
  /// Enable/disable auto-optimization
  void setAutoOptimization(bool enabled) {
    _autoOptimizationEnabled = enabled;
    
    if (enabled && _isEnabled) {
      _optimizationTimer ??= Timer.periodic(_optimizationInterval, (_) {
        _performAutoOptimization();
      });
    } else {
      _optimizationTimer?.cancel();
      _optimizationTimer = null;
    }
  }
  
  /// Dispose of the performance optimizer
  void dispose() {
    stop();
    _optimizationHistory.clear();
    _appliedOptimizations.clear();
    onOptimizationApplied = null;
    onOptimizationSuggested = null;
  }
  
  /// Get enabled status
  bool get isEnabled => _isEnabled;
  
  /// Get auto-optimization status
  bool get autoOptimizationEnabled => _autoOptimizationEnabled;
}