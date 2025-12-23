import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:hard_hat/features/game/presentation/game/hard_hat_game.dart';
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';
import 'package:hard_hat/features/game/domain/entities/ball_entity.dart';
import 'package:hard_hat/features/game/domain/entities/tile.dart';
import 'package:hard_hat/core/di/injection_container.dart';
import 'package:flame/components.dart';

void main() {
  group('Performance Integration Tests', () {
    late HardHatGame game;
    
    setUpAll(() async {
      // Initialize dependency injection
      await initializeDependencies();
    });
    
    setUp(() async {
      game = HardHatGame();
      await game.onLoad();
    });
    
    tearDown(() {
      game.onRemove();
    });

    test('should maintain 60 FPS target with multiple entities', () async {
      const targetFPS = 60;
      const frameDuration = 1.0 / targetFPS; // 16.67ms per frame
      const testDuration = 2.0; // Test for 2 seconds
      const maxFrameTime = frameDuration * 1.5; // Allow 50% variance
      
      // Create multiple entities to stress test
      final entities = <Component>[];
      
      // Add 20 tiles
      for (int i = 0; i < 20; i++) {
        final tile = TileEntity(
          id: 'perf_tile_$i',
          type: TileType.scaffolding,
          position: Vector2(i * 32.0, 200),
        );
        await tile.initializeEntity();
        game.entityManager.registerEntity(tile);
        entities.add(tile);
      }
      
      // Add 5 balls
      for (int i = 0; i < 5; i++) {
        final ball = BallEntity(
          id: 'perf_ball_$i',
          position: Vector2(100 + i * 50.0, 100),
        );
        await ball.initializeEntity();
        game.entityManager.registerEntity(ball);
        entities.add(ball);
      }
      
      // Add 3 players
      for (int i = 0; i < 3; i++) {
        final player = PlayerEntity(
          id: 'perf_player_$i',
          position: Vector2(200 + i * 100.0, 300),
        );
        await player.initializeEntity();
        game.entityManager.registerEntity(player);
        entities.add(player);
      }
      
      // Performance tracking
      final frameTimes = <double>[];
      double totalTime = 0.0;
      int frameCount = 0;
      
      // Run performance test
      while (totalTime < testDuration) {
        final frameStart = DateTime.now().millisecondsSinceEpoch;
        
        // Update game systems
        game.update(frameDuration);
        
        final frameEnd = DateTime.now().millisecondsSinceEpoch;
        final frameTime = (frameEnd - frameStart) / 1000.0; // Convert to seconds
        
        frameTimes.add(frameTime);
        totalTime += frameDuration;
        frameCount++;
      }
      
      // Analyze performance
      final averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final maxFrameTimeRecorded = frameTimes.reduce((a, b) => a > b ? a : b);
      final framesOverTarget = frameTimes.where((time) => time > maxFrameTime).length;
      final performanceRatio = framesOverTarget / frameTimes.length;
      
      print('Performance Test Results:');
      print('  Total frames: $frameCount');
      print('  Average frame time: ${(averageFrameTime * 1000).toStringAsFixed(2)}ms');
      print('  Max frame time: ${(maxFrameTimeRecorded * 1000).toStringAsFixed(2)}ms');
      print('  Frames over target: $framesOverTarget (${(performanceRatio * 100).toStringAsFixed(1)}%)');
      print('  Target frame time: ${(maxFrameTime * 1000).toStringAsFixed(2)}ms');
      
      // Performance assertions
      expect(averageFrameTime, lessThan(maxFrameTime), 
        reason: 'Average frame time should be under target');
      expect(performanceRatio, lessThan(0.2), 
        reason: 'Less than 20% of frames should exceed target time');
      
      // Clean up entities
      for (final entity in entities) {
        if (entity is TileEntity) {
          game.entityManager.unregisterEntity(entity.id);
        } else if (entity is BallEntity) {
          game.entityManager.unregisterEntity(entity.id);
        } else if (entity is PlayerEntity) {
          game.entityManager.unregisterEntity(entity.id);
        }
      }
    });

    test('should optimize rendering performance with sprite batching', () async {
      // Test sprite batching performance
      final renderSystem = game.renderSystem;
      expect(renderSystem, isNotNull);
      
      // Create many similar sprites to test batching
      final sprites = <TileEntity>[];
      for (int i = 0; i < 50; i++) {
        final tile = TileEntity(
          id: 'batch_tile_$i',
          type: TileType.scaffolding,
          position: Vector2(i % 10 * 32.0, (i ~/ 10) * 32.0),
        );
        await tile.initializeEntity();
        game.entityManager.registerEntity(tile);
        sprites.add(tile);
      }
      
      // Measure rendering performance
      final renderStart = DateTime.now().millisecondsSinceEpoch;
      
      // Update render system multiple times
      for (int i = 0; i < 60; i++) {
        renderSystem.updateSystem(1.0 / 60.0);
      }
      
      final renderEnd = DateTime.now().millisecondsSinceEpoch;
      final renderTime = renderEnd - renderStart;
      
      print('Render Performance Test:');
      print('  50 sprites, 60 render updates');
      print('  Total render time: ${renderTime}ms');
      print('  Average per update: ${(renderTime / 60).toStringAsFixed(2)}ms');
      
      // Should complete rendering quickly with batching
      expect(renderTime, lessThan(2000), 
        reason: 'Rendering should complete within 2 seconds with batching');
      
      // Clean up
      for (final sprite in sprites) {
        game.entityManager.unregisterEntity(sprite.id);
      }
    });

    test('should optimize physics performance with collision detection', () async {
      final collisionSystem = game.collisionSystem;
      final movementSystem = game.movementSystem;
      expect(collisionSystem, isNotNull);
      expect(movementSystem, isNotNull);
      
      // Create entities for collision testing
      final entities = <Component>[];
      
      // Add tiles in a grid
      for (int x = 0; x < 10; x++) {
        for (int y = 0; y < 10; y++) {
          final tile = TileEntity(
            id: 'collision_tile_${x}_$y',
            type: TileType.scaffolding,
            position: Vector2(x * 32.0, y * 32.0),
          );
          await tile.initializeEntity();
          game.entityManager.registerEntity(tile);
          entities.add(tile);
        }
      }
      
      // Add moving balls
      for (int i = 0; i < 10; i++) {
        final ball = BallEntity(
          id: 'collision_ball_$i',
          position: Vector2(i * 30.0, 50),
        );
        await ball.initializeEntity();
        ball.velocityComponent.velocity = Vector2(100, 200); // Moving
        game.entityManager.registerEntity(ball);
        entities.add(ball);
      }
      
      // Measure physics performance
      final physicsStart = DateTime.now().millisecondsSinceEpoch;
      
      // Update physics systems multiple times
      for (int i = 0; i < 60; i++) {
        movementSystem.updateSystem(1.0 / 60.0);
        collisionSystem.updateSystem(1.0 / 60.0);
      }
      
      final physicsEnd = DateTime.now().millisecondsSinceEpoch;
      final physicsTime = physicsEnd - physicsStart;
      
      print('Physics Performance Test:');
      print('  110 entities (100 tiles + 10 balls)');
      print('  60 physics updates');
      print('  Total physics time: ${physicsTime}ms');
      print('  Average per update: ${(physicsTime / 60).toStringAsFixed(2)}ms');
      
      // Should complete physics quickly
      expect(physicsTime, lessThan(3000), 
        reason: 'Physics should complete within 3 seconds');
      
      // Clean up
      for (final entity in entities) {
        if (entity is TileEntity) {
          game.entityManager.unregisterEntity(entity.id);
        } else if (entity is BallEntity) {
          game.entityManager.unregisterEntity(entity.id);
        }
      }
    });

    test('should optimize particle system performance', () async {
      final particleSystem = game.particleSystem;
      expect(particleSystem, isNotNull);
      
      // Measure particle system performance
      final particleStart = DateTime.now().millisecondsSinceEpoch;
      
      // Update particle system many times
      for (int i = 0; i < 100; i++) {
        particleSystem.updateSystem(1.0 / 60.0);
      }
      
      final particleEnd = DateTime.now().millisecondsSinceEpoch;
      final particleTime = particleEnd - particleStart;
      
      print('Particle Performance Test:');
      print('  100 particle system updates');
      print('  Total particle time: ${particleTime}ms');
      
      // Should handle particle updates efficiently
      expect(particleTime, lessThan(1000), 
        reason: 'Particle system should update within 1 second');
    });

    test('should optimize audio system performance', () async {
      final audioSystem = game.audioSystem;
      expect(audioSystem, isNotNull);
      
      // Test audio system performance
      final audioStart = DateTime.now().millisecondsSinceEpoch;
      
      // Update audio system many times
      for (int i = 0; i < 100; i++) {
        audioSystem.updateSystem(1.0 / 60.0);
      }
      
      final audioEnd = DateTime.now().millisecondsSinceEpoch;
      final audioTime = audioEnd - audioStart;
      
      print('Audio Performance Test:');
      print('  100 audio system updates');
      print('  Total audio time: ${audioTime}ms');
      
      // Should handle audio updates efficiently
      expect(audioTime, lessThan(1000), 
        reason: 'Audio system should update within 1 second');
    });

    test('should maintain consistent performance under moderate load', () async {
      // Moderate stress test
      const stressTestDuration = 2.0;
      const frameDuration = 1.0 / 60.0;
      
      // Create moderate load scenario
      final entities = <Component>[];
      
      // Add tiles (simulating a level)
      for (int i = 0; i < 50; i++) {
        final tile = TileEntity(
          id: 'stress_tile_$i',
          type: TileType.scaffolding,
          position: Vector2((i % 10) * 32.0, (i ~/ 10) * 32.0),
        );
        await tile.initializeEntity();
        game.entityManager.registerEntity(tile);
        entities.add(tile);
      }
      
      // Add moving balls
      for (int i = 0; i < 10; i++) {
        final ball = BallEntity(
          id: 'stress_ball_$i',
          position: Vector2(i * 20.0, 100),
        );
        await ball.initializeEntity();
        ball.velocityComponent.velocity = Vector2(
          (i % 2 == 0 ? 100 : -100), 
          200 + (i * 10)
        );
        game.entityManager.registerEntity(ball);
        entities.add(ball);
      }
      
      // Run stress test
      double totalTime = 0.0;
      final frameTimes = <double>[];
      
      while (totalTime < stressTestDuration) {
        final frameStart = DateTime.now().millisecondsSinceEpoch;
        
        // Update game
        game.update(frameDuration);
        
        final frameEnd = DateTime.now().millisecondsSinceEpoch;
        final frameTime = (frameEnd - frameStart) / 1000.0;
        frameTimes.add(frameTime);
        
        totalTime += frameDuration;
      }
      
      // Analyze stress test results
      final averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
      final targetFrameTime = 1.0 / 60.0 * 2.0; // Allow 100% variance under stress
      final framesOverTarget = frameTimes.where((time) => time > targetFrameTime).length;
      final performanceRatio = framesOverTarget / frameTimes.length;
      
      print('Stress Test Results:');
      print('  Entities: ${entities.length + 1} (50 tiles + 10 balls + 1 player)');
      print('  Duration: ${stressTestDuration}s');
      print('  Total frames: ${frameTimes.length}');
      print('  Average frame time: ${(averageFrameTime * 1000).toStringAsFixed(2)}ms');
      print('  Max frame time: ${(maxFrameTime * 1000).toStringAsFixed(2)}ms');
      print('  Frames over target: $framesOverTarget (${(performanceRatio * 100).toStringAsFixed(1)}%)');
      
      // Performance assertions for stress test (more lenient)
      expect(averageFrameTime, lessThan(targetFrameTime), 
        reason: 'Average frame time should be reasonable under stress');
      expect(performanceRatio, lessThan(0.3), 
        reason: 'Less than 30% of frames should exceed target under stress');
      
      // Clean up
      for (final entity in entities) {
        if (entity is TileEntity) {
          game.entityManager.unregisterEntity(entity.id);
        } else if (entity is BallEntity) {
          game.entityManager.unregisterEntity(entity.id);
        }
      }
    });

    test('should verify 60 FPS target is achievable', () async {
      // Simple 60 FPS verification test
      const targetFPS = 60;
      const frameDuration = 1.0 / targetFPS;
      const testFrames = 120; // 2 seconds worth
      
      final frameTimes = <double>[];
      
      for (int i = 0; i < testFrames; i++) {
        final frameStart = DateTime.now().millisecondsSinceEpoch;
        
        // Update game
        game.update(frameDuration);
        
        final frameEnd = DateTime.now().millisecondsSinceEpoch;
        final frameTime = (frameEnd - frameStart) / 1000.0;
        frameTimes.add(frameTime);
      }
      
      final averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
      final targetFrameTime = frameDuration;
      
      print('60 FPS Target Verification:');
      print('  Target frame time: ${(targetFrameTime * 1000).toStringAsFixed(2)}ms');
      print('  Average frame time: ${(averageFrameTime * 1000).toStringAsFixed(2)}ms');
      print('  Max frame time: ${(maxFrameTime * 1000).toStringAsFixed(2)}ms');
      print('  Performance ratio: ${(averageFrameTime / targetFrameTime * 100).toStringAsFixed(1)}%');
      
      // Verify 60 FPS is achievable
      expect(averageFrameTime, lessThan(targetFrameTime * 1.2), 
        reason: '60 FPS target should be achievable with 20% margin');
    });
  });
}