import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/data/data.dart';

@LazySingleton(as: LevelRepository)
class LevelRepositoryImpl implements LevelRepository {
  final LevelLocalDataSource _localDataSource;

  LevelRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Level>> getLevel(int levelId) async {
    try {
      final levelData = await _localDataSource.getLevel(levelId);
      final level = Level.fromJson(levelData);
      return Right(level);
    } catch (e) {
      return Left(LevelLoadFailure('Failed to load level $levelId: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Level>>> getAllLevels() async {
    try {
      final levelsData = await _localDataSource.getAllLevels();
      final levels = levelsData.map((data) => Level.fromJson(data)).toList();
      return Right(levels);
    } catch (e) {
      return Left(LevelLoadFailure('Failed to load all levels: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLevel(Level level) async {
    try {
      await _localDataSource.saveLevel(level.toJson());
      return const Right(null);
    } catch (e) {
      return Left(SaveFailure('Failed to save level: $e'));
    }
  }
}