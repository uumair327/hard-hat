import 'package:flutter/foundation.dart';
import 'performance_monitor.dart';
import 'performance_optimizer.dart';
import 'pool_manager.dart';

/// Performance optimization report generator
class PerformanceOptimizationReport {
  static final PerformanceOptimizationReport _instance = PerformanceOptimizationReport._internal();
  factory PerformanceOptimizationReport() => _instance;
  PerformanceOptimizationReport._internal();
  
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();
  final GamePoolManager _poolManager = GamePoolManager();
  
  /// Generate comprehensive performance report
  Map<String, dynamic> generateReport() {
    final performanceStats = _performanceMonitor.getStatistics();
    final optimizationStatus = _performanceOptimizer.getPerformanceStatus();
    final poolStats = _poolManager.getAllStats();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance': {
        'current_metrics': _performanceMonitor.currentMetrics?.toString() ?? 'No metrics available',
        'performance_grade': _performanceMonitor.performanceGrade,
        'is_performance_good': _performanceMonitor.isPerformanceGood,
        'statistics': performanceStats,
      },
      'optimization': {
        'status': optimizationStatus,
        'history': _performanceOptimizer.optimizationHistory.length,
        'auto_optimization_enabled': _performanceOptimizer.autoOptimizationEnabled,
      },
      'object_pools': {
        'stats': poolStats,
        'total_pools': poolStats.length,
        'efficiency': _calculatePoolEfficiency(poolStats),
      },
      'recommendations': _generateRecommendations(),
    };
  }
  
  /// Calculate overall pool efficiency
  double _calculatePoolEfficiency(Map<String, dynamic> poolStats) {
    if (poolStats.isEmpty) return 0.0;
    
    double totalHitRate = 0.0;
    int poolCount = 0;
    
    for (final stats in poolStats.values) {
      // Skip non-pool stats like 'performance'
      if (stats is Map<String, dynamic>) {
        // This is a nested stats object, skip it
        continue;
      }
      
      // Try to parse hit rate from string representation
      if (stats is String && stats.contains('hitRate:')) {
        try {
          final hitRateMatch = RegExp(r'hitRate: ([\d.]+)%').firstMatch(stats);
          if (hitRateMatch != null) {
            final hitRatePercent = double.parse(hitRateMatch.group(1)!);
            totalHitRate += hitRatePercent / 100.0; // Convert percentage to decimal
            poolCount++;
          }
        } catch (e) {
          // Skip if parsing fails
          continue;
        }
      }
    }
    
    return poolCount > 0 ? totalHitRate / poolCount : 0.0;
  }
  
  /// Generate performance recommendations
  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    final currentMetrics = _performanceMonitor.currentMetrics;
    
    if (currentMetrics == null) {
      recommendations.add('Enable performance monitoring to get detailed recommendations');
      return recommendations;
    }
    
    // Frame rate recommendations
    if (currentMetrics.frameRate < 45.0) {
      recommendations.add('Frame rate is below 45 FPS. Consider reducing visual effects or enabling performance optimizations.');
    } else if (currentMetrics.frameRate < 55.0) {
      recommendations.add('Frame rate is below optimal. Monitor for performance degradation.');
    }
    
    // Memory recommendations
    final memoryMB = currentMetrics.memoryUsage / 1024 / 1024;
    if (memoryMB > 150) {
      recommendations.add('Memory usage is high (${memoryMB.toStringAsFixed(1)}MB). Consider clearing caches or reducing object pool sizes.');
    } else if (memoryMB > 100) {
      recommendations.add('Memory usage is moderate (${memoryMB.toStringAsFixed(1)}MB). Monitor for memory leaks.');
    }
    
    // CPU recommendations
    if (currentMetrics.cpuUsage > 80.0) {
      recommendations.add('CPU usage is high (${currentMetrics.cpuUsage.toStringAsFixed(1)}%). Consider reducing collision checks or particle counts.');
    }
    
    // Pool efficiency recommendations
    final poolStats = _poolManager.getAllStats();
    for (final entry in poolStats.entries) {
      final poolName = entry.key;
      final stats = entry.value;
      
      // Skip performance stats
      if (poolName == 'performance' || stats is Map<String, dynamic>) {
        continue;
      }
      
      // Try to parse stats from string representation
      if (stats is String) {
        try {
          final hitRateMatch = RegExp(r'hitRate: ([\d.]+)%').firstMatch(stats);
          final activeMatch = RegExp(r'active: (\d+)').firstMatch(stats);
          final maxSizeMatch = RegExp(r'maxSize: (\d+)').firstMatch(stats);
          
          if (hitRateMatch != null) {
            final hitRatePercent = double.parse(hitRateMatch.group(1)!);
            final hitRate = hitRatePercent / 100.0;
            
            if (hitRate < 0.7) {
              recommendations.add('$poolName pool has low hit rate (${hitRatePercent.toStringAsFixed(1)}%). Consider increasing pool size.');
            }
          }
          
          if (activeMatch != null && maxSizeMatch != null) {
            final active = int.parse(activeMatch.group(1)!);
            final maxSize = int.parse(maxSizeMatch.group(1)!);
            
            if (active > maxSize * 0.9) {
              recommendations.add('$poolName pool is nearly full. Consider increasing max size or reducing usage.');
            }
          }
        } catch (e) {
          // Skip if parsing fails
          continue;
        }
      }
    }
    
    // Auto-optimization recommendations
    if (!_performanceOptimizer.autoOptimizationEnabled) {
      recommendations.add('Auto-optimization is disabled. Enable it for automatic performance adjustments.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is optimal. No immediate optimizations needed.');
    }
    
    return recommendations;
  }
  
  /// Generate detailed performance analysis
  Map<String, dynamic> generateDetailedAnalysis() {
    final report = generateReport();
    final currentMetrics = _performanceMonitor.currentMetrics;
    
    return {
      ...report,
      'detailed_analysis': {
        'frame_time_analysis': _analyzeFrameTime(currentMetrics),
        'memory_analysis': _analyzeMemoryUsage(currentMetrics),
        'pool_analysis': _analyzePoolPerformance(),
        'optimization_history': _analyzeOptimizationHistory(),
      },
    };
  }
  
  /// Analyze frame time performance
  Map<String, dynamic> _analyzeFrameTime(PerformanceMetrics? metrics) {
    if (metrics == null) {
      return {'status': 'No metrics available'};
    }
    
    final targetFrameTime = 1000.0 / 60.0; // 16.67ms for 60 FPS
    final frameTimeRatio = metrics.frameTime / targetFrameTime;
    
    String status;
    String recommendation;
    
    if (frameTimeRatio <= 1.0) {
      status = 'Excellent';
      recommendation = 'Frame time is optimal for 60 FPS';
    } else if (frameTimeRatio <= 1.33) {
      status = 'Good';
      recommendation = 'Frame time is acceptable for 45+ FPS';
    } else if (frameTimeRatio <= 2.0) {
      status = 'Fair';
      recommendation = 'Frame time may cause stuttering. Consider optimizations.';
    } else {
      status = 'Poor';
      recommendation = 'Frame time is too high. Immediate optimization needed.';
    }
    
    return {
      'current_frame_time': '${metrics.frameTime.toStringAsFixed(2)}ms',
      'target_frame_time': '${targetFrameTime.toStringAsFixed(2)}ms',
      'ratio': frameTimeRatio.toStringAsFixed(2),
      'status': status,
      'recommendation': recommendation,
    };
  }
  
  /// Analyze memory usage patterns
  Map<String, dynamic> _analyzeMemoryUsage(PerformanceMetrics? metrics) {
    if (metrics == null) {
      return {'status': 'No metrics available'};
    }
    
    final memoryMB = metrics.memoryUsage / 1024 / 1024;
    
    String status;
    String recommendation;
    
    if (memoryMB <= 50) {
      status = 'Excellent';
      recommendation = 'Memory usage is very low and efficient';
    } else if (memoryMB <= 100) {
      status = 'Good';
      recommendation = 'Memory usage is within acceptable range';
    } else if (memoryMB <= 150) {
      status = 'Fair';
      recommendation = 'Memory usage is moderate. Monitor for increases.';
    } else {
      status = 'Poor';
      recommendation = 'Memory usage is high. Consider optimization.';
    }
    
    return {
      'current_memory': '${memoryMB.toStringAsFixed(1)}MB',
      'status': status,
      'recommendation': recommendation,
    };
  }
  
  /// Analyze object pool performance
  Map<String, dynamic> _analyzePoolPerformance() {
    final poolStats = _poolManager.getAllStats();
    final analysis = <String, dynamic>{};
    
    for (final entry in poolStats.entries) {
      final poolName = entry.key;
      final stats = entry.value;
      
      // Skip performance stats
      if (poolName == 'performance' || stats is Map<String, dynamic>) {
        continue;
      }
      
      String efficiency = 'Unknown';
      String recommendation = 'Unable to analyze pool stats';
      String utilization = 'Unknown';
      
      // Try to parse stats from string representation
      if (stats is String) {
        try {
          final hitRateMatch = RegExp(r'hitRate: ([\d.]+)%').firstMatch(stats);
          final availableMatch = RegExp(r'available: (\d+)').firstMatch(stats);
          final activeMatch = RegExp(r'active: (\d+)').firstMatch(stats);
          final maxSizeMatch = RegExp(r'maxSize: (\d+)').firstMatch(stats);
          
          if (hitRateMatch != null) {
            final hitRatePercent = double.parse(hitRateMatch.group(1)!);
            final hitRate = hitRatePercent / 100.0;
            
            if (hitRate >= 0.9) {
              efficiency = 'Excellent';
              recommendation = 'Pool is highly efficient';
            } else if (hitRate >= 0.7) {
              efficiency = 'Good';
              recommendation = 'Pool efficiency is acceptable';
            } else if (hitRate >= 0.5) {
              efficiency = 'Fair';
              recommendation = 'Consider increasing pool size';
            } else {
              efficiency = 'Poor';
              recommendation = 'Pool needs optimization or size increase';
            }
          }
          
          if (activeMatch != null && maxSizeMatch != null) {
            final active = int.parse(activeMatch.group(1)!);
            final maxSize = int.parse(maxSizeMatch.group(1)!);
            utilization = '${((active / maxSize) * 100).toStringAsFixed(1)}%';
          }
        } catch (e) {
          // Keep default values if parsing fails
        }
      }
      
      analysis[poolName] = {
        'stats': stats.toString(),
        'efficiency': efficiency,
        'recommendation': recommendation,
        'utilization': utilization,
      };
    }
    
    return analysis;
  }
  
  /// Analyze optimization history
  Map<String, dynamic> _analyzeOptimizationHistory() {
    final history = _performanceOptimizer.optimizationHistory;
    
    if (history.isEmpty) {
      return {
        'status': 'No optimizations applied',
        'recommendation': 'Monitor performance and apply optimizations as needed',
      };
    }
    
    final successfulOptimizations = history.where((r) => r.success).length;
    final totalImprovements = history
        .where((r) => r.success)
        .map((r) => r.performanceImprovement)
        .fold(0.0, (sum, improvement) => sum + improvement);
    
    return {
      'total_optimizations': history.length,
      'successful_optimizations': successfulOptimizations,
      'success_rate': '${((successfulOptimizations / history.length) * 100).toStringAsFixed(1)}%',
      'total_performance_improvement': '${totalImprovements.toStringAsFixed(1)}%',
      'recent_optimizations': history.take(5).map((r) => {
        'strategy': r.strategy.toString(),
        'success': r.success,
        'improvement': '${r.performanceImprovement.toStringAsFixed(1)}%',
        'timestamp': r.timestamp.toIso8601String(),
      }).toList(),
    };
  }
  
  /// Export report to string format
  String exportReportAsString() {
    final report = generateDetailedAnalysis();
    final buffer = StringBuffer();
    
    buffer.writeln('=== PERFORMANCE OPTIMIZATION REPORT ===');
    buffer.writeln('Generated: ${report['timestamp']}');
    buffer.writeln();
    
    // Performance section
    final performance = report['performance'] as Map<String, dynamic>;
    buffer.writeln('PERFORMANCE METRICS:');
    buffer.writeln('  Current: ${performance['current_metrics']}');
    buffer.writeln('  Grade: ${performance['performance_grade']}');
    buffer.writeln('  Status: ${performance['is_performance_good'] ? 'Good' : 'Needs Attention'}');
    buffer.writeln();
    
    // Recommendations section
    final recommendations = report['recommendations'] as List<String>;
    buffer.writeln('RECOMMENDATIONS:');
    for (int i = 0; i < recommendations.length; i++) {
      buffer.writeln('  ${i + 1}. ${recommendations[i]}');
    }
    buffer.writeln();
    
    // Object pools section
    final pools = report['object_pools'] as Map<String, dynamic>;
    buffer.writeln('OBJECT POOLS:');
    buffer.writeln('  Total Pools: ${pools['total_pools']}');
    buffer.writeln('  Average Efficiency: ${(pools['efficiency'] * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    
    return buffer.toString();
  }
}