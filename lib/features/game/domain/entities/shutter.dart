import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Shutter entity that moves away when a target is hit
class ShutterEntity extends GameEntity {
  /// Target ID that triggers this shutter
  final String? targetId;

  /// Total distance to move when triggered
  final Vector2 offset;

  /// Duration to slide out
  final double duration;

  /// Whether it's retracting
  final bool retracting;

  ShutterEntity({
    required super.id,
    required Vector2 position,
    this.targetId,
    Vector2? offset,
    this.duration = 1.0,
    this.retracting = false,
  }) : offset = offset ?? Vector2(0, -64.0) {
    addEntityComponent(
      GamePositionComponent(position: position, size: Vector2(32, 64)),
    );

    // A shutter stops the player like a wall usually. Or stops the ball.
    addEntityComponent(
      GameCollisionComponent(
        hitbox: RectangleHitbox(size: Vector2(32, 64)),
        type: GameCollisionType.wall,
        isStatic: true,
        size: Vector2(32, 64),
        position: position,
      ),
    );

    // Visuals
    addEntityComponent(
      GameSpriteComponent(size: Vector2(32, 64), position: position),
    );
  }

  /// Trigger the shutter to open
  void openShutter() {
    // This logic to trigger movement will typically be a Tween applied to the position component.
    // In flame, effects are added to the visual components. We would bridge that properly
    // by altering the logical position component over time inside updateEntity.
  }
}
