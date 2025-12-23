import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

import '../../../../core/errors/failures.dart';
import '../entities/save_data.dart';
import '../repositories/save_repository.dart';

/// SaveSystem provides atomic save operations with corruption detection and recovery
/// Implements requirements 8.1, 8.2, 8.3, 8.4, 8.5
class SaveSystem {
  final SaveRepository _saveRepository;
  static const String _saveFileName = 'save_data.json';
  static const String _backupFileName = 'save_data_backup.json';
  static const String _checksumFileName = 'save_data.checksum';
  
  SaveData? _cachedSaveData;
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  
  SaveSystem(this._saveRepository);

  /// Initialize the save system and load existing data
  /// Requirement 8.2: Load previous progress on game start
  Future<Either<Failure, SaveData>> initialize() async {
    try {
      final result = await _loadSaveDataWithRecovery();
      
      if (result.isRight()) {
        // Successfully loaded from file
        final saveData = result.getOrElse(() => throw Exception('Unexpected null'));
        _cachedSaveData = saveData;
        _startAutoSave();
        return Right(saveData);
      } else {
        // Fallback to repository if direct file access fails
        final repositoryResult = await _saveRepository.getSaveData();
        
        if (repositoryResult.isRight()) {
          final saveData = repositoryResult.getOrElse(() => null);
          if (saveData != null) {
            _cachedSaveData = saveData;
            _startAutoSave();
            return Right(saveData);
          } else {
            // Repository returned null, create default save data
            final defaultSaveData = await _createDefaultSaveData();
            _cachedSaveData = defaultSaveData;
            _startAutoSave();
            return Right(defaultSaveData);
          }
        } else {
          // Both file and repository failed, return original failure
          return result;
        }
      }
    } catch (e) {
      return Left(SaveFailure('Failed to initialize save system: $e'));
    }
  }

  /// Get current save data, loading from cache or storage
  /// Requirement 8.2: Load previous progress and unlock appropriate levels
  Future<Either<Failure, SaveData>> getSaveData() async {
    if (_cachedSaveData != null) {
      return Right(_cachedSaveData!);
    }
    
    final result = await _loadSaveDataWithRecovery();
    return result.fold(
      (failure) => Left(failure),
      (saveData) {
        _cachedSaveData = saveData;
        return Right(saveData);
      },
    );
  }

