import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';
import 'package:hard_hat/features/game/domain/systems/audio_state_manager.dart';

/// Context for state strategies
class GameStateContext {
  final AudioStateManager audioStateManager;
  final List<Function(GameState, GameState?)> stateChangeCallbacks;
  
  GameStateContext({
    required this.audioStateManager,
    required this.stateChangeCallbacks,
  });
}

/// Abstract strategy for game state behavior
/// Follows OCP - new states can be added without modifying existing code
abstract class GameStateStrategy {
  /// Get valid transitions from this state
  Set<GameState> getValidTransitions();
  
  /// Called when entering this state
  void onEnter(GameStateContext context);
  
  /// Called when exiting this state
  void onExit(GameStateContext context);
}

/// Playing state strategy
class PlayingStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.paused,
    GameState.levelComplete,
    GameState.gameOver,
    GameState.menu,
    GameState.loading,
    GameState.error,
  };

  @override
  void onEnter(GameStateContext context) {
    context.audioStateManager.resumeAudio();
  }

  @override
  void onExit(GameStateContext context) {
    // No special exit behavior
  }
}

/// Paused state strategy
class PausedStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.menu,
    GameState.gameOver,
  };

  @override
  void onEnter(GameStateContext context) {
    context.audioStateManager.pauseAudio();
  }

  @override
  void onExit(GameStateContext context) {
    // No special exit behavior
  }
}

/// Menu state strategy
class MenuStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.loading,
    GameState.settings,
  };

  @override
  void onEnter(GameStateContext context) {
    context.audioStateManager.fadeOut(
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void onExit(GameStateContext context) {
    // No special exit behavior
  }
}

/// Level complete state strategy
class LevelCompleteStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.menu,
    GameState.loading,
  };

  @override
  void onEnter(GameStateContext context) {
    // Play level complete sound, show UI effects, etc.
    // This can be extended without modifying other states
  }

  @override
  void onExit(GameStateContext context) {
    // Clean up level complete effects
  }
}

/// Game over state strategy
class GameOverStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.menu,
    GameState.loading,
  };

  @override
  void onEnter(GameStateContext context) {
    // Play game over sound, show effects, etc.
  }

  @override
  void onExit(GameStateContext context) {
    // Clean up game over effects
  }
}

/// Loading state strategy
class LoadingStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.menu,
    GameState.error,
  };

  @override
  void onEnter(GameStateContext context) {
    // Show loading indicators, mute audio, etc.
  }

  @override
  void onExit(GameStateContext context) {
    // Hide loading indicators
  }
}

/// Settings state strategy
class SettingsStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.menu,
    GameState.playing,
  };

  @override
  void onEnter(GameStateContext context) {
    // Pause background audio, show settings UI, etc.
  }

  @override
  void onExit(GameStateContext context) {
    // Apply settings changes, resume audio, etc.
  }
}

/// Error state strategy
class ErrorStateStrategy implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.menu,
    GameState.playing,
    GameState.loading,
  };

  @override
  void onEnter(GameStateContext context) {
    // Show error UI, log error, pause audio, etc.
  }

  @override
  void onExit(GameStateContext context) {
    // Clear error state, resume normal operation
  }
}

/// Factory for creating state strategies
class GameStateStrategyFactory {
  static Map<GameState, GameStateStrategy> createAllStrategies() {
    return {
      GameState.playing: PlayingStateStrategy(),
      GameState.paused: PausedStateStrategy(),
      GameState.menu: MenuStateStrategy(),
      GameState.levelComplete: LevelCompleteStateStrategy(),
      GameState.gameOver: GameOverStateStrategy(),
      GameState.loading: LoadingStateStrategy(),
      GameState.settings: SettingsStateStrategy(),
      GameState.error: ErrorStateStrategy(),
    };
  }
}