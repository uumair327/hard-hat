import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';

/// Abstract interface for game state management
/// Follows DIP - high-level modules depend on this abstraction
abstract class IGameStateManager {
  /// Get current game state
  GameState get currentState;
  
  /// Get previous game state
  GameState? get previousState;
  
  /// Check if can transition to target state
  bool canTransitionTo(GameState targetState);
  
  /// Transition to new state
  bool transitionTo(GameState newState, {String? reason});
  
  /// Convenience methods for common states
  bool get isPlaying;
  bool get isPaused;
  bool get isInMenu;
  bool get isLoading;
  
  /// State transition methods
  void pauseGame();
  void resumeGame();
  void goToMenu();
  void setPlaying();
  void setLevelComplete();
  void setGameOver();
  void setLoading();
  void setError(String error);
  
  /// Add state change callback
  void addStateChangeCallback(Function(GameState, GameState?) callback);
  
  /// Remove state change callback
  void removeStateChangeCallback(Function(GameState, GameState?) callback);
}