import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/config/config.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

// Minimal dependencies for testing
import 'features/game/data/datasources/level_local_datasource.dart';
import 'features/game/data/datasources/level_local_datasource_impl.dart';
import 'features/game/data/datasources/save_local_datasource.dart';
import 'features/game/data/datasources/save_local_datasource_impl.dart';
import 'features/game/data/repositories/level_repository_impl.dart';
import 'features/game/data/repositories/save_repository_impl.dart';
import 'features/game/domain/usecases/load_level.dart';
import 'features/game/domain/usecases/load_level_impl.dart';
import 'features/game/domain/usecases/save_progress.dart';
import 'features/game/domain/usecases/save_progress_impl.dart';
import 'features/game/domain/systems/game_state_manager.dart' as gsm;
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/update_settings.dart';
import 'core/services/audio_manager.dart';
import 'features/game/domain/systems/audio_state_manager.dart';
import 'features/game/domain/systems/audio_system.dart';

final GetIt getIt = GetIt.instance;

/// Simple AudioStateManager implementation for minimal setup
class MinimalAudioStateManager extends AudioStateManager {
  final AudioManager _audioManager;
  
  MinimalAudioStateManager(this._audioManager) : super(AudioSystem(), _audioManager);
  
  @override
  void pauseAudio() {
    try {
      _audioManager.pauseAll();
    } catch (e) {
      // Ignore errors
    }
  }
  
  @override
  void resumeAudio() {
    try {
      _audioManager.resumeAll();
    } catch (e) {
      // Ignore errors
    }
  }
}

Future<void> setupMinimalDependencies() async {
  print('Setting up minimal dependencies...');
  
  // Core Services
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());
  
  // Audio State Manager
  getIt.registerLazySingleton<AudioStateManager>(() => MinimalAudioStateManager(
    getIt<AudioManager>(),
  ));
  
  // Game State Manager
  getIt.registerLazySingleton<gsm.GameStateManager>(() => gsm.GameStateManager(
    getIt<AudioStateManager>(),
  ));
  
  // Data Sources
  getIt.registerLazySingleton<LevelLocalDataSource>(() => LevelLocalDataSourceImpl());
  getIt.registerLazySingleton<SaveLocalDataSource>(() => SaveLocalDataSourceImpl());
  getIt.registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl());
  
  // Repositories
  getIt.registerLazySingleton(() => LevelRepositoryImpl(getIt<LevelLocalDataSource>()));
  getIt.registerLazySingleton(() => SaveRepositoryImpl(getIt<SaveLocalDataSource>()));
  getIt.registerLazySingleton(() => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()));
  
  // Use Cases
  getIt.registerLazySingleton<LoadLevel>(() => LoadLevelImpl(getIt()));
  getIt.registerLazySingleton<SaveProgress>(() => SaveProgressImpl(getIt()));
  getIt.registerLazySingleton(() => GetSettings(getIt()));
  getIt.registerLazySingleton(() => UpdateSettings(getIt()));
  
  // Blocs
  getIt.registerFactory(() => GameBloc(
    loadLevel: getIt<LoadLevel>(),
    saveProgress: getIt<SaveProgress>(),
    gameStateManager: getIt<gsm.GameStateManager>(),
  ));
  
  getIt.registerFactory(() => SettingsBloc(
    getSettings: getIt(),
    updateSettings: getIt(),
  ));
  
  print('Minimal dependencies setup completed!');
}

void main() async {
  print('Starting minimal app...');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set development environment
  AppConfig.setEnvironment(Environment.development);
  
  // Lock orientation to landscape for game
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Setup minimal dependencies
  await setupMinimalDependencies();
  
  print('Running app...');
  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GameBloc>(
          create: (context) => getIt<GameBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => getIt<SettingsBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Hard Hat Havoc - Minimal',
        debugShowCheckedModeBanner: false,
        home: const MinimalHomePage(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}

class MinimalHomePage extends StatelessWidget {
  const MinimalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hard Hat Havoc - Minimal'),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Minimal App Running Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Dependencies loaded without issues.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}