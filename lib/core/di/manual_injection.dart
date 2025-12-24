import 'package:get_it/get_it.dart';
import 'package:hard_hat/core/services/asset_manager.dart';
import 'package:hard_hat/core/services/audio_manager.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

final GetIt getIt = GetIt.instance;

/// Simple AudioStateManager implementation for manual DI
/// This extends the real AudioStateManager but provides minimal functionality
class SimpleAudioStateManager extends AudioStateManager {
  final AudioManager _audioManager;
  
  SimpleAudioStateManager(this._audioManager) 
    : super(_createMinimalAudioSystem(), _audioManager);
  
  static AudioSystem? _minimalAudioSystem;
  
  static AudioSystem _createMinimalAudioSystem() {
    // Create a minimal AudioSystem only once to avoid repeated initialization
    if (_minimalAudioSystem == null) {
      try {
        _minimalAudioSystem = AudioSystem();
        _minimalAudioSystem!.setEntityManager(EntityManagerImpl() as EntityManager);
      } catch (e) {
        // If AudioSystem creation fails, create a null-safe fallback
        // This is a last resort to prevent crashes
        throw Exception('Failed to create minimal AudioSystem: $e');
      }
    }
    return _minimalAudioSystem!;
  }
  
  @override
  void pauseAudio() {
    try {
      // Call parent implementation first
      super.pauseAudio();
    } catch (e) {
      // Fallback to audio manager only
      try {
        _audioManager.pauseAll();
      } catch (e2) {
        // Ignore all errors in simple implementation
      }
    }
  }
  
  @override
  void resumeAudio() {
    try {
      // Call parent implementation first
      super.resumeAudio();
    } catch (e) {
      // Fallback to audio manager only
      try {
        _audioManager.resumeAll();
      } catch (e2) {
        // Ignore all errors in simple implementation
      }
    }
  }
}

/// Manual dependency injection setup
/// This will be replaced by injectable generated code later
Future<void> setupManualDependencies() async {
  // Core Services
  getIt.registerLazySingleton<AssetManager>(() => AssetManager());
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());
  
  // Entity Manager
  getIt.registerLazySingleton<IEntityManager>(() => EntityManagerImpl());
  
  // Game Systems
  getIt.registerLazySingleton<InputSystem>(() {
    final system = InputSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  getIt.registerLazySingleton<CollisionSystem>(() {
    final system = CollisionSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    
    // Wire up system integrations (will be set after all systems are created)
    return system;
  });
  
  getIt.registerLazySingleton<AudioSystem>(() {
    final system = AudioSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  getIt.registerLazySingleton<CameraSystem>(() {
    final system = CameraSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  getIt.registerLazySingleton<MovementSystem>(() {
    final system = MovementSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  getIt.registerLazySingleton<RenderSystem>(() {
    final system = RenderSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
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
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  getIt.registerLazySingleton<IPlayerPhysicsSystem>(() {
    final system = PlayerPhysicsSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  getIt.registerLazySingleton<ITileDamageSystem>(() {
    final system = TileDamageSystem();
    // TileDamageSystem doesn't need entity manager injection
    return system;
  });
  
  getIt.registerLazySingleton<ITileStateSystem>(() {
    final system = TileStateSystem();
    system.setEntityManager(getIt<IEntityManager>() as EntityManager);
    return system;
  });
  
  // Audio State Manager (simplified version without audio system dependency)
  getIt.registerLazySingleton<AudioStateManager>(() => SimpleAudioStateManager(
    getIt<AudioManager>(),
  ));
  
  // Game State Manager
  getIt.registerLazySingleton<IGameStateManager>(() => GameStateManagerImpl(
    getIt<AudioStateManager>(),
  ));
  
  // Focus Detector
  getIt.registerLazySingleton<FocusDetector>(() => FocusDetector.instance);
  
  // ECS Orchestrator with all systems properly registered
  getIt.registerLazySingleton<ECSOrchestrator>(() => ECSOrchestrator(
    entityManager: getIt<IEntityManager>(),
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