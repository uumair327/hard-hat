import 'package:get_it/get_it.dart';
import 'package:hard_hat/core/services/asset_manager.dart';
import 'package:hard_hat/core/services/audio_manager.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/data/data.dart';
import 'package:hard_hat/features/game/presentation/presentation.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart' as gsm;
import 'package:hard_hat/features/settings/domain/usecases/get_settings.dart';
import 'package:hard_hat/features/settings/domain/usecases/update_settings.dart';
import 'package:hard_hat/features/settings/domain/repositories/settings_repository.dart';
import 'package:hard_hat/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hard_hat/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:hard_hat/features/settings/presentation/bloc/settings_bloc.dart';

final GetIt getIt = GetIt.instance;

/// Simple AudioStateManager implementation for manual DI
/// This provides minimal functionality without complex dependencies
class SimpleAudioStateManager extends AudioStateManager {
  final AudioManager _audioManager;
  
  SimpleAudioStateManager(this._audioManager) : super(_createDummyAudioSystem(), _audioManager);
  
  static AudioSystem _createDummyAudioSystem() {
    // Create a dummy audio system that won't cause initialization issues
    final audioSystem = AudioSystem();
    // Don't set entity manager to avoid circular dependencies
    return audioSystem;
  }
  
  @override
  void pauseAudio() {
    try {
      _audioManager.pauseAll();
    } catch (e) {
      // Ignore errors in simple implementation
    }
  }
  
  @override
  void resumeAudio() {
    try {
      _audioManager.resumeAll();
    } catch (e) {
      // Ignore errors in simple implementation
    }
  }
}

