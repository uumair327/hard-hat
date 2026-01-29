import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'save_data.dart';

/// Interface for save management
abstract class ISaveManager {
  /// Initialize the save manager
  Future<void> initialize();

  /// Load save data from storage
  Future<SaveData> load();

  /// Save data to storage
  Future<void> save(SaveData data);

  /// Check if a specific flag is set
  bool check(String flag);

  /// Set a specific flag value
  Future<void> setFlag(String flag, bool value);

  /// Mark a level as completed
  Future<void> markLevelCompleted(int levelId);

  /// Get current save data
  SaveData get currentData;
}

/// Implementation of save manager using SharedPreferences
class SaveManager implements ISaveManager {
  static const String _saveKey = 'hard_hat_save_data';

  SharedPreferences? _prefs;
  SaveData _currentData = const SaveData();

  @override
  SaveData get currentData => _currentData;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentData = await load();
  }

  @override
  Future<SaveData> load() async {
    if (_prefs == null) {
      throw StateError('SaveManager not initialized. Call initialize() first.');
    }

    final jsonString = _prefs!.getString(_saveKey);
    if (jsonString == null) {
      // No save data exists, return default
      _currentData = const SaveData();
      return _currentData;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentData = SaveData.fromJson(json);
      return _currentData;
    } catch (e) {
      // If parsing fails, return default data
      _currentData = const SaveData();
      return _currentData;
    }
  }

  @override
  Future<void> save(SaveData data) async {
    if (_prefs == null) {
      throw StateError('SaveManager not initialized. Call initialize() first.');
    }

    _currentData = data;
    final jsonString = jsonEncode(data.toJson());
    await _prefs!.setString(_saveKey, jsonString);
  }

  @override
  bool check(String flag) {
    switch (flag.toLowerCase()) {
      case 'introviewed':
      case 'intro_viewed':
        return _currentData.introViewed;
      case 'outroviewed':
      case 'outro_viewed':
        return _currentData.outroViewed;
      case 'level1completed':
      case 'level_1_completed':
        return _currentData.level1Completed;
      case 'level2completed':
      case 'level_2_completed':
        return _currentData.level2Completed;
      case 'level3completed':
      case 'level_3_completed':
        return _currentData.level3Completed;
      case 'level4completed':
      case 'level_4_completed':
        return _currentData.level4Completed;
      default:
        return false;
    }
  }

  @override
  Future<void> setFlag(String flag, bool value) async {
    SaveData updatedData;

    switch (flag.toLowerCase()) {
      case 'introviewed':
      case 'intro_viewed':
        updatedData = _currentData.copyWith(introViewed: value);
        break;
      case 'outroviewed':
      case 'outro_viewed':
        updatedData = _currentData.copyWith(outroViewed: value);
        break;
      case 'level1completed':
      case 'level_1_completed':
        updatedData = _currentData.copyWith(level1Completed: value);
        break;
      case 'level2completed':
      case 'level_2_completed':
        updatedData = _currentData.copyWith(level2Completed: value);
        break;
      case 'level3completed':
      case 'level_3_completed':
        updatedData = _currentData.copyWith(level3Completed: value);
        break;
      case 'level4completed':
      case 'level_4_completed':
        updatedData = _currentData.copyWith(level4Completed: value);
        break;
      default:
        // Unknown flag, do nothing
        return;
    }

    await save(updatedData);
  }

  @override
  Future<void> markLevelCompleted(int levelId) async {
    if (levelId < 1 || levelId > 4) {
      throw ArgumentError('Invalid level ID: $levelId. Must be between 1 and 4.');
    }

    SaveData updatedData;
    switch (levelId) {
      case 1:
        updatedData = _currentData.copyWith(level1Completed: true);
        break;
      case 2:
        updatedData = _currentData.copyWith(level2Completed: true);
        break;
      case 3:
        updatedData = _currentData.copyWith(level3Completed: true);
        break;
      case 4:
        updatedData = _currentData.copyWith(level4Completed: true);
        break;
      default:
        return;
    }

    await save(updatedData);
  }
}
