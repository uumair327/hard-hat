import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<Either<Failure, Settings>> call() async {
    return await repository.getSettings();
  }
}