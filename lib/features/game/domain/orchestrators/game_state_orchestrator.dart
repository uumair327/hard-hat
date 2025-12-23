import 'package:hard_hat/features/game/domain/interfaces/game_state_manager_interface.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_manager.dart';
import 'package:hard_hat/features/game/domain/services/focus_detector.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';

/// Game State Orchestrator - manages game state and pause functionality
/// Follows SRP - only responsible for state coordination
class GameStateOrchestrator {
  final IGameStateManager _gameStateManager;
  PauseMenuManager? _pauseMenuManager;
  final FocusDetector _focusDetector;

  GameStateOrchestrator({
    required IGameStateManager gameStateManager,
    PauseMenuManager? pauseMenuManager,
    required FocusDetector focusDetector,
  })  : _gameStateManager = gameStateManager,
        _pauseMenuManager = pauseMenuManager,
        _focusDetector = focusDetector;

  /// Set pause menu manager (for deferred initialization)
  void setPauseMenuManager(PauseMenuManager pauseMenuManager) {
    _pauseMenuManager = pauseMenuManager;
  }

  /// Initialize state orchestrator
  void initialize() {
    _focusDetector.initialize();
  }

  /// Pause the game
  void pauseGame() => _gameStateManager.pauseGame();

  /// Resume the game
  void resumeGame() => _gameStateManager.resumeGame();

  /// Go to main menu
  void goToMenu() => _gameStateManager.goToMenu();

  /// Set game as playing
  void setPlaying() => _gameStateManager.setPlaying();

  /// Set level complete
  void setLevelComplete() => _gameStateManager.setLevelComplete();

  /// Set game over
  void setGameOver() => _gameStateManager.setGameOver();

  /// Set loading state
  void setLoading() => _gameStateManager.setLoading();

  /// Set error state
  void setError(String error) => _gameStateManager.setError(error);

  /// Toggle pause menu
  void togglePauseMenu() => _pauseMenuManager?.togglePauseMenu();

  /// Show pause menu
  void showPauseMenu() => _pauseMenuManager?.showPauseMenu();

  /// Hide pause menu
  void hidePauseMenu() => _pauseMenuManager?.hidePauseMenu();

  /// Set pause menu callbacks
  void setRestartCallback(void Function() callback) {
    _pauseMenuManager?.setRestartCallback(callback);
  }

  void setQuitCallback(void Function() callback) {
    _pauseMenuManager?.setQuitCallback(callback);
  }

  /// State getters
  GameState get currentState => _gameStateManager.currentState;
  bool get isPlaying => _gameStateManager.isPlaying;
  bool get isPaused => _gameStateManager.isPaused;
  bool get isInMenu => _gameStateManager.isInMenu;
  bool get isLoading => _gameStateManager.isLoading;
  bool get isPauseMenuShown => _pauseMenuManager?.isShown ?? false;

  /// Add state change callback
  void addStateChangeCallback(Function(GameState, GameState?) callback) {
    _gameStateManager.addStateChangeCallback(callback);
  }

  /// Remove state change callback
  void removeStateChangeCallback(Function(GameState, GameState?) callback) {
    _gameStateManager.removeStateChangeCallback(callback);
  }

  /// Dispose resources
  void dispose() {
    _pauseMenuManager?.dispose();
    _focusDetector.dispose();
  }
}