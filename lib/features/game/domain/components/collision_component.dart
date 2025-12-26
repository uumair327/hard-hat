import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

/// Enum defining different types of collision objects
enum GameCollisionType {
  player,
  ball,
  tile,
  wall,
  spring,
  elevator,
  sensor,
  hazard,
}

/// Component that manages collision detection and response for entities
class GameCollisionComponent extends PositionComponent with HasCollisionDetection {
  final ShapeHitbox hitbox;
  final GameCollisionType type;
  final Set<GameCollisionType> collidesWith;
  final bool isSensor;
  
  /// Whether this collision component is currently active
  bool isActive = true;
  
  /// Whether this collision component is static (doesn't move)
  bool isStatic = false;
  
  /// Collision layer for layer-based filtering
  int layer = 0;
  
  /// Callback function for collision events
  void Function(GameCollisionComponent other)? onCollision;
  
  /// Callback function for collision end events
  void Function(GameCollisionComponent other)? onCollisionEnd;

  GameCollisionComponent({
    required this.hitbox,
    required this.type,
    Set<GameCollisionType>? collidesWith,
    this.isSensor = false,
    this.isActive = true,
    this.isStatic = false,
    this.layer = 0,
    this.onCollision,
    this.onCollisionEnd,
    Vector2? position,
    Vector2? size,
  }) : collidesWith = collidesWith ?? <GameCollisionType>{} {
    if (position != null) this.position = position;
    if (size != null) this.size = size;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(hitbox);
  }

  /// Checks if this component should collide with another collision type
  bool shouldCollideWith(GameCollisionType otherType) {
    return collidesWith.contains(otherType);
  }

  /// Handles collision with another collision component
  void handleCollision(GameCollisionComponent other) {
    if (shouldCollideWith(other.type)) {
      onCollision?.call(other);
    }
  }

  /// Handles end of collision with another collision component
  void handleCollisionEnd(GameCollisionComponent other) {
    if (shouldCollideWith(other.type)) {
      onCollisionEnd?.call(other);
    }
  }

  /// Updates the hitbox position
  void updateHitboxPosition(Vector2 position) {
    hitbox.position.setFrom(position);
  }
  
  /// Updates the hitbox size (for rectangle hitboxes)
  void updateRectangleHitboxSize(Vector2 size) {
    if (hitbox is RectangleHitbox) {
      (hitbox as RectangleHitbox).size.setFrom(size);
    }
  }
  
  /// Updates the hitbox radius (for circle hitboxes)
  void updateCircleHitboxRadius(double radius) {
    if (hitbox is CircleHitbox) {
      (hitbox as CircleHitbox).radius = radius;
    }
  }
}