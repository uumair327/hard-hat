import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Types of particles for different effects
enum ParticleType {
  impact,      // Star particles for ball impacts
  destruction, // Material-specific break particles
  movement,    // Step particles for player movement
  explosion,   // Explosion effects
  dust,        // Dust clouds
  spark,       // Sparks and flashes
}

/// Particle behavior patterns
enum ParticlePattern {
  burst,       // Particles burst outward from center
  fountain,    // Particles arc upward like a fountain
  stream,      // Particles flow in a direction
  explosion,   // Particles explode in all directions
  drift,       // Particles drift slowly
}

/// Individual particle data
class Particle {
  /// Particle position in world coordinates
  Vector2 position;
  
  /// Particle velocity
  Vector2 velocity;
  
  /// Particle acceleration (gravity, wind, etc.)
  Vector2 acceleration;
  
  /// Particle size
  Vector2 size;
  
  /// Particle rotation angle
  double rotation;
  
  /// Particle rotation speed
  double rotationSpeed;
  
  /// Particle color
  Color color;
  
  /// Particle alpha (opacity)
  double alpha;
  
  /// Particle scale
  double scale;
  
  /// Particle lifetime (total duration)
  double lifetime;
  
  /// Particle age (current time alive)
  double age;
  
  /// Whether particle is active
  bool isActive;
  
  /// Particle type for rendering
  ParticleType type;
  
  /// Sprite to render (optional)
  Sprite? sprite;
  
  /// Custom paint for rendering
  Paint? paint;
  
  Particle({
    Vector2? position,
    Vector2? velocity,
    Vector2? acceleration,
    Vector2? size,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
    this.color = Colors.white,
    this.alpha = 1.0,
    this.scale = 1.0,
    this.lifetime = 1.0,
    this.age = 0.0,
    this.isActive = true,
    this.type = ParticleType.impact,
    this.sprite,
    this.paint,
  }) : position = position ?? Vector2.zero(),
       velocity = velocity ?? Vector2.zero(),
       acceleration = acceleration ?? Vector2.zero(),
       size = size ?? Vector2(4, 4);
  
  /// Update particle physics and lifetime
  void update(double dt) {
    if (!isActive) return;
    
    // Update age
    age += dt;
    
    // Check if particle should die
    if (age >= lifetime) {
      isActive = false;
      return;
    }
    
    // Update physics
    velocity += acceleration * dt;
    position += velocity * dt;
    rotation += rotationSpeed * dt;
    
    // Update visual properties based on age
    final lifeProgress = age / lifetime;
    
    // Fade out over time
    alpha = (1.0 - lifeProgress).clamp(0.0, 1.0);
    
    // Scale changes over time (optional)
    if (type == ParticleType.explosion) {
      scale = (1.0 + lifeProgress * 2.0).clamp(0.1, 3.0);
    } else if (type == ParticleType.dust) {
      scale = (1.0 - lifeProgress * 0.5).clamp(0.1, 1.0);
    }
  }
  
  /// Reset particle for reuse in object pool
  void reset({
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
    this.position.setFrom(position ?? Vector2.zero());
    this.velocity.setFrom(velocity ?? Vector2.zero());
    this.acceleration.setFrom(acceleration ?? Vector2.zero());
    this.size.setFrom(size ?? Vector2(4, 4));
    this.rotation = rotation ?? 0.0;
    this.rotationSpeed = rotationSpeed ?? 0.0;
    this.color = color ?? Colors.white;
    this.alpha = alpha ?? 1.0;
    this.scale = scale ?? 1.0;
    this.lifetime = lifetime ?? 1.0;
    age = 0.0;
    isActive = true;
    this.type = type ?? ParticleType.impact;
    this.sprite = sprite;
    this.paint = paint;
  }
  
  /// Get current color with alpha applied
  Color getCurrentColor() {
    return color.withValues(alpha: alpha);
  }
  
  /// Get current paint for rendering
  Paint getCurrentPaint() {
    if (paint != null) {
      return Paint()
        ..color = getCurrentColor()
        ..blendMode = paint!.blendMode
        ..style = paint!.style;
    }
    
    return Paint()
      ..color = getCurrentColor()
      ..style = PaintingStyle.fill;
  }
}

/// Particle emitter configuration
class ParticleEmitterConfig {
  /// Emission rate (particles per second)
  final double emissionRate;
  
