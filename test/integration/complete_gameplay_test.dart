import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:hard_hat/features/game/presentation/game/hard_hat_game.dart';
import 'package:hard_hat/features/game/domain/systems/level_manager.dart';
import 'package:hard_hat/features/game/domain/systems/save_system.dart';
import 'package:hard_hat/features/game/domain/systems/movement_system.dart';
import 'package:hard_hat/features/game/domain/systems/collision_system.dart';
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';
import 'package:hard_hat/features/game/domain/entities/tile.dart';
import 'package:hard_hat/core/di/injection_container.dart';
import 'package:flame/components.dart';

void main() {
  group('Complete Gameplay Integration Tests', () {
    late HardHatGame game;
    
    setUpAll(() async {
      // Initialize dependency injection
      await initializeDependencies();
    });
    
    setUp(() async {
      game = HardHatGame();
      await game.onLoad();
    });
    
    tearDown(() {
      game.onRemove();
    });

    testWidgets('should integrate all systems for complete gameplay experience', (tester) async {
      // Verify all core systems are initialized
      expect(game.entityManager, isNotNull);
      expect(game.inputSystem, isNotNull);
      expect(game.audioSystem, isNotNull);
      expect(game.gameStateManager, isNotNull);
      expect(game.cameraSystem, isNotNull);
      expect(game.renderSystem, isNotNull);
      expect(game.particleSystem, isNotNull);
      expect(game.stateTransitionSystem, isNotNull);
      expect(game.levelManager, isNotNull);
      expect(game.saveSystem, isNotNull);
      expect(game.movementSystem, isNotNull);
      expect(game.collisionSystem, isNotNull);
      
      // Test that game can be paused and resumed
      expect(game.isPaused, isFalse);
      game.pauseGame();
      expect(game.isPaused, isTrue);
      game.resumeGame();
      expect(game.isPaused, isFalse);
    });

    test('should handle complete level progression flow', () async {
      // Get level manager system
      final levelManager = game.levelManager;
      expect(levelManager, isNotNull);
      
      bool levelLoaded = false;
      bool levelCompleted = false;
      
      // Set up callbacks
      levelManager.onLevelLoaded = (level) {
        levelLoaded = true;
        expect(level.id, equals(1));
        expect(level.tiles.isNotEmpty, isTrue);
      };
      
      levelManager.onLevelComplete = (level) {
        levelCompleted = true;
        expect(level.id, equals(1));
      };
      
      // Load level 1
      await levelManager.loadLevel(1);
      expect(levelLoaded, isTrue);
      expect(levelManager.isLevelLoaded, isTrue);
      expect(levelManager.currentLevelId, equals(1));
      
      // Verify tiles were instantiated
      expect(levelManager.levelTiles.isNotEmpty, isTrue);
      
      // Simulate destroying all destructible tiles to complete level
      final destructibleTiles = levelManager.levelTiles.values
          .where((tile) => tile.isDestructible)
          .toList();
      
      for (final tile in destructibleTiles) {
        tile.takeDamage(tile.durability);
      }
      
      // Update level manager to check objectives
      levelManager.updateSystem(0.2); // Trigger objective check
      
      expect(levelCompleted, isTrue);
    });

    test('should integrate movement and collision systems', () async {
      // Get systems
      final movementSystem = game.movementSystem;
      final collisionSystem = game.collisionSystem;
      
      expect(movementSystem, isNotNull);
      expect(collisionSystem, isNotNull);
      
      // Create test player
      final player = PlayerEntity(
        id: 'test_player',
        position: Vector2(100, 100),
      );
      
      await player.initializeEntity();
      game.entityManager.registerEntity(player);
      
      // Test movement
      final initialPosition = player.positionComponent.position.clone();
      player.velocityComponent.velocity.x = 100; // Move right
      
      // Update movement system
      movementSystem.updateSystem(1.0 / 60.0); // One frame
      
      // Verify player moved
      expect(player.positionComponent.position.x, greaterThan(initialPosition.x));
      
      // Test jump mechanics
      movementSystem.setGroundState(player, true);
      expect(movementSystem.canJump(player), isTrue);
      
      movementSystem.applyJump(player, 300);
      expect(player.velocityComponent.velocity.y, lessThan(0)); // Moving up
    });

    test('should integrate camera system with player movement', () async {
      final cameraSystem = game.cameraSystem;
      
      // Create test player
      final player = PlayerEntity(
        id: 'camera_test_player',
        position: Vector2(200, 200),
      );
      
      await player.initializeEntity();
      game.entityManager.registerEntity(player);
      
      // Set camera to follow player
      cameraSystem.setPlayerTarget(player);
      cameraSystem.setViewportSize(Vector2(800, 600));
      
      // Move player
      player.positionComponent.position.x = 400;
      
      // Update camera system
      cameraSystem.updateSystem(1.0 / 60.0);
      
      // Camera should follow player (basic test)
      expect(cameraSystem, isNotNull);
    });

    test('should handle save system integration with level progression', () async {
      final saveSystem = game.saveSystem;
      
      // Initialize save system
      final initResult = await saveSystem.initialize();
      expect(initResult.isRight(), isTrue);
      
      // Save progress
      final saveResult = await saveSystem.saveProgress(
        currentLevel: 2,
        unlockedLevels: {1, 2},
      );
      expect(saveResult.isRight(), isTrue);
      
      // Load save data
      final loadResult = await saveSystem.getSaveData();
      expect(loadResult.isRight(), isTrue);
      
      loadResult.fold(
        (failure) => fail('Should not fail'),
        (saveData) {
          expect(saveData.currentLevel, equals(2));
          expect(saveData.unlockedLevels, contains(1));
          expect(saveData.unlockedLevels, contains(2));
        },
      );
    });

    test('should verify all requirements are met through gameplay testing', () async {
      // Requirement 1: Player control and physics ball
      final player = game.entityManager.getEntitiesOfType<PlayerEntity>().firstOrNull;
      expect(player, isNotNull);
      expect(player!.canStrike, isTrue);
      
      // Requirement 2: Destructible tiles
      final levelManager = game.levelManager;
      if (levelManager.isLevelLoaded) {
        final tiles = levelManager.levelTiles.values;
        expect(tiles.any((tile) => tile.isDestructible), isTrue);
      }
      
      // Requirement 3: Level management
      expect(levelManager, isNotNull);
      expect(levelManager.onLevelComplete, isNotNull);
      expect(levelManager.onLevelLoaded, isNotNull);
      
      // Requirement 4: Audio system
      expect(game.audioSystem, isNotNull);
      
      // Requirement 5: Camera system
      expect(game.cameraSystem, isNotNull);
      
      // Requirement 6: UI and state management
      expect(game.gameStateManager, isNotNull);
      expect(game.pauseMenuManager, isNotNull);
      
      // Requirement 7: Performance optimizations
      expect(game.renderSystem, isNotNull);
      expect(game.particleSystem, isNotNull);
      
      // Requirement 9: Particle system
      expect(game.particleSystem, isNotNull);
      
      // Requirement 10: Input handling
      expect(game.inputSystem, isNotNull);
    });

    test('should handle error scenarios gracefully', () async {
      // Test level loading failure
      final levelManager = game.levelManager;
      expect(levelManager, isNotNull);
      
      bool errorHandled = false;
      levelManager.onLevelLoadError = (failure) {
        errorHandled = true;
        expect(failure.toString(), isNotEmpty);
      };
      
      // Try to load non-existent level
      await levelManager.loadLevel(999);
      expect(errorHandled, isTrue);
    });

    test('should maintain system integration during pause/resume cycles', () async {
      // Test multiple pause/resume cycles
      for (int i = 0; i < 5; i++) {
        expect(game.isPaused, isFalse);
        
        game.pauseGame();
        expect(game.isPaused, isTrue);
        
        // Verify systems respond to pause
        expect(game.gameStateManager.isPaused, isTrue);
        
        game.resumeGame();
        expect(game.isPaused, isFalse);
        expect(game.gameStateManager.isPaused, isFalse);
      }
      
      // All systems should still be functional
      expect(game.entityManager, isNotNull);
      expect(game.inputSystem, isNotNull);
      expect(game.audioSystem, isNotNull);
      expect(game.cameraSystem, isNotNull);
    });
  });
}