/// Manual dependency injection setup
/// This will be replaced by injectable generated code later
Future<void> setupManualDependencies() async {
  // Core Services
  getIt.registerLazySingleton<AssetManager>(() => AssetManager());
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());
  
  // Entity Manager - register both interface and concrete class
  getIt.registerLazySingleton<IEntityManager>(() => EntityManagerImpl());
  getIt.registerLazySingleton<EntityManager>(() => EntityManager());
  
  // Game Systems
  getIt.registerLazySingleton<InputSystem>(() {
    final system = InputSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  // Register InputSystem as interface too
  getIt.registerLazySingleton<IInputSystem>(() => getIt<InputSystem>());
  
  getIt.registerLazySingleton<CollisionSystem>(() {
    final system = CollisionSystem();
    system.setEntityManager(getIt<EntityManager>());
    
    // Wire up system integrations (will be set after all systems are created)
    return system;
  });
  
  // Register CollisionSystem as interface too
  getIt.registerLazySingleton<ICollisionSystem>(() => getIt<CollisionSystem>());
  
  getIt.registerLazySingleton<AudioSystem>(() {
    final system = AudioSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  // Register AudioSystem as interface too
  getIt.registerLazySingleton<IAudioSystem>(() => getIt<AudioSystem>());
  
  getIt.registerLazySingleton<CameraSystem>(() {
    final system = CameraSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  // Register CameraSystem as interface too
  getIt.registerLazySingleton<ICameraSystem>(() => getIt<CameraSystem>());
  
  getIt.registerLazySingleton<MovementSystem>(() {
    final system = MovementSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  // Register MovementSystem as interface too
  getIt.registerLazySingleton<IMovementSystem>(() => getIt<MovementSystem>());
  
  getIt.registerLazySingleton<RenderSystem>(() {
    final system = RenderSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  // Register RenderSystem as interface too
  getIt.registerLazySingleton<IRenderSystem>(() => getIt<RenderSystem>());
  
  // Register additional systems
  getIt.registerLazySingleton<IParticleSystem>(() {
    final system = ParticleSystem();
    // ParticleSystem doesn't need entity manager injection
    return system;
  });
  
  getIt.registerLazySingleton<IStateTransitionSystem>(() {
    final system = StateTransitionSystem();
    // StateTransitionSystem doesn't need entity manager injection
    return system;
  });
  
  getIt.registerLazySingleton<IPlayerStateSystem>(() {
    final system = PlayerStateSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  getIt.registerLazySingleton<IPlayerPhysicsSystem>(() {
    final system = PlayerPhysicsSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  getIt.registerLazySingleton<ITileDamageSystem>(() {
    final system = TileDamageSystem();
    // TileDamageSystem doesn't need entity manager injection
    return system;
  });
  
  getIt.registerLazySingleton<ITileStateSystem>(() {
    final system = TileStateSystem();
    system.setEntityManager(getIt<EntityManager>());
    return system;
  });
  
  // Audio State Manager (simplified version without audio system dependency)
  getIt.registerLazySingleton<AudioStateManager>(() => SimpleAudioStateManager(
    getIt<AudioManager>(),
  ));
  
  // Game State Manager (concrete class for GameBloc)
  getIt.registerLazySingleton<gsm.GameStateManager>(() => gsm.GameStateManager(
    getIt<AudioStateManager>(),
  ));
  
  // Game State Manager Interface (for other systems)
  getIt.registerLazySingleton<IGameStateManager>(() => GameStateManagerImpl(
    getIt<AudioStateManager>(),
  ));
  
  // Focus Detector
  getIt.registerLazySingleton<FocusDetector>(() => FocusDetector.instance);
  
  // ECS Orchestrator with all systems properly registered
  getIt.registerLazySingleton<ECSOrchestrator>(() => ECSOrchestrator(
    entityManager: getIt<EntityManager>(),
    movementSystem: getIt<MovementSystem>(),
    collisionSystem: getIt<CollisionSystem>(),
    inputSystem: getIt<InputSystem>(),
    audioSystem: getIt<AudioSystem>(),
    cameraSystem: getIt<CameraSystem>(),
    renderSystem: getIt<RenderSystem>(),
    particleSystem: getIt<IParticleSystem>(),
    stateTransitionSystem: getIt<IStateTransitionSystem>(),
    playerStateSystem: getIt<IPlayerStateSystem>(),
    playerPhysicsSystem: getIt<IPlayerPhysicsSystem>(),
    tileDamageSystem: getIt<ITileDamageSystem>(),
    tileStateSystem: getIt<ITileStateSystem>(),
  ));
  
  getIt.registerLazySingleton<GameStateOrchestrator>(() => GameStateOrchestrator(
    gameStateManager: getIt<IGameStateManager>(),
    pauseMenuManager: null, // Will be set when pause menu service is available
    focusDetector: getIt<FocusDetector>(),
  ));
  
  getIt.registerLazySingleton<LevelOrchestrator>(() => LevelOrchestrator(
    levelManager: null, // Placeholder - will be implemented later
    saveSystem: null, // Placeholder - will be implemented later
    entityManager: getIt<IEntityManager>(),
  ));
  
  // Game Controller
  getIt.registerLazySingleton<IGameController>(() => GameController(
    ecsOrchestrator: getIt<ECSOrchestrator>(),
    stateOrchestrator: getIt<GameStateOrchestrator>(),
    levelOrchestrator: getIt<LevelOrchestrator>(),
  ));
  
  // Game Data Layer (needed for GameBloc)
  getIt.registerLazySingleton<LevelLocalDataSource>(() => LevelLocalDataSourceImpl());
  getIt.registerLazySingleton<SaveLocalDataSource>(() => SaveLocalDataSourceImpl());
  
  // Game Repositories (needed for GameBloc)
  getIt.registerLazySingleton<LevelRepository>(() => LevelRepositoryImpl(getIt<LevelLocalDataSource>()));
  getIt.registerLazySingleton<SaveRepository>(() => SaveRepositoryImpl(getIt<SaveLocalDataSource>()));
  
  // Game Use Cases (needed for GameBloc)
  getIt.registerLazySingleton<LoadLevel>(() => LoadLevelImpl(getIt<LevelRepository>()));
  getIt.registerLazySingleton<SaveProgress>(() => SaveProgressImpl(getIt<SaveRepository>()));
  
  // Game Presentation Layer
  getIt.registerFactory(() => GameBloc(
    loadLevel: getIt<LoadLevel>(),
    saveProgress: getIt<SaveProgress>(),
    gameStateManager: getIt<gsm.GameStateManager>(),
  ));
  
  // Settings Data Layer
  getIt.registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl());
  
  // Settings Repositories
  getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()));
  
  // Settings Use Cases
  getIt.registerLazySingleton<GetSettings>(() => GetSettings(getIt<SettingsRepository>()));
  getIt.registerLazySingleton<UpdateSettings>(() => UpdateSettings(getIt<SettingsRepository>()));
  
  // Settings Presentation Layer
  getIt.registerFactory(() => SettingsBloc(
    getSettings: getIt<GetSettings>(),
    updateSettings: getIt<UpdateSettings>(),
  ));
  
  // Wire up system integrations after all systems are registered
  _wireSystemIntegrations();
}

/// Wire up system integrations after all systems are created
void _wireSystemIntegrations() {
  // Get the collision system and wire it up with other systems
  final collisionSystem = getIt<CollisionSystem>();
  
  // Wire up tile damage system
  try {
    final tileDamageSystem = getIt<ITileDamageSystem>();
    collisionSystem.setTileDamageSystem(tileDamageSystem);
    
    // Wire up tile damage system with particle and audio systems
    if (tileDamageSystem is TileDamageSystem) {
      try {
        final particleSystem = getIt<IParticleSystem>();
        tileDamageSystem.setParticleSystem(particleSystem);
      } catch (e) {
        // Particle system not available yet
      }
      
      try {
        final audioSystem = getIt<AudioSystem>();
        tileDamageSystem.setAudioSystem(audioSystem);
      } catch (e) {
        // Audio system not available yet
      }
    }
  } catch (e) {
    // Tile damage system not available yet
  }
  
  // Wire up particle system
  try {
    final particleSystem = getIt<IParticleSystem>();
    collisionSystem.setParticleSystem(particleSystem);
  } catch (e) {
    // Particle system not available yet
  }
  
  // Wire up audio system
  try {
    final audioSystem = getIt<AudioSystem>();
    collisionSystem.setAudioSystem(audioSystem);
    
    // Wire up audio system to game state manager
    try {
      final gameStateManager = getIt<IGameStateManager>();
      if (gameStateManager is GameStateManagerImpl) {
        gameStateManager.setAudioSystem(audioSystem);
      }
    } catch (e) {
      // Game state manager not available yet
    }
  } catch (e) {
    // Audio system not available yet
  }
  
  // Wire up camera system
  try {
    final cameraSystem = getIt<CameraSystem>();
    collisionSystem.setCameraSystem(cameraSystem);
  } catch (e) {
    // Camera system not available yet
  }
}

/// Register pause menu manager after service is available
void registerPauseMenuManager(PauseMenuService pauseMenuService) {
  if (!getIt.isRegistered<PauseMenuService>()) {
    getIt.registerSingleton<PauseMenuService>(pauseMenuService);
  }
  
  if (!getIt.isRegistered<IPauseMenuManager>()) {
    getIt.registerLazySingleton<IPauseMenuManager>(() => PauseMenuManager(
      getIt<IGameStateManager>(),
      getIt<FocusDetector>(),
      getIt<PauseMenuService>(),
    ));
    
    // Update the GameStateOrchestrator with the pause menu manager
    final stateOrchestrator = getIt<GameStateOrchestrator>();
    stateOrchestrator.setPauseMenuManager(getIt<IPauseMenuManager>() as PauseMenuManager);
  }
}