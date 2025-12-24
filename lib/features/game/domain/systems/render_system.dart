import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Render system for drawing entities to the screen
class RenderSystem extends GameSystem implements IRenderSystem {
  late EntityManager _entityManager;
  late CameraSystem _cameraSystem;
  
  // Render layers for proper draw order
  final Map<int, List<GameEntity>> _renderLayers = {};
  
  @override
  int get priority => 9; // Process last to render everything

  @override
  Future<void> initialize() async {
    // Render system initialization
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }
  
  /// Set camera system for viewport calculations
  void setCameraSystem(CameraSystem cameraSystem) {
    _cameraSystem = cameraSystem;
  }

  @override
  void update(double dt) {
    renderEntities(dt);
  }
  
  @override
  void renderEntities(double dt) {
    _sortEntitiesByRenderLayer();
    _renderEntities(dt);
  }
  
  @override
  void enableBatching(bool enabled) {
    // Batching implementation would go here
  }
  
  @override
  void setMaxBatchSize(int size) {
    // Max batch size implementation would go here
  }
  
  /// Sort entities by render layer for proper draw order
  void _sortEntitiesByRenderLayer() {
    _renderLayers.clear();
    
    final entities = _entityManager.getAllEntities();
    
    for (final entity in entities) {
      if (!entity.hasEntityComponent<GameSpriteComponent>()) continue;
      
      final sprite = entity.getEntityComponent<GameSpriteComponent>();
      if (sprite == null) continue;
      
      final layer = sprite.renderLayer;
      _renderLayers.putIfAbsent(layer, () => []).add(entity);
    }
  }
  
  /// Render entities in layer order
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
    }
  }
  
  /// Render an individual entity
  void _renderEntity(GameEntity entity, double dt) {
    final sprite = entity.getEntityComponent<GameSpriteComponent>();
    final position = entity.getEntityComponent<GamePositionComponent>();
    
    if (sprite == null || position == null) return;
    
    // Check if entity is visible in camera bounds
    if (!_isEntityVisible(entity)) return;
    
    // Convert world position to screen position
    final screenPosition = _cameraSystem.worldToScreen(position.position);
    
    // Render the sprite (this would be handled by Flame's rendering system)
    _drawSprite(sprite, screenPosition, dt);
  }
  
  /// Check if entity is visible in camera bounds
  bool _isEntityVisible(GameEntity entity) {
    final position = entity.getEntityComponent<GamePositionComponent>();
    if (position == null) return false;
    
    return _cameraSystem.isVisible(position.position, position.size);
  }
  
  /// Draw sprite at screen position (placeholder for Flame rendering)
  void _drawSprite(GameSpriteComponent sprite, Vector2 screenPosition, double dt) {
    // In a real Flame implementation, this would be handled by Flame's rendering system
    // This is just a placeholder to show the render system structure
    
    // Update sprite position for Flame rendering
    sprite.position = screenPosition;
    
    // Apply camera zoom
    final scale = _cameraSystem.zoom;
    sprite.scale = Vector2.all(scale);
    
    // Apply opacity
    if (sprite.opacity < 1.0) {
      // Handle transparency (would be done in Flame's render method)
    }
  }
  
  /// Render debug information
  void renderDebugInfo(Canvas canvas, Size size) {
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
  
  /// Get entities in render order
  List<GameEntity> getEntitiesInRenderOrder() {
    final result = <GameEntity>[];
    final sortedLayers = _renderLayers.keys.toList()..sort();
    
    for (final layer in sortedLayers) {
      result.addAll(_renderLayers[layer]!);
    }
    
    return result;
  }
  
  /// Get entities in a specific render layer
  List<GameEntity> getEntitiesInLayer(int layer) {
    return _renderLayers[layer] ?? [];
  }
  
  /// Set debug mode
  bool isDebugMode = false;
  
  void setDebugMode(bool debug) {
    isDebugMode = debug;
  }

  @override
  void dispose() {
    _renderLayers.clear();
    super.dispose();
  }
}