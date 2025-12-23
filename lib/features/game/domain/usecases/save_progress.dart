import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hard_hat/core/errors/failures.dart';

abstract class SaveProgress {
  Future<Either<Failure, void>> call(SaveProgressParams params);
}

class SaveProgressParams extends Equatable {
  final int currentLevel;
  final Set<int> unlockedLevels;

  const SaveProgressParams({
    required this.currentLevel,
    required this.unlockedLevels,
  });

  @override
  List<Object?> get props => [currentLevel, unlockedLevels];
}