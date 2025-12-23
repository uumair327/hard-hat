import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/data/datasources/save_local_datasource.dart';

@LazySingleton(as: SaveLocalDataSource)
class SaveLocalDataSourceImpl implements SaveLocalDataSource {
  @override
  Future<Map<String, dynamic>?> getSaveData() async {
    // Implementation for loading save data
    // This would typically load from SharedPreferences or local storage
    throw UnimplementedError('Save data loading not yet implemented');
  }

  @override
  Future<void> saveSaveData(Map<String, dynamic> saveData) async {
    // Implementation for saving save data
    throw UnimplementedError('Save data saving not yet implemented');
  }

  @override
  Future<void> deleteSaveData() async {
    // Implementation for deleting save data
    throw UnimplementedError('Save data deletion not yet implemented');
  }
}