import 'package:hard_hat/features/game/di/game_injection.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/entities/game_entity.dart';

/// Service locator for easy access to game systems and services
class GameServiceLocator {
  /// Get the entity manager instance
  static EntityManager get entityManager => GameInjection.getSystem<EntityManager>();

  /// Get the system manager instance
  static GameSystemManager get systemManager => GameInjection.getSystemManager();

  /// Get a specific core system (registered directly in DI)
  static T getCoreSystem<T extends Object>() {
    return GameInjection.getSystem<T>();
  }

  /// Get a specific game system (registered through system manager)
  static T? getGameSystem<T extends GameSystem>() {
    return systemManager.getSystem<T>();
  }

  /// Get an entity factory
  static T getFactory<T extends Object>() {
    return GameInjection.getFactory<T>();
  }

  /// Register a new game system
  static void registerSystem<T extends GameSystem>(T system) {
    GameInjection.registerSystem<T>(system);
  }

  /// Unregister a game system
  static void unregisterSystem<T extends GameSystem>() {
    GameInjection.unregisterSystem<T>();
  }

  /// Check if a core system is available
  static bool hasCoreSystem<T extends Object>() {
    try {
      GameInjection.getSystem<T>();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a game system is available
  static bool hasGameSystem<T extends GameSystem>() {
    return GameInjection.isSystemRegistered<T>();
  }

  /// Get all registered game systems
  static Map<Type, GameSystem> getAllGameSystems() {
    return GameInjection.getAllSystems();
  }

  /// Convenience method to get multiple systems at once
  static Map<Type, GameSystem> getGameSystems(List<Type> systemTypes) {
    final systems = <Type, GameSystem>{};
    final allSystems = getAllGameSystems();
    
    for (final type in systemTypes) {
      if (allSystems.containsKey(type)) {
        systems[type] = allSystems[type]!;
      }
    }
    return systems;
  }

  /// Initialize all game systems
  static Future<void> initializeAllSystems() async {
    await systemManager.initializeAllSystems();
  }

  /// Update all active game systems
  static void updateAllSystems(double deltaTime) {
    systemManager.updateAllSystems(deltaTime);
  }

  /// Dispose all game systems
  static void disposeAllSystems() {
    systemManager.disposeAllSystems();
  }

  /// Create a new entity using the appropriate factory
  static T createEntity<T extends GameEntity>({
    required String id,
    Map<String, dynamic>? parameters,
  }) {
    // This will be enhanced when specific entity types are implemented
    final factory = getFactory<EntityFactory<T>>();
    return factory.create(id: id, parameters: parameters);
  }

  /// Create multiple entities of the same type
  static List<T> createEntities<T extends GameEntity>({
    required int count,
    String? baseId,
    Map<String, dynamic>? parameters,
  }) {
    final factory = getFactory<EntityFactory<T>>();
    return factory.createMultiple(count, parameters: parameters);
  }
}