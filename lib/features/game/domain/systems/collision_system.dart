import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Collision system for handling entity collisions with spatial partitioning
class CollisionSystem extends GameSystem implements ICollisionSystem {
  late EntityManager _entityManager;
  
  // References to other systems for integration
  ITileDamageSystem? _tileDamageSystem;
  IParticleSystem? _particleSystem;
  IAudioSystem? _audioSystem;
  ICameraSystem? _cameraSystem;
  
  // Spatial partitioning for performance
  final Map<String, List<GameEntity>> _spatialGrid = {};
  final Map<String, List<GameEntity>> _previousSpatialGrid = {};
  static const double gridSize = 256.0; // Further increased from 128.0 for even fewer grid cells
  
  // Performance optimization settings
  bool _spatialPartitioningEnabled = true;
  bool _broadPhaseOptimizationEnabled = true;
  int _maxCollisionChecksPerFrame = 200; // Further reduced from 500 for better performance
  int _currentFrameCollisionChecks = 0;
  
  // Collision filtering and layers
  final Map<GameCollisionType, Set<GameCollisionType>> _collisionMatrix = {};
  final Map<int, Set<GameCollisionType>> _collisionLayers = {};
  
  // Performance tracking
  int _collisionChecksThisFrame = 0;
  int _actualCollisionsThisFrame = 0;
  
  // Collision events for system integration
  final List<CollisionEvent> _collisionEvents = [];
  
  @override
  int get priority => 6; // Process after movement but before rendering

  @override
  Future<void> initialize() async {
    // Initialize collision matrix for filtering
    _initializeCollisionMatrix();
    
    // Initialize collision layers
    _initializeCollisionLayers();
  }
  
  /// Initialize collision matrix for type-based filtering
  void _initializeCollisionMatrix() {
    // Ball collisions
    _collisionMatrix[GameCollisionType.ball] = {
      GameCollisionType.tile,
      GameCollisionType.wall,
      GameCollisionType.spring,
      GameCollisionType.elevator,
    };
    
    // Player collisions
    _collisionMatrix[GameCollisionType.player] = {
      GameCollisionType.tile,
      GameCollisionType.wall,
      GameCollisionType.spring,
      GameCollisionType.elevator,
      GameCollisionType.hazard,
    };
    
    // Tile collisions (bidirectional)
    _collisionMatrix[GameCollisionType.tile] = {
      GameCollisionType.ball,
      GameCollisionType.player,
    };
    
    // Wall collisions (bidirectional)
    _collisionMatrix[GameCollisionType.wall] = {
      GameCollisionType.ball,
      GameCollisionType.player,
    };
    
    // Spring collisions
    _collisionMatrix[GameCollisionType.spring] = {
      GameCollisionType.ball,
      GameCollisionType.player,
    };
    
    // Elevator collisions
    _collisionMatrix[GameCollisionType.elevator] = {
      GameCollisionType.ball,
      GameCollisionType.player,
    };
    
    // Hazard collisions
    _collisionMatrix[GameCollisionType.hazard] = {
      GameCollisionType.player,
    };
  }
  
  /// Initialize collision layers for layer-based filtering
  void _initializeCollisionLayers() {
    // Layer 0: Environment (tiles, walls)
    _collisionLayers[0] = {
      GameCollisionType.tile,
      GameCollisionType.wall,
    };
    
    // Layer 1: Interactive elements (springs, elevators)
    _collisionLayers[1] = {
      GameCollisionType.spring,
      GameCollisionType.elevator,
    };
    
    // Layer 2: Entities (player, ball)
    _collisionLayers[2] = {
      GameCollisionType.player,
      GameCollisionType.ball,
    };
    
    // Layer 3: Hazards
    _collisionLayers[3] = {
      GameCollisionType.hazard,
    };
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
    // Reset performance counters
    _collisionChecksThisFrame = 0;
    _actualCollisionsThisFrame = 0;
    _currentFrameCollisionChecks = 0;
    _collisionEvents.clear();
    
    // Detect collisions using spatial partitioning
    detectCollisions();
    
    // Process collision events
    processCollisions(dt);
    
    // Dispatch collision events to other systems
    _dispatchCollisionEvents();
    
    // Store current grid for next frame comparison
    _storePreviousGrid();
  }
  
