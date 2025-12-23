import 'package:hard_hat/features/game/domain/entities/game_entity.dart';

/// Abstract interface for entity management
/// Follows DIP - high-level modules depend on this abstraction
abstract class IEntityManager {
  /// Add an entity to the manager
  void addEntity(GameEntity entity);
  
  /// Remove an entity by ID
  void removeEntity(String id);
  
  /// Get entity by ID
  GameEntity? getEntity(String id);
  
  /// Get all entities of a specific type
  List<T> getEntitiesOfType<T extends GameEntity>();
  
  /// Get all entities
  List<GameEntity> getAllEntities();
  
  /// Check if entity exists
  bool hasEntity(String id);
  
  /// Clear all entities
  void clearAllEntities();
  
  /// Get entity count
  int get entityCount;
}