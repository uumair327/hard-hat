import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/domain/services/particle_pool.dart';
import 'package:hard_hat/core/services/sprite_batch.dart';
import 'package:hard_hat/core/services/render_performance.dart';

/// System responsible for rendering sprites and visual elements with batching optimization
class RenderSystem extends GameSystem {
  RenderSystem({
    bool enableBatching = true,
    int maxBatchSize = 1000,
    bool enableParticlePooling = true,
  }) : _batchManager = SpriteBatchManager(
         enableBatching: enableBatching,
         maxBatchSize: maxBatchSize,
       ),
       _particlePoolingEnabled = enableParticlePooling;

  @override
  int get priority => 1000; // Execute last for rendering

  final SpriteBatchManager _batchManager;
  final RenderPerformanceMonitor _performanceMonitor = RenderPerformanceMonitor();
  final Map<int, List<RenderableEntity>> _renderLayers = {};
  final Map<int, List<Particle>> _particleLayers = {};
  bool _batchingEnabled = true;
  final bool _particlePoolingEnabled;
  
  /// Global particle pool manager
  GlobalParticlePoolManager? _particlePoolManager;

  @override
  Future<void> initialize() async {
    // Initialize particle pool manager if enabled and not already initialized
    if (_particlePoolingEnabled) {
      _particlePoolManager = GlobalParticlePoolManager();
      // Only initialize if not already initialized by ParticleSystem
      try {
        _particlePoolManager?.initialize(
          particlePoolSize: 1000,
          emitterPoolSize: 100,
        );
      } catch (e) {
        // Already initialized by another system (like ParticleSystem)
        // This is expected and fine
      }
    }
  }

  @override
  void updateSystem(double dt) {
    // Update particle pools if enabled and initialized
    if (_particlePoolingEnabled && _particlePoolManager != null) {
      try {
        _particlePoolManager?.update(dt);
      } catch (e) {
        // Pool manager not initialized, skip update
      }
    }
    
    // Prepare render data
    _prepareRenderData();
  }

  @override
  void renderSystem(Canvas canvas) {
    _performanceMonitor.startFrame();
    
    if (_batchingEnabled) {
      // Use sprite batching for optimized rendering
      _renderWithBatching(canvas);
    } else {
      // Use traditional layer-based rendering
      _renderWithLayers(canvas);
    }
    
    // Render particles with optimization
    _renderParticles(canvas);
    
    _performanceMonitor.endFrame();
  }

  /// Prepare render data by collecting all renderable entities
  void _prepareRenderData() {
    _renderLayers.clear();
    _particleLayers.clear();
    _batchManager.clear();
    
    // Get all entities with renderable components
    final renderableEntities = getComponents<Component>()
        .where((entity) => 
            entity.children.any((c) => c is GamePositionComponent) &&
            entity.children.any((c) => c is GameSpriteComponent))
        .map((entity) => RenderableEntity(
            entity: entity,
            position: entity.children.whereType<GamePositionComponent>().first,
            sprite: entity.children.whereType<GameSpriteComponent>().first,
          ))
        .toList();

    if (_batchingEnabled) {
      // Add entities to sprite batching system
      for (final renderable in renderableEntities) {
        _addToBatch(renderable);
      }
    } else {
      // Group by render layer for traditional rendering
      for (final renderable in renderableEntities) {
        final layer = renderable.sprite.renderLayer;
        _renderLayers.putIfAbsent(layer, () => []);
        _renderLayers[layer]!.add(renderable);
      }
    }
    
    // Prepare particle render data
    _prepareParticleData();
  }
  
  /// Prepare particle render data by collecting all particles
  void _prepareParticleData() {
    // Get all particle components
    final particleComponents = getComponents<ParticleComponent>();
    
    for (final component in particleComponents) {
      for (final particle in component.particles) {
        if (particle.isActive) {
          final layer = RenderLayer.particles.value;
          _particleLayers.putIfAbsent(layer, () => []);
          _particleLayers[layer]!.add(particle);
        }
      }
    }
    
    // Also get particles from global pool if enabled
    if (_particlePoolingEnabled && _particlePoolManager != null) {
      for (final particle in _particlePoolManager!.particlePool.activeParticles) {
        if (particle.isActive) {
          final layer = RenderLayer.particles.value;
          _particleLayers.putIfAbsent(layer, () => []);
          _particleLayers[layer]!.add(particle);
        }
      }
    }
  }

