import 'package:flame/extensions.dart';
import 'package:hard_hat/core/services/level_data.dart';
import 'package:hard_hat/core/services/level_loader.dart';

/// Interface for level management
abstract class ILevelManager {
  /// Loads a level by ID
  Future<void> loadLevel(int levelId);

  /// Switches to a different segment within the current level
  void switchSegment(int segmentId, {bool killBall = true});

  /// Gets the spawn point for the current segment
  Vector2 getCurrentSpawnPoint();

  /// Gets the minimum camera bounds for the current segment
  Vector2 getCurrentCameraMin();

  /// Gets the maximum camera bounds for the current segment
  Vector2 getCurrentCameraMax();

  /// Gets the current segment ID
  int get currentSegment;

  /// Gets the segment ID where the ball is located
  int get ballSegment;

  /// Gets the current level ID
  int get currentLevel;

  /// Gets the current level data
  LevelData? get currentLevelData;

  /// Disposes of the level manager
  void dispose();
}

/// Implementation of level management
class LevelManager implements ILevelManager {
  final LevelLoader _levelLoader;

  LevelData? _currentLevelData;
  int _currentSegment = 0;
  int _ballSegment = 0;
  int _currentLevel = 0;

  LevelManager({LevelLoader? levelLoader})
      : _levelLoader = levelLoader ?? LevelLoader();

  @override
  Future<void> loadLevel(int levelId) async {
    try {
      // Load level data
      _currentLevelData = await _levelLoader.loadLevel(levelId);
      _currentLevel = levelId;

      // Reset to first segment
      _currentSegment = 0;
      _ballSegment = 0;
    } catch (e) {
      throw LevelManagerException(
        'Failed to load level $levelId',
        e,
      );
    }
  }

  @override
  void switchSegment(int segmentId, {bool killBall = true}) {
    if (_currentLevelData == null) {
      throw LevelManagerException(
        'Cannot switch segment: No level loaded',
        null,
      );
    }

    // Validate segment ID
    if (segmentId < 0 || segmentId >= _currentLevelData!.segments.length) {
      throw LevelManagerException(
        'Invalid segment ID: $segmentId (level has ${_currentLevelData!.segments.length} segments)',
        null,
      );
    }

    // Update current segment
    _currentSegment = segmentId;

    // Update ball segment if not killing ball
    if (!killBall) {
      _ballSegment = segmentId;
    }
  }

  @override
  Vector2 getCurrentSpawnPoint() {
    if (_currentLevelData == null) {
      return Vector2.zero();
    }

    // If segments exist and current segment is valid, use segment spawn point
    if (_currentLevelData!.segments.isNotEmpty &&
        _currentSegment < _currentLevelData!.segments.length) {
      final segment = _currentLevelData!.segments[_currentSegment];
      if (segment.spawnPoint != Vector2.zero()) {
        return segment.spawnPoint.clone();
      }
    }

    // Fall back to level's default player spawn
    return _currentLevelData!.playerSpawn.clone();
  }

  @override
  Vector2 getCurrentCameraMin() {
    if (_currentLevelData == null) {
      return Vector2.zero();
    }

    // If segments exist and current segment is valid, use segment camera bounds
    if (_currentLevelData!.segments.isNotEmpty &&
        _currentSegment < _currentLevelData!.segments.length) {
      final segment = _currentLevelData!.segments[_currentSegment];
      if (segment.cameraMin != Vector2.zero()) {
        return segment.cameraMin.clone();
      }
    }

    // Fall back to level's default camera min
    return _currentLevelData!.cameraMin.clone();
  }

  @override
  Vector2 getCurrentCameraMax() {
    if (_currentLevelData == null) {
      return Vector2.zero();
    }

    // If segments exist and current segment is valid, use segment camera bounds
    if (_currentLevelData!.segments.isNotEmpty &&
        _currentSegment < _currentLevelData!.segments.length) {
      final segment = _currentLevelData!.segments[_currentSegment];
      if (segment.cameraMax != Vector2.zero()) {
        return segment.cameraMax.clone();
      }
    }

    // Fall back to level's default camera max
    return _currentLevelData!.cameraMax.clone();
  }

  @override
  int get currentSegment => _currentSegment;

  @override
  int get ballSegment => _ballSegment;

  @override
  int get currentLevel => _currentLevel;

  @override
  LevelData? get currentLevelData => _currentLevelData;

  @override
  void dispose() {
    _currentLevelData = null;
    _currentSegment = 0;
    _ballSegment = 0;
    _currentLevel = 0;
  }
}

/// Exception thrown by LevelManager
class LevelManagerException implements Exception {
  final String message;
  final Object? cause;

  LevelManagerException(this.message, this.cause);

  @override
  String toString() {
    if (cause != null) {
      return 'LevelManagerException: $message\nCaused by: $cause';
    }
    return 'LevelManagerException: $message';
  }
}
