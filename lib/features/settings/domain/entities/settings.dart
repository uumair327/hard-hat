import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final double sfxVolume;
  final double musicVolume;
  final bool isMuted;
  final bool showFps;
  final String difficulty;

  const Settings({
    this.sfxVolume = 1.0,
    this.musicVolume = 0.7,
    this.isMuted = false,
    this.showFps = false,
    this.difficulty = 'normal',
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 1.0,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 0.7,
      isMuted: json['isMuted'] as bool? ?? false,
      showFps: json['showFps'] as bool? ?? false,
      difficulty: json['difficulty'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sfxVolume': sfxVolume,
      'musicVolume': musicVolume,
      'isMuted': isMuted,
      'showFps': showFps,
      'difficulty': difficulty,
    };
  }

  Settings copyWith({
    double? sfxVolume,
    double? musicVolume,
    bool? isMuted,
    bool? showFps,
    String? difficulty,
  }) {
    return Settings(
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      isMuted: isMuted ?? this.isMuted,
      showFps: showFps ?? this.showFps,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  List<Object?> get props => [
    sfxVolume,
    musicVolume,
    isMuted,
    showFps,
    difficulty,
  ];
}