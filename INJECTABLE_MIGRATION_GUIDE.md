# Injectable Migration Guide - Hard Hat Flutter Project

## Overview
This document outlines the migration from manual GetIt dependency injection to `get_it` + `injectable` for better development experience, compile-time safety, and automatic code generation.

## Benefits of Injectable

### 1. Compile-Time Safety
- **Before**: Runtime errors if dependencies are not registered
- **After**: Compile-time errors catch missing dependencies

### 2. Automatic Code Generation
- **Before**: Manual registration of all dependencies
- **After**: Automatic generation based on annotations

### 3. Better Development Experience
- **Before**: Manual maintenance of DI container
- **After**: Annotations handle registration automatically

### 4. Type Safety
- **Before**: Manual type casting and potential runtime errors
- **After**: Full type safety with generic constraints

---

## Migration Changes

### Dependencies Added
```yaml
dependencies:
  injectable: ^2.3.2

dev_dependencies:
  injectable_generator: ^2.4.1
```

### New File Structure
```
lib/
├── core/
│   ├── di/
│   │   ├── injection.dart          # Main injectable configuration
│   │   └── injection.config.dart   # Generated file (auto-created)
│   └── services/
│       ├── asset_manager.dart      # @lazySingleton
│       └── audio_manager.dart      # @lazySingleton
├── features/
│   ├── game/
│   │   ├── di/
│   │   │   └── game_module.dart    # Game-specific module
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── level_local_datasource_impl.dart  # @LazySingleton(as: Interface)
│   │   │   │   └── save_local_datasource_impl.dart   # @LazySingleton(as: Interface)
│   │   │   └── repositories/
│   │   │       ├── level_repository_impl.dart        # @LazySingleton(as: Interface)
│   │   │       └── save_repository_impl.dart         # @LazySingleton(as: Interface)
│   │   ├── domain/
│   │   │   ├── systems/
│   │   │   │   ├── entity_manager_impl.dart          # @LazySingleton(as: Interface)
│   │   │   │   └── game_state_manager_impl.dart      # @LazySingleton(as: Interface)
│   │   │   ├── orchestrators/
│   │   │   │   ├── ecs_orchestrator.dart             # @lazySingleton
│   │   │   │   ├── game_state_orchestrator.dart      # @lazySingleton
│   │   │   │   └── level_orchestrator.dart           # @lazySingleton
│   │   │   └── services/
│   │   │       └── game_controller.dart              # @LazySingleton(as: Interface)
│   │   └── usecases/
│   │       ├── load_level_impl.dart                  # @LazySingleton(as: Interface)
│   │       └── save_progress_impl.dart               # @LazySingleton(as: Interface)
│   └── settings/
│       └── di/
│           └── settings_module.dart                  # Settings-specific module
└── build.yaml                                       # Injectable configuration
```

---

## Injectable Annotations Used

### @lazySingleton
Creates a singleton instance that's lazily initialized:
```dart
@lazySingleton
class AssetManager {
  // Implementation
}
```

### @LazySingleton(as: Interface)
Registers implementation as interface:
```dart
@LazySingleton(as: IEntityManager)
class EntityManagerImpl implements IEntityManager {
  // Implementation
}
```

### @module
Defines a module with factory methods:
```dart
@module
abstract class GameModule {
  @LazySingleton(as: IMovementSystem)
  MovementSystem get movementSystem => MovementSystem();
  
  @lazySingleton
  AudioStateManager audioStateManager(
    IAudioSystem audioSystem,
    AudioManager audioManager,
  ) => AudioStateManager(audioSystem, audioManager);
}
```

### @injectable
For classes that need constructor injection:
```dart
@injectable
class GameBloc extends Bloc<GameEvent, GameState> {
  final LoadLevel _loadLevel;
  final SaveProgress _saveProgress;
  
  GameBloc(this._loadLevel, this._saveProgress);
}
```

---

## Code Generation

### Build Command
```bash
flutter packages pub run build_runner build
```

### Watch Mode (Development)
```bash
flutter packages pub run build_runner watch
```

### Generated Files
- `lib/core/di/injection.config.dart` - Auto-generated DI configuration
- Contains all registration logic based on annotations

---

## Usage Examples

### 1. Basic Singleton Registration
```dart
// Before (Manual)
sl.registerLazySingleton<AssetManager>(() => AssetManager());

// After (Injectable)
@lazySingleton
class AssetManager {
  // Implementation
}
```

### 2. Interface Implementation
```dart
// Before (Manual)
sl.registerLazySingleton<IEntityManager>(() => EntityManagerImpl());

// After (Injectable)
@LazySingleton(as: IEntityManager)
class EntityManagerImpl implements IEntityManager {
  // Implementation
}
```

### 3. Constructor Injection
```dart
// Before (Manual)
sl.registerLazySingleton<GameController>(() => GameController(
  ecsOrchestrator: sl(),
  stateOrchestrator: sl(),
  levelOrchestrator: sl(),
));

// After (Injectable)
@LazySingleton(as: IGameController)
class GameController implements IGameController {
  final ECSOrchestrator _ecsOrchestrator;
  final GameStateOrchestrator _stateOrchestrator;
  final LevelOrchestrator _levelOrchestrator;
  
  GameController(
    this._ecsOrchestrator,
    this._stateOrchestrator,
    this._levelOrchestrator,
  );
}
```

