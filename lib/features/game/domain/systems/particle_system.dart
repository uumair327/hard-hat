import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/particle_component.dart';
import '../services/particle_pool.dart';
import '../../presentation/game/hard_hat_game.dart';
import 'game_system.dart';

/// System responsible for managing all particle effects in the game
/// Handles particle spawning, lifecycle management, and rendering with object pooling
class ParticleSystem extends GameSystem {
  /// Global particle pool manager for performance optimization
  late final GlobalParticlePoolManager _poolManager;
  
  /// List of active particle emitters
  final List<ParticleComponent> _activeEmitters = [];
  
  /// Render layers for different particle types
  static const Map<ParticleType, int> _renderLayers = {
    ParticleType.movement: 1,     // Behind everything
    ParticleType.dust: 2,         // Low priority
    ParticleType.destruction: 3,  // Medium priority
    ParticleType.impact: 4,       // High priority
    ParticleType.explosion: 5,    // Highest priority
    ParticleType.spark: 6,        // Top layer
  };
  
  @override
  int get priority => 100; // Execute after physics but before rendering
  
  @override
  Future<void> initialize() async {
    super.initialize();
    
    // Initialize global particle pool manager
    _poolManager = GlobalParticlePoolManager();
    _poolManager.initialize(
      particlePoolSize: 1000,  // Large pool for performance
      emitterPoolSize: 100,
    );
  }
  
  @override
  void updateSystem(double dt) {
    // Update global pools (handles particle lifecycle and emitter management)
    _poolManager.update(dt);
    
    // Update active emitters
    _updateActiveEmitters(dt);
    
    // Clean up finished emitters
    _cleanupFinishedEmitters();
  }
  
  @override
  void renderSystem(Canvas canvas) {
    // Render particles by layer for proper depth sorting
    _renderParticlesByLayer(canvas);
  }
  
  /// Update all active emitters
  void _updateActiveEmitters(double dt) {
    for (final emitter in _activeEmitters) {
      emitter.updateParticles(dt);
    }
  }
  
  /// Remove finished emitters and return them to pool
  void _cleanupFinishedEmitters() {
    final finishedEmitters = _activeEmitters.where((e) => e.isFinished).toList();
    
    for (final emitter in finishedEmitters) {
      _activeEmitters.remove(emitter);
      _poolManager.emitterPool.returnEmitter(emitter);
    }
  }
  
  /// Render particles sorted by layer
  void _renderParticlesByLayer(Canvas canvas) {
    // Group particles by render layer
    final particlesByLayer = <int, List<Particle>>{};
    
    for (final emitter in _activeEmitters) {
      for (final particle in emitter.particles) {
        final layer = _renderLayers[particle.type] ?? 3;
        particlesByLayer.putIfAbsent(layer, () => []).add(particle);
      }
    }
    
    // Render layers in order (lowest to highest)
    final sortedLayers = particlesByLayer.keys.toList()..sort();
    for (final layer in sortedLayers) {
      final particles = particlesByLayer[layer]!;
      _renderParticles(canvas, particles);
    }
  }
  
  /// Render a list of particles
  void _renderParticles(Canvas canvas, List<Particle> particles) {
    for (final particle in particles) {
      _renderParticle(canvas, particle);
    }
  }
  
  /// Render a single particle
  void _renderParticle(Canvas canvas, Particle particle) {
    if (!particle.isActive || particle.alpha <= 0) return;
    
    canvas.save();
    
    // Apply transformations
    canvas.translate(particle.position.x, particle.position.y);
    canvas.rotate(particle.rotation);
    canvas.scale(particle.scale);
    
    if (particle.sprite != null) {
      // Render sprite with alpha
      final paint = Paint()
        ..color = particle.getCurrentColor()
        ..blendMode = BlendMode.srcOver;
      
      particle.sprite!.render(
        canvas,
        size: particle.size,
        overridePaint: paint,
      );
    } else {
      // Render as colored rectangle
      final paint = particle.getCurrentPaint();
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size.x,
        height: particle.size.y,
      );
      
      canvas.drawRect(rect, paint);
    }
    
