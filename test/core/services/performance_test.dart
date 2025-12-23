import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/core/services/performance_monitor.dart';
import 'package:hard_hat/core/services/memory_profiler.dart';
import 'package:hard_hat/core/services/performance_optimizer.dart';

void main() {
  group('Performance Monitor Tests', () {
    test('should initialize and track metrics', () {
      final monitor = PerformanceMonitor();
      
      monitor.initialize();
      expect(monitor.isEnabled, isFalse);
      
      monitor.start();
      expect(monitor.isEnabled, isTrue);
      
      // Simulate frame timing
      monitor.startFrame();
      monitor.endFrame();
      
      monitor.stop();
      expect(monitor.isEnabled, isFalse);
      
      monitor.dispose();
    });
    
    test('should calculate performance grade', () {
      final monitor = PerformanceMonitor();
      
      monitor.initialize();
      monitor.start();
      
      // Simulate some frame timing
      monitor.startFrame();
      monitor.endFrame();
      
      // Should have a grade (even if no real metrics)
      final grade = monitor.performanceGrade;
      expect(grade, isA<String>());
      expect(['A', 'B', 'C', 'D', 'F', 'N/A'].contains(grade), isTrue);
      
      monitor.dispose();
    });
  });
  
  group('Memory Profiler Tests', () {
    test('should initialize and track memory', () {
      final profiler = MemoryProfiler();
      
      profiler.initialize();
      expect(profiler.isEnabled, isFalse);
      
      profiler.start();
      expect(profiler.isEnabled, isTrue);
      
      // Track some object creation
      profiler.trackObjectCreation('TestObject', size: 100);
      profiler.trackObjectCreation('TestObject', size: 200);
      
      // Track destruction
      profiler.trackObjectDestruction('TestObject');
      
      profiler.stop();
      expect(profiler.isEnabled, isFalse);
      
      profiler.dispose();
    });
    
    test('should calculate memory health score', () {
      final profiler = MemoryProfiler();
      
      profiler.initialize();
      profiler.start();
      
      // Should have a health score
      final score = profiler.memoryHealthScore;
      expect(score, isA<int>());
      expect(score >= 0 && score <= 100, isTrue);
      
      profiler.dispose();
    });
  });
  
  group('Performance Optimizer Tests', () {
    test('should initialize and manage optimization', () {
      final optimizer = PerformanceOptimizer();
      
      optimizer.initialize(
        autoOptimizationEnabled: false, // Disable auto for testing
      );
      
      expect(optimizer.isEnabled, isFalse);
      expect(optimizer.autoOptimizationEnabled, isFalse);
      
      optimizer.start();
      expect(optimizer.isEnabled, isTrue);
      
      // Get performance status
      final status = optimizer.getPerformanceStatus();
      expect(status, isA<Map<String, dynamic>>());
      expect(status.containsKey('performance'), isTrue);
      expect(status.containsKey('memory'), isTrue);
      
      optimizer.stop();
      expect(optimizer.isEnabled, isFalse);
      
      optimizer.dispose();
    });
    
    test('should enable and disable auto-optimization', () {
      final optimizer = PerformanceOptimizer();
      
      optimizer.initialize(autoOptimizationEnabled: false);
      optimizer.start();
      
      expect(optimizer.autoOptimizationEnabled, isFalse);
      
      optimizer.setAutoOptimization(true);
      expect(optimizer.autoOptimizationEnabled, isTrue);
      
      optimizer.setAutoOptimization(false);
      expect(optimizer.autoOptimizationEnabled, isFalse);
      
      optimizer.dispose();
    });
  });
}