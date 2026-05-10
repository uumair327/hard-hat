import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';
import 'package:hard_hat/save/game_save_manager.dart';
import 'app.dart';

/// Main entry point — Hard Hat Havoc
/// Flow: Main Menu → Intro Comic → Game → Level Complete → Next Level → Outro
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await GameSaveManager.initialize();
  GameAudioManager.initialize();

  runApp(const HardHatApp());
}
