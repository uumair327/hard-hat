import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_state_manager_interface.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager.dart';
import 'package:hard_hat/features/game/domain/strategies/game_state_strategy.dart';
import 'package:hard_hat/features/game/domain/systems/audio_state_manager.dart';
import 'package:hard_hat/features/game/domain/systems/audio_system.dart';

@LazySingleton(as: IGameStateManager)
class GameStateManagerImpl implements IGameStateManager {
  final AudioStateManager _audioStateManager;
  final Map<GameState, GameStateStrategy> _stateStrategies;
  
  GameState _currentState = GameState.menu;
  GameState? _previousState;
  final List<Function(GameState, GameState?)> _stateChangeCallbacks = [];
  
  // Reference to audio system for music management
  AudioSystem? _audioSystem;

  GameStateManagerImpl(
    this._audioStateManager,
  ) : _stateStrategies = GameStateStrategyFactory.createAllStrategies();
  
  /// Set audio system for music management
  void setAudioSystem(AudioSystem audioSystem) {
    _audioSystem = audioSystem;
  }

  @override
  GameState get currentState => _currentState;

  @override
  GameState? get previousState => _previousState;

  @override
  bool canTransitionTo(GameState targetState) {
    final strategy = _stateStrategies[_currentState];
    return strategy?.getValidTransitions().contains(targetState) ?? false;
  }

  @override
  bool transitionTo(GameState newState, {String? reason}) {
    if (_currentState == newState) return true;
    if (!canTransitionTo(newState)) return false;

    final context = GameStateContext(
      audioStateManager: _audioStateManager,
      stateChangeCallbacks: _stateChangeCallbacks,
      audioSystem: _audioSystem,
    );

    // Exit old state
    _stateStrategies[_currentState]?.onExit(context);

    // Update state
    _previousState = _currentState;
    _currentState = newState;

    // Enter new state
    _stateStrategies[newState]?.onEnter(context);

    // Notify listeners
    _notifyStateChange();
    return true;
  }

  @override
  bool get isPlaying => _currentState == GameState.playing;

  @override
  bool get isPaused => _currentState == GameState.paused;

  @override
  bool get isInMenu => _currentState == GameState.menu;

  @override
  bool get isLoading => _currentState == GameState.loading;

  @override
  void pauseGame() => transitionTo(GameState.paused);

  @override
  void resumeGame() => transitionTo(GameState.playing);

  @override
  void goToMenu() => transitionTo(GameState.menu);

  @override
  void setPlaying() => transitionTo(GameState.playing);

  @override
  void setLevelComplete() => transitionTo(GameState.levelComplete);

  @override
  void setGameOver() => transitionTo(GameState.gameOver);

  @override
  void setLoading() => transitionTo(GameState.loading);

  @override
  void setError(String error) => transitionTo(GameState.error);

  @override
  void addStateChangeCallback(Function(GameState, GameState?) callback) {
    _stateChangeCallbacks.add(callback);
  }

  @override
  void removeStateChangeCallback(Function(GameState, GameState?) callback) {
    _stateChangeCallbacks.remove(callback);
  }

  void _notifyStateChange() {
    for (final callback in _stateChangeCallbacks) {
      callback(_currentState, _previousState);
    }
  }
}