  /// Maximum number of particles
  final int maxParticles;
  
  /// Particle lifetime range
  final double minLifetime;
  final double maxLifetime;
  
  /// Particle size range
  final Vector2 minSize;
  final Vector2 maxSize;
  
  /// Particle velocity range
  final Vector2 minVelocity;
  final Vector2 maxVelocity;
  
  /// Particle acceleration (gravity, etc.)
  final Vector2 acceleration;
  
  /// Particle color range
  final Color startColor;
  final Color endColor;
  
  /// Particle rotation range
  final double minRotation;
  final double maxRotation;
  final double minRotationSpeed;
  final double maxRotationSpeed;
  
  /// Particle scale range
  final double minScale;
  final double maxScale;
  
  /// Particle type
  final ParticleType type;
  
  /// Particle pattern
  final ParticlePattern pattern;
  
  /// Sprite to use for particles
  final Sprite? sprite;
  
  ParticleEmitterConfig({
    this.emissionRate = 50.0,
    this.maxParticles = 100,
    this.minLifetime = 0.5,
    this.maxLifetime = 2.0,
    Vector2? minSize,
    Vector2? maxSize,
    Vector2? minVelocity,
    Vector2? maxVelocity,
    Vector2? acceleration,
    this.startColor = Colors.white,
    this.endColor = Colors.transparent,
    this.minRotation = 0.0,
    this.maxRotation = 6.28, // 2π
    this.minRotationSpeed = -3.14,
    this.maxRotationSpeed = 3.14,
    this.minScale = 0.5,
    this.maxScale = 1.5,
    this.type = ParticleType.impact,
    this.pattern = ParticlePattern.burst,
    this.sprite,
  }) : minSize = minSize ?? Vector2(2, 2),
       maxSize = maxSize ?? Vector2(8, 8),
       minVelocity = minVelocity ?? Vector2(-50, -100),
       maxVelocity = maxVelocity ?? Vector2(50, 50),
       acceleration = acceleration ?? Vector2(0, 98);
  
  /// Create impact particle config
  static ParticleEmitterConfig get impact => ParticleEmitterConfig(
    emissionRate: 30.0,
    maxParticles: 20,
    minLifetime: 0.3,
    maxLifetime: 0.8,
    minVelocity: Vector2(-80, -120),
    maxVelocity: Vector2(80, -20),
    startColor: Colors.yellow,
    endColor: Colors.orange,
    type: ParticleType.impact,
    pattern: ParticlePattern.burst,
  );
  
  /// Create destruction particle config
  static ParticleEmitterConfig get destruction => ParticleEmitterConfig(
    emissionRate: 50.0,
    maxParticles: 30,
    minLifetime: 0.5,
    maxLifetime: 1.5,
    minVelocity: Vector2(-100, -150),
    maxVelocity: Vector2(100, -50),
    startColor: Colors.brown,
    endColor: Colors.grey,
    type: ParticleType.destruction,
    pattern: ParticlePattern.explosion,
  );
  
  /// Create movement particle config
  static ParticleEmitterConfig get movement => ParticleEmitterConfig(
    emissionRate: 10.0,
    maxParticles: 5,
    minLifetime: 0.2,
    maxLifetime: 0.5,
    minVelocity: Vector2(-20, -30),
    maxVelocity: Vector2(20, 10),
    minSize: Vector2(1, 1),
    maxSize: Vector2(3, 3),
    startColor: Colors.grey,
    endColor: Colors.transparent,
    type: ParticleType.movement,
    pattern: ParticlePattern.drift,
  );
}

/// Component for managing particle effects
class ParticleComponent extends Component {
  /// List of active particles
  final List<Particle> particles = [];
  
  /// Particle emitter configuration
  ParticleEmitterConfig config;
  
  /// Emitter position
  Vector2 position;
  
  /// Whether emitter is active
  bool isActive;
  
  /// Whether emitter should emit continuously
  bool isContinuous;
  
  /// Emission timer
  double _emissionTimer = 0.0;
  
  /// Total particles emitted
  int _totalEmitted = 0;
  
  /// Maximum burst particles (for non-continuous emission)
  int? maxBurstParticles;
  
  ParticleComponent({
    required this.config,
    Vector2? position,
    this.isActive = true,
    this.isContinuous = false,
    this.maxBurstParticles,
  }) : position = position ?? Vector2.zero();
  
