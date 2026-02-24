import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Beam entity that moves when the player stands on it
class PlayerBeamEntity extends GameEntity {
  late final GamePositionComponent _positionComponent;
  late final VelocityComponent _velocityComponent;
  late final GameCollisionComponent _collisionComponent;
  late final GameSpriteComponent _spriteComponent;

  /// The player currently standing on the beam
  PlayerEntity? currentPlayer;

  PlayerBeamEntity({required super.id, required Vector2 position}) {
    _positionComponent = GamePositionComponent(
      position: position,
      size: Vector2(64, 16),
    );

    _velocityComponent = VelocityComponent();

    _collisionComponent = GameCollisionComponent(
      hitbox: RectangleHitbox(size: Vector2(64, 16)),
      type: GameCollisionType.wall,
      isStatic: false,
      onCollision: _handleCollision,
      onCollisionEnd: _handleCollisionEnd,
      size: Vector2(64, 16),
      position: position,
    );

    _spriteComponent = GameSpriteComponent(
      size: Vector2(64, 16),
      position: position,
    );
  }

  @override
  Future<void> initializeEntity() async {
    addEntityComponent(_positionComponent);
    addEntityComponent(_velocityComponent);
    addEntityComponent(_collisionComponent);
    addEntityComponent(_spriteComponent);
  }

  @override
  void updateEntity(double dt) {
    if (currentPlayer != null &&
        currentPlayer!.currentState != PlayerState.aiming &&
        currentPlayer!.isOnGround) {
      _velocityComponent.velocity.x = 2.0 * 64.0; // Scaled speed
    } else {
      _velocityComponent.velocity.x = 0.0;
    }

    final deltaPosition = _velocityComponent.velocity * dt;
    _positionComponent.updatePosition(
      _positionComponent.position + deltaPosition,
    );
    _spriteComponent.position = _positionComponent.position;
    _collisionComponent.position = _positionComponent.position;
  }

  void _handleCollision(GameCollisionComponent other) {
    if (other.type == GameCollisionType.player) {
      // In a real implementation we would fetch the entity associated with the collision
      // but flame collisions give us components. We'll need a way to link them, or let a system handle it.
      // For now we'll set it hypothetically, but this logic might be moved to a system.
      // AudioManager.play_sound(AudioRegistry.SFX_DING, global_position);
    }
  }

  void _handleCollisionEnd(GameCollisionComponent other) {
    if (other.type == GameCollisionType.player) {
      currentPlayer = null;
    }
  }
}
