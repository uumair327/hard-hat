import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsModel> getSettings();
  Future<void> saveSettings(SettingsModel settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _settingsFileName = 'settings.json';

  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_settingsFileName');
  }

  @override
  Future<SettingsModel> getSettings() async {
    try {
      final file = await _getSettingsFile();
      if (!await file.exists()) {
        // Return default settings if file doesn't exist
        return const SettingsModel();
      }

      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString);
      return SettingsModel.fromJson(jsonMap);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      final file = await _getSettingsFile();
      final jsonString = json.encode(settings.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw CacheException();
    }
  }
}