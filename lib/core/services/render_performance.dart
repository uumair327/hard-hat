import 'dart:collection';

/// Performance monitoring for the render system
class RenderPerformanceMonitor {
  RenderPerformanceMonitor({
    this.maxSamples = 60,
  });

  final int maxSamples;
  final Queue<double> _frameTimes = Queue<double>();
  final Queue<int> _drawCalls = Queue<int>();
  final Queue<int> _spriteCount = Queue<int>();
  
  DateTime? _lastFrameTime;
  int _currentDrawCalls = 0;
  int _currentSpriteCount = 0;

  /// Start frame timing
  void startFrame() {
    _lastFrameTime = DateTime.now();
    _currentDrawCalls = 0;
    _currentSpriteCount = 0;
  }

  /// End frame timing and record metrics
  void endFrame() {
    if (_lastFrameTime != null) {
      final frameTime = DateTime.now().difference(_lastFrameTime!).inMicroseconds / 1000.0;
      
      _frameTimes.add(frameTime);
      _drawCalls.add(_currentDrawCalls);
      _spriteCount.add(_currentSpriteCount);
      
      // Keep only the last N samples
      while (_frameTimes.length > maxSamples) {
        _frameTimes.removeFirst();
        _drawCalls.removeFirst();
        _spriteCount.removeFirst();
      }
    }
  }

  /// Record a draw call
  void recordDrawCall() {
    _currentDrawCalls++;
  }

  /// Record sprites rendered
  void recordSprites(int count) {
    _currentSpriteCount += count;
  }

  /// Get average frame time in milliseconds
  double get averageFrameTime {
    if (_frameTimes.isEmpty) return 0.0;
    return _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
  }

  /// Get average FPS
  double get averageFPS {
    final avgFrameTime = averageFrameTime;
    return avgFrameTime > 0 ? 1000.0 / avgFrameTime : 0.0;
  }

  /// Get minimum FPS (worst frame)
  double get minFPS {
    if (_frameTimes.isEmpty) return 0.0;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    return maxFrameTime > 0 ? 1000.0 / maxFrameTime : 0.0;
  }

  /// Get maximum FPS (best frame)
  double get maxFPS {
    if (_frameTimes.isEmpty) return 0.0;
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);
    return minFrameTime > 0 ? 1000.0 / minFrameTime : 0.0;
  }

  /// Get average draw calls per frame
  double get averageDrawCalls {
    if (_drawCalls.isEmpty) return 0.0;
    return _drawCalls.reduce((a, b) => a + b) / _drawCalls.length;
  }

  /// Get average sprites per frame
  double get averageSpriteCount {
    if (_spriteCount.isEmpty) return 0.0;
    return _spriteCount.reduce((a, b) => a + b) / _spriteCount.length;
  }

  /// Get current frame time
  double get currentFrameTime {
    return _frameTimes.isNotEmpty ? _frameTimes.last : 0.0;
  }

  /// Get current FPS
  double get currentFPS {
    final frameTime = currentFrameTime;
    return frameTime > 0 ? 1000.0 / frameTime : 0.0;
  }

  /// Check if performance is good (above target FPS)
  bool isPerformanceGood({double targetFPS = 60.0}) {
    return averageFPS >= targetFPS * 0.9; // Allow 10% tolerance
  }

  /// Get performance grade
  String get performanceGrade {
    final fps = averageFPS;
    if (fps >= 55) return 'A';
    if (fps >= 45) return 'B';
    if (fps >= 30) return 'C';
    if (fps >= 20) return 'D';
    return 'F';
  }

  /// Get detailed performance statistics
  Map<String, dynamic> getDetailedStats() {
    return {
      'averageFrameTime': averageFrameTime,
      'averageFPS': averageFPS,
      'minFPS': minFPS,
      'maxFPS': maxFPS,
      'currentFPS': currentFPS,
      'averageDrawCalls': averageDrawCalls,
      'averageSpriteCount': averageSpriteCount,
      'performanceGrade': performanceGrade,
      'sampleCount': _frameTimes.length,
      'isPerformanceGood': isPerformanceGood(),
    };
  }

  /// Reset all statistics
  void reset() {
    _frameTimes.clear();
    _drawCalls.clear();
    _spriteCount.clear();
    _lastFrameTime = null;
    _currentDrawCalls = 0;
    _currentSpriteCount = 0;
  }

  /// Get frame time percentiles
  Map<String, double> getFrameTimePercentiles() {
    if (_frameTimes.isEmpty) {
      return {'p50': 0.0, 'p90': 0.0, 'p95': 0.0, 'p99': 0.0};
    }

    final sortedTimes = _frameTimes.toList()..sort();
    final length = sortedTimes.length;

    return {
      'p50': sortedTimes[(length * 0.5).floor()],
      'p90': sortedTimes[(length * 0.9).floor()],
      'p95': sortedTimes[(length * 0.95).floor()],
      'p99': sortedTimes[(length * 0.99).floor()],
    };
  }

  /// Check if there are performance issues
  List<String> getPerformanceIssues({
    double targetFPS = 60.0,
    int maxDrawCalls = 100,
    int maxSprites = 1000,
  }) {
    final issues = <String>[];

    if (averageFPS < targetFPS * 0.8) {
      issues.add('Low FPS: ${averageFPS.toStringAsFixed(1)} (target: $targetFPS)');
    }

    if (averageDrawCalls > maxDrawCalls) {
      issues.add('High draw calls: ${averageDrawCalls.toStringAsFixed(1)} (max: $maxDrawCalls)');
    }

    if (averageSpriteCount > maxSprites) {
      issues.add('High sprite count: ${averageSpriteCount.toStringAsFixed(1)} (max: $maxSprites)');
    }

    final percentiles = getFrameTimePercentiles();
    if (percentiles['p95']! > 1000.0 / targetFPS * 2) {
      issues.add('Frame time spikes detected (p95: ${percentiles['p95']!.toStringAsFixed(1)}ms)');
    }

    return issues;
  }
}