  /// Save progress data with atomic operations
  /// Requirement 8.1: Persist progress data to local storage immediately
  Future<Either<Failure, void>> saveProgress({
    int? currentLevel,
    Set<int>? unlockedLevels,
  }) async {
    try {
      final currentData = _cachedSaveData ?? await _getDefaultSaveData();
      
      final updatedData = currentData.copyWith(
        currentLevel: currentLevel,
        unlockedLevels: unlockedLevels,
        lastPlayed: DateTime.now(),
      );
      
      final result = await _atomicSave(updatedData);
      return result.fold(
        (failure) => Left(failure),
        (_) {
          _cachedSaveData = updatedData;
          _isDirty = false;
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(SaveFailure('Failed to save progress: $e'));
    }
  }

  /// Save settings with persistence
  /// Requirement 8.3: Store preferences persistently
  Future<Either<Failure, void>> saveSettings(Map<String, dynamic> settings) async {
    try {
      final currentData = _cachedSaveData ?? await _getDefaultSaveData();
      
      final updatedData = currentData.copyWith(
        settings: settings,
        lastPlayed: DateTime.now(),
      );
      
      final result = await _atomicSave(updatedData);
      return result.fold(
        (failure) => Left(failure),
        (_) {
          _cachedSaveData = updatedData;
          _isDirty = false;
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(SaveFailure('Failed to save settings: $e'));
    }
  }

  /// Mark save data as dirty for auto-save
  void markDirty() {
    _isDirty = true;
  }

  /// Perform atomic save operation with backup and checksum verification
  /// Requirement 8.5: Maintain data integrity through atomic operations
  Future<Either<Failure, void>> _atomicSave(SaveData saveData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final saveFile = File('${directory.path}/$_saveFileName');
      final backupFile = File('${directory.path}/$_backupFileName');
      final checksumFile = File('${directory.path}/$_checksumFileName');
      final tempFile = File('${directory.path}/$_saveFileName.tmp');
      
      // Create backup of existing save if it exists
      if (await saveFile.exists()) {
        await saveFile.copy(backupFile.path);
      }
      
      // Serialize data
      final jsonString = json.encode(saveData.toJson());
      final checksum = _calculateChecksum(jsonString);
      
      // Write to temporary file first (atomic operation part 1)
      await tempFile.writeAsString(jsonString);
      
      // Verify the temporary file was written correctly
      final tempContent = await tempFile.readAsString();
      final tempChecksum = _calculateChecksum(tempContent);
      
      if (tempChecksum != checksum) {
        await tempFile.delete();
        return const Left(SaveFailure('Save data verification failed during write'));
      }
      
      // Atomic rename (atomic operation part 2)
      await tempFile.rename(saveFile.path);
      
      // Save checksum
      await checksumFile.writeAsString(checksum);
      
      return const Right(null);
    } catch (e) {
      return Left(SaveFailure('Atomic save operation failed: $e'));
    }
  }

  /// Load save data with corruption detection and recovery
  /// Requirement 8.4: Handle save corruption gracefully with recovery options
  Future<Either<Failure, SaveData>> _loadSaveDataWithRecovery() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final saveFile = File('${directory.path}/$_saveFileName');
      final backupFile = File('${directory.path}/$_backupFileName');
      final checksumFile = File('${directory.path}/$_checksumFileName');
      
      // Try to load primary save file
      if (await saveFile.exists()) {
        final primaryResult = await _loadAndVerifySaveFile(saveFile, checksumFile);
        if (primaryResult.isRight()) {
          return primaryResult;
        }
        
        // Primary file is corrupted, try backup
        if (await backupFile.exists()) {
          final backupResult = await _loadAndVerifySaveFile(backupFile, null);
          if (backupResult.isRight()) {
            // Restore from backup
            await backupFile.copy(saveFile.path);
            final jsonString = await saveFile.readAsString();
            final checksum = _calculateChecksum(jsonString);
            await checksumFile.writeAsString(checksum);
            
            return backupResult;
          }
        }
        
        // Both files corrupted, create default save data
        return Right(await _createDefaultSaveData());
      }
      
      // No save file exists, create default
      return Right(await _createDefaultSaveData());
    } catch (e) {
      return Left(SaveFailure('Failed to load save data: $e'));
    }
  }

  /// Load and verify a save file against its checksum
  Future<Either<Failure, SaveData>> _loadAndVerifySaveFile(
    File saveFile, 
    File? checksumFile,
  ) async {
    try {
      final jsonString = await saveFile.readAsString();
      
      // Verify checksum if available
      if (checksumFile != null && await checksumFile.exists()) {
        final expectedChecksum = await checksumFile.readAsString();
        final actualChecksum = _calculateChecksum(jsonString);
        
        if (expectedChecksum != actualChecksum) {
          return const Left(SaveFailure('Save file checksum mismatch'));
        }
      }
      
      // Parse JSON
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final saveData = SaveData.fromJson(jsonMap);
      
      return Right(saveData);
    } catch (e) {
      return Left(SaveFailure('Failed to load save file: $e'));
    }
  }

  /// Calculate SHA-256 checksum for data integrity verification
  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create default save data for new games
  Future<SaveData> _createDefaultSaveData() async {
    return SaveData(
      currentLevel: 1,
      unlockedLevels: {1},
      settings: <String, dynamic>{},
      lastPlayed: DateTime.now(),
    );
  }

  /// Get default save data
  Future<SaveData> _getDefaultSaveData() async {
    return _cachedSaveData ?? await _createDefaultSaveData();
  }

  /// Start auto-save timer for dirty data
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isDirty && _cachedSaveData != null) {
        _atomicSave(_cachedSaveData!);
        _isDirty = false;
      }
    });
  }

  /// Clean up resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _cachedSaveData = null;
  }

  /// Delete all save data
  Future<Either<Failure, void>> deleteSaveData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final saveFile = File('${directory.path}/$_saveFileName');
      final backupFile = File('${directory.path}/$_backupFileName');
      final checksumFile = File('${directory.path}/$_checksumFileName');
      
      if (await saveFile.exists()) {
        await saveFile.delete();
      }
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      if (await checksumFile.exists()) {
        await checksumFile.delete();
      }
      
      _cachedSaveData = null;
      _isDirty = false;
      
      return const Right(null);
    } catch (e) {
      return Left(SaveFailure('Failed to delete save data: $e'));
    }
  }

  /// Get current save data synchronously (cached)
  SaveData? get currentSaveData => _cachedSaveData;

  /// Check if save data has unsaved changes
  bool get isDirty => _isDirty;
}