import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Collision system for handling entity collisions
class CollisionSystem extends GameSystem implements ICollisionSystem {
  late EntityManager _entityManager;
  
  // References to other systems for integration
  ITileDamageSystem? _tileDamageSystem;
  IParticleSystem? _particleSystem;
  IAudioSystem? _audioSystem;
  ICameraSystem? _cameraSystem;
  
  // Spatial partitioning for performance
  final Map<String, List<GameEntity>> _spatialGrid = {};
  static const double gridSize = 64.0;
  
  @override
  int get priority => 6; // Process after movement but before rendering

  @override
  Future<void> initialize() async {
    // Collision system initialization
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }
  
  /// Set tile damage system for integration
  void setTileDamageSystem(ITileDamageSystem tileDamageSystem) {
    _tileDamageSystem = tileDamageSystem;
  }
  
  /// Set particle system for integration
  void setParticleSystem(IParticleSystem particleSystem) {
    _particleSystem = particleSystem;
  }
  
  /// Set audio system for integration
  void setAudioSystem(IAudioSystem audioSystem) {
    _audioSystem = audioSystem;
  }
  
  /// Set camera system for integration
  void setCameraSystem(ICameraSystem cameraSystem) {
    _cameraSystem = cameraSystem;
  }

  @override
  void update(double dt) {
    detectCollisions();
    processCollisions(dt);
  }
  
  @override
  void detectCollisions() {
    // Clear spatial grid
    _spatialGrid.clear();
    
    // Populate spatial grid
    _populateSpatialGrid();
  }
  
  @override
  void processCollisions(double dt) {
    // Check collisions
    _checkCollisions();
  }
  
  /// Populate spatial grid for efficient collision detection
  void _populateSpatialGrid() {
    final entities = _entityManager.getAllEntities();
    
    for (final entity in entities) {
      if (!entity.hasEntityComponent<GameCollisionComponent>()) continue;
      
      final collision = entity.getEntityComponent<GameCollisionComponent>();
      if (collision == null) continue;
      
      // Calculate grid cells this entity occupies
      final gridCells = _getGridCells(collision.position, collision.size);
      
      for (final cell in gridCells) {
        _spatialGrid.putIfAbsent(cell, () => []).add(entity);
      }
    }
  }
  
