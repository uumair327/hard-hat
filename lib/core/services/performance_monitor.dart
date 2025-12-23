import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Performance metrics data structure
class PerformanceMetrics {
  const PerformanceMetrics({
    required this.frameRate,
    required this.frameTime,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.renderTime,
    required this.updateTime,
    required this.timestamp,
  });
  
  final double frameRate;
  final double frameTime; // in milliseconds
  final int memoryUsage; // in bytes
  final double cpuUsage; // percentage
  final double renderTime; // in milliseconds
  final double updateTime; // in milliseconds
  final DateTime timestamp;
  
  @override
  String toString() {
    return 'PerformanceMetrics(fps: ${frameRate.toStringAsFixed(1)}, '
           'frameTime: ${frameTime.toStringAsFixed(2)}ms, '
           'memory: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
           'cpu: ${cpuUsage.toStringAsFixed(1)}%)';
  }
}

/// Performance alert levels
enum PerformanceAlertLevel {
  normal,
  warning,
  critical,
}

/// Performance alert data
class PerformanceAlert {
  const PerformanceAlert({
    required this.level,
    required this.message,
    required this.metric,
    required this.value,
    required this.threshold,
    required this.timestamp,
  });
  
  final PerformanceAlertLevel level;
  final String message;
  final String metric;
  final double value;
  final double threshold;
  final DateTime timestamp;
}

/// Performance thresholds configuration
class PerformanceThresholds {
  const PerformanceThresholds({
    this.minFrameRate = 45.0,
    this.maxFrameTime = 20.0,
    this.maxMemoryUsage = 100 * 1024 * 1024, // 100MB
    this.maxCpuUsage = 80.0,
    this.maxRenderTime = 10.0,
    this.maxUpdateTime = 5.0,
  });
  
  final double minFrameRate;
  final double maxFrameTime;
  final int maxMemoryUsage;
  final double maxCpuUsage;
  final double maxRenderTime;
  final double maxUpdateTime;
}

