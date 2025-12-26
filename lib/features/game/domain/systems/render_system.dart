import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Render system for drawing entities to the screen with optimization
class RenderSystem extends GameSystem implements IRenderSystem {
  late EntityManager _entityManager;
  late CameraSystem _cameraSystem;
  IParticleSystem? _particleSystem;
  
  // Render layers for proper draw order
  final Map<int, List<GameEntity>> _renderLayers = {};
  
  // Sprite batching for performance
  bool _batchingEnabled = true;
  int _maxBatchSize = 100;
  final Map<String, List<GameEntity>> _spriteBatches = {};
  
  // Render statistics
  int _entitiesRendered = 0;
  int _batchesRendered = 0;
  int _particlesRendered = 0;
  
  // Culling for performance
  bool _frustumCullingEnabled = true;
  final List<GameEntity> _visibleEntities = [];
  
  // Z-ordering and depth sorting
  final List<RenderItem> _renderQueue = [];
  
  @override
  int get priority => 9; // Process last to render everything

  @override
  Future<void> initialize() async {
    // Initialize render system with default settings
    _batchingEnabled = true;
    _maxBatchSize = 100;
    _frustumCullingEnabled = true;
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }
  
  /// Set camera system for viewport calculations
  void setCameraSystem(CameraSystem cameraSystem) {
    _cameraSystem = cameraSystem;
  }
  
  /// Set particle system for particle rendering integration
  void setParticleSystem(IParticleSystem particleSystem) {
    _particleSystem = particleSystem;
  }

  @override
  void update(double dt) {
    // Reset render statistics
    _entitiesRendered = 0;
    _batchesRendered = 0;
    _particlesRendered = 0;
    
    // Perform frustum culling
    _performFrustumCulling();
    
    // Sort entities by render layer and depth
    _sortEntitiesByRenderOrder();
    
    // Prepare sprite batches if batching is enabled
    if (_batchingEnabled) {
      _prepareBatches();
    }
    
    // Render all entities and particles
    renderEntities(dt);
    
    // Render particles through particle system integration
    _renderParticles(dt);
  }
  
  /// Perform frustum culling to filter visible entities
  void _performFrustumCulling() {
    _visibleEntities.clear();
    
    if (!_frustumCullingEnabled) {
      _visibleEntities.addAll(_entityManager.getAllEntities());
      return;
    }
    
    final entities = _entityManager.getAllEntities();
    final cameraBounds = _cameraSystem.getCameraBounds();
    
    for (final entity in entities) {
      if (_isEntityVisible(entity, cameraBounds)) {
        _visibleEntities.add(entity);
      }
    }
  }
  
  /// Check if entity is visible within camera bounds
  bool _isEntityVisible(GameEntity entity, Rect cameraBounds) {
    final position = entity.getEntityComponent<GamePositionComponent>();
    if (position == null) return false;
    
    final entityBounds = Rect.fromLTWH(
      position.position.x,
      position.position.y,
      position.size.x,
      position.size.y,
    );
    
    return cameraBounds.overlaps(entityBounds);
  }
  
  /// Prepare sprite batches for optimized rendering
  void _prepareBatches() {
    _spriteBatches.clear();
    
    for (final entity in _visibleEntities) {
      final sprite = entity.getEntityComponent<GameSpriteComponent>();
      if (sprite?.sprite == null) continue;
      
      // Group entities by sprite for batching
      final spriteKey = _getSpriteKey(sprite!);
      _spriteBatches.putIfAbsent(spriteKey, () => []).add(entity);
    }
  }
  
  /// Get a unique key for sprite batching
  String _getSpriteKey(GameSpriteComponent sprite) {
    // In a real implementation, this would use sprite texture ID
    return sprite.sprite?.image.hashCode.toString() ?? 'default';
  }
  
  /// Render particles through particle system integration
  void _renderParticles(double dt) {
    if (_particleSystem == null) return;
    
    // Get particles from particle system and render them
    if (_particleSystem is ParticleSystem) {
      // Note: getActiveParticles method would need to be implemented in ParticleSystem
      // For now, this is a placeholder showing the integration point
      _particlesRendered += 0; // Placeholder
    }
  }
  
  @override
  void renderEntities(double dt) {
    if (_batchingEnabled) {
      _renderEntitiesBatched(dt);
    } else {
      _renderEntitiesIndividual(dt);
    }
  }
  
  /// Render entities using sprite batching
  void _renderEntitiesBatched(double dt) {
    for (final entry in _spriteBatches.entries) {
      final entities = entry.value;
      if (entities.isEmpty) continue;
      
      // Limit batch size for performance
      final batchSize = entities.length > _maxBatchSize ? _maxBatchSize : entities.length;
      final batch = entities.take(batchSize).toList();
      
      _renderBatch(batch, dt);
      _batchesRendered++;
    }
  }
  
