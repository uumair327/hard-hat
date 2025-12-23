import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/data/data.dart';

@LazySingleton(as: SaveRepository)
class SaveRepositoryImpl implements SaveRepository {
  final SaveLocalDataSource _localDataSource;

  SaveRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, SaveData?>> getSaveData() async {
    try {
      final saveDataMap = await _localDataSource.getSaveData();
      if (saveDataMap == null) {
        return const Right(null);
      }
      final saveData = SaveData.fromJson(saveDataMap);
      return Right(saveData);
    } catch (e) {
      return Left(SaveFailure('Failed to load save data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSaveData(SaveData saveData) async {
    try {
      await _localDataSource.saveSaveData(saveData.toJson());
      return const Right(null);
    } catch (e) {
      return Left(SaveFailure('Failed to save data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSaveData() async {
    try {
      await _localDataSource.deleteSaveData();
      return const Right(null);
    } catch (e) {
      return Left(SaveFailure('Failed to delete save data: $e'));
    }
  }
}