import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/particle_component.dart';

/// Object pool for particles to avoid frequent allocation/deallocation
class ParticlePool {
  ParticlePool({
    this.initialSize = 100,
    this.maxSize = 1000,
  }) {
    // Pre-allocate initial particles
    for (int i = 0; i < initialSize; i++) {
      _availableParticles.add(Particle());
    }
  }
  
  final int initialSize;
  final int maxSize;
  
  final Queue<Particle> _availableParticles = Queue<Particle>();
  final Set<Particle> _activeParticles = <Particle>{};
  
  /// Get a particle from the pool
  Particle getParticle({
    Vector2? position,
    Vector2? velocity,
    Vector2? acceleration,
    Vector2? size,
    double? rotation,
    double? rotationSpeed,
    Color? color,
    double? alpha,
    double? scale,
    double? lifetime,
    ParticleType? type,
    Sprite? sprite,
    Paint? paint,
  }) {
    Particle particle;
    
    if (_availableParticles.isNotEmpty) {
      // Reuse existing particle
      particle = _availableParticles.removeFirst();
    } else if (_activeParticles.length + _availableParticles.length < maxSize) {
      // Create new particle if under limit
      particle = Particle();
    } else {
      // Pool is full, force recycle oldest active particle
      particle = _activeParticles.first;
      _activeParticles.remove(particle);
    }
    
    // Reset particle with new parameters
    particle.reset(
      position: position,
      velocity: velocity,
      acceleration: acceleration,
      size: size,
      rotation: rotation,
      rotationSpeed: rotationSpeed,
      color: color,
      alpha: alpha,
      scale: scale,
      lifetime: lifetime,
      type: type,
      sprite: sprite,
      paint: paint,
    );
    
    _activeParticles.add(particle);
    return particle;
  }
  
  /// Return a particle to the pool
  void returnParticle(Particle particle) {
    if (_activeParticles.remove(particle)) {
      particle.isActive = false;
      _availableParticles.add(particle);
    }
  }
  
  /// Return multiple particles to the pool
  void returnParticles(Iterable<Particle> particles) {
    for (final particle in particles) {
      returnParticle(particle);
    }
  }
  
  /// Update all active particles and return inactive ones to pool
  void updateActiveParticles(double dt) {
    final inactiveParticles = <Particle>[];
    
    for (final particle in _activeParticles) {
      particle.update(dt);
      if (!particle.isActive) {
        inactiveParticles.add(particle);
      }
    }
    
    // Return inactive particles to pool
    returnParticles(inactiveParticles);
  }
  
  /// Get all active particles
  Iterable<Particle> get activeParticles => _activeParticles;
  
  /// Get pool statistics
  Map<String, int> getStats() {
    return {
      'available': _availableParticles.length,
      'active': _activeParticles.length,
      'total': _availableParticles.length + _activeParticles.length,
      'maxSize': maxSize,
    };
  }
  
  /// Clear all particles
  void clear() {
    _availableParticles.addAll(_activeParticles);
    _activeParticles.clear();
  }
  
  /// Dispose of the pool
  void dispose() {
    _availableParticles.clear();
    _activeParticles.clear();
  }
}

/// Pool manager for different types of particle emitters
class ParticleEmitterPool {
  ParticleEmitterPool({
    this.initialSize = 20,
    this.maxSize = 100,
  }) {
    // Pre-allocate initial emitters
    for (int i = 0; i < initialSize; i++) {
      _availableEmitters.add(ParticleComponent(
        config: ParticleEmitterConfig.impact,
        isActive: false,
      ));
    }
  }
  
  final int initialSize;
  final int maxSize;
  
  final Queue<ParticleComponent> _availableEmitters = Queue<ParticleComponent>();
  final Set<ParticleComponent> _activeEmitters = <ParticleComponent>{};
  
