import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Spring entity that bounces the player upwards
class SpringEntity extends GameEntity {
  SpringEntity({required super.id, required Vector2 position}) {
    // Position component
    addEntityComponent(
      GamePositionComponent(position: position, size: Vector2(32, 32)),
    );

    // Collision component setup as spring
    addEntityComponent(
      GameCollisionComponent(
        hitbox: RectangleHitbox(size: Vector2(32, 16)), // typically half-size
        type: GameCollisionType.spring,
        isStatic: true,
        onCollision: _handleCollision,
        size: Vector2(32, 16),
        position: position + Vector2(0, 16), // Offset applied to component pos
      ),
    );

    // Graphic component
    addEntityComponent(
      GameSpriteComponent(size: Vector2(32, 32), position: position),
    );
  }

  void _handleCollision(GameCollisionComponent other) {
    if (other.type == GameCollisionType.player) {
      // Trigger animation for compressing and expanding spring
      _playBounceAnimation();
    }
  }

  void _playBounceAnimation() {
    // Trigger visual bounce scaling effect
    final sprite = spriteComponent;
    if (sprite != null) {
      sprite.scale = Vector2(1.0, 0.8);

      // We would use an Effect here or switch to an expanded sprite in Flame
      // Needs integrating with Flame Effects system later
    }
  }
}
