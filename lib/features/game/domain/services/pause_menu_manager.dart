import 'package:hard_hat/features/game/domain/interfaces/game_state_manager_interface.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_system_interfaces.dart';
import 'package:hard_hat/features/game/domain/services/focus_detector.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_service.dart';

/// Manages the pause menu coordination and game state
/// This is a domain service that coordinates with the presentation layer through interfaces
class PauseMenuManager implements IPauseMenuManager {
  final IGameStateManager _gameStateManager;
  final FocusDetector _focusDetector;
  final PauseMenuService _pauseMenuService;
  
  /// Callbacks for menu actions
  void Function()? _onRestart;
  void Function()? _onQuit;

  PauseMenuManager(
    this._gameStateManager, 
    this._focusDetector,
    this._pauseMenuService,
  ) {
    _initializeFocusDetection();
    _setupPauseMenuCallbacks();
  }

  /// Setup pause menu service callbacks
  void _setupPauseMenuCallbacks() {
    _pauseMenuService.setOnResume(_handleResume);
    _pauseMenuService.setOnRestart(_handleRestart);
    _pauseMenuService.setOnQuit(_handleQuit);
  }

  /// Initialize focus detection for auto-pause
  void _initializeFocusDetection() {
    _focusDetector.initialize();
    _focusDetector.addFocusLostCallback(_handleFocusLost);
    _focusDetector.addFocusGainedCallback(_handleFocusGained);
  }

  /// Handle focus lost event
  void _handleFocusLost() {
    if (_gameStateManager.isPlaying && !_pauseMenuService.isShown) {
      showPauseMenu();
    }
  }

  /// Handle focus gained event
  void _handleFocusGained() {
    // Focus gained is handled by the user explicitly resuming
    // We don't auto-resume to avoid accidental resumes
  }

  /// Show the pause menu
  @override
  void showPauseMenu() {
    if (_pauseMenuService.isShown) return;
    
    // Pause the game
    _gameStateManager.pauseGame();
    
    // Show pause menu through service
    _pauseMenuService.showPauseMenu();
  }

  /// Hide the pause menu
  @override
  void hidePauseMenu() {
    if (!_pauseMenuService.isShown) return;
    
    _pauseMenuService.hidePauseMenu();
  }

  /// Handle resume action
  void _handleResume() {
    hidePauseMenu();
    _gameStateManager.resumeGame();
  }

  /// Handle restart action
  void _handleRestart() {
    hidePauseMenu();
    _gameStateManager.resumeGame();
    
    if (_onRestart != null) {
      _onRestart!();
    }
  }

  /// Handle quit action
  void _handleQuit() {
    hidePauseMenu();
    _gameStateManager.goToMenu();
    
    if (_onQuit != null) {
      _onQuit!();
    }
  }

  /// Set restart callback
  @override
  void setRestartCallback(void Function() callback) {
    _onRestart = callback;
  }

  /// Set quit callback
  @override
  void setQuitCallback(void Function() callback) {
    _onQuit = callback;
  }

  /// Toggle pause menu visibility
  @override
  void togglePauseMenu() {
    if (_pauseMenuService.isShown) {
      _handleResume();
    } else {
      showPauseMenu();
    }
  }

  /// Check if pause menu is currently shown
  @override
  bool get isShown => _pauseMenuService.isShown;

  /// Dispose resources
  @override
  void dispose() {
    hidePauseMenu();
    _focusDetector.removeFocusLostCallback(_handleFocusLost);
    _focusDetector.removeFocusGainedCallback(_handleFocusGained);
  }
}