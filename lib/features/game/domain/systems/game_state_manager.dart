import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hard_hat/features/game/domain/systems/audio_state_manager.dart';

/// Manages overall game state and coordinates with audio system
/// Integrates with BLoC pattern for state management
class GameStateManager {
  final AudioStateManager _audioStateManager;
  
  /// Current game state
  GameState _currentState = GameState.playing;
  
  /// Previous state (for resume functionality)
  GameState? _previousState;
  
  /// State history for debugging and validation
  final List<GameStateTransition> _stateHistory = [];
  
  /// Callbacks for state changes
  final List<Function(GameState, GameState?)> _stateChangeCallbacks = [];
  
  /// Timer for auto-pause on focus loss
  Timer? _focusLossTimer;
  
  /// State persistence key
  static const String _stateKey = 'game_state_persistence';
  
  /// Maximum state history size
  static const int _maxHistorySize = 50;
  
  /// Valid state transitions map
  static final Map<GameState, Set<GameState>> _validTransitions = {
    GameState.menu: {GameState.playing, GameState.loading, GameState.settings},
    GameState.playing: {GameState.paused, GameState.levelComplete, GameState.gameOver, GameState.menu, GameState.loading, GameState.error},
    GameState.paused: {GameState.playing, GameState.menu, GameState.gameOver},
    GameState.levelComplete: {GameState.playing, GameState.menu, GameState.loading},
    GameState.gameOver: {GameState.playing, GameState.menu, GameState.loading},
    GameState.loading: {GameState.playing, GameState.menu, GameState.error},
    GameState.settings: {GameState.menu, GameState.playing},
    GameState.error: {GameState.menu, GameState.playing, GameState.loading},
  };

  GameStateManager(this._audioStateManager);

  /// Current game state
  GameState get currentState => _currentState;
  
  /// Previous game state
  GameState? get previousState => _previousState;
  
  /// Get state history
  List<GameStateTransition> get stateHistory => List.unmodifiable(_stateHistory);
  
  /// Validate if a state transition is allowed
  bool canTransitionTo(GameState targetState) {
    final validTargets = _validTransitions[_currentState];
    return validTargets?.contains(targetState) ?? false;
  }
  
  /// Transition to a new state with validation
  bool transitionTo(GameState newState, {String? reason}) {
    // Don't transition to the same state
    if (_currentState == newState) {
      return true; // Already in target state
    }
    
    if (!canTransitionTo(newState)) {
      if (kDebugMode) {
        print('Invalid state transition: $_currentState -> $newState');
      }
      return false;
    }
    
    _recordTransition(newState, reason);
    _previousState = _currentState;
    _currentState = newState;
    
    // Apply state-specific behavior
    _applyStateSpecificBehavior(newState);
    
    _notifyStateChange();
    return true;
  }
  
  /// Record a state transition in history
  void _recordTransition(GameState newState, String? reason) {
    final transition = GameStateTransition(
      from: _currentState,
      to: newState,
      timestamp: DateTime.now(),
      reason: reason,
    );
    
    _stateHistory.add(transition);
    
    // Limit history size
    if (_stateHistory.length > _maxHistorySize) {
      _stateHistory.removeAt(0);
    }
  }
  
  /// Apply state-specific behavior (audio, etc.)
  void _applyStateSpecificBehavior(GameState state) {
    switch (state) {
      case GameState.paused:
        _audioStateManager.pauseAudio();
        break;
      case GameState.playing:
        _audioStateManager.resumeAudio();
        break;
      case GameState.menu:
        _audioStateManager.fadeOut(duration: const Duration(milliseconds: 500));
        break;
      case GameState.levelComplete:
      case GameState.gameOver:
        // Keep audio playing but may adjust volume
        break;
      case GameState.loading:
      case GameState.settings:
      case GameState.error:
        // No specific audio behavior
        break;
    }
  }

  /// Pause the game
  void pauseGame() {
    transitionTo(GameState.paused, reason: 'Manual pause');
  }

  /// Resume the game
  void resumeGame() {
    if (_currentState == GameState.paused) {
      final targetState = _previousState ?? GameState.playing;
      transitionTo(targetState, reason: 'Resume from pause');
    }
  }

  /// Start playing the game
  void startGame() {
    transitionTo(GameState.playing, reason: 'Start game');
  }

  /// Go to main menu
  void goToMenu() {
    transitionTo(GameState.menu, reason: 'Navigate to menu');
  }

