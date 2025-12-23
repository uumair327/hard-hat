import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/components/position_component.dart';
import 'package:hard_hat/features/game/domain/components/collision_component.dart';
import 'package:hard_hat/features/game/domain/components/velocity_component.dart';

/// System responsible for collision detection and response with spatial partitioning
class CollisionSystem extends GameSystem {
  @override
  int get priority => 200; // Execute after movement

  /// List of collision pairs detected this frame
  final List<CollisionPair> _collisionPairs = [];
  
  /// Spatial hash grid for broad phase collision detection
  SpatialHashGrid? _spatialGrid;
  
  /// Collision layers for filtering
  final Map<GameCollisionType, Set<GameCollisionType>> _collisionMatrix = {};

  @override
  Future<void> initialize() async {
    // Initialize spatial grid with cell size of 64x64 pixels
    _spatialGrid = SpatialHashGrid(cellSize: 64.0);
    
    // Setup collision matrix - define which types can collide with each other
    _setupCollisionMatrix();
  }

  void _setupCollisionMatrix() {
    // Player collides with tiles, walls, springs, elevators
    _collisionMatrix[GameCollisionType.player] = {
      GameCollisionType.tile,
      GameCollisionType.wall,
      GameCollisionType.spring,
      GameCollisionType.elevator,
      GameCollisionType.sensor,
    };
    
    // Ball collides with tiles, walls, player
    _collisionMatrix[GameCollisionType.ball] = {
      GameCollisionType.tile,
      GameCollisionType.wall,
      GameCollisionType.player,
      GameCollisionType.sensor,
    };
    
    // Tiles collide with player and ball
    _collisionMatrix[GameCollisionType.tile] = {
      GameCollisionType.player,
      GameCollisionType.ball,
    };
    
    // Walls collide with everything except sensors
    _collisionMatrix[GameCollisionType.wall] = {
      GameCollisionType.player,
      GameCollisionType.ball,
    };
    
    // Springs collide with player
    _collisionMatrix[GameCollisionType.spring] = {
      GameCollisionType.player,
    };
    
    // Elevators collide with player
    _collisionMatrix[GameCollisionType.elevator] = {
      GameCollisionType.player,
    };
    
    // Sensors collide with everything (but don't block movement)
    _collisionMatrix[GameCollisionType.sensor] = {
      GameCollisionType.player,
      GameCollisionType.ball,
    };
  }

  @override
  void updateSystem(double dt) {
    _collisionPairs.clear();
    _spatialGrid?.clear();
    
    // Get all entities with collision components
    final collidableEntities = getComponents<Component>()
        .where((entity) => 
            entity.children.any((c) => c is GamePositionComponent) &&
            entity.children.any((c) => c is GameCollisionComponent))
        .toList();

    // Populate spatial grid (broad phase)
    for (final entity in collidableEntities) {
      final position = entity.children.whereType<GamePositionComponent>().firstOrNull;
      final collision = entity.children.whereType<GameCollisionComponent>().firstOrNull;
      
      if (position != null && collision != null) {
        final bounds = collision.hitbox.toRect().translate(position.position.x, position.position.y);
        _spatialGrid?.insert(entity, bounds);
      }
    }

    // Narrow phase collision detection using spatial grid
    for (final entity in collidableEntities) {
      final position = entity.children.whereType<GamePositionComponent>().firstOrNull;
      final collision = entity.children.whereType<GameCollisionComponent>().firstOrNull;
      
      if (position != null && collision != null) {
        final bounds = collision.hitbox.toRect().translate(position.position.x, position.position.y);
        final nearbyEntities = _spatialGrid?.query(bounds) ?? <Component>{};
        
        for (final otherEntity in nearbyEntities) {
          if (entity != otherEntity && _checkCollision(entity, otherEntity)) {
            final pair = CollisionPair(entity, otherEntity);
            if (!_collisionPairs.contains(pair)) {
              _collisionPairs.add(pair);
            }
          }
        }
      }
    }

    // Handle collision responses
    for (final pair in _collisionPairs) {
      _handleCollisionResponse(pair, dt);
    }
  }

  bool _checkCollision(Component entityA, Component entityB) {
    final posA = entityA.children.whereType<GamePositionComponent>().firstOrNull;
    final posB = entityB.children.whereType<GamePositionComponent>().firstOrNull;
    final collisionA = entityA.children.whereType<GameCollisionComponent>().firstOrNull;
    final collisionB = entityB.children.whereType<GameCollisionComponent>().firstOrNull;

    if (posA == null || posB == null || collisionA == null || collisionB == null) {
      return false;
    }

    // Check collision matrix for type compatibility
    final canCollide = _collisionMatrix[collisionA.type]?.contains(collisionB.type) ?? false;
    if (!canCollide) {
      return false;
    }

    // AABB collision detection
    final rectA = collisionA.hitbox.toRect().translate(posA.position.x, posA.position.y);
    final rectB = collisionB.hitbox.toRect().translate(posB.position.x, posB.position.y);

    return rectA.overlaps(rectB);
  }

