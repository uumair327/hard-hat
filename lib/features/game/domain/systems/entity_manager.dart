import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// System responsible for managing entity lifecycle and registration
@LazySingleton(as: IEntityManager)
class EntityManager extends GameSystem implements IEntityManager {
  /// Map of all registered entities by their ID
  final Map<String, GameEntity> _entities = {};
  
  /// Map of entities by type for quick lookup
  final Map<Type, Set<GameEntity>> _entitiesByType = {};

  @override
  int get priority => -1000; // Execute first

  /// Register an entity with the manager
  @override
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

  /// Add entity (alias for registerEntity for compatibility)
  @override
  void addEntity(GameEntity entity) {
    registerEntity(entity);
  }

  /// Remove an entity by ID (alias for unregisterEntity for compatibility)
  @override
  void removeEntity(String entityId) {
    unregisterEntity(entityId);
  }

  /// Unregister an entity from the manager
  @override
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
  @override
  GameEntity? getEntity(String entityId) {
    return _entities[entityId];
  }

  /// Get all entities of a specific type
  @override
  List<T> getEntitiesOfType<T extends GameEntity>() {
    return (_entitiesByType[T]?.cast<T>() ?? <T>[]).toList();
  }

  /// Get all registered entities
  @override
  List<GameEntity> getAllEntities() {
    return _entities.values.toList();
  }

  /// Check if an entity exists
  @override
  bool hasEntity(String entityId) {
    return _entities.containsKey(entityId);
  }

  /// Get the count of entities of a specific type
  int getEntityCount<T extends GameEntity>() {
    return _entitiesByType[T]?.length ?? 0;
  }

  /// Get the total count of all entities
  int get totalEntityCount => _entities.length;

  /// Get entity count (interface compatibility)
  @override
  int get entityCount => _entities.length;

  /// Clear all entities
  @override
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