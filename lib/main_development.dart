import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/core.dart';
import 'features/game/di/game_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set development environment
  AppConfig.setEnvironment(Environment.development);
  
  // Lock orientation to landscape for game
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Initialize dependency injection with injectable
  await initializeDependencies();
  
  // Initialize game-specific dependencies
  await GameInjection.initializeGameDependencies();
  
  runApp(const HardHatApp());
}