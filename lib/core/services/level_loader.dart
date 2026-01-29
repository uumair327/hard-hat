import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hard_hat/core/services/level_data.dart';

/// Service for loading level data from JSON files
class LevelLoader {
  /// Cache of loaded levels to avoid reloading
  final Map<int, LevelData> _levelCache = {};

  /// Loads a level from JSON file
  /// 
  /// Throws [LevelLoadException] if the level cannot be loaded
  Future<LevelData> loadLevel(int levelId) async {
    // Check cache first
    if (_levelCache.containsKey(levelId)) {
      return _levelCache[levelId]!;
    }

    try {
      // Load JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/levels/level_$levelId.json',
      );

      // Parse JSON
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Create LevelData from JSON
      final levelData = LevelData.fromJson(jsonData);

      // Cache the level
      _levelCache[levelId] = levelData;

      return levelData;
    } on FormatException catch (e) {
      throw LevelLoadException(
        'Failed to parse level $levelId: Invalid JSON format',
        levelId,
        e,
      );
    } catch (e) {
      throw LevelLoadException(
        'Failed to load level $levelId: ${e.toString()}',
        levelId,
        e,
      );
    }
  }

  /// Preloads multiple levels into cache
  Future<void> preloadLevels(List<int> levelIds) async {
    for (final levelId in levelIds) {
      try {
        await loadLevel(levelId);
      } catch (e) {
        // Log error but continue loading other levels
        print('Warning: Failed to preload level $levelId: $e');
      }
    }
  }

  /// Clears the level cache
  void clearCache() {
    _levelCache.clear();
  }

  /// Checks if a level is cached
  bool isCached(int levelId) {
    return _levelCache.containsKey(levelId);
  }

  /// Gets a cached level without loading
  LevelData? getCached(int levelId) {
    return _levelCache[levelId];
  }
}

/// Exception thrown when a level fails to load
class LevelLoadException implements Exception {
  final String message;
  final int levelId;
  final Object? cause;

  LevelLoadException(this.message, this.levelId, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'LevelLoadException: $message\nCaused by: $cause';
    }
    return 'LevelLoadException: $message';
  }
}