  /// Show level complete screen
  void completeLevel() {
    transitionTo(GameState.levelComplete, reason: 'Level completed');
  }

  /// Show game over screen
  void gameOver() {
    transitionTo(GameState.gameOver, reason: 'Game over');
  }
  
  /// Go to settings
  void goToSettings() {
    transitionTo(GameState.settings, reason: 'Navigate to settings');
  }
  
  /// Set loading state
  void setLoading() {
    transitionTo(GameState.loading, reason: 'Loading content');
  }
  
  /// Set error state
  void setError(String errorMessage) {
    transitionTo(GameState.error, reason: 'Error: $errorMessage');
  }

  /// Handle focus loss (auto-pause)
  void onFocusLost() {
    if (_currentState == GameState.playing) {
      // Auto-pause after a short delay to avoid accidental pauses
      _focusLossTimer = Timer(const Duration(milliseconds: 100), () {
        transitionTo(GameState.paused, reason: 'Focus lost');
      });
    }
  }

  /// Handle focus gained
  void onFocusGained() {
    // Cancel auto-pause timer if focus is regained quickly
    _focusLossTimer?.cancel();
  }
  
  /// Save current state to persistent storage
  Future<void> saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = {
        'currentState': _currentState.name,
        'previousState': _previousState?.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_stateKey, jsonEncode(stateData));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save game state: $e');
      }
    }
  }
  
  /// Restore state from persistent storage
  Future<void> restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);
      
      if (stateJson != null) {
        final stateData = jsonDecode(stateJson) as Map<String, dynamic>;
        final currentStateName = stateData['currentState'] as String?;
        final previousStateName = stateData['previousState'] as String?;
        
        if (currentStateName != null) {
          final restoredState = GameState.values.firstWhere(
            (state) => state.name == currentStateName,
            orElse: () => GameState.menu,
          );
          
          final restoredPreviousState = previousStateName != null
              ? GameState.values.firstWhere(
                  (state) => state.name == previousStateName,
                  orElse: () => GameState.menu,
                )
              : null;
          
          // Only restore if it's a valid transition or we're starting fresh
          if (canTransitionTo(restoredState) || _currentState == GameState.playing) {
            _currentState = restoredState;
            _previousState = restoredPreviousState;
            _applyStateSpecificBehavior(_currentState);
            _notifyStateChange();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore game state: $e');
      }
    }
  }
  
  /// Clear persisted state
  Future<void> clearPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stateKey);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear persisted state: $e');
      }
    }
  }
  /// Add a callback for state changes
  void addStateChangeCallback(Function(GameState, GameState?) callback) {
    _stateChangeCallbacks.add(callback);
  }

  /// Remove a state change callback
  void removeStateChangeCallback(Function(GameState, GameState?) callback) {
    _stateChangeCallbacks.remove(callback);
  }

  /// Notify all callbacks of state change
  void _notifyStateChange() {
    for (final callback in _stateChangeCallbacks) {
      callback(_currentState, _previousState);
    }
  }

  /// Check if game is currently paused
  bool get isPaused => _currentState == GameState.paused;
  
  /// Check if game is currently playing
  bool get isPlaying => _currentState == GameState.playing;
  
  /// Check if in menu
  bool get isInMenu => _currentState == GameState.menu;
  
  /// Check if in loading state
  bool get isLoading => _currentState == GameState.loading;
  
  /// Check if in error state
  bool get isError => _currentState == GameState.error;
  
  /// Check if level is complete
  bool get isLevelComplete => _currentState == GameState.levelComplete;
  
  /// Check if game is over
  bool get isGameOver => _currentState == GameState.gameOver;

  /// Dispose resources
  void dispose() {
    _focusLossTimer?.cancel();
    _stateChangeCallbacks.clear();
    _stateHistory.clear();
  }
}

/// Game state enumeration
enum GameState {
  menu,
  playing,
  paused,
  levelComplete,
  gameOver,
  loading,
  settings,
  error,
}

/// Represents a state transition for debugging and validation
class GameStateTransition {
  final GameState from;
  final GameState to;
  final DateTime timestamp;
  final String? reason;
  
  const GameStateTransition({
    required this.from,
    required this.to,
    required this.timestamp,
    this.reason,
  });
  
  @override
  String toString() {
    return 'GameStateTransition(from: $from, to: $to, timestamp: $timestamp, reason: $reason)';
  }
}