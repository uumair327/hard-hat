import 'package:get_it/get_it.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/data/data.dart';
import 'package:hard_hat/features/game/presentation/presentation.dart';

/// Game-specific dependency injection configuration
/// This maintains proper separation from core dependencies
class GameInjection {
  static final GetIt _sl = GetIt.instance;

  /// Initialize game-specific dependencies
  static Future<void> initializeGameDependencies() async {
    // Check if already initialized to prevent duplicate registrations
    // Use GameBloc as marker since it's only registered in game injection
    if (_sl.isRegistered<GameBloc>()) {
      return; // Already initialized
    }
    
    // Game Data Layer
    _sl.registerLazySingleton<LevelLocalDataSource>(() => LevelLocalDataSourceImpl());
    _sl.registerLazySingleton<SaveLocalDataSource>(() => SaveLocalDataSourceImpl());
    
    // Game Repositories
    _sl.registerLazySingleton<LevelRepository>(() => LevelRepositoryImpl(_sl()));
    _sl.registerLazySingleton<SaveRepository>(() => SaveRepositoryImpl(_sl()));
    
    // Game Use Cases
    _sl.registerLazySingleton<LoadLevel>(() => LoadLevelImpl(_sl()));
    _sl.registerLazySingleton<SaveProgress>(() => SaveProgressImpl(_sl()));
    
    // Game Domain Services (only register what's not already in manual injection)
    _sl.registerLazySingleton<IMovementSystem>(() => MovementSystem());
    _sl.registerLazySingleton<CollisionSystem>(() => CollisionSystem());
    _sl.registerLazySingleton<InputSystem>(() => InputSystem());
    _sl.registerLazySingleton<AudioSystem>(() => AudioSystem());
    _sl.registerLazySingleton<GameStateManager>(() => GameStateManager(_sl()));
    _sl.registerLazySingleton<CameraSystem>(() => CameraSystem());
    _sl.registerLazySingleton<RenderSystem>(() => RenderSystem());
    _sl.registerLazySingleton<ParticleSystem>(() => ParticleSystem());
    _sl.registerLazySingleton<StateTransitionSystem>(() => StateTransitionSystem());
    _sl.registerLazySingleton<LevelManager>(() => LevelManager(
      levelRepository: _sl(),
      entityManager: _sl(),
    ));
    _sl.registerLazySingleton<SaveSystem>(() => SaveSystem(_sl()));
    _sl.registerLazySingleton<PlayerStateSystem>(() => PlayerStateSystem());
    _sl.registerLazySingleton<PlayerPhysicsSystem>(() => PlayerPhysicsSystem());
    _sl.registerLazySingleton<TileDamageSystem>(() => TileDamageSystem());
    _sl.registerLazySingleton<TileStateSystem>(() => TileStateSystem());
    
    // Game Controller (Domain) - already registered in manual injection
    // All orchestrators are already registered in manual injection
    
    // Game Presentation Layer
    _sl.registerFactory(() => GameBloc(
      loadLevel: _sl(),
      saveProgress: _sl(),
      gameStateManager: _sl<GameStateManager>(),
    ));
    
    // System Manager for dynamic system registration
    _sl.registerLazySingleton<GameSystemManager>(() => GameSystemManager());
  }

  /// Register pause menu service (called from presentation layer)
  static void registerPauseMenuService(PauseMenuService pauseMenuService) {
    _sl.registerLazySingleton<PauseMenuService>(() => pauseMenuService);
    
    // Now we can create the pause menu manager
    _sl.registerLazySingleton<PauseMenuManager>(() => PauseMenuManager(
      _sl(), // GameStateManager
      _sl(), // FocusDetector
      _sl(), // PauseMenuService
    ));
  }

  /// Get a game system instance
  static T getSystem<T extends Object>() {
    return _sl.get<T>();
  }

  /// Get an entity factory
  static T getFactory<T extends Object>() {
    return _sl.get<T>();
  }

  /// Get the system manager
  static GameSystemManager getSystemManager() {
    return _sl.get<GameSystemManager>();
  }

  /// Register a new game system dynamically
  static void registerSystem<T extends GameSystem>(T system) {
    final manager = getSystemManager();
    manager.registerSystem<T>(system);
  }

  /// Unregister a game system
  static void unregisterSystem<T extends GameSystem>() {
    final manager = getSystemManager();
    manager.unregisterSystem<T>();
  }