  /// Render entities individually (fallback)
  void _renderEntitiesIndividual(double dt) {
    _sortEntitiesByRenderLayer();
    _renderEntitiesInOrder(dt);
  }
  
  /// Render a batch of entities with the same sprite
  void _renderBatch(List<GameEntity> entities, double dt) {
    // Sort entities in batch by depth
    entities.sort((a, b) {
      final spriteA = a.getEntityComponent<GameSpriteComponent>();
      final spriteB = b.getEntityComponent<GameSpriteComponent>();
      
      final depthA = spriteA?.depth ?? 0.0;
      final depthB = spriteB?.depth ?? 0.0;
      
      return depthA.compareTo(depthB);
    });
    
    // Render all entities in the batch
    for (final entity in entities) {
      _renderEntity(entity, dt);
      _entitiesRendered++;
    }
  }
  
  @override
  void enableBatching(bool enabled) {
    _batchingEnabled = enabled;
  }
  
  @override
  void setMaxBatchSize(int size) {
    _maxBatchSize = size.clamp(1, 1000); // Reasonable limits
  }
  
  /// Sort entities by render layer and depth for proper draw order
  void _sortEntitiesByRenderOrder() {
    _renderQueue.clear();
    
    for (final entity in _visibleEntities) {
      final sprite = entity.getEntityComponent<GameSpriteComponent>();
      final position = entity.getEntityComponent<GamePositionComponent>();
      
      if (sprite == null || position == null) continue;
      
      final renderItem = RenderItem(
        entity: entity,
        layer: sprite.renderLayer,
        depth: sprite.depth,
        position: position.position.clone(),
      );
      
      _renderQueue.add(renderItem);
    }
    
    // Sort by layer first, then by depth
    _renderQueue.sort((a, b) {
      final layerComparison = a.layer.compareTo(b.layer);
      if (layerComparison != 0) return layerComparison;
      return a.depth.compareTo(b.depth);
    });
  }
  
  /// Render entities in sorted order
  void _renderEntitiesInOrder(double dt) {
    for (final renderItem in _renderQueue) {
      _renderEntity(renderItem.entity, dt);
      _entitiesRendered++;
    }
  }
  
  /// Sort entities by render layer for proper draw order
  void _sortEntitiesByRenderLayer() {
    _renderLayers.clear();
    
    for (final entity in _visibleEntities) {
      if (!entity.hasEntityComponent<GameSpriteComponent>()) continue;
      
      final sprite = entity.getEntityComponent<GameSpriteComponent>();
      if (sprite == null) continue;
      
      final layer = sprite.renderLayer;
      _renderLayers.putIfAbsent(layer, () => []).add(entity);
    }
    
    // Sort entities within each layer by depth
    for (final entities in _renderLayers.values) {
      entities.sort((a, b) {
        final spriteA = a.getEntityComponent<GameSpriteComponent>();
        final spriteB = b.getEntityComponent<GameSpriteComponent>();
        
        final depthA = spriteA?.depth ?? 0.0;
        final depthB = spriteB?.depth ?? 0.0;
        
        return depthA.compareTo(depthB);
      });
    }
  }
  
  /// Render entities in layer order (legacy method)
  void _renderEntities(double dt) {
    // Sort layers by key (lower numbers render first)
    final sortedLayers = _renderLayers.keys.toList()..sort();
    
    for (final layer in sortedLayers) {
      final entities = _renderLayers[layer]!;
      _renderLayer(entities, dt);
    }
  }
  
  /// Render a specific layer of entities
  void _renderLayer(List<GameEntity> entities, double dt) {
    for (final entity in entities) {
      _renderEntity(entity, dt);
      _entitiesRendered++;
    }
  }
  
  /// Render an individual entity with sprite component integration
  void _renderEntity(GameEntity entity, double dt) {
    final sprite = entity.getEntityComponent<GameSpriteComponent>();
    final position = entity.getEntityComponent<GamePositionComponent>();
    
    if (sprite == null || position == null) return;
    
    // Skip if sprite is not visible
    if (!sprite.isVisible) return;
    
    // Convert world position to screen position
    final screenPosition = _cameraSystem.worldToScreen(position.position);
    
    // Apply camera transformations
    final transformedSprite = _applyTransformations(sprite, screenPosition);
    
    // Render the sprite (this integrates with Flame's rendering system)
    _drawSpriteComponent(transformedSprite, screenPosition, dt);
  }
  
