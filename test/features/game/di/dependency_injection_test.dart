import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hard_hat/features/game/di/game_injection.dart';
import 'package:hard_hat/features/game/domain/services/game_service_locator.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/systems/movement_system.dart';
import 'package:hard_hat/features/game/domain/systems/collision_system.dart';
import 'package:hard_hat/features/game/domain/systems/render_system.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';

void main() {
  group('Dependency Injection Tests', () {
    setUpAll(() async {
      // Initialize game dependencies once for all tests
      await GameInjection.initializeGameDependencies();
    });

    test('should register and retrieve game systems', () async {
      // Arrange
      final movementSystem = MovementSystem();
      final collisionSystem = CollisionSystem();

      // Act
      GameServiceLocator.registerSystem<MovementSystem>(movementSystem);
      GameServiceLocator.registerSystem<CollisionSystem>(collisionSystem);

      // Assert
      expect(GameServiceLocator.hasGameSystem<MovementSystem>(), isTrue);
      expect(GameServiceLocator.hasGameSystem<CollisionSystem>(), isTrue);
      
      final retrievedMovementSystem = GameServiceLocator.getGameSystem<MovementSystem>();
      final retrievedCollisionSystem = GameServiceLocator.getGameSystem<CollisionSystem>();
      
      expect(retrievedMovementSystem, equals(movementSystem));
      expect(retrievedCollisionSystem, equals(collisionSystem));
    });

    test('should unregister game systems', () async {
      // Arrange
      final renderSystem = RenderSystem();
      GameServiceLocator.registerSystem<RenderSystem>(renderSystem);
      
      expect(GameServiceLocator.hasGameSystem<RenderSystem>(), isTrue);

      // Act
      GameServiceLocator.unregisterSystem<RenderSystem>();

      // Assert
      expect(GameServiceLocator.hasGameSystem<RenderSystem>(), isFalse);
      expect(GameServiceLocator.getGameSystem<RenderSystem>(), isNull);
    });

    test('should get all registered systems', () async {
      // Arrange
      final movementSystem = MovementSystem();
      final collisionSystem = CollisionSystem();
      final renderSystem = RenderSystem();

      GameServiceLocator.registerSystem<MovementSystem>(movementSystem);
      GameServiceLocator.registerSystem<CollisionSystem>(collisionSystem);
      GameServiceLocator.registerSystem<RenderSystem>(renderSystem);

      // Act
      final allSystems = GameServiceLocator.getAllGameSystems();

      // Assert
      expect(allSystems.length, greaterThanOrEqualTo(3));
      expect(allSystems.containsKey(MovementSystem), isTrue);
      expect(allSystems.containsKey(CollisionSystem), isTrue);
      expect(allSystems.containsKey(RenderSystem), isTrue);
      expect(allSystems[MovementSystem], equals(movementSystem));
      expect(allSystems[CollisionSystem], equals(collisionSystem));
      expect(allSystems[RenderSystem], equals(renderSystem));
    });

    test('should handle system updates', () async {
      // Arrange
      final testSystem = TestGameSystem();
      GameServiceLocator.registerSystem<TestGameSystem>(testSystem);

      // Act
      GameServiceLocator.updateAllSystems(0.016); // 60 FPS

      // Assert
      expect(testSystem.lastUpdateDelta, equals(0.016));
    });

    test('should handle system disposal', () async {
      // Arrange
      final testSystem = TestGameSystem();
      GameServiceLocator.registerSystem<TestGameSystem>(testSystem);

      // Act
      GameServiceLocator.disposeAllSystems();

      // Assert
      expect(testSystem.isDisposed, isTrue);
    });
  });
}

/// Test system for verifying dependency injection functionality
class TestGameSystem extends GameSystem {
  bool isInitialized = false;
  bool isDisposed = false;
  double lastUpdateDelta = 0.0;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  void updateSystem(double dt) {
    lastUpdateDelta = dt;
  }

  @override
  void dispose() {
    isDisposed = true;
  }
}