  /// Store current spatial grid for next frame comparison
  void _storePreviousGrid() {
    _previousSpatialGrid.clear();
    for (final entry in _spatialGrid.entries) {
      _previousSpatialGrid[entry.key] = List.from(entry.value);
    }
  }
  
  /// Dispatch collision events to integrated systems
  void _dispatchCollisionEvents() {
    for (final event in _collisionEvents) {
      _handleCollisionEvent(event);
    }
  }
  
  /// Handle a collision event by dispatching to appropriate systems
  void _handleCollisionEvent(CollisionEvent event) {
    switch (event.type) {
      case CollisionEventType.ballTileHit:
        _handleBallTileCollisionEvent(event);
        break;
      case CollisionEventType.playerGroundContact:
        _handlePlayerGroundContactEvent(event);
        break;
      case CollisionEventType.ballWallBounce:
        _handleBallWallBounceEvent(event);
        break;
      case CollisionEventType.playerHazardContact:
        _handlePlayerHazardContactEvent(event);
        break;
      case CollisionEventType.springActivation:
        _handleSpringActivationEvent(event);
        break;
    }
  }
  
  /// Handle ball-tile collision event
  void _handleBallTileCollisionEvent(CollisionEvent event) {
    final ball = event.entityA as BallEntity?;
    final tile = event.entityB as TileEntity?;
    
    if (ball == null || tile == null) return;
    
    // Apply damage through tile damage system
    if (tile.isDestructible && _tileDamageSystem != null) {
      final damage = _calculateTileDamage(tile.type);
      _tileDamageSystem!.queueDamage(tile, damage, source: 'ball_collision');
    }
    
    // Spawn particles through particle system with enhanced integration
    if (_particleSystem != null) {
      if (_particleSystem is ParticleSystem) {
        final particleSystem = _particleSystem as ParticleSystem;
        
        // Spawn impact particles
        particleSystem.spawnImpactParticles(event.position, count: 15);
        
        // Spawn material-specific particles based on tile type and state
        if (tile.isDestructible) {
          particleSystem.spawnMaterialParticles(
            event.position,
            tile.type,
            tile.currentState,
            count: _getImpactParticleCount(tile.type),
          );
        }
        
        // Spawn synchronized particles with audio
        particleSystem.spawnSynchronizedParticles(
          event.position,
          'impact',
          _getTileHitSound(tile.type),
          count: 10,
          audioSystem: _audioSystem,
        );
      } else {
        // Fallback to basic particle spawning
        _particleSystem!.spawnParticles('impact', event.position);
        
        // Material-specific particles
        final particleType = _getTileParticleType(tile.type);
        _particleSystem!.spawnParticles(particleType, event.position);
      }
    }
    
    // Play audio through audio system (if not already handled by synchronized particles)
    if (_audioSystem != null && !(_particleSystem is ParticleSystem)) {
      final soundName = _getTileHitSound(tile.type);
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(event.position);
      } else {
        _audioSystem!.playSound(soundName);
      }
    }
    