  /// Apply camera and entity transformations to sprite
  GameSpriteComponent _applyTransformations(GameSpriteComponent sprite, Vector2 screenPosition) {
    // Create a copy for transformation
    final transformedSprite = GameSpriteComponent(
      sprite: sprite.sprite,
      size: sprite.size.clone(),
      renderLayer: sprite.renderLayer,
      depth: sprite.depth,
      isVisible: sprite.isVisible,
      opacity: sprite.opacity,
    );
    
    // Apply camera zoom
    final scale = _cameraSystem.zoom;
    transformedSprite.scale = Vector2.all(scale);
    
    // Apply entity rotation if any
    transformedSprite.angle = sprite.angle;
    
    // Apply position
    transformedSprite.position = screenPosition;
    
    return transformedSprite;
  }
  
  /// Draw sprite component (integrates with Flame rendering)
  void _drawSpriteComponent(GameSpriteComponent sprite, Vector2 screenPosition, double dt) {
    // In a real Flame implementation, this would be handled by Flame's rendering system
    // This is the integration point where the render system connects to Flame's renderer
    
    // Update sprite properties for Flame rendering
    sprite.position = screenPosition;
    
    // Apply transformations
    if (sprite.scale != null) {
      // Apply scale transformation
    }
    
    if (sprite.opacity < 1.0) {
      // Apply opacity transformation
    }
    
    // The actual rendering would be done by Flame's built-in systems
    // This method serves as the integration point
  }
  
  /// Check if entity is visible within camera bounds (enhanced version)
  bool _isEntityVisibleEnhanced(GameEntity entity, Rect? cameraBounds) {
    final position = entity.getEntityComponent<GamePositionComponent>();
    if (position == null) return false;
    
    // If no camera bounds provided, use camera system
    if (cameraBounds != null) {
      final entityBounds = Rect.fromLTWH(
        position.position.x,
        position.position.y,
        position.size.x,
        position.size.y,
      );
      return cameraBounds.overlaps(entityBounds);
    }
    
    return _cameraSystem.isVisible(position.position, position.size);
  }
  
  /// Render debug information
  void renderDebugInfo(Canvas canvas, Size size) {
    // Debug mode would be controlled by a debug flag
    final isDebugMode = false; // This would be set from game configuration
    
    if (!isDebugMode) return;
    
    _renderEntityBounds(canvas);
    _renderCollisionBoxes(canvas);
    _renderCameraBounds(canvas);
  }
  
  /// Render entity bounding boxes for debugging
  void _renderEntityBounds(Canvas canvas) {
    final entities = _entityManager.getAllEntities();
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (final entity in entities) {
      final position = entity.getEntityComponent<GamePositionComponent>();
      if (position == null) continue;
      
      final screenPos = _cameraSystem.worldToScreen(position.position);
      final size = position.size * _cameraSystem.zoom;
      
      canvas.drawRect(
        Rect.fromLTWH(screenPos.x, screenPos.y, size.x, size.y),
        paint,
      );
    }
  }
  
  /// Render collision boxes for debugging
  void _renderCollisionBoxes(Canvas canvas) {
    final entities = _entityManager.getAllEntities();
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    for (final entity in entities) {
      final collision = entity.getEntityComponent<GameCollisionComponent>();
      if (collision == null) continue;
      
      final screenPos = _cameraSystem.worldToScreen(collision.position);
      final size = collision.size * _cameraSystem.zoom;
      
      canvas.drawRect(
        Rect.fromLTWH(screenPos.x, screenPos.y, size.x, size.y),
        paint,
      );
    }
  }
  
  /// Render camera bounds for debugging
  void _renderCameraBounds(Canvas canvas) {
    final bounds = _cameraSystem.getCameraBounds();
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, bounds.width * _cameraSystem.zoom, bounds.height * _cameraSystem.zoom),
      paint,
    );
  }
  
  /// Get render performance statistics
  Map<String, int> getRenderStats() {
    return {
      'entities_rendered': _entitiesRendered,
      'batches_rendered': _batchesRendered,
      'particles_rendered': _particlesRendered,
      'visible_entities': _visibleEntities.length,
      'render_queue_size': _renderQueue.length,
      'sprite_batches': _spriteBatches.length,
    };
  }
  
  /// Enable or disable frustum culling
  void setFrustumCulling(bool enabled) {
    _frustumCullingEnabled = enabled;
  }
  
  /// Get entities currently visible in camera
  List<GameEntity> getVisibleEntities() {
    return List.unmodifiable(_visibleEntities);
  }
  
  /// Force a render order update
  void updateRenderOrder() {
    _sortEntitiesByRenderOrder();
  }

  @override
  void dispose() {
    _renderLayers.clear();
    _spriteBatches.clear();
    _visibleEntities.clear();
    _renderQueue.clear();
    super.dispose();
  }
}

/// Render item for depth sorting and batching
class RenderItem {
  final GameEntity entity;
  final int layer;
  final double depth;
  final Vector2 position;
  
  RenderItem({
    required this.entity,
    required this.layer,
    required this.depth,
    required this.position,
  });
}