  /// Add a renderable entity to the sprite batch
  void _addToBatch(RenderableEntity entity) {
    final sprite = entity.sprite.sprite;
    if (sprite == null) return;

    final renderLayer = _mapToRenderLayer(entity.sprite.renderLayer);
    
    final batchItem = SpriteBatchItem(
      sprite: sprite,
      position: entity.position.position,
      size: entity.sprite.size,
      rotation: entity.position.angle,
      scale: 1.0, // Use default scale for now
      paint: entity.sprite.paint,
      anchor: entity.sprite.anchor,
      renderLayer: renderLayer,
    );

    _batchManager.addSprite(batchItem);
  }

  /// Map integer render layer to RenderLayer enum
  RenderLayer _mapToRenderLayer(int layer) {
    if (layer < 50) return RenderLayer.background;
    if (layer < 150) return RenderLayer.tiles;
    if (layer < 250) return RenderLayer.interactive;
    if (layer < 350) return RenderLayer.entities;
    if (layer < 450) return RenderLayer.projectiles;
    if (layer < 550) return RenderLayer.particles;
    return RenderLayer.ui;
  }

  /// Render using sprite batching system
  void _renderWithBatching(Canvas canvas) {
    final batches = _batchManager.getSortedBatches();
    _performanceMonitor.recordDrawCall(); // One draw call per batch group
    
    for (final batch in batches) {
      _performanceMonitor.recordSprites(batch.items.length);
    }
    
    _batchManager.renderBatches(canvas);
  }

  /// Render using traditional layer-based system
  void _renderWithLayers(Canvas canvas) {
    // Render entities by layer (lower numbers render first)
    final sortedLayers = _renderLayers.keys.toList()..sort();
    
    for (final layer in sortedLayers) {
      final entities = _renderLayers[layer] ?? [];
      for (final entity in entities) {
        _performanceMonitor.recordDrawCall();
        _performanceMonitor.recordSprites(1);
        _renderEntity(canvas, entity);
      }
    }
  }

  /// Render an individual entity (traditional method)
  void _renderEntity(Canvas canvas, RenderableEntity entity) {
    final sprite = entity.sprite.sprite;
    final position = entity.position.position;
    final size = entity.sprite.size;
    final paint = entity.sprite.paint;

    if (sprite != null) {
      canvas.save();
      
      // Apply transformations
      final anchorOffset = _getAnchorOffset(entity.sprite.anchor, size);
      canvas.translate(
        position.x - anchorOffset.x,
        position.y - anchorOffset.y,
      );
      
      if (entity.position.angle != 0) {
        canvas.translate(size.x / 2, size.y / 2);
        canvas.rotate(entity.position.angle);
        canvas.translate(-size.x / 2, -size.y / 2);
      }
      
      // Scale is handled by the sprite component itself
      
      // Render sprite
      sprite.render(
        canvas,
        size: size,
        overridePaint: paint,
      );
      
      canvas.restore();
    }
  }

  /// Get anchor offset for positioning
  Vector2 _getAnchorOffset(Anchor anchor, Vector2 size) {
    switch (anchor) {
      case Anchor.topLeft:
        return Vector2.zero();
      case Anchor.topCenter:
        return Vector2(size.x / 2, 0);
      case Anchor.topRight:
        return Vector2(size.x, 0);
      case Anchor.centerLeft:
        return Vector2(0, size.y / 2);
      case Anchor.center:
        return Vector2(size.x / 2, size.y / 2);
      case Anchor.centerRight:
        return Vector2(size.x, size.y / 2);
      case Anchor.bottomLeft:
        return Vector2(0, size.y);
      case Anchor.bottomCenter:
        return Vector2(size.x / 2, size.y);
      case Anchor.bottomRight:
        return Vector2(size.x, size.y);
      default:
        return Vector2.zero();
    }
  }