/// Comprehensive performance monitoring system
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();
  
  // Configuration
  PerformanceThresholds _thresholds = const PerformanceThresholds();
  bool _isEnabled = false;
  Duration _sampleInterval = const Duration(milliseconds: 100);
  
  // Data storage
  final Queue<PerformanceMetrics> _metricsHistory = Queue<PerformanceMetrics>();
  final Queue<PerformanceAlert> _alertHistory = Queue<PerformanceAlert>();
  static const int maxHistoryLength = 600; // 1 minute at 100ms intervals
  static const int maxAlertHistory = 100;
  
  // Timing
  Timer? _sampleTimer;
  Stopwatch? _frameStopwatch;
  Stopwatch? _renderStopwatch;
  Stopwatch? _updateStopwatch;
  
  // Frame rate calculation
  final Queue<DateTime> _frameTimes = Queue<DateTime>();
  static const int frameTimeWindow = 60; // Calculate FPS over 60 frames
  
  // Memory tracking
  int _lastMemoryUsage = 0;
  
  // Callbacks
  void Function(PerformanceMetrics metrics)? onMetricsUpdated;
  void Function(PerformanceAlert alert)? onAlert;
  
  /// Initialize the performance monitor
  void initialize({
    PerformanceThresholds? thresholds,
    Duration? sampleInterval,
    void Function(PerformanceMetrics metrics)? onMetricsUpdated,
    void Function(PerformanceAlert alert)? onAlert,
  }) {
    _thresholds = thresholds ?? const PerformanceThresholds();
    _sampleInterval = sampleInterval ?? const Duration(milliseconds: 100);
    this.onMetricsUpdated = onMetricsUpdated;
    this.onAlert = onAlert;
    
    _frameStopwatch = Stopwatch();
    _renderStopwatch = Stopwatch();
    _updateStopwatch = Stopwatch();
  }
  
  /// Start performance monitoring
  void start() {
    if (_isEnabled) return;
    
    _isEnabled = true;
    _frameStopwatch?.start();
    
    // Start sampling timer
    _sampleTimer = Timer.periodic(_sampleInterval, (_) {
      _collectMetrics();
    });
  }
  
  /// Stop performance monitoring
  void stop() {
    if (!_isEnabled) return;
    
    _isEnabled = false;
    _sampleTimer?.cancel();
    _sampleTimer = null;
    
    _frameStopwatch?.stop();
    _renderStopwatch?.stop();
    _updateStopwatch?.stop();
  }
  
  /// Mark the start of a frame
  void startFrame() {
    if (!_isEnabled) return;
    
    _frameStopwatch?.reset();
    _frameStopwatch?.start();
    
    // Record frame time for FPS calculation
    final now = DateTime.now();
    _frameTimes.add(now);
    
    // Keep only recent frame times
    while (_frameTimes.length > frameTimeWindow) {
      _frameTimes.removeFirst();
    }
  }
  
  /// Mark the end of a frame
  void endFrame() {
    if (!_isEnabled) return;
    
    _frameStopwatch?.stop();
  }
  
  /// Mark the start of render phase
  void startRender() {
    if (!_isEnabled) return;
    
    _renderStopwatch?.reset();
    _renderStopwatch?.start();
  }
  
  /// Mark the end of render phase
  void endRender() {
    if (!_isEnabled) return;
    
    _renderStopwatch?.stop();
  }
  
  /// Mark the start of update phase
  void startUpdate() {
    if (!_isEnabled) return;
    
    _updateStopwatch?.reset();
    _updateStopwatch?.start();
  }
  
  /// Mark the end of update phase
  void endUpdate() {
    if (!_isEnabled) return;
    
    _updateStopwatch?.stop();
  }
  
  /// Collect current performance metrics
  void _collectMetrics() {
    if (!_isEnabled) return;
    
    final frameRate = _calculateFrameRate();
    final frameTime = (_frameStopwatch?.elapsedMicroseconds ?? 0).toDouble() / 1000.0;
    final memoryUsage = _getMemoryUsage();
    final cpuUsage = _getCpuUsage();
    final renderTime = (_renderStopwatch?.elapsedMicroseconds ?? 0).toDouble() / 1000.0;
    final updateTime = (_updateStopwatch?.elapsedMicroseconds ?? 0).toDouble() / 1000.0;
    
    final metrics = PerformanceMetrics(
      frameRate: frameRate,
      frameTime: frameTime,
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage,
      renderTime: renderTime,
      updateTime: updateTime,
      timestamp: DateTime.now(),
    );
    
    // Store metrics
    _metricsHistory.add(metrics);
    if (_metricsHistory.length > maxHistoryLength) {
      _metricsHistory.removeFirst();
    }
    
    // Check for performance issues
    _checkPerformanceThresholds(metrics);
    
    // Notify callback
    onMetricsUpdated?.call(metrics);
  }
  
  /// Calculate current frame rate
  double _calculateFrameRate() {
    if (_frameTimes.length < 2) return 0.0;
    
    final now = DateTime.now();
    final oldestFrame = _frameTimes.first;
    final timeDiff = now.difference(oldestFrame).inMicroseconds / 1000000.0;
    
    if (timeDiff <= 0) return 0.0;
    
    return (_frameTimes.length - 1) / timeDiff;
  }
  
  /// Get current memory usage
  int _getMemoryUsage() {
    try {
      // On mobile platforms, we can get memory info
      if (Platform.isAndroid || Platform.isIOS) {
        // This is a simplified approach - in a real implementation,
        // you would use platform-specific methods to get accurate memory usage
        return ProcessInfo.currentRss;
      }
      
      // Fallback for other platforms
      return _lastMemoryUsage;
    } catch (e) {
      // If we can't get memory info, return last known value
      return _lastMemoryUsage;
    }
  }
  
  /// Get current CPU usage (simplified)
  double _getCpuUsage() {
    // This is a placeholder - real CPU usage monitoring would require
    // platform-specific implementations or additional packages
    // For now, we estimate based on frame time
    final frameTime = (_frameStopwatch?.elapsedMicroseconds ?? 0).toDouble() / 1000.0;
    final targetFrameTime = 1000.0 / 60.0; // 60 FPS target
    
    return (frameTime / targetFrameTime * 100.0).clamp(0.0, 100.0);
  }
  
  /// Check performance metrics against thresholds
  void _checkPerformanceThresholds(PerformanceMetrics metrics) {
    // Check frame rate
    if (metrics.frameRate < _thresholds.minFrameRate) {
      _createAlert(
        level: metrics.frameRate < _thresholds.minFrameRate * 0.7 
            ? PerformanceAlertLevel.critical 
            : PerformanceAlertLevel.warning,
        message: 'Low frame rate detected',
        metric: 'frameRate',
        value: metrics.frameRate,
        threshold: _thresholds.minFrameRate,
      );
    }
    
    // Check frame time
    if (metrics.frameTime > _thresholds.maxFrameTime) {
      _createAlert(
        level: metrics.frameTime > _thresholds.maxFrameTime * 1.5 
            ? PerformanceAlertLevel.critical 
            : PerformanceAlertLevel.warning,
        message: 'High frame time detected',
        metric: 'frameTime',
        value: metrics.frameTime,
        threshold: _thresholds.maxFrameTime,
      );
    }
    
    // Check memory usage
    if (metrics.memoryUsage > _thresholds.maxMemoryUsage) {
      _createAlert(
        level: metrics.memoryUsage > _thresholds.maxMemoryUsage * 1.2 
            ? PerformanceAlertLevel.critical 
            : PerformanceAlertLevel.warning,
        message: 'High memory usage detected',
        metric: 'memoryUsage',
        value: metrics.memoryUsage.toDouble(),
        threshold: _thresholds.maxMemoryUsage.toDouble(),
      );
    }
    
    // Check CPU usage
    if (metrics.cpuUsage > _thresholds.maxCpuUsage) {
      _createAlert(
        level: metrics.cpuUsage > _thresholds.maxCpuUsage * 1.2 
            ? PerformanceAlertLevel.critical 
            : PerformanceAlertLevel.warning,
        message: 'High CPU usage detected',
        metric: 'cpuUsage',
        value: metrics.cpuUsage,
        threshold: _thresholds.maxCpuUsage,
      );
    }
  }
  
  /// Create a performance alert
  void _createAlert({
    required PerformanceAlertLevel level,
    required String message,
    required String metric,
    required double value,
    required double threshold,
  }) {
    final alert = PerformanceAlert(
      level: level,
      message: message,
      metric: metric,
      value: value,
      threshold: threshold,
      timestamp: DateTime.now(),
    );
    
    _alertHistory.add(alert);
    if (_alertHistory.length > maxAlertHistory) {
      _alertHistory.removeFirst();
    }
    
    // Notify callback
    onAlert?.call(alert);
    
    // Log in debug mode
    if (kDebugMode) {
      print('Performance Alert: $message (${metric}: ${value.toStringAsFixed(2)}, threshold: ${threshold.toStringAsFixed(2)})');
    }
  }
  
  /// Get current performance metrics
  PerformanceMetrics? get currentMetrics => _metricsHistory.isNotEmpty ? _metricsHistory.last : null;
  
  /// Get metrics history
  List<PerformanceMetrics> get metricsHistory => List.unmodifiable(_metricsHistory);
  
  /// Get alert history
  List<PerformanceAlert> get alertHistory => List.unmodifiable(_alertHistory);
  
  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    if (_metricsHistory.isEmpty) {
      return {'error': 'No metrics available'};
    }
    
    final metrics = _metricsHistory.toList();
    
    // Calculate averages
    final avgFrameRate = metrics.map((m) => m.frameRate).reduce((a, b) => a + b) / metrics.length;
    final avgFrameTime = metrics.map((m) => m.frameTime).reduce((a, b) => a + b) / metrics.length;
    final avgMemoryUsage = metrics.map((m) => m.memoryUsage).reduce((a, b) => a + b) / metrics.length;
    final avgCpuUsage = metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) / metrics.length;
    
    // Calculate min/max
    final minFrameRate = metrics.map((m) => m.frameRate).reduce((a, b) => a < b ? a : b);
    final maxFrameRate = metrics.map((m) => m.frameRate).reduce((a, b) => a > b ? a : b);
    final minFrameTime = metrics.map((m) => m.frameTime).reduce((a, b) => a < b ? a : b);
    final maxFrameTime = metrics.map((m) => m.frameTime).reduce((a, b) => a > b ? a : b);
    
    return {
      'current': currentMetrics?.toString() ?? 'No current metrics',
      'averages': {
        'frameRate': avgFrameRate,
        'frameTime': avgFrameTime,
        'memoryUsage': avgMemoryUsage,
        'cpuUsage': avgCpuUsage,
      },
      'ranges': {
        'frameRate': {'min': minFrameRate, 'max': maxFrameRate},
        'frameTime': {'min': minFrameTime, 'max': maxFrameTime},
      },
      'alerts': {
        'total': _alertHistory.length,
        'critical': _alertHistory.where((a) => a.level == PerformanceAlertLevel.critical).length,
        'warning': _alertHistory.where((a) => a.level == PerformanceAlertLevel.warning).length,
      },
      'sampleCount': metrics.length,
      'isEnabled': _isEnabled,
    };
  }
  
  /// Clear all metrics and alerts
  void clear() {
    _metricsHistory.clear();
    _alertHistory.clear();
    _frameTimes.clear();
  }
  
  /// Update thresholds
  void updateThresholds(PerformanceThresholds newThresholds) {
    _thresholds = newThresholds;
  }
  
  /// Check if performance is currently good
  bool get isPerformanceGood {
    final current = currentMetrics;
    if (current == null) return true;
    
    return current.frameRate >= _thresholds.minFrameRate &&
           current.frameTime <= _thresholds.maxFrameTime &&
           current.memoryUsage <= _thresholds.maxMemoryUsage &&
           current.cpuUsage <= _thresholds.maxCpuUsage;
  }
  
  /// Get performance grade (A-F)
  String get performanceGrade {
    final current = currentMetrics;
    if (current == null) return 'N/A';
    
    int score = 0;
    
    // Frame rate score (0-25 points)
    if (current.frameRate >= 60) score += 25;
    else if (current.frameRate >= 45) score += 20;
    else if (current.frameRate >= 30) score += 15;
    else if (current.frameRate >= 20) score += 10;
    else score += 5;
    
    // Frame time score (0-25 points)
    if (current.frameTime <= 16.67) score += 25; // 60 FPS
    else if (current.frameTime <= 22.22) score += 20; // 45 FPS
    else if (current.frameTime <= 33.33) score += 15; // 30 FPS
    else if (current.frameTime <= 50) score += 10; // 20 FPS
    else score += 5;
    
    // Memory score (0-25 points)
    final memoryMB = current.memoryUsage / 1024 / 1024;
    if (memoryMB <= 50) score += 25;
    else if (memoryMB <= 100) score += 20;
    else if (memoryMB <= 150) score += 15;
    else if (memoryMB <= 200) score += 10;
    else score += 5;
    
    // CPU score (0-25 points)
    if (current.cpuUsage <= 30) score += 25;
    else if (current.cpuUsage <= 50) score += 20;
    else if (current.cpuUsage <= 70) score += 15;
    else if (current.cpuUsage <= 85) score += 10;
    else score += 5;
    
    // Convert to letter grade
    if (score >= 90) return 'A';
    else if (score >= 80) return 'B';
    else if (score >= 70) return 'C';
    else if (score >= 60) return 'D';
    else return 'F';
  }
  
  /// Dispose of the performance monitor
  void dispose() {
    stop();
    clear();
    onMetricsUpdated = null;
    onAlert = null;
  }
  
  /// Get enabled status
  bool get isEnabled => _isEnabled;
  
  /// Get current thresholds
  PerformanceThresholds get thresholds => _thresholds;
}