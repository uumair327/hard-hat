import 'package:equatable/equatable.dart';

import '../../domain/entities/settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateSettingsEvent extends SettingsEvent {
  final Settings settings;

  const UpdateSettingsEvent(this.settings);

  @override
  List<Object> get props => [settings];
}

class UpdateSfxVolumeEvent extends SettingsEvent {
  final double volume;

  const UpdateSfxVolumeEvent(this.volume);

  @override
  List<Object> get props => [volume];
}

class UpdateMusicVolumeEvent extends SettingsEvent {
  final double volume;

  const UpdateMusicVolumeEvent(this.volume);

  @override
  List<Object> get props => [volume];
}

class ToggleMuteEvent extends SettingsEvent {}