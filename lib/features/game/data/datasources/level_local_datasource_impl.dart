import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/data/datasources/level_local_datasource.dart';

@LazySingleton(as: LevelLocalDataSource)
class LevelLocalDataSourceImpl implements LevelLocalDataSource {
  @override
  Future<Map<String, dynamic>> getLevel(int levelId) async {
    // Implementation for loading level data
    // This would typically load from assets or local storage
    throw UnimplementedError('Level loading not yet implemented');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllLevels() async {
    // Implementation for loading all levels
    throw UnimplementedError('All levels loading not yet implemented');
  }

  @override
  Future<void> saveLevel(Map<String, dynamic> levelData) async {
    // Implementation for saving level data
    throw UnimplementedError('Level saving not yet implemented');
  }
}