import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Memory allocation tracking data
class MemoryAllocation {
  const MemoryAllocation({
    required this.objectType,
    required this.size,
    required this.timestamp,
    required this.stackTrace,
  });
  
  final String objectType;
  final int size;
  final DateTime timestamp;
  final String stackTrace;
}

/// Memory usage snapshot
class MemorySnapshot {
  const MemorySnapshot({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
    required this.objectCounts,
    required this.timestamp,
  });
  
  final int totalMemory;
  final int usedMemory;
  final int freeMemory;
  final Map<String, int> objectCounts;
  final DateTime timestamp;
  
  double get memoryUtilization => usedMemory / totalMemory;
  
  @override
  String toString() {
    return 'MemorySnapshot(used: ${(usedMemory / 1024 / 1024).toStringAsFixed(1)}MB, '
           'free: ${(freeMemory / 1024 / 1024).toStringAsFixed(1)}MB, '
           'utilization: ${(memoryUtilization * 100).toStringAsFixed(1)}%)';
  }
}

/// Memory leak detection result
class MemoryLeakInfo {
  const MemoryLeakInfo({
    required this.objectType,
    required this.instanceCount,
    required this.totalSize,
    required this.growthRate,
    required this.severity,
  });
  
  final String objectType;
  final int instanceCount;
  final int totalSize;
  final double growthRate; // instances per second
  final MemoryLeakSeverity severity;
}

/// Memory leak severity levels
enum MemoryLeakSeverity {
  low,
  medium,
  high,
  critical,
}

/// Memory profiler for tracking memory usage and detecting leaks
class MemoryProfiler {
  static final MemoryProfiler _instance = MemoryProfiler._internal();
  factory MemoryProfiler() => _instance;
  MemoryProfiler._internal();
  
  // Configuration
  bool _isEnabled = false;
  Duration _snapshotInterval = const Duration(seconds: 5);
  int _maxSnapshots = 100;
  int _leakDetectionThreshold = 10; // minimum instances to consider for leak detection
  
  // Data storage
  final Queue<MemorySnapshot> _snapshots = Queue<MemorySnapshot>();
  final Queue<MemoryAllocation> _allocations = Queue<MemoryAllocation>();
  final Map<String, List<DateTime>> _objectCreationTimes = {};
  
  // Timers
  Timer? _snapshotTimer;
  Timer? _leakDetectionTimer;
  
  // Callbacks
  void Function(MemorySnapshot snapshot)? onSnapshotTaken;
  void Function(List<MemoryLeakInfo> leaks)? onLeaksDetected;
  
  /// Initialize the memory profiler
  void initialize({
    Duration? snapshotInterval,
    int? maxSnapshots,
    int? leakDetectionThreshold,
    void Function(MemorySnapshot snapshot)? onSnapshotTaken,
    void Function(List<MemoryLeakInfo> leaks)? onLeaksDetected,
  }) {
    _snapshotInterval = snapshotInterval ?? const Duration(seconds: 5);
    _maxSnapshots = maxSnapshots ?? 100;
    _leakDetectionThreshold = leakDetectionThreshold ?? 10;
    this.onSnapshotTaken = onSnapshotTaken;
    this.onLeaksDetected = onLeaksDetected;
  }
  
  /// Start memory profiling
  void start() {
    if (_isEnabled) return;
    
    _isEnabled = true;
    
    // Take initial snapshot
    _takeSnapshot();
    
    // Start periodic snapshots
    _snapshotTimer = Timer.periodic(_snapshotInterval, (_) {
      _takeSnapshot();
    });
    
    // Start leak detection (less frequent)
    _leakDetectionTimer = Timer.periodic(
      Duration(seconds: _snapshotInterval.inSeconds * 3),
      (_) => _detectMemoryLeaks(),
    );
  }
  
  /// Stop memory profiling
  void stop() {
    if (!_isEnabled) return;
    
    _isEnabled = false;
    _snapshotTimer?.cancel();
    _leakDetectionTimer?.cancel();
    _snapshotTimer = null;
    _leakDetectionTimer = null;
  }
  