  /// Enable/disable sprite batching for performance
  void setBatchingEnabled(bool enabled) {
    _batchingEnabled = enabled;
  }

  /// Get batching enabled state
  bool get isBatchingEnabled => _batchingEnabled;

  /// Optimize batches for better performance
  void optimizeBatches() {
    _batchManager.optimizeBatches();
  }

  /// Get rendering statistics
  Map<String, dynamic> getRenderStats() {
    final batchStats = _batchManager.getStats();
    final perfStats = _performanceMonitor.getDetailedStats();
    final particleStats = getParticleStats();
    
    return {
      ...batchStats,
      ...perfStats,
      'renderLayers': _renderLayers.length,
      'particleLayers': _particleLayers.length,
      'totalEntities': _renderLayers.values.fold(0, (sum, entities) => sum + entities.length),
      'totalParticles': _particleLayers.values.fold(0, (sum, particles) => sum + particles.length),
      'particles': particleStats,
    };
  }

  /// Render particles with optimization
  void _renderParticles(Canvas canvas) {
    if (_particleLayers.isEmpty) return;
    
    // Render particles by layer (particles should render on top)
    final sortedLayers = _particleLayers.keys.toList()..sort();
    
    for (final layer in sortedLayers) {
      final particles = _particleLayers[layer] ?? [];
      
      if (particles.isNotEmpty) {
        _renderParticleLayer(canvas, particles);
      }
    }
  }
  
  /// Render a layer of particles with batching optimization
  void _renderParticleLayer(Canvas canvas, List<Particle> particles) {
    // Group particles by type and sprite for batching
    final Map<String, List<Particle>> particleGroups = {};
    
    for (final particle in particles) {
      final key = '${particle.type}_${particle.sprite?.hashCode ?? 'null'}';
      particleGroups.putIfAbsent(key, () => []);
      particleGroups[key]!.add(particle);
    }
    
    // Render each group
    for (final group in particleGroups.values) {
      _renderParticleGroup(canvas, group);
    }
  }
  
  /// Render a group of similar particles
  void _renderParticleGroup(Canvas canvas, List<Particle> particles) {
    if (particles.isEmpty) return;
    
    final firstParticle = particles.first;
    
    if (firstParticle.sprite != null) {
      // Render sprite-based particles
      _renderSpriteParticles(canvas, particles);
    } else {
      // Render shape-based particles
      _renderShapeParticles(canvas, particles);
    }
    
    _performanceMonitor.recordDrawCall();
    _performanceMonitor.recordSprites(particles.length);
  }
  
  /// Render sprite-based particles
  void _renderSpriteParticles(Canvas canvas, List<Particle> particles) {
    for (final particle in particles) {
      if (particle.sprite == null) continue;
      
      canvas.save();
      
      // Apply transformations
      canvas.translate(particle.position.x, particle.position.y);
      
      if (particle.rotation != 0) {
        canvas.rotate(particle.rotation);
      }
      
      if (particle.scale != 1.0) {
        canvas.scale(particle.scale);
      }
      
      // Apply alpha
      final paint = particle.getCurrentPaint();
      
      // Render sprite
      particle.sprite!.render(
        canvas,
        size: particle.size,
        overridePaint: paint,
      );
      
      canvas.restore();
    }
  }
  
  /// Render shape-based particles (circles, rectangles)
  void _renderShapeParticles(Canvas canvas, List<Particle> particles) {
    for (final particle in particles) {
      canvas.save();
      
      // Apply transformations
      canvas.translate(particle.position.x, particle.position.y);
      
      if (particle.rotation != 0) {
        canvas.rotate(particle.rotation);
      }
      
      if (particle.scale != 1.0) {
        canvas.scale(particle.scale);
      }
      
      final paint = particle.getCurrentPaint();
      
      // Render based on particle type
      switch (particle.type) {
        case ParticleType.impact:
          // Render as star shape
          _drawStar(canvas, particle.size, paint);
          break;
          
        case ParticleType.destruction:
          // Render as irregular chunks
          _drawChunk(canvas, particle.size, paint);
          break;
          
        case ParticleType.movement:
        case ParticleType.dust:
          // Render as small circles
          _drawCircle(canvas, particle.size, paint);
          break;
          
        case ParticleType.explosion:
          // Render as expanding circles
          _drawExpandingCircle(canvas, particle.size, paint, particle.age / particle.lifetime);
          break;
          
        case ParticleType.spark:
          // Render as lines
          _drawSpark(canvas, particle.size, paint);
          break;
      }
      
      canvas.restore();
    }
  }
  
