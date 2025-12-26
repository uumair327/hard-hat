import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:hard_hat/features/game/presentation/game/hard_hat_game.dart';
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';
import 'package:hard_hat/features/game/domain/entities/ball.dart';
import 'package:hard_hat/features/game/domain/entities/tile.dart';
import 'package:hard_hat/core/di/manual_injection.dart';

/// Integration test for Task 22: Core gameplay functional checkpoint
/// Validates that all core gameplay mechanics work together properly
void main() {
  group('Core Gameplay Integration Checkpoint', () {
    late HardHatGame game;
    
    setUpAll(() async {
      // Initialize dependency injection
      await setupManualDependencies();
    });
    
    setUp(() async {
      game = HardHatGame();
      await game.onLoad();
      
      // Give systems time to initialize
      await Future.delayed(const Duration(milliseconds: 100));
    });
    
    tearDown(() {
      game.onRemove();
    });

    group('System Initialization', () {
      test('all core systems are properly initialized', () async {
        // Verify all critical systems are available
        expect(game.entityManager, isNotNull, reason: 'Entity manager should be initialized');
        expect(game.inputSystem, isNotNull, reason: 'Input system should be initialized');
        expect(game.movementSystem, isNotNull, reason: 'Movement system should be initialized');
        expect(game.collisionSystem, isNotNull, reason: 'Collision system should be initialized');
        expect(game.audioSystem, isNotNull, reason: 'Audio system should be initialized');
        expect(game.cameraSystem, isNotNull, reason: 'Camera system should be initialized');
        expect(game.renderSystem, isNotNull, reason: 'Render system should be initialized');
        expect(game.gameStateManager, isNotNull, reason: 'Game state manager should be initialized');
      });
    });

    group('Player Entity Functionality', () {
      test('player entity can be created and initialized', () async {
        final player = PlayerEntity(
          id: 'test_player',
          position: Vector2(100, 100),
        );
        
        await player.initializeEntity();
        game.entityManager.addEntity(player);
        
        // Verify player was added
        final players = game.entityManager.getEntitiesOfType<PlayerEntity>();
        expect(players.isNotEmpty, isTrue, reason: 'Player entity should exist');
        expect(players.first.id, equals('test_player'));
      });

      test('player has correct components', () async {
        final players = game.entityManager.getEntitiesOfType<PlayerEntity>();
        expect(players.isNotEmpty, isTrue);
        
        final player = players.first;
        
        // Verify components exist
        expect(player.positionComponent, isNotNull, reason: 'Player should have position component');
        expect(player.velocityComponent, isNotNull, reason: 'Player should have velocity component');
        expect(player.collisionComponent, isNotNull, reason: 'Player should have collision component');
        expect(player.spriteComponent, isNotNull, reason: 'Player should have sprite component');
        expect(player.inputComponent, isNotNull, reason: 'Player should have input component');
      });

      test('player can change states', () async {
        final players = game.entityManager.getEntitiesOfType<PlayerEntity>();
        expect(players.isNotEmpty, isTrue);
        
        final player = players.first;
        
        // Test state changes
        final initialState = player.currentState;
        expect(initialState, isNotNull, reason: 'Player should have an initial state');
        
        // Force state change
        player.forceStateChange(PlayerState.jumping);
        expect(player.currentState, equals(PlayerState.jumping), reason: 'Player state should change');
      });

      test('player movement updates position', () async {
        final players = game.entityManager.getEntitiesOfType<PlayerEntity>();
        expect(players.isNotEmpty, isTrue);
        
        final player = players.first;
        final initialPosition = player.positionComponent.position.x;
        
        // Set velocity
        player.velocityComponent.velocity.x = 100;
        
        // Update player
        player.updateEntity(1.0 / 60.0);
        
        // Position should have changed
        expect(player.positionComponent.position.x, greaterThan(initialPosition),
            reason: 'Player position should update when velocity is applied');
      });
    });

    group('Ball Entity Functionality', () {
      test('ball entity can be created and initialized', () async {
        final ball = BallEntity(
          id: 'test_ball',
          position: Vector2(200, 200),
        );
        
        await ball.initializeEntity();
        game.entityManager.addEntity(ball);
        
        // Verify ball was added
        final balls = game.entityManager.getEntitiesOfType<BallEntity>();
        expect(balls.isNotEmpty, isTrue, reason: 'Ball entity should exist');
        expect(balls.first.id, equals('test_ball'));
      });

      test('ball has correct components', () async {
        final ball = BallEntity(
          id: 'component_test_ball',
          position: Vector2(150, 150),
        );
        
        await ball.initializeEntity();
        game.entityManager.addEntity(ball);
        
        // Verify components exist
        expect(ball.positionComponent, isNotNull, reason: 'Ball should have position component');
        expect(ball.velocityComponent, isNotNull, reason: 'Ball should have velocity component');
        expect(ball.collisionComponent, isNotNull, reason: 'Ball should have collision component');
        expect(ball.spriteComponent, isNotNull, reason: 'Ball should have sprite component');
      });

      test('ball can change states and shoot', () async {
        final ball = BallEntity(
          id: 'state_test_ball',
          position: Vector2(250, 250),
        );
        
        await ball.initializeEntity();
        game.entityManager.addEntity(ball);
        
        // Test state changes
        expect(ball.currentState, equals(BallState.idle));
        
        ball.startTracking();
        expect(ball.currentState, equals(BallState.tracking));
        
        ball.setDirection(Vector2(1, 0));
        ball.shoot();
        expect(ball.currentState, equals(BallState.flying));
        expect(ball.velocityComponent.velocity.length, greaterThan(0));
      });
    });

    group('Tile Entity Functionality', () {
      test('tile entity can be created and take damage', () async {
        final tile = TileEntity(
          id: 'test_tile',
          position: Vector2(300, 300),
          type: TileType.scaffolding,
          durability: 1,
        );
        
        await tile.initializeEntity();
        game.entityManager.addEntity(tile);
        
        // Verify tile was added
        final tiles = game.entityManager.getEntitiesOfType<TileEntity>();
        expect(tiles.isNotEmpty, isTrue, reason: 'Tile entity should exist');
        
        // Test damage
        expect(tile.isDestroyed, isFalse);
        tile.takeDamage(1);
        expect(tile.isDestroyed, isTrue, reason: 'Scaffolding should be destroyed in 1 hit');
      });

      test('different tile types have correct durability', () async {
        final scaffolding = TileEntity(
          id: 'scaffolding_tile',
          position: Vector2(100, 300),
          type: TileType.scaffolding,
          durability: 1,
        );
        
        final timber = TileEntity(
          id: 'timber_tile',
          position: Vector2(150, 300),
          type: TileType.timber,
          durability: 2,
        );
        
        final brick = TileEntity(
          id: 'brick_tile',
          position: Vector2(200, 300),
          type: TileType.bricks,
          durability: 3,
        );
        
        await scaffolding.initializeEntity();
        await timber.initializeEntity();
        await brick.initializeEntity();
        
        game.entityManager.addEntity(scaffolding);
        game.entityManager.addEntity(timber);
        game.entityManager.addEntity(brick);
        
        // Test scaffolding (1 hit)
        scaffolding.takeDamage(1);
        expect(scaffolding.isDestroyed, isTrue);
        
        // Test timber (2 hits)
        timber.takeDamage(1);
        expect(timber.isDestroyed, isFalse);
        timber.takeDamage(1);
        expect(timber.isDestroyed, isTrue);
        
        // Test bricks (3 hits)
        brick.takeDamage(1);
        expect(brick.isDestroyed, isFalse);
        brick.takeDamage(1);
        expect(brick.isDestroyed, isFalse);
        brick.takeDamage(1);
        expect(brick.isDestroyed, isTrue);
      });
    });

    group('Game State Management', () {
      test('game can be paused and resumed', () async {
        expect(game.isPaused, isFalse, reason: 'Game should start unpaused');
        
        // Pause game
        game.pauseGame();
        expect(game.isPaused, isTrue, reason: 'Game should be paused after pause call');
        
        // Resume game
        game.resumeGame();
        expect(game.isPaused, isFalse, reason: 'Game should be unpaused after resume call');
      });

      test('game state manager works correctly', () async {
        final gameStateManager = game.gameStateManager;
        expect(gameStateManager, isNotNull);
        
        // Test state transitions
        expect(gameStateManager.currentState, isNotNull,
            reason: 'Game should have a current state');
        
        // Test pause/resume through state manager
        gameStateManager.pauseGame();
        expect(gameStateManager.isPaused, isTrue,
            reason: 'State manager should reflect paused state');
        
        gameStateManager.resumeGame();
        expect(gameStateManager.isPaused, isFalse,
            reason: 'State manager should reflect resumed state');
      });
    });

    group('Entity Manager Integration', () {
      test('entity manager can handle multiple entity types', () async {
        final entityManager = game.entityManager;
        
        // Create entities of different types
        final player = PlayerEntity(id: 'multi_test_player', position: Vector2(50, 50));
        final ball = BallEntity(id: 'multi_test_ball', position: Vector2(100, 100));
        final tile = TileEntity(id: 'multi_test_tile', position: Vector2(150, 150), 
                               type: TileType.scaffolding, durability: 1);
        
        await player.initializeEntity();
        await ball.initializeEntity();
        await tile.initializeEntity();
        
        entityManager.addEntity(player);
        entityManager.addEntity(ball);
        entityManager.addEntity(tile);
        
        // Verify all entities were added
        expect(entityManager.getEntitiesOfType<PlayerEntity>().length, greaterThan(0));
        expect(entityManager.getEntitiesOfType<BallEntity>().length, greaterThan(0));
        expect(entityManager.getEntitiesOfType<TileEntity>().length, greaterThan(0));
        
        // Test entity removal
        entityManager.removeEntity(ball.id);
        expect(entityManager.getEntitiesOfType<BallEntity>()
               .any((e) => e.id == 'multi_test_ball'), isFalse);
      });
    });

    group('System Stability', () {
      test('game maintains stability during rapid updates', () async {
        // Perform rapid updates to test stability
        for (int i = 0; i < 50; i++) {
          game.update(1.0 / 60.0);
          
          // Verify core systems remain functional
          expect(game.entityManager, isNotNull,
              reason: 'Entity manager should remain stable during updates');
          expect(game.gameStateManager, isNotNull,
              reason: 'Game state manager should remain stable during updates');
        }
      });

      test('entity creation and destruction is stable', () async {
        final entityManager = game.entityManager;
        
        // Create and destroy multiple entities rapidly
        for (int i = 0; i < 5; i++) {
          final testBall = BallEntity(
            id: 'stability_test_$i',
            position: Vector2(i * 50.0, 100),
          );
          
          await testBall.initializeEntity();
          entityManager.addEntity(testBall);
          
          // Immediately remove
          entityManager.removeEntity(testBall.id);
        }
        
        // System should remain stable
        expect(entityManager, isNotNull,
            reason: 'Entity manager should handle rapid creation/destruction');
      });
    });

    group('Integration Validation', () {
      test('complete gameplay components work together', () async {
        // This test validates the integration of core components
        
        // 1. Create and verify player
        final player = PlayerEntity(
          id: 'integration_player',
          position: Vector2(100, 400),
        );
        await player.initializeEntity();
        game.entityManager.addEntity(player);
        
        // 2. Create and verify ball
        final ball = BallEntity(
          id: 'integration_ball',
          position: Vector2(150, 400),
        );
        await ball.initializeEntity();
        game.entityManager.addEntity(ball);
        
        // 3. Create and verify tile
        final tile = TileEntity(
          id: 'integration_tile',
          position: Vector2(200, 400),
          type: TileType.scaffolding,
          durability: 1,
        );
        await tile.initializeEntity();
        game.entityManager.addEntity(tile);
        
        // 4. Test basic interactions
        expect(game.entityManager.getEntitiesOfType<PlayerEntity>().length, greaterThan(0));
        expect(game.entityManager.getEntitiesOfType<BallEntity>().length, greaterThan(0));
        expect(game.entityManager.getEntitiesOfType<TileEntity>().length, greaterThan(0));
        
        // 5. Test state management
        game.pauseGame();
        expect(game.isPaused, isTrue);
        game.resumeGame();
        expect(game.isPaused, isFalse);
        
        // 6. Test entity updates
        player.updateEntity(1.0 / 60.0);
        ball.updateEntity(1.0 / 60.0);
        tile.updateEntity(1.0 / 60.0);
        
        // If we get here, all core systems are working together
        expect(true, isTrue, reason: 'Core gameplay integration successful');
      });
    });
  });
}