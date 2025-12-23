# Game Dependency Injection System

This directory contains the dependency injection (DI) system for the Hard Hat Havoc game, built using the `get_it` package. The system provides a clean way to manage game systems, entities, and services.

## Architecture Overview

The DI system consists of three main components:

1. **GameInjection** - Core dependency registration and management
2. **GameServiceLocator** - High-level API for accessing services
3. **GameSystemManager** - Dynamic system registration and lifecycle management

## Key Components

### GameInjection (`game_injection.dart`)

The core dependency injection configuration that handles:
- Registration of core game systems (EntityManager, GameSystemManager)
- Registration of entity factories (PlayerEntityFactory, BallEntityFactory, TileEntityFactory)
- System lifecycle management (register, unregister, reset)

### GameServiceLocator (`../domain/services/game_service_locator.dart`)

A high-level service locator that provides:
- Easy access to core systems and game systems
- Entity factory access
- System registration and management
- Batch system operations

### GameSystemManager

Manages dynamic registration of game systems:
- Register/unregister systems at runtime
- System initialization and updates
- System disposal and cleanup

## Usage Examples

### Basic Setup

```dart
// Initialize game dependencies (usually at app startup)
await GameInjection.initializeGameDependencies();

// Register game systems
GameServiceLocator.registerSystem<MovementSystem>(MovementSystem());
GameServiceLocator.registerSystem<CollisionSystem>(CollisionSystem());

// Initialize all systems
await GameServiceLocator.initializeAllSystems();
```

### Accessing Systems

```dart
// Get core systems
final entityManager = GameServiceLocator.entityManager;

// Get game systems
final movementSystem = GameServiceLocator.getGameSystem<MovementSystem>();
final collisionSystem = GameServiceLocator.getGameSystem<CollisionSystem>();

// Check system availability
if (GameServiceLocator.hasGameSystem<RenderSystem>()) {
  final renderSystem = GameServiceLocator.getGameSystem<RenderSystem>();
  // Use render system
}
```

### Entity Factories

```dart
// Get entity factories
final playerFactory = GameServiceLocator.getFactory<PlayerEntityFactory>();
final ballFactory = GameServiceLocator.getFactory<BallEntityFactory>();

// Create entities (when concrete implementations are available)
// final player = GameServiceLocator.createEntity<PlayerEntity>(
//   id: 'player_1',
//   parameters: {'startPosition': Vector2(100, 100)},
// );
```

### Game Loop Integration

```dart
class GameLoop {
  void update(double deltaTime) {
    // Update all active systems
    GameServiceLocator.updateAllSystems(deltaTime);
  }
  
  void dispose() {
    // Clean up all systems
    GameServiceLocator.disposeAllSystems();
  }
}
```

### Batch Operations

```dart
// Get multiple systems at once
final coreSystems = GameServiceLocator.getGameSystems([
  MovementSystem,
  CollisionSystem,
  RenderSystem,
]);

// Get all registered systems
final allSystems = GameServiceLocator.getAllGameSystems();
```

## System Registration Patterns

### Core Systems (Singletons)
Core systems like EntityManager are registered as singletons and available throughout the application lifecycle.

### Game Systems (Dynamic)
Game systems can be registered and unregistered dynamically through the GameSystemManager.

### Entity Factories (Factories)
Entity factories are registered as factories, creating new instances each time they're requested.

## Testing

The DI system includes comprehensive tests that verify:
- System registration and retrieval
- System lifecycle management
- Entity factory access
- Batch operations
- System disposal

Run tests with:
```bash
flutter test test/features/game/di/dependency_injection_test.dart
```

## Best Practices

1. **Initialize Early**: Call `GameInjection.initializeGameDependencies()` at app startup
2. **Register Systems**: Register all game systems before starting the game loop
3. **Use Service Locator**: Access systems through `GameServiceLocator` for consistency
4. **Clean Up**: Call `disposeAllSystems()` when shutting down the game
5. **Check Availability**: Always check if systems are available before using them

## Integration with Main App

The DI system is integrated with the main app through `lib/core/di/injection_container.dart`:

```dart
Future<void> initializeDependencies() async {
  // ... other dependencies
  
  // Initialize game-specific dependencies
  await GameInjection.initializeGameDependencies();
  
  // Register additional game systems
  await _registerGameSystems();
}
```

This ensures that game dependencies are properly initialized when the app starts.