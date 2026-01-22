import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:hard_hat/core/services/audio_manager.dart';
import 'package:hard_hat/features/settings/domain/usecases/get_settings.dart';
import 'package:hard_hat/features/settings/domain/usecases/update_settings.dart';
import 'package:hard_hat/features/settings/domain/repositories/settings_repository.dart';
import 'package:hard_hat/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:hard_hat/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:hard_hat/features/settings/presentation/bloc/settings_bloc.dart';

final GetIt getIt = GetIt.instance;

/// Manual dependency injection setup
/// This will be replaced by injectable generated code later
Future<void> setupManualDependencies() async {
  debugPrint('Starting ultra-simplified dependency setup...');
  
  try {
    // Only register what's absolutely necessary for navigation
    debugPrint('Registering core services...');
    getIt.registerLazySingleton<AudioManager>(() => AudioManager());
    
    // Settings layer (minimal)
    debugPrint('Registering settings layer...');
    getIt.registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl());
    getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()));
    getIt.registerLazySingleton<GetSettings>(() => GetSettings(getIt<SettingsRepository>()));
    getIt.registerLazySingleton<UpdateSettings>(() => UpdateSettings(getIt<SettingsRepository>()));
    
    // Settings Bloc (minimal)
    getIt.registerFactory(() => SettingsBloc(
      getSettings: getIt<GetSettings>(),
      updateSettings: getIt<UpdateSettings>(),
    ));
    
    debugPrint('Ultra-simplified dependency setup completed successfully!');
  } catch (e) {
    debugPrint('Error in ultra-simplified dependency setup: $e');
    rethrow;
  }
}

