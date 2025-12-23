import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  Future<Either<Failure, void>> call(Settings settings) async {
    return await repository.saveSettings(settings);
  }
}