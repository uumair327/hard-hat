import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Abstract base class for all game systems in the ECS architecture
abstract class GameSystem extends Component {
  /// Whether this system is currently active
  bool isActive = true;
  
  /// Priority for system execution order (lower numbers execute first)
  @override
  int get priority => 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await initialize();
  }

  /// Initialize the system - called once when the system is added to the game
  Future<void> initialize() async {}

  @override
  void update(double dt) {
    if (!isActive) return;
    super.update(dt);
    updateSystem(dt);
  }

  /// Update the system logic - called every frame when active
  void updateSystem(double dt) {}

  @override
  void render(Canvas canvas) {
    if (!isActive) return;
    super.render(canvas);
    renderSystem(canvas);
  }

  /// Render system-specific graphics - called every frame when active
  void renderSystem(Canvas canvas) {}

  /// Activate the system
  void activate() {
    isActive = true;
  }

  /// Deactivate the system
  void deactivate() {
    isActive = false;
  }

  /// Check if a component type exists in the game
  bool hasComponent<T extends Component>() {
    return findGame()?.findByKeyName(T.toString()) != null;
  }

  /// Get all components of a specific type from the game
  Iterable<T> getComponents<T extends Component>() {
    return findGame()?.children.query<T>() ?? <T>[];
  }

  /// Get the first component of a specific type
  T? getComponent<T extends Component>() {
    return findGame()?.children.query<T>().firstOrNull;
  }

  @override
  void onRemove() {
    dispose();
    super.onRemove();
  }

  /// Clean up system resources - called when the system is removed
  void dispose() {}
}