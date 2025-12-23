import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/usecases/load_level.dart';
import 'package:hard_hat/features/game/domain/repositories/level_repository.dart';
import 'package:hard_hat/features/game/domain/entities/level.dart';

@LazySingleton(as: LoadLevel)
class LoadLevelImpl implements LoadLevel {
  final LevelRepository _repository;

  LoadLevelImpl(this._repository);

  @override
  Future<Either<Failure, Level>> call(LoadLevelParams params) async {
    return await _repository.getLevel(params.levelId);
  }
}