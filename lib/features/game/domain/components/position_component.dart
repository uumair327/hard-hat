import 'package:flame/components.dart';

/// Component that manages position, rotation, and previous position for entities
class GamePositionComponent extends PositionComponent {
  Vector2 previousPosition;
  
  GamePositionComponent({
    Vector2? position,
    Vector2? size,
    double? angle,
    Anchor? anchor,
  }) : previousPosition = position?.clone() ?? Vector2.zero(),
       super(
         position: position,
         size: size,
         angle: angle,
         anchor: anchor,
       );

  /// Updates the previous position before changing current position
  void updatePosition(Vector2 newPosition) {
    previousPosition.setFrom(position);
    position.setFrom(newPosition);
  }

  /// Gets the movement delta from previous to current position
  Vector2 getMovementDelta() {
    return position - previousPosition;
  }

  /// Resets previous position to current position
  void resetPreviousPosition() {
    previousPosition.setFrom(position);
  }
}