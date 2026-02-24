import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Save manager — replicates Godot save_manager.gd
/// Manages 6 boolean progress flags using SharedPreferences.
class GameSaveManager {
  static SharedPreferences? _prefs;

  // Save data keys matching Godot exactly
  static const String _keyIntroViewed = 'intro_viewed';
  static const String _keyLevel1Completed = 'level_1_completed';
  static const String _keyLevel2Completed = 'level_2_completed';
  static const String _keyLevel3Completed = 'level_3_completed';
  static const String _keyLevel4Completed = 'level_4_completed';
  static const String _keyOutroViewed = 'outro_viewed';

  /// Initialize the save manager
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Update a save value (matching Godot SaveManager.update())
  static Future<void> update(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  /// Check a save value (matching Godot SaveManager.check())
  static bool check(String key) {
    return _prefs?.getBool(key) ?? false;
  }

  // === Convenience methods ===

  static bool get introViewed => check(_keyIntroViewed);
  static bool get level1Completed => check(_keyLevel1Completed);
  static bool get level2Completed => check(_keyLevel2Completed);
  static bool get level3Completed => check(_keyLevel3Completed);
  static bool get level4Completed => check(_keyLevel4Completed);
  static bool get outroViewed => check(_keyOutroViewed);

  static Future<void> setIntroViewed() => update(_keyIntroViewed, true);
  static Future<void> setLevel1Completed() => update(_keyLevel1Completed, true);
  static Future<void> setLevel2Completed() => update(_keyLevel2Completed, true);
  static Future<void> setLevel3Completed() => update(_keyLevel3Completed, true);
  static Future<void> setLevel4Completed() => update(_keyLevel4Completed, true);
  static Future<void> setOutroViewed() => update(_keyOutroViewed, true);

  /// Check which levels are unlocked
  static int getHighestUnlockedLevel() {
    if (level4Completed) return 4;
    if (level3Completed) return 4;
    if (level2Completed) return 3;
    if (level1Completed) return 2;
    return 1;
  }

  /// Reset all progress
  static Future<void> resetAll() async {
    await _prefs?.clear();
  }

  /// Export save data as JSON (for debugging)
  static String exportToJson() {
    return jsonEncode({
      _keyIntroViewed: introViewed,
      _keyLevel1Completed: level1Completed,
      _keyLevel2Completed: level2Completed,
      _keyLevel3Completed: level3Completed,
      _keyLevel4Completed: level4Completed,
      _keyOutroViewed: outroViewed,
    });
  }
}
