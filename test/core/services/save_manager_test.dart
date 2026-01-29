import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/core/services/save_data.dart';
import 'package:hard_hat/core/services/save_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SaveData', () {
    test('should create default SaveData with all flags false', () {
      const saveData = SaveData();

      expect(saveData.introViewed, false);
      expect(saveData.outroViewed, false);
      expect(saveData.level1Completed, false);
      expect(saveData.level2Completed, false);
      expect(saveData.level3Completed, false);
      expect(saveData.level4Completed, false);
    });

    test('should create SaveData with custom values', () {
      const saveData = SaveData(
        introViewed: true,
        level1Completed: true,
        level2Completed: true,
      );

      expect(saveData.introViewed, true);
      expect(saveData.outroViewed, false);
      expect(saveData.level1Completed, true);
      expect(saveData.level2Completed, true);
      expect(saveData.level3Completed, false);
      expect(saveData.level4Completed, false);
    });

    test('should serialize to JSON correctly', () {
      const saveData = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      final json = saveData.toJson();

      expect(json['introViewed'], true);
      expect(json['outroViewed'], false);
      expect(json['level1Completed'], true);
      expect(json['level2Completed'], false);
      expect(json['level3Completed'], false);
      expect(json['level4Completed'], false);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'introViewed': true,
        'outroViewed': false,
        'level1Completed': true,
        'level2Completed': true,
        'level3Completed': false,
        'level4Completed': false,
      };

      final saveData = SaveData.fromJson(json);

      expect(saveData.introViewed, true);
      expect(saveData.outroViewed, false);
      expect(saveData.level1Completed, true);
      expect(saveData.level2Completed, true);
      expect(saveData.level3Completed, false);
      expect(saveData.level4Completed, false);
    });

    test('should handle missing JSON fields with defaults', () {
      final json = <String, dynamic>{};

      final saveData = SaveData.fromJson(json);

      expect(saveData.introViewed, false);
      expect(saveData.outroViewed, false);
      expect(saveData.level1Completed, false);
      expect(saveData.level2Completed, false);
      expect(saveData.level3Completed, false);
      expect(saveData.level4Completed, false);
    });

    test('should create copy with updated fields', () {
      const original = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      final updated = original.copyWith(
        level2Completed: true,
        outroViewed: true,
      );

      expect(updated.introViewed, true);
      expect(updated.outroViewed, true);
      expect(updated.level1Completed, true);
      expect(updated.level2Completed, true);
      expect(updated.level3Completed, false);
      expect(updated.level4Completed, false);
    });

    test('should compare equality correctly', () {
      const saveData1 = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      const saveData2 = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      const saveData3 = SaveData(
        introViewed: true,
        level2Completed: true,
      );

      expect(saveData1, equals(saveData2));
      expect(saveData1, isNot(equals(saveData3)));
    });
  });

  group('SaveManager', () {
    late SaveManager saveManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      saveManager = SaveManager();
      await saveManager.initialize();
    });

    test('should initialize with default SaveData when no save exists', () async {
      final data = await saveManager.load();

      expect(data.introViewed, false);
      expect(data.outroViewed, false);
      expect(data.level1Completed, false);
      expect(data.level2Completed, false);
      expect(data.level3Completed, false);
      expect(data.level4Completed, false);
    });

    test('should save and load data correctly', () async {
      const saveData = SaveData(
        introViewed: true,
        level1Completed: true,
        level2Completed: true,
      );

      await saveManager.save(saveData);
      final loaded = await saveManager.load();

      expect(loaded, equals(saveData));
    });

    test('should persist data across manager instances', () async {
      const saveData = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      await saveManager.save(saveData);

      // Create new manager instance
      final newManager = SaveManager();
      await newManager.initialize();
      final loaded = await newManager.load();

      expect(loaded, equals(saveData));
    });

    test('should check flags correctly', () async {
      const saveData = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      await saveManager.save(saveData);

      expect(saveManager.check('introViewed'), true);
      expect(saveManager.check('intro_viewed'), true);
      expect(saveManager.check('outroViewed'), false);
      expect(saveManager.check('level1Completed'), true);
      expect(saveManager.check('level_1_completed'), true);
      expect(saveManager.check('level2Completed'), false);
    });

    test('should return false for unknown flags', () {
      expect(saveManager.check('unknownFlag'), false);
    });

    test('should set flags correctly', () async {
      await saveManager.setFlag('introViewed', true);
      expect(saveManager.check('introViewed'), true);

      await saveManager.setFlag('level1Completed', true);
      expect(saveManager.check('level1Completed'), true);

      await saveManager.setFlag('level2Completed', true);
      expect(saveManager.check('level2Completed'), true);
    });

    test('should handle flag name variations', () async {
      await saveManager.setFlag('intro_viewed', true);
      expect(saveManager.check('introViewed'), true);

      await saveManager.setFlag('level_1_completed', true);
      expect(saveManager.check('level1Completed'), true);
    });

    test('should mark levels as completed', () async {
      await saveManager.markLevelCompleted(1);
      expect(saveManager.check('level1Completed'), true);

      await saveManager.markLevelCompleted(2);
      expect(saveManager.check('level2Completed'), true);

      await saveManager.markLevelCompleted(3);
      expect(saveManager.check('level3Completed'), true);

      await saveManager.markLevelCompleted(4);
      expect(saveManager.check('level4Completed'), true);
    });

    test('should throw error for invalid level IDs', () async {
      expect(
        () => saveManager.markLevelCompleted(0),
        throwsArgumentError,
      );

      expect(
        () => saveManager.markLevelCompleted(5),
        throwsArgumentError,
      );

      expect(
        () => saveManager.markLevelCompleted(-1),
        throwsArgumentError,
      );
    });

    test('should update currentData after save', () async {
      const saveData = SaveData(
        introViewed: true,
        level1Completed: true,
      );

      await saveManager.save(saveData);

      expect(saveManager.currentData, equals(saveData));
    });

    test('should handle corrupted save data gracefully', () async {
      // Manually set corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hard_hat_save_data', 'corrupted json data');

      final newManager = SaveManager();
      await newManager.initialize();
      final loaded = await newManager.load();

      // Should return default data
      expect(loaded, equals(const SaveData()));
    });

    test('should throw error when not initialized', () async {
      final uninitializedManager = SaveManager();

      expect(
        () => uninitializedManager.load(),
        throwsStateError,
      );

      expect(
        () => uninitializedManager.save(const SaveData()),
        throwsStateError,
      );
    });

    test('should handle multiple sequential saves', () async {
      await saveManager.setFlag('introViewed', true);
      expect(saveManager.check('introViewed'), true);

      await saveManager.markLevelCompleted(1);
      expect(saveManager.check('level1Completed'), true);

      await saveManager.markLevelCompleted(2);
      expect(saveManager.check('level2Completed'), true);

      await saveManager.setFlag('outroViewed', true);
      expect(saveManager.check('outroViewed'), true);

      // Verify all flags are still set
      expect(saveManager.check('introViewed'), true);
      expect(saveManager.check('level1Completed'), true);
      expect(saveManager.check('level2Completed'), true);
      expect(saveManager.check('outroViewed'), true);
    });

    test('should handle complete game progression', () async {
      // Start game
      await saveManager.setFlag('introViewed', true);

      // Complete levels in order
      await saveManager.markLevelCompleted(1);
      await saveManager.markLevelCompleted(2);
      await saveManager.markLevelCompleted(3);
      await saveManager.markLevelCompleted(4);

      // View outro
      await saveManager.setFlag('outroViewed', true);

      // Verify complete progression
      expect(saveManager.check('introViewed'), true);
      expect(saveManager.check('level1Completed'), true);
      expect(saveManager.check('level2Completed'), true);
      expect(saveManager.check('level3Completed'), true);
      expect(saveManager.check('level4Completed'), true);
      expect(saveManager.check('outroViewed'), true);
    });
  });
}
