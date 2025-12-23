import 'package:get_it/get_it.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/systems/input_system.dart';
import 'package:hard_hat/features/game/domain/systems/audio_system.dart';
import 'package:hard_hat/features/game/domain/systems/audio_state_manager.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';
import 'package:hard_hat/features/game/domain/systems/camera_system.dart';
import 'package:hard_hat/features/game/domain/systems/render_system.dart';
import 'package:hard_hat/features/game/domain/systems/particle_system.dart';
import 'package:hard_hat/features/game/domain/systems/state_transition_system.dart';
import 'package:hard_hat/features/game/domain/systems/level_manager.dart';
import 'package:hard_hat/features/game/domain/systems/save_system.dart';
import 'package:hard_hat/features/game/domain/systems/movement_system.dart';
import 'package:hard_hat/features/game/domain/systems/collision_system.dart';
import 'package:hard_hat/features/game/domain/entities/game_entity.dart';
import 'package:hard_hat/features/game/domain/services/game_controller.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_service.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_manager.dart';
import 'package:hard_hat/features/game/domain/services/focus_detector.dart';
import 'package:hard_hat/features/game/data/datasources/level_local_datasource.dart';
import 'package:hard_hat/features/game/data/datasources/save_local_datasource.dart';
import 'package:hard_hat/features/game/data/repositories/level_repository_impl.dart';
import 'package:hard_hat/features/game/data/repositories/save_repository_impl.dart';
import 'package:hard_hat/features/game/domain/repositories/level_repository.dart';
import 'package:hard_hat/features/game/domain/repositories/save_repository.dart';
import 'package:hard_hat/features/game/domain/usecases/load_level.dart';
import 'package:hard_hat/features/game/domain/usecases/save_progress.dart';
import 'package:hard_hat/features/game/presentation/bloc/game_bloc.dart';
import 'package:hard_hat/core/services/asset_manager.dart';
import 'package:hard_hat/core/services/audio_manager.dart';
import 'package:hard_hat/core/di/injection_container.dart';

/// Game-specific dependency injection configuration
/// This maintains proper separation from core dependencies
class GameInjection {
  static final GetIt _sl = GetIt.instance;

  /// Initialize game-specific dependencies
  static Future<void> initializeGameDependencies() async {
    // Game Data Layer
    _sl.registerLazySingleton<LevelLocalDataSource>(() => LevelLocalDataSourceImpl());
    _sl.registerLazySingleton<SaveLocalDataSource>(() => SaveLocalDataSourceImpl());
    
    // Game Repositories
    _sl.registerLazySingleton<LevelRepository>(() => LevelRepositoryImpl(_sl()));
    _sl.registerLazySingleton<SaveRepository>(() => SaveRepositoryImpl(_sl()));
    
    // Game Use Cases
    _sl.registerLazySingleton(() => LoadLevel(_sl()));
    _sl.registerLazySingleton(() => SaveProgress(_sl()));
    
    // Game Domain Services
    _sl.registerLazySingleton<EntityManager>(() => EntityManager());
    _sl.registerLazySingleton<MovementSystem>(() => MovementSystem());
    _sl.registerLazySingleton<CollisionSystem>(() => CollisionSystem());
    _sl.registerLazySingleton<InputSystem>(() => InputSystem());
    _sl.registerLazySingleton<AudioSystem>(() => AudioSystem(sl()));
    _sl.registerLazySingleton<AudioStateManager>(() => AudioStateManager(
      _sl(), 
      sl()
    ));
    _sl.registerLazySingleton<GameStateManager>(() => GameStateManager(
      _sl()
    ));
    _sl.registerLazySingleton<CameraSystem>(() => CameraSystem());
    _sl.registerLazySingleton<RenderSystem>(() => RenderSystem(
      enableBatching: true,
      maxBatchSize: 1000,
      enableParticlePooling: true,
    ));
    _sl.registerLazySingleton<ParticleSystem>(() => ParticleSystem());
    _sl.registerLazySingleton<StateTransitionSystem>(() => StateTransitionSystem());
    _sl.registerLazySingleton<LevelManager>(() => LevelManager(
      levelRepository: _sl(),
      entityManager: _sl(),
    ));
    _sl.registerLazySingleton<SaveSystem>(() => SaveSystem(_sl()));
    _sl.registerLazySingleton<FocusDetector>(() => FocusDetector.instance);
    
    // Game Controller (Domain)
    _sl.registerLazySingleton<GameController>(() => GameController());
    
    // Game Presentation Layer
    _sl.registerFactory(() => GameBloc(
      loadLevel: _sl(),
      saveProgress: _sl(),
      gameStateManager: _sl(),
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