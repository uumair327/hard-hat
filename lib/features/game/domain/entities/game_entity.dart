import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/components/position_component.dart';
import 'package:hard_hat/features/game/domain/components/velocity_component.dart';
import 'package:hard_hat/features/game/domain/components/collision_component.dart';
import 'package:hard_hat/features/game/domain/components/sprite_component.dart';

/// Base class for all game entities in the ECS architecture
abstract class GameEntity extends Component {
  /// Unique identifier for this entity
  final String id;
  
  /// Whether this entity is currently active
  bool isActive = true;
  
  /// Components attached to this entity
  final Map<Type, Component> _components = {};

  GameEntity({
    required this.id,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await initializeEntity();
  }

  /// Initialize the entity - override to add components and setup
  Future<void> initializeEntity() async {}

  /// Add a component to this entity
  T addEntityComponent<T extends Component>(T component) {
    _components[T] = component;
    add(component);
    return component;
  }

  /// Get a component from this entity
  T? getEntityComponent<T extends Component>() {
    return _components[T] as T?;
  }

  /// Check if this entity has a specific component
  bool hasEntityComponent<T extends Component>() {
    return _components.containsKey(T);
  }

  /// Remove a component from this entity
  void removeEntityComponent<T extends Component>() {
    final component = _components.remove(T);
    if (component != null) {
      remove(component);
    }
  }

  /// Get all components attached to this entity
  Iterable<Component> getAllComponents() {
    return _components.values;
  }

  @override
  void update(double dt) {
    if (!isActive) return;
    super.update(dt);
    updateEntity(dt);
  }

  /// Update entity logic - override for custom behavior
  void updateEntity(double dt) {}

  /// Activate this entity
  void activate() {
    isActive = true;
  }

  /// Deactivate this entity
  void deactivate() {
    isActive = false;
  }

  /// Destroy this entity and remove it from the game
  void destroy() {
    removeFromParent();
  }

  // Convenience methods for common components

  GamePositionComponent? get positionComponent => 
      getEntityComponent<GamePositionComponent>();

  VelocityComponent? get velocityComponent => 
      getEntityComponent<VelocityComponent>();

  GameCollisionComponent? get collisionComponent => 
      getEntityComponent<GameCollisionComponent>();

  GameSpriteComponent? get spriteComponent => 
      getEntityComponent<GameSpriteComponent>();
}