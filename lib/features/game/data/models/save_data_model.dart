import '../../domain/entities/save_data.dart';

class SaveDataModel extends SaveData {
  const SaveDataModel({
    required super.currentLevel,
    required super.unlockedLevels,
    required super.settings,
    required super.lastPlayed,
  });

  factory SaveDataModel.fromJson(Map<String, dynamic> json) {
    return SaveDataModel(
      currentLevel: json['currentLevel'] as int,
      unlockedLevels: Set<int>.from(json['unlockedLevels'] as List),
      settings: json['settings'] as Map<String, dynamic>,
      lastPlayed: DateTime.parse(json['lastPlayed'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'currentLevel': currentLevel,
      'unlockedLevels': unlockedLevels.toList(),
      'settings': settings,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  factory SaveDataModel.fromEntity(SaveData saveData) {
    return SaveDataModel(
      currentLevel: saveData.currentLevel,
      unlockedLevels: saveData.unlockedLevels,
      settings: saveData.settings,
      lastPlayed: saveData.lastPlayed,
    );
  }
}