    // Request camera shake through camera system
    if (_cameraSystem != null && _cameraSystem is CameraSystem) {
      (_cameraSystem as CameraSystem).shakeFromBallImpact(
        event.position, 
        ball.velocityComponent.velocity
      );
    }
  }
  
  /// Get impact particle count based on tile type
  int _getImpactParticleCount(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return 8; // Metal - fewer sparks on impact
      case TileType.timber:
        return 12; // Wood - moderate chips
      case TileType.bricks:
        return 15; // Bricks - more dust on impact
      default:
        return 10;
    }
  }
  
  /// Handle player ground contact event
  void _handlePlayerGroundContactEvent(CollisionEvent event) {
    final player = event.entityA as PlayerEntity?;
    if (player == null) return;
    
    // Update player ground state
    player.setOnGround(true);
    
    // Play landing sound if player was falling
    if (player.velocityComponent.velocity.y > 100.0 && _audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(event.position);
      } else {
        _audioSystem!.playSound('land');
      }
    }
  }
  
  /// Handle ball wall bounce event
  void _handleBallWallBounceEvent(CollisionEvent event) {
    // Spawn impact particles
    if (_particleSystem != null) {
      _particleSystem!.spawnParticles('wall_impact', event.position);
    }
    
    // Play wall hit sound
    if (_audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(event.position);
      } else {
        _audioSystem!.playSound('wall_hit');
      }
    }
  }
  
  /// Handle player hazard contact event
  void _handlePlayerHazardContactEvent(CollisionEvent event) {
    final player = event.entityA as PlayerEntity?;
    if (player == null) return;
    
    // Kill player
    player.kill();
    
    // Play death sound
    if (_audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(event.position);
      } else {
        _audioSystem!.playSound('death');
      }
    }
    
    // Spawn death particles
    if (_particleSystem != null) {
      _particleSystem!.spawnParticles('death', event.position);
    }
  }
  
  /// Handle spring activation event
  void _handleSpringActivationEvent(CollisionEvent event) {
    // Play spring sound
    if (_audioSystem != null) {
      if (_audioSystem is AudioSystem) {
        (_audioSystem as AudioSystem).playHitSound(event.position);
      } else {
        _audioSystem!.playSound('spring');
      }
    }
    
    // Spawn spring particles
    if (_particleSystem != null) {
      _particleSystem!.spawnParticles('spring_bounce', event.position);
    }
  }
  
  @override
  void detectCollisions() {
    // Clear spatial grid
    _spatialGrid.clear();
    
    // Populate spatial grid with improved efficiency
    _populateSpatialGridOptimized();
  }
  
  @override
  void processCollisions(double dt) {
    // Check collisions with improved algorithms
    _checkCollisionsOptimized();
  }
  
  /// Optimized spatial grid population
  void _populateSpatialGridOptimized() {
    final entities = _entityManager.getAllEntities();
    
    for (final entity in entities) {
      if (!entity.hasEntityComponent<GameCollisionComponent>()) continue;
      
      final collision = entity.getEntityComponent<GameCollisionComponent>();
      if (collision == null || !collision.isActive) continue;
      
      // Calculate grid cells this entity occupies
      final gridCells = _getGridCellsOptimized(collision.position, collision.size);
      
      for (final cell in gridCells) {
        _spatialGrid.putIfAbsent(cell, () => []).add(entity);
      }
    }
  }
  
  /// Optimized grid cell calculation
  List<String> _getGridCellsOptimized(Vector2 position, Vector2 size) {
    final cells = <String>[];
    
    final minX = (position.x / gridSize).floor();
    final minY = (position.y / gridSize).floor();
    final maxX = ((position.x + size.x) / gridSize).floor();
    final maxY = ((position.y + size.y) / gridSize).floor();
    
    // Pre-allocate list size for better performance
    final expectedSize = (maxX - minX + 1) * (maxY - minY + 1);
    cells.length = expectedSize;
    
    int index = 0;
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells[index++] = '${x}_$y';
      }
    }
    
    return cells;
  }
  
  /// Optimized collision checking with filtering and performance limits
  void _checkCollisionsOptimized() {
    final checkedPairs = <String>{};
    
    for (final entities in _spatialGrid.values) {
      if (entities.length < 2) continue; // Skip cells with less than 2 entities
      
      for (int i = 0; i < entities.length; i++) {
        for (int j = i + 1; j < entities.length; j++) {
          // Check performance limit
          if (_currentFrameCollisionChecks >= _maxCollisionChecksPerFrame) {
            return; // Skip remaining checks to maintain performance
          }
          
          final entityA = entities[i];
          final entityB = entities[j];
          
          // Create unique pair identifier
          final pairId = entityA.id.compareTo(entityB.id) < 0 
              ? '${entityA.id}_${entityB.id}'
              : '${entityB.id}_${entityA.id}';
          
          if (checkedPairs.contains(pairId)) continue;
          checkedPairs.add(pairId);
          
          _collisionChecksThisFrame++;
          _currentFrameCollisionChecks++;
          
          // Broad phase optimization - quick distance check
          if (_broadPhaseOptimizationEnabled && !_quickDistanceCheck(entityA, entityB)) {
            continue;
          }
          
          // Check if entities should collide with filtering
          if (_shouldCollideWithFiltering(entityA, entityB)) {
            _handleCollisionWithEvents(entityA, entityB);
            _actualCollisionsThisFrame++;
          }
        }
      }
    }
  }
  
  /// Quick distance check for broad phase optimization
  bool _quickDistanceCheck(GameEntity entityA, GameEntity entityB) {
    final posA = entityA.getEntityComponent<GamePositionComponent>();
    final posB = entityB.getEntityComponent<GamePositionComponent>();
    
    if (posA == null || posB == null) return false;
    
    final centerA = posA.position + posA.size / 2;
    final centerB = posB.position + posB.size / 2;
    final distance = centerA.distanceTo(centerB);
    
    // Quick rejection if entities are too far apart
    final maxSize = (posA.size.length + posB.size.length) / 2;
    return distance <= maxSize * 1.5; // 50% margin for safety
  }
  
  /// Enhanced collision filtering
  bool _shouldCollideWithFiltering(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return false;
    if (!collisionA.isActive || !collisionB.isActive) return false;
    
    // Check collision matrix filtering
    if (!_canCollideByMatrix(collisionA.type, collisionB.type)) return false;
    
    // Check layer filtering
    if (!_canCollideByLayer(collisionA.layer, collisionB.layer)) return false;
    
    // Check bounding box collision
    if (!_checkBoundingBoxCollision(collisionA, collisionB)) return false;
    
    // Additional filtering for performance
    if (_isStaticStaticCollision(collisionA, collisionB)) return false;
    
    return true;
  }
  
  /// Check if two collision types can collide based on collision matrix
  bool _canCollideByMatrix(GameCollisionType typeA, GameCollisionType typeB) {
    final matrixA = _collisionMatrix[typeA];
    final matrixB = _collisionMatrix[typeB];
    
    return (matrixA?.contains(typeB) ?? false) || 
           (matrixB?.contains(typeA) ?? false);
  }
  
  /// Check if two collision layers can collide
  bool _canCollideByLayer(int layerA, int layerB) {
    // Same layer entities can always collide
    if (layerA == layerB) return true;
    
    // Check if layers are configured to interact
    final layerTypesA = _collisionLayers[layerA];
    final layerTypesB = _collisionLayers[layerB];
    
    if (layerTypesA == null || layerTypesB == null) return true;
    
    // Allow interaction between different layers by default
    return true;
  }
  
  /// Check if this is a static-static collision (can be skipped)
  bool _isStaticStaticCollision(GameCollisionComponent a, GameCollisionComponent b) {
    return a.isStatic && b.isStatic;
  }
  
  /// Handle collision with event generation
  void _handleCollisionWithEvents(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return;
    
    // Calculate collision point
    final collisionPoint = _calculateCollisionPoint(collisionA, collisionB);
    
    // Generate collision event
    final eventType = _determineCollisionEventType(entityA, entityB);
    if (eventType != null) {
      final event = CollisionEvent(
        type: eventType,
        entityA: entityA,
        entityB: entityB,
        position: collisionPoint,
        normal: _calculateCollisionNormal(collisionA, collisionB),
        timestamp: DateTime.now(),
      );
      _collisionEvents.add(event);
    }
    
    // Handle specific collision types with custom logic
    _handleSpecificCollisions(entityA, entityB, collisionA, collisionB);
    
    // Trigger collision callbacks
    collisionA.onCollision?.call(collisionB);
    collisionB.onCollision?.call(collisionA);
  }
  
  /// Calculate collision point between two collision components
  Vector2 _calculateCollisionPoint(GameCollisionComponent a, GameCollisionComponent b) {
    final centerA = a.position + a.size / 2;
    final centerB = b.position + b.size / 2;
    return (centerA + centerB) / 2;
  }
  
  /// Calculate collision normal
  Vector2 _calculateCollisionNormal(GameCollisionComponent a, GameCollisionComponent b) {
    final centerA = a.position + a.size / 2;
    final centerB = b.position + b.size / 2;
    return (centerA - centerB).normalized();
  }
  
  /// Determine collision event type based on entities
  CollisionEventType? _determineCollisionEventType(GameEntity entityA, GameEntity entityB) {
    if (_isBallTileCollision(entityA, entityB)) {
      return CollisionEventType.ballTileHit;
    } else if (_isPlayerTileCollision(entityA, entityB)) {
      return CollisionEventType.playerGroundContact;
    } else if (_isBallWallCollision(entityA, entityB)) {
      return CollisionEventType.ballWallBounce;
    } else if (_isPlayerHazardCollision(entityA, entityB)) {
      return CollisionEventType.playerHazardContact;
    } else if (_isSpringCollision(entityA, entityB)) {
      return CollisionEventType.springActivation;
    }
    
    return null;
  }
  
  /// Check if collision is between ball and tile
  bool _isBallTileCollision(GameEntity entityA, GameEntity entityB) {
    return (entityA is BallEntity && entityB is TileEntity) ||
           (entityA is TileEntity && entityB is BallEntity);
  }
  
  /// Check if collision is between player and tile
  bool _isPlayerTileCollision(GameEntity entityA, GameEntity entityB) {
    return (entityA is PlayerEntity && entityB is TileEntity) ||
           (entityA is TileEntity && entityB is PlayerEntity);
  }
  
  /// Check if collision is between ball and wall
  bool _isBallWallCollision(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return false;
    
    return (entityA is BallEntity && collisionB.type == GameCollisionType.wall) ||
           (entityB is BallEntity && collisionA.type == GameCollisionType.wall);
  }
  
  /// Check if collision is between player and hazard
  bool _isPlayerHazardCollision(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return false;
    
    return (entityA is PlayerEntity && collisionB.type == GameCollisionType.hazard) ||
           (entityB is PlayerEntity && collisionA.type == GameCollisionType.hazard);
  }
  
  /// Check if collision involves a spring
  bool _isSpringCollision(GameEntity entityA, GameEntity entityB) {
    final collisionA = entityA.getEntityComponent<GameCollisionComponent>();
    final collisionB = entityB.getEntityComponent<GameCollisionComponent>();
    
    if (collisionA == null || collisionB == null) return false;
    
    return collisionA.type == GameCollisionType.spring || 
           collisionB.type == GameCollisionType.spring;
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
  
  /// Handle specific collision types with custom logic
  void _handleSpecificCollisions(
    GameEntity entityA, 
    GameEntity entityB, 
    GameCollisionComponent collisionA, 
    GameCollisionComponent collisionB
  ) {
    // Ball-Tile collisions
    if (_isBallTileCollisionLegacy(collisionA, collisionB)) {
      _handleBallTileCollision(entityA, entityB, collisionA, collisionB);
    }
    
    // Player-Tile collisions (for ground detection)
    if (_isPlayerTileCollisionLegacy(collisionA, collisionB)) {
      _handlePlayerTileCollision(entityA, entityB, collisionA, collisionB);
    }
    
    // Ball-Wall collisions
    if (_isBallWallCollisionLegacy(collisionA, collisionB)) {
      _handleBallWallCollision(entityA, entityB, collisionA, collisionB);
    }
  }
  
  /// Check if collision is between ball and tile (legacy)
  bool _isBallTileCollisionLegacy(GameCollisionComponent a, GameCollisionComponent b) {
    return (a.type == GameCollisionType.ball && b.type == GameCollisionType.tile) ||
           (a.type == GameCollisionType.tile && b.type == GameCollisionType.ball);
  }
  
  /// Check if collision is between player and tile (legacy)
  bool _isPlayerTileCollisionLegacy(GameCollisionComponent a, GameCollisionComponent b) {
    return (a.type == GameCollisionType.player && b.type == GameCollisionType.tile) ||
           (a.type == GameCollisionType.tile && b.type == GameCollisionType.player);
  }
  
  /// Check if collision is between ball and wall (legacy)
  bool _isBallWallCollisionLegacy(GameCollisionComponent a, GameCollisionComponent b) {
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
      if (_particleSystem is ParticleSystem) {
        final particleSystem = _particleSystem as ParticleSystem;
        
        // Spawn impact particles at collision point
        particleSystem.spawnImpactParticles(ballCenter, count: 15);
        
        // Spawn material-specific particles if tile is destructible
        if (tile.isDestructible) {
          particleSystem.spawnMaterialParticles(
            ballCenter,
            tile.type,
            tile.currentState,
            count: _getImpactParticleCount(tile.type),
          );
        }
      } else {
        // Fallback to basic particle spawning
        _particleSystem!.spawnParticles('impact', ballCenter);
      }
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
  
  /// Get particle type for tile material
  String _getTileParticleType(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return 'metal_sparks';
      case TileType.timber:
        return 'wood_chips';
      case TileType.bricks:
        return 'brick_dust';
      case TileType.beam:
        return 'metal_sparks';
      case TileType.indestructible:
        return 'sparks';
    }
  }
  
  /// Get hit sound for tile material
  String _getTileHitSound(TileType tileType) {
    switch (tileType) {
      case TileType.scaffolding:
        return 'metal_hit';
      case TileType.timber:
        return 'wood_hit';
      case TileType.bricks:
        return 'brick_hit';
      case TileType.beam:
        return 'metal_hit';
      case TileType.indestructible:
        return 'hard_hit';
    }
  }
  
  /// Get collision performance metrics
  Map<String, int> getPerformanceMetrics() {
    return {
      'collision_checks': _collisionChecksThisFrame,
      'actual_collisions': _actualCollisionsThisFrame,
      'spatial_grid_cells': _spatialGrid.length,
      'collision_events': _collisionEvents.length,
      'max_checks_per_frame': _maxCollisionChecksPerFrame,
      'current_frame_checks': _currentFrameCollisionChecks,
    };
  }
  
  /// Optimize collision detection performance
  void optimizePerformance({
    int? maxCollisionChecksPerFrame,
    bool? enableBroadPhaseOptimization,
    bool? enableSpatialPartitioning,
    double? gridSize,
  }) {
    if (maxCollisionChecksPerFrame != null) {
      _maxCollisionChecksPerFrame = maxCollisionChecksPerFrame;
    }
    
    if (enableBroadPhaseOptimization != null) {
      _broadPhaseOptimizationEnabled = enableBroadPhaseOptimization;
    }
    
    if (enableSpatialPartitioning != null) {
      _spatialPartitioningEnabled = enableSpatialPartitioning;
    }
    
    if (gridSize != null) {
      // Note: Changing grid size would require rebuilding the spatial grid
      // For now, we'll just store the preference
    }
  }
  
  /// Get performance optimization status
  Map<String, dynamic> getOptimizationStatus() {
    return {
      'spatial_partitioning_enabled': _spatialPartitioningEnabled,
      'broad_phase_optimization_enabled': _broadPhaseOptimizationEnabled,
      'max_collision_checks_per_frame': _maxCollisionChecksPerFrame,
      'grid_size': gridSize,
      'current_performance': {
        'checks_this_frame': _collisionChecksThisFrame,
        'collisions_this_frame': _actualCollisionsThisFrame,
        'efficiency': _collisionChecksThisFrame > 0 
            ? (_actualCollisionsThisFrame / _collisionChecksThisFrame * 100).toStringAsFixed(1) + '%'
            : '0%',
      },
    };
  }
  
  /// Configure collision layer interactions
  void setLayerInteraction(int layerA, int layerB, bool canInteract) {
    // Implementation for dynamic layer configuration
    // This would be used for advanced collision filtering
  }
  
  /// Add custom collision type to matrix
  void addCollisionType(GameCollisionType type, Set<GameCollisionType> collidesWith) {
    _collisionMatrix[type] = collidesWith;
  }
  
  /// Remove collision type from matrix
  void removeCollisionType(GameCollisionType type) {
    _collisionMatrix.remove(type);
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
    final gridCells = _getGridCellsOptimized(position, size);
    
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
    _previousSpatialGrid.clear();
    _collisionMatrix.clear();
    _collisionLayers.clear();
    _collisionEvents.clear();
    super.dispose();
  }
}

/// Collision event for system integration
class CollisionEvent {
  final CollisionEventType type;
  final GameEntity entityA;
  final GameEntity entityB;
  final Vector2 position;
  final Vector2 normal;
  final DateTime timestamp;
  
  CollisionEvent({
    required this.type,
    required this.entityA,
    required this.entityB,
    required this.position,
    required this.normal,
    required this.timestamp,
  });
}

/// Types of collision events
enum CollisionEventType {
  ballTileHit,
  playerGroundContact,
  ballWallBounce,
  playerHazardContact,
  springActivation,
}