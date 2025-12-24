import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Movement system for updating entity positions based on velocity
class MovementSystem extends GameSystem implements IMovementSystem {
  late EntityManager _entityManager;
  
  @override
  int get priority => 5; // Process after physics but before collision

  @override
  Future<void> initialize() async {
    // Movement system initialization
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }

  @override
  void update(double dt) {
    updateMovement(dt);
  }
  
  @override
  void updateMovement(double dt) {
    _updatePlayerMovement(dt);
    _updateBallMovement(dt);
    _updateOtherEntities(dt);
  }
  
  /// Update player movement
  void _updatePlayerMovement(double dt) {
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    
    for (final player in players) {
      if (!player.hasEntityComponent<VelocityComponent>()) continue;
      
      final velocity = player.getEntityComponent<VelocityComponent>();
      final position = player.positionComponent;
      
      if (velocity == null) continue;
      
      // Update position based on velocity
      final deltaPosition = velocity.velocity * dt;
      final newPosition = position!.position + deltaPosition;
      
      // Update position component
      position.updatePosition(newPosition);
      
      // Update sprite position if available
      if (player.hasEntityComponent<GameSpriteComponent>()) {
        final sprite = player.getEntityComponent<GameSpriteComponent>();
        sprite?.position = newPosition;
      }
      
      // Update collision component position
      if (player.hasEntityComponent<GameCollisionComponent>()) {
        final collision = player.getEntityComponent<GameCollisionComponent>();
        collision?.position = newPosition;
      }
    }
  }
  
  /// Update ball movement
  void _updateBallMovement(double dt) {
    final balls = _entityManager.getEntitiesOfType<BallEntity>();
    
    for (final ball in balls) {
      if (!ball.isFlying) continue;
      
      final velocity = ball.velocityComponent;
      final position = ball.positionComponent;
      
      // Update position based on velocity
      final deltaPosition = velocity!.velocity * dt;
      final newPosition = position!.position + deltaPosition;
      
      // Update position component
      position.updatePosition(newPosition);
      
      // Update sprite position
      ball.spriteComponent!.position = newPosition;
      
      // Update collision component position
      ball.collisionComponent!.position = newPosition;
    }
  }
  
  /// Update other entities with velocity components
  void _updateOtherEntities(double dt) {
    final entities = _entityManager.getAllEntities();
    
    for (final entity in entities) {
      // Skip players and balls (handled separately)
      if (entity is PlayerEntity || entity is BallEntity) continue;
      
      if (!entity.hasEntityComponent<VelocityComponent>()) continue;
      if (!entity.hasEntityComponent<GamePositionComponent>()) continue;
      
      final velocity = entity.getEntityComponent<VelocityComponent>();
      final position = entity.getEntityComponent<GamePositionComponent>();
      
      if (velocity == null || position == null) continue;
      
      // Update position based on velocity
      final deltaPosition = velocity.velocity * dt;
      final newPosition = position.position + deltaPosition;
      
      // Update position component
      position.updatePosition(newPosition);
      
      // Update sprite position if available
      if (entity.hasEntityComponent<GameSpriteComponent>()) {
        final sprite = entity.getEntityComponent<GameSpriteComponent>();
        sprite?.position = newPosition;
      }
      
      // Update collision component position if available
      if (entity.hasEntityComponent<GameCollisionComponent>()) {
        final collision = entity.getEntityComponent<GameCollisionComponent>();
        collision?.position = newPosition;
      }
    }
  }
  
  /// Apply impulse to an entity
  void applyImpulse(GameEntity entity, Vector2 impulse) {
    final velocity = entity.getEntityComponent<VelocityComponent>();
    if (velocity != null) {
      velocity.velocity += impulse;
    }
  }
  
  /// Set entity velocity
  void setVelocity(GameEntity entity, Vector2 newVelocity) {
    final velocity = entity.getEntityComponent<VelocityComponent>();
    if (velocity != null) {
      velocity.velocity = newVelocity;
    }
  }
  
  /// Stop entity movement
  void stopMovement(GameEntity entity) {
    setVelocity(entity, Vector2.zero());
  }
  
  /// Get entity velocity
  Vector2? getVelocity(GameEntity entity) {
    final velocity = entity.getEntityComponent<VelocityComponent>();
    return velocity?.velocity;
  }
  
  /// Check if entity is moving
  bool isMoving(GameEntity entity) {
    final velocity = getVelocity(entity);
    return velocity != null && velocity.length > 0.1;
  }
  
  /// Get entity speed (magnitude of velocity)
  double getSpeed(GameEntity entity) {
    final velocity = getVelocity(entity);
    return velocity?.length ?? 0.0;
  }

  @override
  void dispose() {
    // Clean up resources
  }
}