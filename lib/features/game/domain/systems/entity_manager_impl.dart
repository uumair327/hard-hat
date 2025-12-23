import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/interfaces/entity_manager_interface.dart';
import 'package:hard_hat/features/game/domain/entities/game_entity.dart';

@LazySingleton(as: IEntityManager)
class EntityManagerImpl implements IEntityManager {
  final Map<String, GameEntity> _entities = {};

  @override
  void addEntity(GameEntity entity) {
    _entities[entity.id] = entity;
  }

  @override
  void removeEntity(String id) {
    _entities.remove(id);
  }

  @override
  GameEntity? getEntity(String id) {
    return _entities[id];
  }

  @override
  List<T> getEntitiesOfType<T extends GameEntity>() {
    return _entities.values.whereType<T>().toList();
  }

  @override
  List<GameEntity> getAllEntities() {
    return _entities.values.toList();
  }

  @override
  bool hasEntity(String id) {
    return _entities.containsKey(id);
  }

  @override
  void clearAllEntities() {
    _entities.clear();
  }

  @override
  int get entityCount => _entities.length;
}