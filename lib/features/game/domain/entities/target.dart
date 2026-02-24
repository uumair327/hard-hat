import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Target entity that can be hit by the player ball to complete level goals
class TargetEntity extends GameEntity {
  bool _isHit = false;

  /// Optional event when hit
  final void Function()? onHit;

  TargetEntity({required super.id, required Vector2 position, this.onHit}) {
    // Position component
    addEntityComponent(
      GamePositionComponent(position: position, size: Vector2(32, 32)),
    );

    // Collision setup
    addEntityComponent(
      GameCollisionComponent(
        hitbox: RectangleHitbox(size: Vector2(32, 32)),
        type: GameCollisionType
            .sensor, // Fallback type for targets since target not in enum
        isStatic: true,
        onCollision: handleCollision,
        size: Vector2(32, 32),
        position: position,
      ),
    );

    // Graphic component
    addEntityComponent(
      GameSpriteComponent(size: Vector2(32, 32), position: position),
    );
  }

  void handleCollision(GameCollisionComponent other) {
    if (other.type == GameCollisionType.ball) {
      if (!_isHit) {
        _isHit = true;
        _destroyVisuals();

        // Signal systems/callbacks
        onHit?.call();
      }
    }
  }

  void _destroyVisuals() {
    // Hide graphic
    final sprite = spriteComponent;
    if (sprite != null) {
      sprite.opacity = 0.0;
    }

    // Disable collision
    final coll = collisionComponent;
    if (coll != null) {
      coll.isStatic = false; // Stops reacting to colls
      // We ideally want to remove or disable the hitbox explicitly.
      // This might require a flag on GameCollisionComponent in the future.
    }
  }

  void resetTarget() {
    _isHit = false;

    // Show graphic
    final sprite = spriteComponent;
    if (sprite != null) {
      sprite.setOpacity(1.0);
    }

    // Enable collision
    final coll = collisionComponent;
    if (coll != null) {
      coll.isStatic = true;
    }
  }

  bool get isHit => _isHit;
}
