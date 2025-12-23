import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:hard_hat/features/game/domain/ecs.dart';

void main() {
  group('ECS Architecture Tests', () {
    test('should create position component with correct initial values', () {
      final position = Vector2(10, 20);
      final component = GamePositionComponent(position: position);
      
      expect(component.position, equals(position));
      expect(component.previousPosition, equals(position));
    });

    test('should create velocity component with correct initial values', () {
      final velocity = Vector2(5, -10);
      final component = VelocityComponent(
        velocity: velocity,
        maxSpeed: 100,
        friction: 0.1,
      );
      
      expect(component.velocity, equals(velocity));
      expect(component.maxSpeed, equals(100));
      expect(component.friction, equals(0.1));
    });

    test('should create collision component with correct type', () {
      final hitbox = RectangleHitbox(size: Vector2(32, 32));
      final component = GameCollisionComponent(
        hitbox: hitbox,
        type: GameCollisionType.player,
        collidesWith: {GameCollisionType.tile, GameCollisionType.wall},
        position: Vector2.zero(),
        size: Vector2(32, 32),
      );
      
      expect(component.type, equals(GameCollisionType.player));
      expect(component.shouldCollideWith(GameCollisionType.tile), isTrue);
      expect(component.shouldCollideWith(GameCollisionType.ball), isFalse);
    });

    test('should create game entity with unique ID', () {
      final entity = TestGameEntity(id: 'test_entity_1');
      
      expect(entity.id, equals('test_entity_1'));
      expect(entity.isActive, isTrue);
    });

    test('should add and retrieve components from entity', () {
      final entity = TestGameEntity(id: 'test_entity_2');
      final positionComponent = GamePositionComponent(position: Vector2(5, 10));
      
      entity.addEntityComponent(positionComponent);
      
      expect(entity.hasEntityComponent<GamePositionComponent>(), isTrue);
      expect(entity.getEntityComponent<GamePositionComponent>(), equals(positionComponent));
      expect(entity.positionComponent, equals(positionComponent));
    });

    test('should create entity manager and register entities', () {
      final entityManager = EntityManager();
      final entity = TestGameEntity(id: 'managed_entity');
      
      entityManager.registerEntity(entity);
      
      expect(entityManager.hasEntity('managed_entity'), isTrue);
      expect(entityManager.getEntity('managed_entity'), equals(entity));
      expect(entityManager.totalEntityCount, equals(1));
    });

    test('should get entities by type from entity manager', () {
      final entityManager = EntityManager();
      final entity1 = TestGameEntity(id: 'entity_1');
      final entity2 = TestGameEntity(id: 'entity_2');
      
      entityManager.registerEntity(entity1);
      entityManager.registerEntity(entity2);
      
      final entities = entityManager.getEntitiesOfType<TestGameEntity>();
      expect(entities.length, equals(2));
      expect(entities.contains(entity1), isTrue);
      expect(entities.contains(entity2), isTrue);
    });
  });
}

/// Test implementation of GameEntity for testing purposes
class TestGameEntity extends GameEntity {
  TestGameEntity({required super.id});
  
  @override
  Future<void> initializeEntity() async {
    // Test entity doesn't need special initialization
  }
}