import 'package:dartz/dartz.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/entities/save_data.dart';

abstract class SaveRepository {
  Future<Either<Failure, SaveData?>> getSaveData();
  Future<Either<Failure, void>> saveSaveData(SaveData saveData);
  Future<Either<Failure, void>> deleteSaveData();
}