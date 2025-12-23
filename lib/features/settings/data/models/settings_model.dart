import '../../domain/entities/settings.dart';

class SettingsModel extends Settings {
  const SettingsModel({
    super.sfxVolume,
    super.musicVolume,
    super.isMuted,
    super.showFps,
    super.difficulty,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.7,
      isMuted: json['isMuted'] as bool? ?? false,
      showFps: json['showFps'] as bool? ?? false,
      difficulty: json['difficulty'] as String? ?? 'normal',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'sfxVolume': sfxVolume,
      'musicVolume': musicVolume,
      'isMuted': isMuted,
      'showFps': showFps,
      'difficulty': difficulty,
    };
  }

  factory SettingsModel.fromEntity(Settings settings) {
    return SettingsModel(
      sfxVolume: settings.sfxVolume,
      musicVolume: settings.musicVolume,
      isMuted: settings.isMuted,
      showFps: settings.showFps,
      difficulty: settings.difficulty,
    );
  }
}