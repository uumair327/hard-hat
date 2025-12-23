import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:hard_hat/core/services/object_pool.dart';
import 'package:hard_hat/core/services/ball_pool.dart';
import 'package:hard_hat/core/services/audio_player_pool.dart';
import 'package:hard_hat/core/services/pool_manager.dart';

// Test object for generic pool testing
class TestObject {
  String value = '';
  bool isReset = false;
  
  void reset() {
    value = '';
    isReset = true;
  }
}

void main() {
  group('ObjectPool Tests', () {
    test('should create and manage objects correctly', () {
      final pool = GenericObjectPool<TestObject>(
        factory: () => TestObject(),
        reset: (obj) => obj.reset(),
        initialSize: 3,
        maxSize: 10,
      );
      
      // Should have initial objects available
      expect(pool.stats.available, equals(3));
      expect(pool.stats.active, equals(0));
      
      // Acquire objects
      final obj1 = pool.acquire();
      final obj2 = pool.acquire();
      
      expect(pool.stats.available, equals(1));
      expect(pool.stats.active, equals(2));
      
      // Release objects
      pool.release(obj1);
      pool.release(obj2);
      
      expect(pool.stats.available, equals(3));
      expect(pool.stats.active, equals(0));
      
      pool.dispose();
    });
    
    test('should expand pool when needed', () {
      final pool = GenericObjectPool<TestObject>(
        factory: () => TestObject(),
        reset: (obj) => obj.reset(),
        initialSize: 2,
        maxSize: 5,
        autoExpand: true,
      );
      
      // Acquire more objects than initial size
      final objects = <TestObject>[];
      for (int i = 0; i < 4; i++) {
        objects.add(pool.acquire());
      }
      
      expect(pool.stats.active, equals(4));
      expect(pool.stats.total, equals(4));
      
      // Release all objects
      pool.releaseAll(objects);
      
      expect(pool.stats.available, equals(4));
      expect(pool.stats.active, equals(0));
      
      pool.dispose();
    });
    
    test('should track hit and miss rates', () {
      final pool = GenericObjectPool<TestObject>(
        factory: () => TestObject(),
        reset: (obj) => obj.reset(),
        initialSize: 2,
        maxSize: 5,
      );
      
      // First acquisitions should be hits (reusing pre-allocated objects)
      final obj1 = pool.acquire();
      final obj2 = pool.acquire();
      
      expect(pool.stats.hitRate, equals(1.0)); // 2 hits, 0 misses
      
      // Third acquisition should be a miss (creating new object)
      final obj3 = pool.acquire();
      
      expect(pool.stats.hitRate, closeTo(0.67, 0.01)); // 2 hits, 1 miss
      expect(pool.stats.missRate, closeTo(0.33, 0.01));
      
      pool.releaseAll([obj1, obj2, obj3]);
      pool.dispose();
    });
  });
  
  group('BallPool Tests', () {
    test('should create and manage ball entities', () {
      final ballPool = BallPool(
        initialSize: 2,
        maxSize: 5,
      );
      
      expect(ballPool.stats.available, equals(2));
      expect(ballPool.activeBallCount, equals(0));
      
      // Launch a ball
      final ball = ballPool.launchBall(
        position: Vector2(100, 100),
        direction: Vector2(1, 0),
        speed: 200,
      );
      
      expect(ballPool.activeBallCount, equals(1));
      expect(ball.isActive, isTrue);
      
      // Recycle the ball
      ballPool.release(ball);
      
      expect(ballPool.activeBallCount, equals(0));
      expect(ballPool.stats.available, equals(2));
      
      ballPool.dispose();
    });
    
    test('should update active balls', () {
      final ballPool = BallPool(
        initialSize: 1,
        maxSize: 3,
      );
      
      final ball = ballPool.launchBall(
        position: Vector2.zero(),
        direction: Vector2(1, 0),
      );
      
      expect(ballPool.activeBallCount, equals(1));
      
      // Update balls (simulate game loop)
      ballPool.updateActiveBalls(0.016); // 60 FPS
      
      // Ball should still be active
      expect(ballPool.activeBallCount, equals(1));
      
      // Force recycle
      ball.forceRecycle();
      ballPool.updateActiveBalls(0.016);
      
      // Ball should be recycled
      expect(ballPool.activeBallCount, equals(0));
      
      ballPool.dispose();
    });
  });
  
  group('AudioPlayerPool Tests', () {
    test('should create and manage audio players', () {
      final audioPool = AudioPlayerPool(
        initialSize: 3,
        maxSize: 10,
      );
      
      expect(audioPool.stats.available, equals(3));
      expect(audioPool.activePlayerCount, equals(0));
      
      // Acquire an audio player
      final player = audioPool.acquire();
      
      expect(audioPool.activePlayerCount, equals(1));
      
      // Release the player
      audioPool.release(player);
      
      expect(audioPool.activePlayerCount, equals(0));
      expect(audioPool.stats.available, equals(3));
      
      audioPool.dispose();
    });
  });
  
  group('GamePoolManager Tests', () {
    test('should initialize all pools', () {
      final poolManager = GamePoolManager();
      
      poolManager.initialize(
        config: const PoolConfiguration(
          ballPoolSize: 5,
          particlePoolSize: 100,
          audioPlayerPoolSize: 10,
        ),
      );
      
      expect(poolManager.isInitialized, isTrue);
      
      // Test ball pool access
      expect(poolManager.ballPool.isInitialized, isTrue);
      
      // Test audio pool access
      expect(poolManager.audioPool.isInitialized, isTrue);
      
      // Get statistics
      final stats = poolManager.getAllStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('balls'), isTrue);
      expect(stats.containsKey('audio'), isTrue);
      
      poolManager.dispose();
    });
    
    test('should update all pools', () {
      final poolManager = GamePoolManager();
      
      poolManager.initialize();
      
      // Update should not throw
      expect(() => poolManager.update(0.016), returnsNormally);
      
      poolManager.dispose();
    });
    
    test('should clear all pools', () {
      final poolManager = GamePoolManager();
      
      poolManager.initialize();
      
      // Clear should not throw
      expect(() => poolManager.clearAll(), returnsNormally);
      
      poolManager.dispose();
    });
  });
  
  group('PoolManager Tests', () {
    test('should register and retrieve pools', () {
      final poolManager = PoolManager();
      
      final testPool = GenericObjectPool<TestObject>(
        factory: () => TestObject(),
        reset: (obj) => obj.reset(),
        initialSize: 2,
        maxSize: 5,
      );
      
      poolManager.registerPool('test', testPool);
      
      final retrievedPool = poolManager.getPool<TestObject>('test');
      expect(retrievedPool, equals(testPool));
      
      // Test statistics
      final stats = poolManager.getAllStats();
      expect(stats.containsKey('test'), isTrue);
      
      poolManager.disposeAll();
    });
  });
}