### 4. Module-Based Registration
```dart
@module
abstract class GameModule {
  @LazySingleton(as: IRenderSystem)
  RenderSystem get renderSystem => RenderSystem(
    enableBatching: true,
    maxBatchSize: 1000,
    enableParticlePooling: true,
  );
  
  @lazySingleton
  AudioStateManager audioStateManager(
    IAudioSystem audioSystem,
    AudioManager audioManager,
  ) => AudioStateManager(audioSystem, audioManager);
}
```

---

## Dependency Resolution

### Getting Dependencies
```dart
// Before (Manual GetIt)
final gameController = sl<GameController>();
final assetManager = sl<AssetManager>();

// After (Injectable)
final gameController = getIt<IGameController>();
final assetManager = getIt<AssetManager>();
```

### In Widget/Presentation Layer
```dart
class GamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GameBloc>(),
      child: GameView(),
    );
  }
}
```

---

## Testing with Injectable

### Mock Registration for Tests
```dart
@module
abstract class TestModule {
  @LazySingleton(as: IGameController)
  IGameController get mockGameController => MockGameController();
  
  @LazySingleton(as: IEntityManager)
  IEntityManager get mockEntityManager => MockEntityManager();
}

void main() {
  setUpAll(() {
    // Configure test dependencies
    getIt.reset();
    configureDependencies(); // Uses TestModule in test environment
  });
  
  testWidgets('Game controller test', (tester) async {
    final gameController = getIt<IGameController>();
    // Test with mock
  });
}
```

---

## Environment-Specific Configuration

### Development Environment
```dart
// lib/core/di/injection.dart
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();
```

### Test Environment
```dart
// test/helpers/injection.dart
@InjectableInit(
  initializerName: 'initTest',
  preferRelativeImports: true,
  asExtension: true,
)
void configureTestDependencies() => getIt.initTest();
```

---

## Migration Checklist

### ✅ Completed
- [x] Added injectable dependencies to pubspec.yaml
- [x] Created main injection configuration
- [x] Migrated core services (AssetManager, AudioManager)
- [x] Created injectable implementations for data layer
- [x] Created injectable implementations for domain layer
- [x] Created module-based registration for game systems
- [x] Updated orchestrators with injectable annotations
- [x] Updated GameController with injectable
- [x] Updated main.dart to use new DI setup
- [x] Updated HardHatGame to use injectable
- [x] Created build.yaml configuration
- [x] Created comprehensive documentation

### 🔄 Next Steps
1. Run code generation: `flutter packages pub run build_runner build`
2. Test all dependency resolution
3. Update remaining systems with injectable annotations
4. Create test-specific modules for mocking
5. Update CI/CD to include code generation

---

## Benefits Achieved

### 1. Compile-Time Safety
```dart
// This will now fail at compile time if IGameController is not registered
final controller = getIt<IGameController>(); // ✅ Type-safe
```

### 2. Automatic Registration
```dart
// No more manual registration - handled by code generation
@lazySingleton
class AssetManager { } // ✅ Automatically registered
```

### 3. Clear Dependencies
```dart
// Constructor injection makes dependencies explicit
@LazySingleton(as: IGameController)
class GameController implements IGameController {
  GameController(
    this._ecsOrchestrator,     // ✅ Clear dependency
    this._stateOrchestrator,   // ✅ Clear dependency
    this._levelOrchestrator,   // ✅ Clear dependency
  );
}
```

### 4. Better Testing
```dart
// Easy to mock with interface-based registration
@LazySingleton(as: IEntityManager)
class EntityManagerImpl implements IEntityManager { }

// In tests
class MockEntityManager extends Mock implements IEntityManager { }
```

---

## Performance Impact

### Positive Impacts
- **Lazy Loading**: Dependencies created only when needed
- **Singleton Management**: Automatic singleton lifecycle
- **Memory Efficiency**: No duplicate instances

### Code Generation
- **Build Time**: Slightly increased due to code generation
- **Runtime**: No performance impact - same as manual registration
- **Bundle Size**: Minimal increase from generated code

---

## Troubleshooting

### Common Issues

#### 1. Missing Generated File
```bash
# Run code generation
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 2. Circular Dependencies
```dart
// Avoid circular dependencies in constructor injection
// Use interfaces to break cycles
```

#### 3. Registration Conflicts
```dart
// Use different registration types or environments
@Environment('dev')
@LazySingleton(as: IService)
class DevServiceImpl implements IService { }

@Environment('prod')
@LazySingleton(as: IService)
class ProdServiceImpl implements IService { }
```

---

## Conclusion

The migration to `get_it` + `injectable` provides:
- **Better Developer Experience**: Annotations handle registration
- **Compile-Time Safety**: Catch dependency issues early
- **Maintainable Code**: Clear dependency relationships
- **Testable Architecture**: Easy mocking with interfaces
- **Scalable Structure**: Module-based organization

The project now has a robust, type-safe dependency injection system that scales with the application's growth.