import 'package:hard_hat/features/game/domain/services/game_service_locator.dart';
import 'package:hard_hat/features/game/domain/systems/movement_system.dart';
import 'package:hard_hat/features/game/domain/systems/collision_system.dart';
import 'package:hard_hat/features/game/domain/systems/render_system.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/di/game_injection.dart';

/// Example demonstrating how to use the dependency injection system
class DependencyInjectionExample {
  
  /// Example of registering and using game systems
  static Future<void> exampleSystemRegistration() async {
    // 1. Initialize the game dependencies (usually done at app startup)
    await GameInjection.initializeGameDependencies();
    
    // 2. Register custom game systems
    final movementSystem = MovementSystem();
    final collisionSystem = CollisionSystem();
    final renderSystem = RenderSystem();
    
    GameServiceLocator.registerSystem<MovementSystem>(movementSystem);
    GameServiceLocator.registerSystem<CollisionSystem>(collisionSystem);
    GameServiceLocator.registerSystem<RenderSystem>(renderSystem);
    
    // 3. Initialize all systems
    await GameServiceLocator.initializeAllSystems();
    
    // 4. Get systems when needed
    final retrievedMovementSystem = GameServiceLocator.getGameSystem<MovementSystem>();
    final entityManager = GameServiceLocator.entityManager;
    
    print('Movement system retrieved: ${retrievedMovementSystem != null}');
    print('Entity manager available: ${entityManager != null}');
    
    // 5. Update systems in game loop
    const deltaTime = 1.0 / 60.0; // 60 FPS
    GameServiceLocator.updateAllSystems(deltaTime);
    
    // 6. Check system availability
    if (GameServiceLocator.hasGameSystem<CollisionSystem>()) {
      final collisionSys = GameServiceLocator.getGameSystem<CollisionSystem>();
      print('Collision system is active: ${collisionSys?.isActive}');
    }
  }
  
  /// Example of using entity factories
  static Future<void> exampleEntityFactories() async {
    // Initialize dependencies first
    await GameInjection.initializeGameDependencies();
    
    // Get entity factories
    final playerFactory = GameServiceLocator.getFactory<PlayerEntityFactory>();
    final ballFactory = GameServiceLocator.getFactory<BallEntityFactory>();
    final tileFactory = GameServiceLocator.getFactory<TileEntityFactory>();
    
    print('Player factory available: ${playerFactory != null}');
    print('Ball factory available: ${ballFactory != null}');
    print('Tile factory available: ${tileFactory != null}');
    
    // Note: Entity creation will be available once concrete entity classes are implemented
    // Example usage would be:
    // final player = GameServiceLocator.createEntity<PlayerEntity>(
    //   id: 'player_1',
    //   parameters: {'startPosition': Vector2(100, 100)},
    // );
  }
  
  /// Example of system lifecycle management
  static Future<void> exampleSystemLifecycle() async {
    // Initialize dependencies
    await GameInjection.initializeGameDependencies();
    
    // Register a system
    final testSystem = MovementSystem();
    GameServiceLocator.registerSystem<MovementSystem>(testSystem);
    
    // Check if system is registered
    print('System registered: ${GameServiceLocator.hasGameSystem<MovementSystem>()}');
    
    // Get all registered systems
    final allSystems = GameServiceLocator.getAllGameSystems();
    print('Total systems registered: ${allSystems.length}');
    
    // Update systems
    GameServiceLocator.updateAllSystems(0.016);
    
    // Unregister a system
    GameServiceLocator.unregisterSystem<MovementSystem>();
    print('System after unregister: ${GameServiceLocator.hasGameSystem<MovementSystem>()}');
    
    // Dispose all systems (usually done at app shutdown)
    GameServiceLocator.disposeAllSystems();
    print('All systems disposed');
  }
  
  /// Example of getting multiple systems at once
  static Future<void> exampleBatchSystemRetrieval() async {
    // Initialize and register systems
    await GameInjection.initializeGameDependencies();
    
    GameServiceLocator.registerSystem<MovementSystem>(MovementSystem());
    GameServiceLocator.registerSystem<CollisionSystem>(CollisionSystem());
    GameServiceLocator.registerSystem<RenderSystem>(RenderSystem());
    
    // Get specific systems by type
    final requestedSystems = GameServiceLocator.getGameSystems([
      MovementSystem,
      CollisionSystem,
    ]);
    
    print('Retrieved ${requestedSystems.length} systems');
    for (final entry in requestedSystems.entries) {
      print('System type: ${entry.key}, Active: ${entry.value.isActive}');
    }
  }
}