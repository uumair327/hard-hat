import 'package:equatable/equatable.dart';

class SaveData extends Equatable {
  final int currentLevel;
  final Set<int> unlockedLevels;
  final Map<String, dynamic> settings;
  final DateTime lastPlayed;

  const SaveData({
    required this.currentLevel,
    required this.unlockedLevels,
    required this.settings,
    required this.lastPlayed,
  });

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      currentLevel: json['currentLevel'] as int,
      unlockedLevels: Set<int>.from(json['unlockedLevels'] as List),
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'unlockedLevels': unlockedLevels.toList(),
      'settings': settings,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  SaveData copyWith({
    int? currentLevel,
    Set<int>? unlockedLevels,
    Map<String, dynamic>? settings,
    DateTime? lastPlayed,
  }) {
    return SaveData(
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      settings: settings ?? this.settings,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  @override
  List<Object?> get props => [currentLevel, unlockedLevels, settings, lastPlayed];
}