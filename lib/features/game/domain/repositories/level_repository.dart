import 'package:dartz/dartz.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/entities/level.dart';

abstract class LevelRepository {
  Future<Either<Failure, Level>> getLevel(int levelId);
  Future<Either<Failure, List<Level>>> getAllLevels();
  Future<Either<Failure, void>> saveLevel(Level level);
}