  /// Get grid cells that an entity occupies
  List<String> _getGridCells(Vector2 position, Vector2 size) {
    final cells = <String>[];
    
    final minX = (position.x / gridSize).floor();
    final minY = (position.y / gridSize).floor();
    final maxX = ((position.x + size.x) / gridSize).floor();
    final maxY = ((position.y + size.y) / gridSize).floor();
    
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add('${x}_$y');
      }
    }
    
    return cells;
  }
  
  /// Check collisions between entities
  void _checkCollisions() {
    final checkedPairs = <String>{};
    
    for (final entities in _spatialGrid.values) {
      for (int i = 0; i < entities.length; i++) {
        for (int j = i + 1; j < entities.length; j++) {
          final entityA = entities[i];
          final entityB = entities[j];
          
          // Create unique pair identifier
          final pairId = '${entityA.id}_${entityB.id}';
          if (checkedPairs.contains(pairId)) continue;
          checkedPairs.add(pairId);
          
          // Check if entities should collide
          if (_shouldCollide(entityA, entityB)) {
            _handleCollision(entityA, entityB);
          }
        }
      }
    }
  }
  
  /// Check if two entities should collide
  bool _shouldCollide(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return false;
    
    // Check if collision types are compatible
    if (!collisionA.collidesWith.contains(collisionB.type)) return false;
    if (!collisionB.collidesWith.contains(collisionA.type)) return false;
    
    // Check bounding box collision
    return _checkBoundingBoxCollision(collisionA, collisionB);
  }
  
  /// Check bounding box collision between two collision components
  bool _checkBoundingBoxCollision(GameCollisionComponent a, GameCollisionComponent b) {
    final aLeft = a.position.x;
    final aRight = a.position.x + a.size.x;
    final aTop = a.position.y;
    final aBottom = a.position.y + a.size.y;
    
    final bLeft = b.position.x;
    final bRight = b.position.x + b.size.x;
    final bTop = b.position.y;
    final bBottom = b.position.y + b.size.y;
    
    return !(aRight < bLeft || aLeft > bRight || aBottom < bTop || aTop > bBottom);
  }
  
  /// Handle collision between two entities
  void _handleCollision(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return;
    
    // Handle specific collision types
    _handleSpecificCollisions(entityA, entityB, collisionA, collisionB);
    
    // Trigger collision callbacks
    collisionA.onCollision?.call(collisionB);
    collisionB.onCollision?.call(collisionA);
  }
  
  /// Handle specific collision types with custom logic
  void _handleSpecificCollisions(
    GameEntity entityA, 
    GameEntity entityB, 
    GameCollisionComponent collisionA, 
    GameCollisionComponent collisionB
  ) {
    // Ball-Tile collisions
    if (_isBallTileCollision(collisionA, collisionB)) {
      _handleBallTileCollision(entityA, entityB, collisionA, collisionB);
    }
    
    // Player-Tile collisions (for ground detection)
    if (_isPlayerTileCollision(collisionA, collisionB)) {
      _handlePlayerTileCollision(entityA, entityB, collisionA, collisionB);
    }
    
    // Ball-Wall collisions
    if (_isBallWallCollision(collisionA, collisionB)) {
      _handleBallWallCollision(entityA, entityB, collisionA, collisionB);
    }
  }
  
  /// Check if collision is between ball and tile
  bool _isBallTileCollision(GameCollisionComponent a, GameCollisionComponent b) {
    return (a.type == GameCollisionType.ball && b.type == GameCollisionType.tile) ||
           (a.type == GameCollisionType.tile && b.type == GameCollisionType.ball);
  }
  
  /// Check if collision is between player and tile
  bool _isPlayerTileCollision(GameCollisionComponent a, GameCollisionComponent b) {
    return (a.type == GameCollisionType.player && b.type == GameCollisionType.tile) ||
           (a.type == GameCollisionType.tile && b.type == GameCollisionType.player);
  }
  
  /// Check if collision is between ball and wall
  bool _isBallWallCollision(GameCollisionComponent a, GameCollisionComponent b) {
    return (a.type == GameCollisionType.ball && b.type == GameCollisionType.wall) ||
           (a.type == GameCollisionType.wall && b.type == GameCollisionType.ball);
  }
  
  /// Handle ball-tile collision
  void _handleBallTileCollision(
    GameEntity entityA, 
    GameEntity entityB, 
    GameCollisionComponent collisionA, 
    GameCollisionComponent collisionB
  ) {
    BallEntity? ball;
    TileEntity? tile;
    
    if (entityA is BallEntity && entityB is TileEntity) {
      ball = entityA;
      tile = entityB;
    } else if (entityA is TileEntity && entityB is BallEntity) {
      tile = entityA;
      ball = entityB;
    }
    
    if (ball == null || tile == null) return;
    if (ball.currentState != BallState.flying) return;
    
    // Calculate collision normal
    final ballCenter = ball.positionComponent.position + Vector2(BallEntity.ballRadius, BallEntity.ballRadius);
    final tileCenter = tile.positionComponent.position + tile.positionComponent.size / 2;
    final collisionNormal = (ballCenter - tileCenter).normalized();
    
    // Bounce ball
    final velocity = ball.velocityComponent.velocity;
    ball.velocityComponent.velocity = velocity.reflected(collisionNormal);
    
    // Apply damage to tile through damage system
    if (tile.isDestructible && _tileDamageSystem != null) {
      // Determine damage based on tile type
      int damage = _calculateTileDamage(tile.type);
      _tileDamageSystem!.queueDamage(tile, damage, source: 'ball_collision');
    }
    
    // Spawn impact particles through particle system
    if (_particleSystem != null) {
      _particleSystem!.spawnParticles('impact', ballCenter);
    }
    
    // Play collision sound through audio system
    if (_audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(ballCenter);
      } else {
        _audioSystem!.playSound('hit');
      }
    }
    
    // Request camera shake through camera system
    if (_cameraSystem != null) {
      if (_cameraSystem is CameraSystem) {
        (_cameraSystem as CameraSystem).shakeFromBallImpact(ballCenter, ball.velocityComponent.velocity);
      } else {
        // Fallback to ball's callback
        ball.onCameraShakeRequest?.call(ball.velocityComponent.velocity);
      }
    }
    
    // Trigger ball's tile hit callback for additional effects
    ball.onTileHit?.call(tile, ballCenter, collisionNormal);
  }
  
  /// Calculate damage based on tile type and ball impact
  int _calculateTileDamage(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return 1; // Scaffolding breaks in one hit
      case TileType.timber:
        return 1; // Timber takes 2 hits total, so 1 damage per hit
      case TileType.bricks:
        return 1; // Bricks take 3 hits total, so 1 damage per hit
      case TileType.beam:
      case TileType.indestructible:
        return 0; // Indestructible tiles take no damage
    }
  }
  
  /// Handle player-tile collision (for ground detection)
  void _handlePlayerTileCollision(
    GameEntity entityA, 
    GameEntity entityB, 
    GameCollisionComponent collisionA, 
    GameCollisionComponent collisionB
  ) {
    PlayerEntity? player;
    TileEntity? tile;
    
    if (entityA is PlayerEntity && entityB is TileEntity) {
      player = entityA;
      tile = entityB;
    } else if (entityA is TileEntity && entityB is PlayerEntity) {
      tile = entityA;
      player = entityB;
    }
    
    if (player == null || tile == null) return;
    
    // Check if player is on top of tile (ground detection)
    final playerBottom = player.positionComponent.position.y + player.positionComponent.size.y;
    final tileTop = tile.positionComponent.position.y;
    
    if (playerBottom <= tileTop + 5.0) { // Small tolerance
      player.setOnGround(true);
    }
  }
  
  /// Handle ball-wall collision
  void _handleBallWallCollision(
    GameEntity entityA, 
    GameEntity entityB, 
    GameCollisionComponent collisionA, 
    GameCollisionComponent collisionB
  ) {
    BallEntity? ball;
    GameCollisionComponent? wall;
    
    if (entityA is BallEntity) {
      ball = entityA;
      wall = collisionB;
    } else if (entityB is BallEntity) {
      ball = entityB;
      wall = collisionA;
    }
    
    if (ball == null || wall == null) return;
    if (ball.currentState != BallState.flying) return;
    
    // Calculate collision normal (simplified)
    final ballCenter = ball.positionComponent.position + Vector2(BallEntity.ballRadius, BallEntity.ballRadius);
    final wallCenter = wall.position + wall.size / 2;
    final collisionNormal = (ballCenter - wallCenter).normalized();
    
    // Bounce ball
    final velocity = ball.velocityComponent.velocity;
    ball.velocityComponent.velocity = velocity.reflected(collisionNormal);
    
    // Spawn impact particles
    if (_particleSystem != null) {
      _particleSystem!.spawnParticles('impact', ballCenter);
    }
    
    // Play wall hit sound
    if (_audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(ballCenter);
      } else {
        _audioSystem!.playSound('hit');
      }
    }
    
    // Trigger camera shake
    if (_cameraSystem != null && _cameraSystem is CameraSystem) {
      (_cameraSystem as CameraSystem).shakeFromBallImpact(ballCenter, ball.velocityComponent.velocity);
    } else {
      ball.onCameraShakeRequest?.call(ball.velocityComponent.velocity);
    }
  }
  
  /// Get all entities in a specific area
  List<GameEntity> getEntitiesInArea(Vector2 position, Vector2 size) {
    final entities = <GameEntity>[];
    final gridCells = _getGridCells(position, size);
    
    for (final cell in gridCells) {
      final cellEntities = _spatialGrid[cell];
      if (cellEntities != null) {
        entities.addAll(cellEntities);
      }
    }
    
    return entities.toSet().toList(); // Remove duplicates
  }
  
  /// Check if a point collides with any entity of a specific type
  GameEntity? getEntityAtPoint(Vector2 point, GameCollisionType type) {
    final gridCell = '${(point.x / gridSize).floor()}_${(point.y / gridSize).floor()}';
    final entities = _spatialGrid[gridCell];
    
    if (entities == null) return null;
    
    for (final entity in entities) {
      final collision = entity.getEntityComponent<GameCollisionComponent>();
      if (collision == null || collision.type != type) continue;
      
      if (_pointInBounds(point, collision.position, collision.size)) {
        return entity;
      }
    }
    
    return null;
  }
  
  /// Check if a point is within bounds
  bool _pointInBounds(Vector2 point, Vector2 position, Vector2 size) {
    return point.x >= position.x &&
           point.x <= position.x + size.x &&
           point.y >= position.y &&
           point.y <= position.y + size.y;
  }

  @override
  void dispose() {
    _spatialGrid.clear();
    super.dispose();
  }
}