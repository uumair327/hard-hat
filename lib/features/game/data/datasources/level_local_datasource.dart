abstract class LevelLocalDataSource {
  Future<Map<String, dynamic>> getLevel(int levelId);
  Future<List<Map<String, dynamic>>> getAllLevels();
  Future<void> saveLevel(Map<String, dynamic> levelData);
}