  /// Take a memory snapshot
  void _takeSnapshot() {
    if (!_isEnabled) return;
    
    try {
      final totalMemory = _getTotalMemory();
      final usedMemory = _getUsedMemory();
      final freeMemory = totalMemory - usedMemory;
      final objectCounts = _getObjectCounts();
      
      final snapshot = MemorySnapshot(
        totalMemory: totalMemory,
        usedMemory: usedMemory,
        freeMemory: freeMemory,
        objectCounts: objectCounts,
        timestamp: DateTime.now(),
      );
      
      _snapshots.add(snapshot);
      
      // Limit snapshot history
      while (_snapshots.length > _maxSnapshots) {
        _snapshots.removeFirst();
      }
      
      onSnapshotTaken?.call(snapshot);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error taking memory snapshot: $e');
      }
    }
  }
  
  /// Get total system memory (simplified)
  int _getTotalMemory() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, we can estimate based on device capabilities
        // This is a simplified approach - real implementation would use platform channels
        return 2 * 1024 * 1024 * 1024; // Assume 2GB for now
      }
      return 4 * 1024 * 1024 * 1024; // Assume 4GB for desktop
    } catch (e) {
      return 2 * 1024 * 1024 * 1024; // Fallback
    }
  }
  
  /// Get current memory usage
  int _getUsedMemory() {
    try {
      return ProcessInfo.currentRss;
    } catch (e) {
      // Fallback estimation
      return 50 * 1024 * 1024; // 50MB fallback
    }
  }
  
  /// Get object counts (simplified tracking)
  Map<String, int> _getObjectCounts() {
    final counts = <String, int>{};
    
    // Count tracked object types
    for (final entry in _objectCreationTimes.entries) {
      counts[entry.key] = entry.value.length;
    }
    
    return counts;
  }
  
  /// Track object creation
  void trackObjectCreation(String objectType, {int size = 0}) {
    if (!_isEnabled) return;
    
    final now = DateTime.now();
    
    // Track creation time
    _objectCreationTimes.putIfAbsent(objectType, () => <DateTime>[]);
    _objectCreationTimes[objectType]!.add(now);
    
    // Track allocation
    if (size > 0) {
      final allocation = MemoryAllocation(
        objectType: objectType,
        size: size,
        timestamp: now,
        stackTrace: _getCurrentStackTrace(),
      );
      
      _allocations.add(allocation);
      
      // Limit allocation history
      while (_allocations.length > 1000) {
        _allocations.removeFirst();
      }
    }
    
    // Clean up old creation times (keep only last hour)
    final cutoff = now.subtract(const Duration(hours: 1));
    _objectCreationTimes[objectType]!.removeWhere((time) => time.isBefore(cutoff));
  }
  
  /// Track object destruction
  void trackObjectDestruction(String objectType) {
    if (!_isEnabled) return;
    
    final creationTimes = _objectCreationTimes[objectType];
    if (creationTimes != null && creationTimes.isNotEmpty) {
      creationTimes.removeAt(0); // Remove oldest creation
    }
  }
  
  /// Get current stack trace (simplified)
  String _getCurrentStackTrace() {
    try {
      return StackTrace.current.toString().split('\n').take(5).join('\n');
    } catch (e) {
      return 'Stack trace unavailable';
    }
  }
  
  /// Detect potential memory leaks
  void _detectMemoryLeaks() {
    if (!_isEnabled || _snapshots.length < 3) return;
    
    final leaks = <MemoryLeakInfo>[];
    
    for (final entry in _objectCreationTimes.entries) {
      final objectType = entry.key;
      final creationTimes = entry.value;
      
      if (creationTimes.length < _leakDetectionThreshold) continue;
      
      // Calculate growth rate over the last few snapshots
      final now = DateTime.now();
      final recentCreations = creationTimes.where(
        (time) => now.difference(time).inMinutes < 5,
      ).length;
      
      final growthRate = recentCreations / 300.0; // per second over 5 minutes
      
      // Determine severity
      MemoryLeakSeverity severity;
      if (growthRate > 1.0) {
        severity = MemoryLeakSeverity.critical;
      } else if (growthRate > 0.5) {
        severity = MemoryLeakSeverity.high;
      } else if (growthRate > 0.1) {
        severity = MemoryLeakSeverity.medium;
      } else {
        severity = MemoryLeakSeverity.low;
      }
      
      // Only report significant leaks
      if (severity != MemoryLeakSeverity.low) {
        final totalSize = _allocations
            .where((alloc) => alloc.objectType == objectType)
            .fold(0, (sum, alloc) => sum + alloc.size);
        
        leaks.add(MemoryLeakInfo(
          objectType: objectType,
          instanceCount: creationTimes.length,
          totalSize: totalSize,
          growthRate: growthRate,
          severity: severity,
        ));
      }
    }
    
    if (leaks.isNotEmpty) {
      onLeaksDetected?.call(leaks);
      
      if (kDebugMode) {
        print('Memory leaks detected: ${leaks.length}');
        for (final leak in leaks) {
          print('  ${leak.objectType}: ${leak.instanceCount} instances, '
                '${leak.growthRate.toStringAsFixed(2)}/s growth, '
                'severity: ${leak.severity}');
        }
      }
    }
  }
  
  /// Force garbage collection (if possible)
  void forceGarbageCollection() {
    // Note: Dart doesn't provide direct GC control
    // This is a placeholder for potential future implementation
    if (kDebugMode) {
      print('Garbage collection requested (not directly controllable in Dart)');
    }
  }
  
  /// Get current memory usage
  MemorySnapshot? get currentSnapshot => _snapshots.isNotEmpty ? _snapshots.last : null;
  
  /// Get memory usage history
  List<MemorySnapshot> get snapshotHistory => List.unmodifiable(_snapshots);
  
  /// Get allocation history
  List<MemoryAllocation> get allocationHistory => List.unmodifiable(_allocations);
  
  /// Get memory statistics
  Map<String, dynamic> getStatistics() {
    if (_snapshots.isEmpty) {
      return {'error': 'No snapshots available'};
    }
    
    final snapshots = _snapshots.toList();
    final current = snapshots.last;
    
    // Calculate memory usage trend
    double memoryTrend = 0.0;
    if (snapshots.length >= 2) {
      final first = snapshots.first;
      final timeDiff = current.timestamp.difference(first.timestamp).inSeconds;
      if (timeDiff > 0) {
        memoryTrend = (current.usedMemory - first.usedMemory) / timeDiff.toDouble();
      }
    }
    
    // Calculate average memory usage
    final avgMemoryUsage = snapshots
        .map((s) => s.usedMemory)
        .reduce((a, b) => a + b) / snapshots.length;
    
    // Get peak memory usage
    final peakMemoryUsage = snapshots
        .map((s) => s.usedMemory)
        .reduce((a, b) => a > b ? a : b);
    
    return {
      'current': current.toString(),
      'trend': '${(memoryTrend / 1024).toStringAsFixed(1)} KB/s',
      'average': '${(avgMemoryUsage / 1024 / 1024).toStringAsFixed(1)} MB',
      'peak': '${(peakMemoryUsage / 1024 / 1024).toStringAsFixed(1)} MB',
      'objectCounts': current.objectCounts,
      'totalAllocations': _allocations.length,
      'snapshotCount': snapshots.length,
      'isEnabled': _isEnabled,
    };
  }
  
  /// Clear all profiling data
  void clear() {
    _snapshots.clear();
    _allocations.clear();
    _objectCreationTimes.clear();
  }
  
  /// Get memory health score (0-100)
  int get memoryHealthScore {
    final current = currentSnapshot;
    if (current == null) return 100;
    
    int score = 100;
    
    // Penalize high memory utilization
    final utilization = current.memoryUtilization;
    if (utilization > 0.9) score -= 30;
    else if (utilization > 0.8) score -= 20;
    else if (utilization > 0.7) score -= 10;
    
    // Penalize memory growth trend
    if (_snapshots.length >= 2) {
      final first = _snapshots.first;
      final growth = (current.usedMemory - first.usedMemory) / first.usedMemory.toDouble();
      if (growth > 0.5) score -= 25; // 50% growth
      else if (growth > 0.3) score -= 15; // 30% growth
      else if (growth > 0.1) score -= 5;  // 10% growth
    }
    
    // Penalize potential memory leaks
    final leakCount = _objectCreationTimes.values
        .where((times) => times.length > _leakDetectionThreshold)
        .length;
    score -= leakCount * 10;
    
    return score.clamp(0, 100);
  }
  
  /// Dispose of the memory profiler
  void dispose() {
    stop();
    clear();
    onSnapshotTaken = null;
    onLeaksDetected = null;
  }
  
  /// Get enabled status
  bool get isEnabled => _isEnabled;
}