  /// Check if a system is registered
  static bool isSystemRegistered<T extends GameSystem>() {
    final manager = getSystemManager();
    return manager.isSystemRegistered<T>();
  }

  /// Get all registered systems
  static Map<Type, GameSystem> getAllSystems() {
    final manager = getSystemManager();
    return manager.getAllSystems();
  }

  /// Reset all game dependencies (useful for testing)
  static Future<void> resetGameDependencies() async {
    // Clear system manager first
    if (_sl.isRegistered<GameSystemManager>()) {
      final manager = _sl.get<GameSystemManager>();
      manager.clearAllSystems();
    }
    
    // Unregister game-specific dependencies
    final gameTypes = [
      EntityManager,
      MovementSystem,
      CollisionSystem,
      InputSystem,
      AudioSystem,
      AudioStateManager,
      GameStateManager,
      CameraSystem,
      RenderSystem,
      ParticleSystem,
      StateTransitionSystem,
      LevelManager,
      SaveSystem,
      GameController,
      FocusDetector,
      PauseMenuManager,
      GameSystemManager,
    ];
    
    for (final type in gameTypes) {
      if (_sl.isRegistered(instance: type)) {
        await _sl.unregister(instance: type);
      }
    }
    
    // Re-initialize game dependencies
    await initializeGameDependencies();
  }
}

/// Abstract factory for creating game entities
abstract class EntityFactory<T extends GameEntity> {
  /// Create a new entity instance
  T create({required String id, Map<String, dynamic>? parameters});
  
  /// Create multiple entities
  List<T> createMultiple(int count, {Map<String, dynamic>? parameters}) {
    return List.generate(count, (index) => 
        create(id: '${T.toString()}_$index', parameters: parameters));
  }
}

/// Factory for creating player entities
class PlayerEntityFactory extends EntityFactory<GameEntity> {
  @override
  GameEntity create({required String id, Map<String, dynamic>? parameters}) {
    // This will be implemented when we create the PlayerEntity class
    throw UnimplementedError('PlayerEntity not yet implemented');
  }
}

/// Factory for creating ball entities
class BallEntityFactory extends EntityFactory<GameEntity> {
  @override
  GameEntity create({required String id, Map<String, dynamic>? parameters}) {
    // This will be implemented when we create the BallEntity class
    throw UnimplementedError('BallEntity not yet implemented');
  }
}

/// Factory for creating tile entities
class TileEntityFactory extends EntityFactory<GameEntity> {
  @override
  GameEntity create({required String id, Map<String, dynamic>? parameters}) {
    // This will be implemented when we create the TileEntity class
    throw UnimplementedError('TileEntity not yet implemented');
  }
}

/// Manager for dynamically registering and managing game systems
class GameSystemManager {
  /// Map of registered systems by type
  final Map<Type, GameSystem> _systems = {};
  
  /// Register a new game system
  void registerSystem<T extends GameSystem>(T system) {
    _systems[T] = system;
  }
  
  /// Unregister a game system
  void unregisterSystem<T extends GameSystem>() {
    _systems.remove(T);
  }
  
  /// Get a specific system
  T? getSystem<T extends GameSystem>() {
    return _systems[T] as T?;
  }
  
  /// Check if a system is registered
  bool isSystemRegistered<T extends GameSystem>() {
    return _systems.containsKey(T);
  }
  
  /// Get all registered systems
  Map<Type, GameSystem> getAllSystems() {
    return Map.unmodifiable(_systems);
  }
  
  /// Get systems of a specific base type
  Iterable<T> getSystemsOfType<T extends GameSystem>() {
    return _systems.values.whereType<T>();
  }
  
  /// Clear all systems
  void clearAllSystems() {
    _systems.clear();
  }
  
  /// Get system count
  int get systemCount => _systems.length;
  
  /// Initialize all registered systems
  Future<void> initializeAllSystems() async {
    for (final system in _systems.values) {
      await system.initialize();
    }
  }
  
  /// Update all active systems
  void updateAllSystems(double deltaTime) {
    for (final system in _systems.values) {
      if (system.isActive) {
        system.updateSystem(deltaTime);
      }
    }
  }
  
  /// Dispose all systems
  void disposeAllSystems() {
    for (final system in _systems.values) {
      system.dispose();
    }
    clearAllSystems();
  }
}