  /// Get an emitter from the pool
  ParticleComponent getEmitter({
    required ParticleEmitterConfig config,
    Vector2? position,
    bool isContinuous = false,
    int? maxBurstParticles,
  }) {
    ParticleComponent emitter;
    
    if (_availableEmitters.isNotEmpty) {
      // Reuse existing emitter
      emitter = _availableEmitters.removeFirst();
    } else if (_activeEmitters.length + _availableEmitters.length < maxSize) {
      // Create new emitter if under limit
      emitter = ParticleComponent(
        config: config,
        isActive: false,
      );
    } else {
      // Pool is full, force recycle oldest active emitter
      emitter = _activeEmitters.first;
      _activeEmitters.remove(emitter);
    }
    
    // Reset emitter with new parameters
    emitter.config = config;
    emitter.position = position ?? Vector2.zero();
    emitter.isContinuous = isContinuous;
    emitter.maxBurstParticles = maxBurstParticles;
    emitter.isActive = true;
    emitter.clear();
    
    _activeEmitters.add(emitter);
    return emitter;
  }
  
  /// Return an emitter to the pool
  void returnEmitter(ParticleComponent emitter) {
    if (_activeEmitters.remove(emitter)) {
      emitter.stop();
      emitter.clear();
      _availableEmitters.add(emitter);
    }
  }
  
  /// Update all active emitters and return finished ones to pool
  void updateActiveEmitters(double dt) {
    final finishedEmitters = <ParticleComponent>[];
    
    for (final emitter in _activeEmitters) {
      emitter.updateParticles(dt);
      if (emitter.isFinished) {
        finishedEmitters.add(emitter);
      }
    }
    
    // Return finished emitters to pool
    for (final emitter in finishedEmitters) {
      returnEmitter(emitter);
    }
  }
  
  /// Get all active emitters
  Iterable<ParticleComponent> get activeEmitters => _activeEmitters;
  
  /// Get pool statistics
  Map<String, int> getStats() {
    return {
      'available': _availableEmitters.length,
      'active': _activeEmitters.length,
      'total': _availableEmitters.length + _activeEmitters.length,
      'maxSize': maxSize,
    };
  }
  
  /// Clear all emitters
  void clear() {
    for (final emitter in _activeEmitters) {
      emitter.clear();
    }
    _availableEmitters.addAll(_activeEmitters);
    _activeEmitters.clear();
  }
  
  /// Dispose of the pool
  void dispose() {
    clear();
    _availableEmitters.clear();
  }
}

/// Global particle pool manager
class GlobalParticlePoolManager {
  static final GlobalParticlePoolManager _instance = GlobalParticlePoolManager._internal();
  factory GlobalParticlePoolManager() => _instance;
  GlobalParticlePoolManager._internal();
  
  ParticlePool? _particlePool;
  ParticleEmitterPool? _emitterPool;
  
  /// Initialize the global pools
  void initialize({
    int particlePoolSize = 500,
    int emitterPoolSize = 50,
  }) {
    // Only initialize if not already initialized
    try {
      _particlePool = ParticlePool(
        initialSize: particlePoolSize ~/ 5,
        maxSize: particlePoolSize,
      );
    } catch (e) {
      // Already initialized, dispose and recreate
      _particlePool?.dispose();
      _particlePool = ParticlePool(
        initialSize: particlePoolSize ~/ 5,
        maxSize: particlePoolSize,
      );
    }
    
    try {
      _emitterPool = ParticleEmitterPool(
        initialSize: emitterPoolSize ~/ 5,
        maxSize: emitterPoolSize,
      );
    } catch (e) {
      // Already initialized, dispose and recreate
      _emitterPool?.dispose();
      _emitterPool = ParticleEmitterPool(
        initialSize: emitterPoolSize ~/ 5,
        maxSize: emitterPoolSize,
      );
    }
  }
  
  /// Get the particle pool
  ParticlePool get particlePool => _particlePool!;
  
  /// Get the emitter pool
  ParticleEmitterPool get emitterPool => _emitterPool!;
  
  /// Update all pools
  void update(double dt) {
    _particlePool?.updateActiveParticles(dt);
    _emitterPool?.updateActiveEmitters(dt);
  }
  
  /// Get combined statistics
  Map<String, dynamic> getStats() {
    return {
      'particles': _particlePool?.getStats() ?? {},
      'emitters': _emitterPool?.getStats() ?? {},
    };
  }
  
  /// Clear all pools
  void clear() {
    _particlePool?.clear();
    _emitterPool?.clear();
  }
  
  /// Dispose of all pools
  void dispose() {
    _particlePool?.dispose();
    _emitterPool?.dispose();
    _particlePool = null;
    _emitterPool = null;
  }
}