import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/usecases/save_progress.dart';
import 'package:hard_hat/features/game/domain/repositories/save_repository.dart';
import 'package:hard_hat/features/game/domain/entities/save_data.dart';

@LazySingleton(as: SaveProgress)
class SaveProgressImpl implements SaveProgress {
  final SaveRepository _repository;

  SaveProgressImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(SaveProgressParams params) async {
    final saveData = SaveData(
      currentLevel: params.currentLevel,
      unlockedLevels: params.unlockedLevels,
      lastPlayed: DateTime.now(),
    );
    
    return await _repository.saveSaveData(saveData);
  }
}