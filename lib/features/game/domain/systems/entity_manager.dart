import 'package:hard_hat/features/game/domain/entities/game_entity.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';

/// System responsible for managing entity lifecycle and registration
class EntityManager extends GameSystem {
  /// Map of all registered entities by their ID
  final Map<String, GameEntity> _entities = {};
  
  /// Map of entities by type for quick lookup
  final Map<Type, Set<GameEntity>> _entitiesByType = {};

  @override
  int get priority => -1000; // Execute first

  /// Register an entity with the manager
  void registerEntity(GameEntity entity) {
    _entities[entity.id] = entity;
    
    // Add to type map
    final entityType = entity.runtimeType;
    _entitiesByType.putIfAbsent(entityType, () => <GameEntity>{});
    _entitiesByType[entityType]!.add(entity);
    
    // Add to game if we have a parent
    if (parent != null) {
      parent!.add(entity);
    }
  }

  /// Unregister an entity from the manager
  void unregisterEntity(String entityId) {
    final entity = _entities.remove(entityId);
    if (entity != null) {
      // Remove from type map
      final entityType = entity.runtimeType;
      _entitiesByType[entityType]?.remove(entity);
      if (_entitiesByType[entityType]?.isEmpty == true) {
        _entitiesByType.remove(entityType);
      }
      
      // Remove from game
      entity.removeFromParent();
    }
  }

  /// Get an entity by its ID
  GameEntity? getEntity(String entityId) {
    return _entities[entityId];
  }

  /// Get all entities of a specific type
  Iterable<T> getEntitiesOfType<T extends GameEntity>() {
    return _entitiesByType[T]?.cast<T>() ?? <T>[];
  }

  /// Get all registered entities
  Iterable<GameEntity> getAllEntities() {
    return _entities.values;
  }

  /// Check if an entity exists
  bool hasEntity(String entityId) {
    return _entities.containsKey(entityId);
  }

  /// Get the count of entities of a specific type
  int getEntityCount<T extends GameEntity>() {
    return _entitiesByType[T]?.length ?? 0;
  }

  /// Get the total count of all entities
  int get totalEntityCount => _entities.length;

  /// Clear all entities
  void clearAllEntities() {
    final entityIds = _entities.keys.toList();
    for (final id in entityIds) {
      unregisterEntity(id);
    }
  }

  @override
  void updateSystem(double dt) {
    // Clean up destroyed entities
    final destroyedEntities = <String>[];
    for (final entry in _entities.entries) {
      if (entry.value.isRemoved) {
        destroyedEntities.add(entry.key);
      }
    }
    
    for (final id in destroyedEntities) {
      unregisterEntity(id);
    }
  }

  @override
  void dispose() {
    clearAllEntities();
    super.dispose();
  }
}