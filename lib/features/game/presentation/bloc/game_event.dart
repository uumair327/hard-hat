import 'package:equatable/equatable.dart';

import '../../domain/entities/save_data.dart';
import '../../domain/systems/game_state_manager.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class LoadLevelEvent extends GameEvent {
  final int levelId;

  const LoadLevelEvent(this.levelId);

  @override
  List<Object> get props => [levelId];
}

class SaveProgressEvent extends GameEvent {
  final SaveData saveData;

  const SaveProgressEvent(this.saveData);

  @override
  List<Object> get props => [saveData];
}

class StartGameEvent extends GameEvent {}

class PauseGameEvent extends GameEvent {}

class ResumeGameEvent extends GameEvent {}

class RestartLevelEvent extends GameEvent {}

class CompleteLevel extends GameEvent {
  final int levelId;

  const CompleteLevel(this.levelId);

  @override
  List<Object> get props => [levelId];
}

class GoToMenuEvent extends GameEvent {}

class GoToSettingsEvent extends GameEvent {}

class GameOverEvent extends GameEvent {}

class SetLoadingEvent extends GameEvent {}

class SetErrorEvent extends GameEvent {
  final String errorMessage;

  const SetErrorEvent(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

class StateTransitionEvent extends GameEvent {
  final GameState targetState;
  final String? reason;

  const StateTransitionEvent(this.targetState, {this.reason});

  @override
  List<Object> get props => [targetState, reason ?? ''];
}

class RestoreStateEvent extends GameEvent {}

class SaveStateEvent extends GameEvent {}

class FocusLostEvent extends GameEvent {}

class FocusGainedEvent extends GameEvent {}