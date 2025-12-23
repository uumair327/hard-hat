import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:hard_hat/core/errors/failures.dart';
import 'package:hard_hat/features/game/domain/entities/level.dart';

abstract class LoadLevel {
  Future<Either<Failure, Level>> call(LoadLevelParams params);
}

class LoadLevelParams extends Equatable {
  final int levelId;

  const LoadLevelParams({required this.levelId});

  @override
  List<Object?> get props => [levelId];
}