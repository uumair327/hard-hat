import 'package:equatable/equatable.dart';

import '../../domain/entities/level.dart';
import '../../domain/entities/save_data.dart';
import '../../domain/systems/game_state_manager.dart' as gsm;

enum GameStatus {
  initial,
  loading,
  playing,
  paused,
  levelComplete,
  gameOver,
  menu,
  settings,
  error,
}

class GameState extends Equatable {
  final GameStatus status;
  final Level? currentLevel;
  final SaveData? saveData;
  final String? errorMessage;
  final gsm.GameState? gameManagerState;
  final List<gsm.GameStateTransition>? stateHistory;

  const GameState({
    this.status = GameStatus.initial,
    this.currentLevel,
    this.saveData,
    this.errorMessage,
    this.gameManagerState,
    this.stateHistory,
  });

  GameState copyWith({
    GameStatus? status,
    Level? currentLevel,
    SaveData? saveData,
    String? errorMessage,
    gsm.GameState? gameManagerState,
    List<gsm.GameStateTransition>? stateHistory,
  }) {
    return GameState(
      status: status ?? this.status,
      currentLevel: currentLevel ?? this.currentLevel,
      saveData: saveData ?? this.saveData,
      errorMessage: errorMessage ?? this.errorMessage,
      gameManagerState: gameManagerState ?? this.gameManagerState,
      stateHistory: stateHistory ?? this.stateHistory,
    );
  }
  
  /// Convert GameStateManager state to BLoC GameStatus
  static GameStatus _mapGameStateToStatus(gsm.GameState gameState) {
    switch (gameState) {
      case gsm.GameState.menu:
        return GameStatus.menu;
      case gsm.GameState.playing:
        return GameStatus.playing;
      case gsm.GameState.paused:
        return GameStatus.paused;
      case gsm.GameState.levelComplete:
        return GameStatus.levelComplete;
      case gsm.GameState.gameOver:
        return GameStatus.gameOver;
      case gsm.GameState.loading:
        return GameStatus.loading;
      case gsm.GameState.settings:
        return GameStatus.settings;
      case gsm.GameState.error:
        return GameStatus.error;
    }
  }
  
  /// Create GameState from GameStateManager state
  GameState withGameManagerState(gsm.GameState gameManagerState, {List<gsm.GameStateTransition>? history}) {
    return copyWith(
      status: _mapGameStateToStatus(gameManagerState),
      gameManagerState: gameManagerState,
      stateHistory: history,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentLevel,
    saveData,
    errorMessage,
    gameManagerState,
    stateHistory,
  ];
}