    canvas.restore();
  }
  
  /// Spawn impact particles at a specific location
  /// Used when the physics ball hits surfaces
  void spawnImpactParticles(Vector2 position, {int count = 15}) {
    final emitter = _poolManager.emitterPool.getEmitter(
      config: ParticleEmitterConfig.impact,
      position: position.clone(),
      maxBurstParticles: count,
    );
    
    _activeEmitters.add(emitter);
    emitter.emitBurst(count);
  }
  
  /// Spawn destruction particles for different tile materials
  /// Used when tiles are destroyed by the ball
  void spawnDestructionParticles(
    Vector2 position, 
    TileType tileType, {
    int count = 20,
  }) {
    final config = _getDestructionConfig(tileType);
    final emitter = _poolManager.emitterPool.getEmitter(
      config: config,
      position: position.clone(),
      maxBurstParticles: count,
    );
    
    _activeEmitters.add(emitter);
    emitter.emitBurst(count);
  }
  
  /// Spawn movement particles for player steps
  /// Used when the player character moves
  void spawnMovementParticles(Vector2 position) {
    final emitter = _poolManager.emitterPool.getEmitter(
      config: ParticleEmitterConfig.movement,
      position: position.clone(),
      maxBurstParticles: 3,
    );
    
    _activeEmitters.add(emitter);
    emitter.emitBurst(3);
  }
  
  /// Spawn explosion particles for special effects
  void spawnExplosionParticles(Vector2 position, {int count = 30}) {
    final config = ParticleEmitterConfig(
      emissionRate: 100.0,
      maxParticles: count,
      minLifetime: 0.8,
      maxLifetime: 2.0,
      minVelocity: Vector2(-150, -200),
      maxVelocity: Vector2(150, -50),
      startColor: Colors.orange,
      endColor: Colors.red,
      type: ParticleType.explosion,
      pattern: ParticlePattern.explosion,
    );
    
    final emitter = _poolManager.emitterPool.getEmitter(
      config: config,
      position: position.clone(),
      maxBurstParticles: count,
    );
    
    _activeEmitters.add(emitter);
    emitter.emitBurst(count);
  }
  
  /// Create continuous particle emitter (for ongoing effects)
  ParticleComponent createContinuousEmitter(
    Vector2 position,
    ParticleEmitterConfig config,
  ) {
    final emitter = _poolManager.emitterPool.getEmitter(
      config: config,
      position: position.clone(),
      isContinuous: true,
    );
    
    _activeEmitters.add(emitter);
    return emitter;
  }
  
  /// Stop and remove a continuous emitter
  void stopEmitter(ParticleComponent emitter) {
    emitter.stop();
    _activeEmitters.remove(emitter);
    _poolManager.emitterPool.returnEmitter(emitter);
  }
  
  /// Get destruction particle configuration based on tile type
  ParticleEmitterConfig _getDestructionConfig(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return ParticleEmitterConfig(
          emissionRate: 60.0,
          maxParticles: 25,
          minLifetime: 0.4,
          maxLifetime: 1.2,
          minVelocity: Vector2(-120, -180),
          maxVelocity: Vector2(120, -40),
          startColor: Colors.grey.shade600,
          endColor: Colors.grey.shade300,
          type: ParticleType.destruction,
          pattern: ParticlePattern.explosion,
        );
        
      case TileType.timber:
        return ParticleEmitterConfig(
          emissionRate: 50.0,
          maxParticles: 20,
          minLifetime: 0.6,
          maxLifetime: 1.8,
          minVelocity: Vector2(-100, -160),
          maxVelocity: Vector2(100, -30),
          startColor: Colors.brown.shade700,
          endColor: Colors.brown.shade300,
          type: ParticleType.destruction,
          pattern: ParticlePattern.burst,
        );
        
      case TileType.bricks:
        return ParticleEmitterConfig(
          emissionRate: 70.0,
          maxParticles: 30,
          minLifetime: 0.8,
          maxLifetime: 2.2,
          minVelocity: Vector2(-140, -200),
          maxVelocity: Vector2(140, -20),
          startColor: Colors.red.shade800,
          endColor: Colors.red.shade400,
          type: ParticleType.destruction,
          pattern: ParticlePattern.explosion,
        );
        
      default:
        return ParticleEmitterConfig.destruction;
    }
  }
  
  /// Get current particle system statistics
  Map<String, dynamic> getStats() {
    final poolStats = _poolManager.getStats();
    return {
      ...poolStats,
      'activeEmitters': _activeEmitters.length,
      'totalActiveParticles': _activeEmitters.fold<int>(
        0, 
        (sum, emitter) => sum + emitter.activeParticleCount,
      ),
    };
  }
  
  /// Clear all particles and emitters
  void clearAllParticles() {
    for (final emitter in _activeEmitters) {
      emitter.clear();
      _poolManager.emitterPool.returnEmitter(emitter);
    }
    _activeEmitters.clear();
    _poolManager.clear();
  }
  
  @override
  void dispose() {
    clearAllParticles();
    _poolManager.dispose();
    super.dispose();
  }
}

/// Tile types for material-specific particle effects
enum TileType {
  scaffolding,
  timber,
  bricks,
  beam,
  indestructible,
}

/// Extension methods for easy particle spawning from other systems
extension ParticleSystemExtensions on HardHatGame {
  /// Get the particle system from the game
  ParticleSystem? get particleSystem {
    return children.query<ParticleSystem>().firstOrNull;
  }
  
  /// Spawn impact particles (convenience method)
  void spawnImpact(Vector2 position, {int count = 15}) {
    particleSystem?.spawnImpactParticles(position, count: count);
  }
  
  /// Spawn destruction particles (convenience method)
  void spawnDestruction(Vector2 position, TileType tileType, {int count = 20}) {
    particleSystem?.spawnDestructionParticles(position, tileType, count: count);
  }
  
  /// Spawn movement particles (convenience method)
  void spawnMovement(Vector2 position) {
    particleSystem?.spawnMovementParticles(position);
  }
  
  /// Spawn explosion particles (convenience method)
  void spawnExplosion(Vector2 position, {int count = 30}) {
    particleSystem?.spawnExplosionParticles(position, count: count);
  }
}