import 'package:equatable/equatable.dart';

import '../../domain/entities/settings.dart';

enum SettingsStatus {
  initial,
  loading,
  loaded,
  error,
}

class SettingsState extends Equatable {
  final SettingsStatus status;
  final Settings settings;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const Settings(),
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    Settings? settings,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    errorMessage,
  ];
}