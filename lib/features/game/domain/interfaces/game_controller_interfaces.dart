import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';
import 'package:hard_hat/features/game/domain/entities/level.dart';

/// Segregated interfaces for game controller functionality
/// Follows ISP - clients depend only on what they need

/// Manages game initialization and lifecycle
abstract class IGameInitializer {
  Future<void> initializeGame();
  void dispose();
  bool get isInitialized;
}

/// Updates game systems
abstract class IGameUpdater {
  void update(double dt);
}

/// Provides game state information
abstract class IGameStateProvider {
  GameState get currentState;
  bool get isPlaying;
  bool get isPaused;
}

/// Manages level operations
abstract class ILevelController {
  Future<void> loadLevel(int levelId);
  Future<void> restartLevel();
}

/// Manages pause operations
abstract class IPauseController {
  void pauseGame();
  void resumeGame();
  void togglePauseMenu();
}

/// Manages navigation operations
abstract class INavigationController {
  void goToMenu();
}

/// Provides game event callbacks
abstract class IGameEventProvider {
  void Function(Level level)? get onLevelComplete;
  void Function(Level level)? get onLevelLoaded;
  void Function()? get onGameOver;
  
  set onLevelComplete(void Function(Level level)? callback);
  set onLevelLoaded(void Function(Level level)? callback);
  set onGameOver(void Function()? callback);
}

/// Complete game controller interface (composition of all interfaces)
abstract class IGameController implements 
    IGameInitializer,
    IGameUpdater,
    IGameStateProvider,
    ILevelController,
    IPauseController,
    INavigationController,
    IGameEventProvider {
}