  void _handleCollisionResponse(CollisionPair pair, double dt) {
    final posA = pair.entityA.children.whereType<GamePositionComponent>().firstOrNull;
    final posB = pair.entityB.children.whereType<GamePositionComponent>().firstOrNull;
    final collisionA = pair.entityA.children.whereType<GameCollisionComponent>().firstOrNull;
    final collisionB = pair.entityB.children.whereType<GameCollisionComponent>().firstOrNull;
    final velocityA = pair.entityA.children.whereType<VelocityComponent>().firstOrNull;
    final velocityB = pair.entityB.children.whereType<VelocityComponent>().firstOrNull;

    if (posA == null || posB == null || collisionA == null || collisionB == null) {
      return;
    }

    // Calculate collision normal and penetration
    final rectA = collisionA.hitbox.toRect().translate(posA.position.x, posA.position.y);
    final rectB = collisionB.hitbox.toRect().translate(posB.position.x, posB.position.y);
    
    final overlapX = math.min(rectA.right, rectB.right) - math.max(rectA.left, rectB.left);
    final overlapY = math.min(rectA.bottom, rectB.bottom) - math.max(rectA.top, rectB.top);
    
    Vector2 normal;
    double penetration;
    
    if (overlapX < overlapY) {
      // Horizontal collision
      normal = Vector2(rectA.center.dx < rectB.center.dx ? -1 : 1, 0);
      penetration = overlapX;
    } else {
      // Vertical collision
      normal = Vector2(0, rectA.center.dy < rectB.center.dy ? -1 : 1);
      penetration = overlapY;
    }

    // Handle different collision response types
    _handleSpecificCollisionResponse(
      pair.entityA, pair.entityB,
      collisionA, collisionB,
      posA, posB,
      velocityA, velocityB,
      normal, penetration, dt
    );

    // Trigger collision callbacks
    collisionA.handleCollision(collisionB);
    collisionB.handleCollision(collisionA);
  }

  void _handleSpecificCollisionResponse(
    Component entityA, Component entityB,
    GameCollisionComponent collisionA, GameCollisionComponent collisionB,
    GamePositionComponent posA, GamePositionComponent posB,
    VelocityComponent? velocityA, VelocityComponent? velocityB,
    Vector2 normal, double penetration, double dt
  ) {
    // Don't resolve sensor collisions physically
    if (collisionA.isSensor || collisionB.isSensor) {
      return;
    }

    // Determine which entity should be moved (prefer moving dynamic objects)
    final aIsDynamic = velocityA != null;
    final bIsDynamic = velocityB != null;
    
    if (aIsDynamic && !bIsDynamic) {
      // Move A away from B
      _resolveCollision(posA, velocityA, normal, penetration, 1.0);
    } else if (!aIsDynamic && bIsDynamic) {
      // Move B away from A
      _resolveCollision(posB, velocityB, -normal, penetration, 1.0);
    } else if (aIsDynamic && bIsDynamic) {
      // Both dynamic - split the resolution
      _resolveCollision(posA, velocityA, normal, penetration, 0.5);
      _resolveCollision(posB, velocityB, -normal, penetration, 0.5);
    }
    // If neither is dynamic, no position resolution needed
  }

  void _resolveCollision(
    GamePositionComponent position,
    VelocityComponent velocity,
    Vector2 normal,
    double penetration,
    double factor
  ) {
    // Separate objects
    final separation = normal * (penetration * factor);
    position.position.add(separation);
    
    // Apply collision response to velocity
    final velocityDotNormal = velocity.velocity.dot(normal);
    if (velocityDotNormal < 0) {
      // Objects are moving towards each other
      final restitution = 0.3; // Bounce factor
      final impulse = normal * (-(1 + restitution) * velocityDotNormal);
      velocity.velocity.add(impulse);
    }
  }

  /// Get all collision pairs from this frame
  List<CollisionPair> get collisionPairs => List.unmodifiable(_collisionPairs);

  /// Check if two collision types can collide
  bool canTypesCollide(GameCollisionType typeA, GameCollisionType typeB) {
    return _collisionMatrix[typeA]?.contains(typeB) ?? false;
  }

  @override
  void dispose() {
    _collisionPairs.clear();
    _spatialGrid?.clear();
  }
}

/// Represents a collision between two entities
class CollisionPair {
  final Component entityA;
  final Component entityB;

  CollisionPair(this.entityA, this.entityB);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollisionPair &&
        ((other.entityA == entityA && other.entityB == entityB) ||
         (other.entityA == entityB && other.entityB == entityA));
  }

  @override
  int get hashCode => entityA.hashCode ^ entityB.hashCode;
}

/// Spatial hash grid for efficient broad-phase collision detection
class SpatialHashGrid {
  final double cellSize;
  final Map<int, Set<Component>> _grid = {};

  SpatialHashGrid({required this.cellSize});

  /// Insert an entity into the spatial grid
  void insert(Component entity, Rect bounds) {
    final cells = _getCellsForBounds(bounds);
    for (final cellHash in cells) {
      _grid.putIfAbsent(cellHash, () => <Component>{});
      _grid[cellHash]?.add(entity);
    }
  }

  /// Query entities in the same cells as the given bounds
  Set<Component> query(Rect bounds) {
    final result = <Component>{};
    final cells = _getCellsForBounds(bounds);
    
    for (final cellHash in cells) {
      final cellEntities = _grid[cellHash];
      if (cellEntities != null) {
        result.addAll(cellEntities);
      }
    }
    
    return result;
  }

  /// Clear the spatial grid
  void clear() {
    _grid.clear();
  }

  /// Get all cell hashes that the bounds intersect
  Set<int> _getCellsForBounds(Rect bounds) {
    final cells = <int>{};
    
    final minX = (bounds.left / cellSize).floor();
    final maxX = (bounds.right / cellSize).floor();
    final minY = (bounds.top / cellSize).floor();
    final maxY = (bounds.bottom / cellSize).floor();
    
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add(_hashCell(x, y));
      }
    }
    
    return cells;
  }

  /// Hash function for grid cells
  int _hashCell(int x, int y) {
    // Simple hash function - can be improved for better distribution
    return (x * 73856093) ^ (y * 19349663);
  }
}