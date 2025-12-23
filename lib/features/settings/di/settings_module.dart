import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:hard_hat/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hard_hat/features/settings/domain/repositories/settings_repository.dart';
import 'package:hard_hat/features/settings/domain/usecases/get_settings.dart';
import 'package:hard_hat/features/settings/domain/usecases/update_settings.dart';

@module
abstract class SettingsModule {
  // Data Sources
  @LazySingleton(as: SettingsLocalDataSource)
  SettingsLocalDataSourceImpl get settingsLocalDataSource => SettingsLocalDataSourceImpl();

  // Repositories
  @LazySingleton(as: SettingsRepository)
  SettingsRepositoryImpl settingsRepository(SettingsLocalDataSource dataSource) =>
      SettingsRepositoryImpl(dataSource);

  // Use Cases
  @lazySingleton
  GetSettings getSettings(SettingsRepository repository) => GetSettings(repository);

  @lazySingleton
  UpdateSettings updateSettings(SettingsRepository repository) => UpdateSettings(repository);
}