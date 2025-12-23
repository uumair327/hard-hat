import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;
  
  /// Audio state manager for real-time audio control
  AudioStateManager? _audioStateManager;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
  }) : super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<UpdateSfxVolumeEvent>(_onUpdateSfxVolume);
    on<UpdateMusicVolumeEvent>(_onUpdateMusicVolume);
    on<ToggleMuteEvent>(_onToggleMute);
  }

  Future<void> _onLoadSettings(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: SettingsStatus.loading));

    final result = await getSettings();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'Failed to load settings',
      )),
      (settings) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        settings: settings,
      )),
    );
  }

  Future<void> _onUpdateSettings(UpdateSettingsEvent event, Emitter<SettingsState> emit) async {
    final result = await updateSettings(event.settings);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'Failed to save settings',
      )),
      (_) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        settings: event.settings,
      )),
    );
  }
  Future<void> _onUpdateSfxVolume(UpdateSfxVolumeEvent event, Emitter<SettingsState> emit) async {
    // Apply audio change immediately if available
    _audioStateManager?.setSfxVolume(event.volume);
    
    final newSettings = state.settings.copyWith(sfxVolume: event.volume);
    add(UpdateSettingsEvent(newSettings));
  }

  Future<void> _onUpdateMusicVolume(UpdateMusicVolumeEvent event, Emitter<SettingsState> emit) async {
    // Apply audio change immediately if available
    _audioStateManager?.setMusicVolume(event.volume);
    
    final newSettings = state.settings.copyWith(musicVolume: event.volume);
    add(UpdateSettingsEvent(newSettings));
  }

  Future<void> _onToggleMute(ToggleMuteEvent event, Emitter<SettingsState> emit) async {
    final newMuteState = !state.settings.isMuted;
    
    // Apply audio change immediately if available
    if (newMuteState) {
      _audioStateManager?.muteAudio();
    } else {
      _audioStateManager?.unmuteAudio();
    }
    
    final newSettings = state.settings.copyWith(isMuted: newMuteState);
    add(UpdateSettingsEvent(newSettings));
  }
  
  /// Set the audio state manager (called when game systems are initialized)
  void setAudioStateManager(AudioStateManager audioStateManager) {
    _audioStateManager = audioStateManager;
    
    // Apply current settings to audio system
    _audioStateManager?.setSfxVolume(state.settings.sfxVolume);
    _audioStateManager?.setMusicVolume(state.settings.musicVolume);
    if (state.settings.isMuted) {
      _audioStateManager?.muteAudio();
    }
  }
}