  /// Draw a star shape for impact particles
  void _drawStar(Canvas canvas, Vector2 size, Paint paint) {
    final path = Path();
    final radius = size.x / 2;
    final innerRadius = radius * 0.5;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5);
      final r = (i % 2 == 0) ? radius : innerRadius;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  /// Draw a chunk shape for destruction particles
  void _drawChunk(Canvas canvas, Vector2 size, Paint paint) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    canvas.drawRect(rect, paint);
  }
  
  /// Draw a circle for dust/movement particles
  void _drawCircle(Canvas canvas, Vector2 size, Paint paint) {
    final radius = size.x / 2;
    canvas.drawCircle(Offset.zero, radius, paint);
  }
  
  /// Draw an expanding circle for explosion particles
  void _drawExpandingCircle(Canvas canvas, Vector2 size, Paint paint, double progress) {
    final radius = (size.x / 2) * (1.0 + progress);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0 * (1.0 - progress);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
  
  /// Draw a spark line
  void _drawSpark(Canvas canvas, Vector2 size, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(-size.x / 2, 0),
      Offset(size.x / 2, 0),
      paint,
    );
  }
  
  /// Create particle effect at position
  ParticleComponent? createParticleEffect({
    required ParticleType type,
    required Vector2 position,
    int? particleCount,
    ParticleEmitterConfig? customConfig,
  }) {
    if (!_particlePoolingEnabled) return null;
    
    // Select appropriate config
    ParticleEmitterConfig config;
    switch (type) {
      case ParticleType.impact:
        config = customConfig ?? ParticleEmitterConfig.impact;
        break;
      case ParticleType.destruction:
        config = customConfig ?? ParticleEmitterConfig.destruction;
        break;
      case ParticleType.movement:
        config = customConfig ?? ParticleEmitterConfig.movement;
        break;
      default:
        config = customConfig ?? ParticleEmitterConfig.impact;
    }
    
    // Get emitter from pool
    final emitter = _particlePoolManager!.emitterPool.getEmitter(
      config: config,
      position: position,
      isContinuous: false,
      maxBurstParticles: particleCount ?? 20,
    );
    
    // Emit initial burst
    emitter.emitBurst(particleCount ?? 20);
    
    return emitter;
  }
  
  /// Enable/disable particle pooling
  void setParticlePoolingEnabled(bool enabled) {
    // Note: This can't change the pooling state after initialization
    // It's here for consistency with other enable/disable methods
  }
  
  /// Get particle pooling enabled state
  bool get isParticlePoolingEnabled => _particlePoolingEnabled;
  
  /// Get particle pool statistics
  Map<String, dynamic> getParticleStats() {
    if (!_particlePoolingEnabled) {
      return {'poolingEnabled': false};
    }
    
    return {
      'poolingEnabled': true,
      ...(_particlePoolManager?.getStats() ?? {}),
    };
  }

  /// Get performance monitor
  RenderPerformanceMonitor get performanceMonitor => _performanceMonitor;

  @override
  void dispose() {
    _renderLayers.clear();
    _particleLayers.clear();
    _batchManager.clear();
    
    if (_particlePoolingEnabled && _particlePoolManager != null) {
      try {
        _particlePoolManager!.dispose();
      } catch (e) {
        // Pool manager not initialized or already disposed
      }
    }
  }
}

/// Helper class to group renderable components
class RenderableEntity {
  final Component entity;
  final GamePositionComponent position;
  final GameSpriteComponent sprite;

  RenderableEntity({
    required this.entity,
    required this.position,
    required this.sprite,
  });
}