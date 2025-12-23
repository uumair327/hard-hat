abstract class SaveLocalDataSource {
  Future<Map<String, dynamic>?> getSaveData();
  Future<void> saveSaveData(Map<String, dynamic> saveData);
  Future<void> deleteSaveData();
}