  /// Update all particles and emit new ones
  void updateParticles(double dt) {
    if (!isActive) return;
    
    // Update existing particles
    particles.removeWhere((particle) {
      particle.update(dt);
      return !particle.isActive;
    });
    
    // Emit new particles
    if (isContinuous || (maxBurstParticles != null && _totalEmitted < maxBurstParticles!)) {
      _emissionTimer += dt;
      
      final emissionInterval = 1.0 / config.emissionRate;
      while (_emissionTimer >= emissionInterval && particles.length < config.maxParticles) {
        _emissionTimer -= emissionInterval;
        _emitParticle();
        _totalEmitted++;
        
        if (maxBurstParticles != null && _totalEmitted >= maxBurstParticles!) {
          break;
        }
      }
    }
  }
  
  /// Emit a single particle
  void _emitParticle() {
    final particle = _createParticle();
    particles.add(particle);
  }
  
  /// Create a new particle based on configuration
  Particle _createParticle() {
    // Random values within configured ranges
    final lifetime = _randomRange(config.minLifetime, config.maxLifetime);
    final size = Vector2(
      _randomRange(config.minSize.x, config.maxSize.x),
      _randomRange(config.minSize.y, config.maxSize.y),
    );
    final rotation = _randomRange(config.minRotation, config.maxRotation);
    final rotationSpeed = _randomRange(config.minRotationSpeed, config.maxRotationSpeed);
    final scale = _randomRange(config.minScale, config.maxScale);
    
    // Generate velocity based on pattern
    final velocity = _generateVelocity();
    
    return Particle(
      position: position.clone(),
      velocity: velocity,
      acceleration: config.acceleration.clone(),
      size: size,
      rotation: rotation,
      rotationSpeed: rotationSpeed,
      color: config.startColor,
      scale: scale,
      lifetime: lifetime,
      type: config.type,
      sprite: config.sprite,
    );
  }
  
  /// Generate velocity based on emission pattern
  Vector2 _generateVelocity() {
    switch (config.pattern) {
      case ParticlePattern.burst:
        // Random direction outward
        final angle = _randomRange(0, 2 * math.pi);
        final speed = _randomRange(
          config.minVelocity.length,
          config.maxVelocity.length,
        );
        return Vector2(speed * math.cos(angle), speed * math.sin(angle));
        
      case ParticlePattern.fountain:
        // Upward arc with some spread
        final angle = _randomRange(-0.5, 0.5); // ±30 degrees from vertical
        final speed = _randomRange(
          config.minVelocity.length,
          config.maxVelocity.length,
        );
        return Vector2(speed * math.sin(angle), -speed * math.cos(angle));
        
      case ParticlePattern.explosion:
        // Full 360-degree explosion
        final angle = _randomRange(0, 2 * math.pi);
        final speed = _randomRange(50, 200);
        return Vector2(speed * math.cos(angle), speed * math.sin(angle));
        
      case ParticlePattern.stream:
      case ParticlePattern.drift:
        // Random within velocity range
        return Vector2(
          _randomRange(config.minVelocity.x, config.maxVelocity.x),
          _randomRange(config.minVelocity.y, config.maxVelocity.y),
        );
    }
  }
  
  /// Generate random value within range
  double _randomRange(double min, double max) {
    // Simple pseudo-random using current time
    final seed = DateTime.now().microsecondsSinceEpoch % 1000000;
    final normalized = (seed / 1000000.0);
    return min + (max - min) * normalized;
  }
  
  /// Emit a burst of particles
  void emitBurst(int count) {
    for (int i = 0; i < count && particles.length < config.maxParticles; i++) {
      _emitParticle();
    }
  }
  
  /// Stop emitting particles
  void stop() {
    isActive = false;
  }
  
  /// Start emitting particles
  void start() {
    isActive = true;
  }
  
  /// Clear all particles
  void clear() {
    particles.clear();
    _totalEmitted = 0;
    _emissionTimer = 0.0;
  }
  
  /// Set emitter position
  void setPosition(Vector2 newPosition) {
    position.setFrom(newPosition);
  }
  
  /// Check if emitter has finished (for burst emitters)
  bool get isFinished {
    return !isContinuous && 
           maxBurstParticles != null && 
           _totalEmitted >= maxBurstParticles! && 
           particles.isEmpty;
  }
  
  /// Get number of active particles
  int get activeParticleCount => particles.length;
}