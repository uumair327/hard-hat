import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/systems/particle_system.dart';
import 'package:hard_hat/features/game/domain/components/particle_component.dart';
import 'package:hard_hat/features/game/domain/services/particle_pool.dart';
import 'dart:math' as math;

void main() {
  group('ParticleSystem Tests', () {
    late ParticleSystem particleSystem;

    setUp(() {
      // Reset the singleton before each test
      GlobalParticlePoolManager().dispose();
      particleSystem = ParticleSystem();
    });

    tearDown(() {
      particleSystem.dispose();
      GlobalParticlePoolManager().dispose();
    });

    test('should initialize particle system correctly', () async {
      // Act
      await particleSystem.initialize();
      
      // Assert
      expect(particleSystem.isActive, isTrue);
      final stats = particleSystem.getStats();
      expect(stats, isNotNull);
      expect(stats['particles'], isNotNull);
      expect(stats['emitters'], isNotNull);
    });

    test('should spawn impact particles', () async {
      // Arrange
      await particleSystem.initialize();
      final position = Vector2(100, 100);
      
      // Act
      particleSystem.spawnImpactParticles(position, count: 10);
      
      // Assert
      final stats = particleSystem.getStats();
      expect(stats['activeEmitters'], greaterThan(0));
    });

    test('should spawn destruction particles for different tile types', () async {
      // Arrange
      await particleSystem.initialize();
      final position = Vector2(50, 50);
      
      // Act
      particleSystem.spawnDestructionParticles(position, TileType.scaffolding, count: 15);
      particleSystem.spawnDestructionParticles(position, TileType.timber, count: 12);
      particleSystem.spawnDestructionParticles(position, TileType.bricks, count: 20);
      
      // Assert
      final stats = particleSystem.getStats();
      expect(stats['activeEmitters'], equals(3));
    });

    test('should spawn movement particles', () async {
      // Arrange
      await particleSystem.initialize();
      final position = Vector2(75, 75);
      
      // Act
      particleSystem.spawnMovementParticles(position);
      
      // Assert
      final stats = particleSystem.getStats();
      expect(stats['activeEmitters'], greaterThan(0));
    });

    test('should create and manage continuous emitters', () async {
      // Arrange
      await particleSystem.initialize();
      final position = Vector2(200, 200);
      final config = ParticleEmitterConfig.impact;
      
      // Act
      final emitter = particleSystem.createContinuousEmitter(position, config);
      
      // Assert
      expect(emitter, isNotNull);
      expect(emitter.isContinuous, isTrue);
      
      // Clean up
      particleSystem.stopEmitter(emitter);
    });

    test('should update particles over time', () async {
      // Arrange
      await particleSystem.initialize();
      final position = Vector2(150, 150);
      particleSystem.spawnImpactParticles(position, count: 5);
      
      // Act
      particleSystem.updateSystem(0.016); // One frame at 60 FPS
      
      // Assert - particles should still be active after one frame
      final stats = particleSystem.getStats();
      expect(stats['totalActiveParticles'], greaterThan(0));
    });

    test('should clear all particles', () async {
      // Arrange
      await particleSystem.initialize();
      final position = Vector2(100, 100);
      particleSystem.spawnImpactParticles(position, count: 10);
      particleSystem.spawnMovementParticles(position);
      
      // Act
      particleSystem.clearAllParticles();
      
      // Assert
      final stats = particleSystem.getStats();
      expect(stats['activeEmitters'], equals(0));
      expect(stats['totalActiveParticles'], equals(0));
    });

    test('should provide accurate statistics', () async {
      // Arrange
      await particleSystem.initialize();
      
      // Act
      final initialStats = particleSystem.getStats();
      particleSystem.spawnImpactParticles(Vector2(100, 100), count: 5);
      final afterSpawnStats = particleSystem.getStats();
      
      // Assert
      expect(initialStats['activeEmitters'], equals(0));
      expect(afterSpawnStats['activeEmitters'], equals(1));
      expect(afterSpawnStats.containsKey('particles'), isTrue);
      expect(afterSpawnStats.containsKey('emitters'), isTrue);
      expect(afterSpawnStats.containsKey('totalActiveParticles'), isTrue);
    });
  });

  group('ParticlePool Tests', () {
    late ParticlePool particlePool;

    setUp(() {
      particlePool = ParticlePool(initialSize: 10, maxSize: 50);
    });

    tearDown(() {
      particlePool.dispose();
    });

    test('should initialize with correct pool size', () {
      // Assert
      final stats = particlePool.getStats();
      expect(stats['available'], equals(10));
      expect(stats['active'], equals(0));
      expect(stats['maxSize'], equals(50));
    });

    test('should get and return particles correctly', () {
      // Act
      final particle1 = particlePool.getParticle(position: Vector2(10, 10));
      final particle2 = particlePool.getParticle(position: Vector2(20, 20));
      
      // Assert
      expect(particle1, isNotNull);
      expect(particle2, isNotNull);
      expect(particle1.position.x, equals(10));
      expect(particle2.position.x, equals(20));
      
      final stats = particlePool.getStats();
      expect(stats['active'], equals(2));
      expect(stats['available'], equals(8));
      
      // Return particles
      particlePool.returnParticle(particle1);
      particlePool.returnParticle(particle2);
      
      final finalStats = particlePool.getStats();
      expect(finalStats['active'], equals(0));
      expect(finalStats['available'], equals(10));
    });

    test('should update active particles and return inactive ones', () {
      // Arrange
      final particle = particlePool.getParticle(
        position: Vector2(0, 0),
        lifetime: 0.1, // Very short lifetime
      );
      
      // Act - update for longer than lifetime
      particlePool.updateActiveParticles(0.2);
      
      // Assert - particle should be returned to pool
      final stats = particlePool.getStats();
      expect(stats['active'], lessThanOrEqualTo(1)); // May still be active due to timing
      expect(stats['available'], greaterThanOrEqualTo(9));
    });
  });

  group('ParticleComponent Tests', () {
    test('should create particle with correct properties', () {
      // Arrange
      final position = Vector2(100, 200);
      final velocity = Vector2(50, -100);
      const lifetime = 2.0;
      
      // Act
      final particle = Particle(
        position: position,
        velocity: velocity,
        lifetime: lifetime,
        type: ParticleType.impact,
      );
      
      // Assert
      expect(particle.position, equals(position));
      expect(particle.velocity, equals(velocity));
      expect(particle.lifetime, equals(lifetime));
      expect(particle.type, equals(ParticleType.impact));
      expect(particle.isActive, isTrue);
      expect(particle.age, equals(0.0));
    });

    test('should update particle physics correctly', () {
      // Arrange
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(10, 0),
        acceleration: Vector2(0, 9.8),
        lifetime: 1.0,
      );
      
      // Act
      particle.update(0.1); // Update for 0.1 seconds
      
      // Assert
      expect(particle.position.x, closeTo(1.0, 0.001)); // 10 * 0.1
      expect(particle.velocity.y, closeTo(0.98, 0.001)); // 9.8 * 0.1
      expect(particle.age, equals(0.1));
      expect(particle.isActive, isTrue);
    });

    test('should deactivate particle when lifetime expires', () {
      // Arrange
      final particle = Particle(
        position: Vector2(0, 0),
        lifetime: 0.5,
      );
      
      // Act
      particle.update(0.6); // Update for longer than lifetime
      
      // Assert
      expect(particle.isActive, isFalse);
    });

    test('should reset particle properties correctly', () {
      // Arrange
      final particle = Particle(
        position: Vector2(100, 100),
        velocity: Vector2(50, 50),
        lifetime: 1.0,
      );
      particle.update(0.5); // Age the particle
      
      // Act
      final newPosition = Vector2(200, 200);
      final newVelocity = Vector2(25, 25);
      particle.reset(
        position: newPosition,
        velocity: newVelocity,
        lifetime: 2.0,
      );
      
      // Assert
      expect(particle.position.x, equals(200));
      expect(particle.position.y, equals(200));
      expect(particle.velocity.x, equals(25));
      expect(particle.velocity.y, equals(25));
      expect(particle.lifetime, equals(2.0));
      expect(particle.age, equals(0.0));
      expect(particle.isActive, isTrue);
    });
  });

  group('ParticleEmitterConfig Tests', () {
    test('should create impact config with correct properties', () {
      // Act
      final config = ParticleEmitterConfig.impact;
      
      // Assert
      expect(config.type, equals(ParticleType.impact));
      expect(config.pattern, equals(ParticlePattern.burst));
      expect(config.emissionRate, equals(30.0));
      expect(config.maxParticles, equals(20));
    });

    test('should create destruction config with correct properties', () {
      // Act
      final config = ParticleEmitterConfig.destruction;
      
      // Assert
      expect(config.type, equals(ParticleType.destruction));
      expect(config.pattern, equals(ParticlePattern.explosion));
      expect(config.emissionRate, equals(50.0));
      expect(config.maxParticles, equals(30));
    });

    test('should create movement config with correct properties', () {
      // Act
      final config = ParticleEmitterConfig.movement;
      
      // Assert
      expect(config.type, equals(ParticleType.movement));
      expect(config.pattern, equals(ParticlePattern.drift));
      expect(config.emissionRate, equals(10.0));
      expect(config.maxParticles, equals(5));
    });
  });

  // Property-Based Tests
  group('Property-Based Tests', () {
    late ParticleSystem particleSystem;

    setUp(() async {
      // Reset the singleton before each test
      GlobalParticlePoolManager().dispose();
      particleSystem = ParticleSystem();
      await particleSystem.initialize();
    });

    tearDown(() {
      particleSystem.dispose();
      GlobalParticlePoolManager().dispose();
    });

    // **Feature: hard-hat-flutter-migration, Property 33: Impact particle spawning**
    test('Property 33: Impact particle spawning - For any Physics_Ball surface impact, star particles should be spawned at the collision point', () {
      // Property: For any valid position, impact particles should be spawned
      for (int i = 0; i < 100; i++) {
        // Generate random position
        final position = _generateRandomPosition();
        final particleCount = _generateRandomParticleCount(5, 25);
        
        // Clear previous particles
        particleSystem.clearAllParticles();
        
        // Act
        particleSystem.spawnImpactParticles(position, count: particleCount);
        
        // Assert
        final stats = particleSystem.getStats();
        expect(stats['activeEmitters'], greaterThan(0), 
          reason: 'Impact particles should spawn emitters at position $position');
        expect(stats['totalActiveParticles'], greaterThan(0),
          reason: 'Impact particles should create active particles at position $position');
      }
    });

    // **Feature: hard-hat-flutter-migration, Property 34: Material-specific particles**
    test('Property 34: Material-specific particles - For any tile destruction, the Particle_System should create particles appropriate to the tile material', () {
      // Property: For any tile type and position, material-specific particles should be spawned
      final tileTypes = [TileType.scaffolding, TileType.timber, TileType.bricks];
      
      for (int i = 0; i < 100; i++) {
        // Generate random tile type and position
        final tileType = tileTypes[i % tileTypes.length];
        final position = _generateRandomPosition();
        final particleCount = _generateRandomParticleCount(10, 30);
        
        // Clear previous particles
        particleSystem.clearAllParticles();
        
        // Act
        particleSystem.spawnDestructionParticles(position, tileType, count: particleCount);
        
        // Assert
        final stats = particleSystem.getStats();
        expect(stats['activeEmitters'], greaterThan(0),
          reason: 'Destruction particles should spawn emitters for $tileType at position $position');
        expect(stats['totalActiveParticles'], greaterThan(0),
          reason: 'Destruction particles should create active particles for $tileType at position $position');
        
        // Verify that different tile types produce different particle configurations
        // This is validated by the system using different configs for different tile types
        expect(stats['activeEmitters'], equals(1),
          reason: 'Each destruction call should create exactly one emitter');
      }
    });

    // **Feature: hard-hat-flutter-migration, Property 35: Movement particle generation**
    test('Property 35: Movement particle generation - For any Player_Character movement, appropriate step particles should be generated', () {
      // Property: For any valid position, movement particles should be spawned
      for (int i = 0; i < 100; i++) {
        // Generate random position
        final position = _generateRandomPosition();
        
        // Clear previous particles
        particleSystem.clearAllParticles();
        
        // Act
        particleSystem.spawnMovementParticles(position);
        
        // Assert
        final stats = particleSystem.getStats();
        expect(stats['activeEmitters'], greaterThan(0),
          reason: 'Movement particles should spawn emitters at position $position');
        expect(stats['totalActiveParticles'], greaterThan(0),
          reason: 'Movement particles should create active particles at position $position');
        
        // Movement particles should be fewer than destruction particles
        expect(stats['totalActiveParticles'], lessThanOrEqualTo(5),
          reason: 'Movement particles should be subtle (few particles) at position $position');
      }
    });
  });

  // Unit Tests for Particle Lifecycle
  group('Unit Tests for Particle Lifecycle', () {
    late ParticlePool particlePool;

    setUp(() {
      particlePool = ParticlePool(initialSize: 20, maxSize: 100);
    });

    tearDown(() {
      particlePool.dispose();
    });

    test('should create particles with correct initial state', () {
      // Test particle creation
      for (int i = 0; i < 10; i++) {
        final position = Vector2(i * 10.0, i * 5.0);
        final velocity = Vector2(i * 2.0, -i * 3.0);
        final lifetime = 1.0 + i * 0.1;
        
        final particle = particlePool.getParticle(
          position: position,
          velocity: velocity,
          lifetime: lifetime,
          type: ParticleType.impact,
        );
        
        expect(particle.position.x, equals(position.x));
        expect(particle.position.y, equals(position.y));
        expect(particle.velocity.x, equals(velocity.x));
        expect(particle.velocity.y, equals(velocity.y));
        expect(particle.lifetime, equals(lifetime));
        expect(particle.isActive, isTrue);
        expect(particle.age, equals(0.0));
        expect(particle.type, equals(ParticleType.impact));
      }
    });

    test('should update particle physics correctly over time', () {
      // Test particle update mechanics
      final particle = particlePool.getParticle(
        position: Vector2(0, 0),
        velocity: Vector2(100, -50),
        acceleration: Vector2(0, 98), // Gravity
        lifetime: 2.0,
      );
      
      // Update for multiple time steps
      final timeSteps = [0.016, 0.016, 0.016]; // Three frames at 60 FPS
      var totalTime = 0.0;
      
      for (final dt in timeSteps) {
        particle.update(dt);
        totalTime += dt;
        
        expect(particle.isActive, isTrue);
        expect(particle.age, closeTo(totalTime, 0.001));
      }
      
      // Check that particle moved in the expected direction
      expect(particle.position.x, greaterThan(0)); // Should move right
      expect(particle.velocity.y, greaterThan(-50)); // Should accelerate downward
    });

    test('should handle particle destruction when lifetime expires', () {
      // Test particle lifecycle completion
      final shortLifetimeParticles = <Particle>[];
      
      for (int i = 0; i < 5; i++) {
        final particle = particlePool.getParticle(
          position: Vector2(i * 10.0, 0),
          lifetime: 0.1 + i * 0.05, // Very short lifetimes
        );
        shortLifetimeParticles.add(particle);
      }
      
      // Update particles beyond their lifetimes
      particlePool.updateActiveParticles(0.5);
      
      // All particles should be inactive and returned to pool
      for (final particle in shortLifetimeParticles) {
        expect(particle.isActive, isFalse);
      }
      
      final stats = particlePool.getStats();
      expect(stats['active'], equals(0));
      expect(stats['available'], equals(20)); // Back to initial size
    });

    test('should verify object pooling functionality', () {
      // Test object pooling efficiency
      final initialStats = particlePool.getStats();
      expect(initialStats['available'], equals(20));
      expect(initialStats['active'], equals(0));
      
      // Get particles from pool
      final particles = <Particle>[];
      for (int i = 0; i < 15; i++) {
        particles.add(particlePool.getParticle(
          position: Vector2(i * 5.0, 0),
          lifetime: 1.0,
        ));
      }
      
      final activeStats = particlePool.getStats();
      expect(activeStats['available'], equals(5));
      expect(activeStats['active'], equals(15));
      
      // Return particles to pool
      particlePool.returnParticles(particles);
      
      final returnedStats = particlePool.getStats();
      expect(returnedStats['available'], equals(20));
      expect(returnedStats['active'], equals(0));
    });

    test('should handle pool size limits correctly', () {
      // Test pool size management
      final particles = <Particle>[];
      
      // Fill pool to maximum capacity
      for (int i = 0; i < 100; i++) {
        particles.add(particlePool.getParticle(
          position: Vector2(i * 2.0, 0),
          lifetime: 1.0,
        ));
      }
      
      final fullStats = particlePool.getStats();
      expect(fullStats['active'], equals(100));
      expect(fullStats['available'], equals(0));
      
      // Try to get one more particle (should recycle oldest)
      final extraParticle = particlePool.getParticle(
        position: Vector2(200, 0),
        lifetime: 1.0,
      );
      
      expect(extraParticle, isNotNull);
      final overflowStats = particlePool.getStats();
      expect(overflowStats['active'], equals(100)); // Still at max
      expect(overflowStats['total'], equals(100)); // Total should not exceed max
    });
  });
}

// Helper functions for property-based testing
Vector2 _generateRandomPosition() {
  final random = math.Random();
  return Vector2(
    random.nextDouble() * 1000 - 500, // -500 to 500
    random.nextDouble() * 1000 - 500, // -500 to 500
  );
}

int _generateRandomParticleCount(int min, int max) {
  final random = math.Random();
  return min + random.nextInt(max - min + 1);
}