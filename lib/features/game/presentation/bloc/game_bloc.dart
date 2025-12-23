import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_level.dart';
import '../../domain/usecases/save_progress.dart';
import '../../domain/systems/game_state_manager.dart' as gsm;
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final LoadLevel loadLevel;
  final SaveProgress saveProgress;
  final gsm.GameStateManager gameStateManager;

  GameBloc({
    required this.loadLevel,
    required this.saveProgress,
    required this.gameStateManager,
  }) : super(const GameState()) {
    // Register state change callback with GameStateManager
    gameStateManager.addStateChangeCallback(_onGameStateChanged);
    
    on<LoadLevelEvent>(_onLoadLevel);
    on<SaveProgressEvent>(_onSaveProgress);
    on<StartGameEvent>(_onStartGame);
    on<PauseGameEvent>(_onPauseGame);
    on<ResumeGameEvent>(_onResumeGame);
    on<RestartLevelEvent>(_onRestartLevel);
    on<CompleteLevel>(_onCompleteLevel);
    on<GoToMenuEvent>(_onGoToMenu);
    on<GoToSettingsEvent>(_onGoToSettings);
    on<GameOverEvent>(_onGameOver);
    on<SetLoadingEvent>(_onSetLoading);
    on<SetErrorEvent>(_onSetError);
    on<StateTransitionEvent>(_onStateTransition);
    on<RestoreStateEvent>(_onRestoreState);
    on<SaveStateEvent>(_onSaveState);
    on<FocusLostEvent>(_onFocusLost);
    on<FocusGainedEvent>(_onFocusGained);
  }
  
  /// Handle state changes from GameStateManager
  void _onGameStateChanged(gsm.GameState newState, gsm.GameState? previousState) {
    // Use add instead of emit to trigger state change through event
    add(StateTransitionEvent(newState, reason: 'GameStateManager callback'));
  }

  Future<void> _onLoadLevel(LoadLevelEvent event, Emitter<GameState> emit) async {
    gameStateManager.setLoading();

    final result = await loadLevel(LoadLevelParams(levelId: event.levelId));
    result.fold(
      (failure) {
        gameStateManager.setError('Failed to load level: ${failure.toString()}');
        emit(state.copyWith(
          errorMessage: 'Failed to load level: ${failure.toString()}',
        ));
      },
      (level) {
        gameStateManager.startGame();
        emit(state.copyWith(
          currentLevel: level,
        ));
      },
    );
  }

  Future<void> _onSaveProgress(SaveProgressEvent event, Emitter<GameState> emit) async {
    final result = await saveProgress(SaveProgressParams(
      currentLevel: event.saveData.currentLevel,
      unlockedLevels: event.saveData.unlockedLevels,
    ));
    result.fold(
      (failure) {
        gameStateManager.setError('Failed to save progress: ${failure.toString()}');
        emit(state.copyWith(
          errorMessage: 'Failed to save progress: ${failure.toString()}',
        ));
      },
      (_) => emit(state.copyWith(saveData: event.saveData)),
    );
  }

  void _onStartGame(StartGameEvent event, Emitter<GameState> emit) {
    gameStateManager.startGame();
  }

  void _onPauseGame(PauseGameEvent event, Emitter<GameState> emit) {
    gameStateManager.pauseGame();
  }

  void _onResumeGame(ResumeGameEvent event, Emitter<GameState> emit) {
    gameStateManager.resumeGame();
  }

  void _onRestartLevel(RestartLevelEvent event, Emitter<GameState> emit) {
    gameStateManager.startGame();
  }

  void _onCompleteLevel(CompleteLevel event, Emitter<GameState> emit) {
    gameStateManager.completeLevel();
  }
  
  void _onGoToMenu(GoToMenuEvent event, Emitter<GameState> emit) {
    gameStateManager.goToMenu();
  }
  
  void _onGoToSettings(GoToSettingsEvent event, Emitter<GameState> emit) {
    gameStateManager.goToSettings();
  }
  
  void _onGameOver(GameOverEvent event, Emitter<GameState> emit) {
    gameStateManager.gameOver();
  }
  
  void _onSetLoading(SetLoadingEvent event, Emitter<GameState> emit) {
    gameStateManager.setLoading();
  }
  
  void _onSetError(SetErrorEvent event, Emitter<GameState> emit) {
    gameStateManager.setError(event.errorMessage);
    emit(state.copyWith(errorMessage: event.errorMessage));
  }
  
  void _onStateTransition(StateTransitionEvent event, Emitter<GameState> emit) {
    final success = gameStateManager.transitionTo(event.targetState, reason: event.reason);
    if (success) {
      emit(state.withGameManagerState(event.targetState, history: gameStateManager.stateHistory));
    }
  }
  
  Future<void> _onRestoreState(RestoreStateEvent event, Emitter<GameState> emit) async {
    await gameStateManager.restoreState();
  }
  
  Future<void> _onSaveState(SaveStateEvent event, Emitter<GameState> emit) async {
    await gameStateManager.saveState();
  }
  
  void _onFocusLost(FocusLostEvent event, Emitter<GameState> emit) {
    gameStateManager.onFocusLost();
  }
  
  void _onFocusGained(FocusGainedEvent event, Emitter<GameState> emit) {
    gameStateManager.onFocusGained();
  }
  
  @override
  Future<void> close() {
    gameStateManager.removeStateChangeCallback(_onGameStateChanged);
    return super.close();
  }
}