import 'package:equatable/equatable.dart';

class SaveData extends Equatable {
  final int currentLevel;
  final Set<int> unlockedLevels;
  final DateTime lastPlayed;

  const SaveData({
    required this.currentLevel,
    required this.unlockedLevels,
    required this.lastPlayed,
  });

  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      currentLevel: json['currentLevel'] as int,
      unlockedLevels: Set<int>.from(json['unlockedLevels'] as List),
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'unlockedLevels': unlockedLevels.toList(),
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [currentLevel, unlockedLevels, lastPlayed];
}