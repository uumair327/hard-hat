import 'package:get_it/get_it.dart';
import 'package:hard_hat/core/services/asset_manager.dart';
import 'package:hard_hat/core/services/audio_manager.dart';
import 'package:hard_hat/features/game/domain/interfaces/entity_manager_interface.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_state_manager_interface.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_controller_interfaces.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager_impl.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager_impl.dart';
import 'package:hard_hat/features/game/domain/systems/audio_state_manager.dart';
import 'package:hard_hat/features/game/domain/orchestrators/ecs_orchestrator.dart';
import 'package:hard_hat/features/game/domain/orchestrators/game_state_orchestrator.dart';
import 'package:hard_hat/features/game/domain/orchestrators/level_orchestrator.dart';
import 'package:hard_hat/features/game/domain/services/game_controller.dart';
import 'package:hard_hat/features/game/domain/services/focus_detector.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_manager.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_service.dart';

final GetIt getIt = GetIt.instance;

/// Simple AudioStateManager implementation for manual DI
class SimpleAudioStateManager extends AudioStateManager {
  SimpleAudioStateManager(AudioManager audioManager) 
    : super(null as dynamic, audioManager);
  
  @override
  void pauseAudio() {
    // Simple implementation without audio system
  }
  
  @override
  void resumeAudio() {
    // Simple implementation without audio system
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
  
  // Simplified Orchestrators (without complex system dependencies for now)
  getIt.registerLazySingleton<ECSOrchestrator>(() => ECSOrchestrator(
    entityManager: getIt<IEntityManager>(),
    // All systems set to null for now - will be implemented later
    movementSystem: null,
    collisionSystem: null,
    inputSystem: null,
    audioSystem: null,
    cameraSystem: null,
    renderSystem: null,
    particleSystem: null,
    stateTransitionSystem: null,
    playerStateSystem: null,
    playerPhysicsSystem: null,
    tileDamageSystem: null,
    tileStateSystem: null,
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
  
  // Pause Menu Manager (will be registered when PauseMenuService is available)
  // This is deferred until the presentation layer registers the service
}

/// Register pause menu manager after service is available
void registerPauseMenuManager(PauseMenuService pauseMenuService) {
  if (!getIt.isRegistered<PauseMenuService>()) {
    getIt.registerSingleton<PauseMenuService>(pauseMenuService);
  }
  
  if (!getIt.isRegistered<PauseMenuManager>()) {
    getIt.registerLazySingleton<PauseMenuManager>(() => PauseMenuManager(
      getIt<IGameStateManager>(),
      getIt<FocusDetector>(),
      getIt<PauseMenuService>(),
    ));
    
    // Update the GameStateOrchestrator with the pause menu manager
    final stateOrchestrator = getIt<GameStateOrchestrator>();
    stateOrchestrator.setPauseMenuManager(getIt<PauseMenuManager>());
  }
}