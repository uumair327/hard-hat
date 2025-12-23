import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set production environment
  AppConfig.setEnvironment(Environment.production);
  
  // Lock orientation to landscape for game
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Initialize dependency injection
  await initializeDependencies();
  
  runApp(const HardHatApp());
}