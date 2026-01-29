/// Save data model representing player progress
class SaveData {
  final bool introViewed;
  final bool outroViewed;
  final bool level1Completed;
  final bool level2Completed;
  final bool level3Completed;
  final bool level4Completed;

  const SaveData({
    this.introViewed = false,
    this.outroViewed = false,
    this.level1Completed = false,
    this.level2Completed = false,
    this.level3Completed = false,
    this.level4Completed = false,
  });

  /// Create SaveData from JSON
  factory SaveData.fromJson(Map<String, dynamic> json) {
    return SaveData(
      introViewed: json['introViewed'] as bool? ?? false,
      outroViewed: json['outroViewed'] as bool? ?? false,
      level1Completed: json['level1Completed'] as bool? ?? false,
      level2Completed: json['level2Completed'] as bool? ?? false,
      level3Completed: json['level3Completed'] as bool? ?? false,
      level4Completed: json['level4Completed'] as bool? ?? false,
    );
  }

  /// Convert SaveData to JSON
  Map<String, dynamic> toJson() {
    return {
      'introViewed': introViewed,
      'outroViewed': outroViewed,
      'level1Completed': level1Completed,
      'level2Completed': level2Completed,
      'level3Completed': level3Completed,
      'level4Completed': level4Completed,
    };
  }

  /// Create a copy with updated fields
  SaveData copyWith({
    bool? introViewed,
    bool? outroViewed,
    bool? level1Completed,
    bool? level2Completed,
    bool? level3Completed,
    bool? level4Completed,
  }) {
    return SaveData(
      introViewed: introViewed ?? this.introViewed,
      outroViewed: outroViewed ?? this.outroViewed,
      level1Completed: level1Completed ?? this.level1Completed,
      level2Completed: level2Completed ?? this.level2Completed,
      level3Completed: level3Completed ?? this.level3Completed,
      level4Completed: level4Completed ?? this.level4Completed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SaveData &&
        other.introViewed == introViewed &&
        other.outroViewed == outroViewed &&
        other.level1Completed == level1Completed &&
        other.level2Completed == level2Completed &&
        other.level3Completed == level3Completed &&
        other.level4Completed == level4Completed;
  }

  @override
  int get hashCode {
    return Object.hash(
      introViewed,
      outroViewed,
      level1Completed,
      level2Completed,
      level3Completed,
      level4Completed,
    );
  }

  @override
  String toString() {
    return 'SaveData(introViewed: $introViewed, outroViewed: $outroViewed, '
        'level1Completed: $level1Completed, level2Completed: $level2Completed, '
        'level3Completed: $level3Completed, level4Completed: $level4Completed)';
  }
}
