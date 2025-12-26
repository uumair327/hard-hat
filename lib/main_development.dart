import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set development environment
  AppConfig.setEnvironment(Environment.development);
  
  // Lock orientation to landscape for game
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Setup manual dependencies
  await setupManualDependencies();
  
  runApp(const HardHatApp());
}