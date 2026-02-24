import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Elevator entity that moves the player vertically
class ElevatorEntity extends GameEntity {
  /// The target Y position (relative to starting position)
  final double targetY;

  /// Speed of the elevator
  final double speed;

  /// Duration of the startup animation before main movement
  final double startupDuration;

  /// Delay before startup starts
  final double startupDelay;

  /// How much it dips or raises slightly before main movement
  final double startupAdjustment;

  /// Starting position
  late final Vector2 _startPosition;

  ElevatorEntity({
    required super.id,
    required Vector2 position,
    this.targetY = 10.0,
    this.speed = 4.0,
    this.startupDuration = 1.0,
    this.startupDelay = 0.5,
    this.startupAdjustment = 1.25,
  }) {
    _startPosition = position.clone();

    // Position component
    addEntityComponent(
      GamePositionComponent(
        position: position,
        size: Vector2(32, 16), // Example size based on standard prop dimensions
      ),
    );

    // Collision component
    addEntityComponent(
      GameCollisionComponent(
        hitbox: RectangleHitbox(size: Vector2(32, 16)),
        type: GameCollisionType.elevator,
        isStatic: true,
        onCollision: _handleCollision,
        size: Vector2(32, 16),
        position: position,
      ),
    );

    // Graphic component
    // Note: Sprite should be loaded properly from AssetManager later
    addEntityComponent(
      GameSpriteComponent(size: Vector2(32, 16), position: position),
    );
  }

  void _handleCollision(GameCollisionComponent other) {
    if (other.type == GameCollisionType.player) {
      // Logic for elevator start will be handled by systems based on state and overlap
      // This is a hook if we need immediate reaction
    }
  }

  /// Get the starting position
  Vector2 get startPosition => _startPosition;
}
