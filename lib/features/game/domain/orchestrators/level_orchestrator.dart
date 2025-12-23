import 'package:hard_hat/features/game/domain/domain.dart';

/// Level Management Orchestrator - manages levels and save data
/// Follows SRP - only responsible for level coordination
class LevelOrchestrator {
  final ILevelManager? _levelManager;
  final ISaveSystem? _saveSystem;
  final IEntityManager _entityManager;

  /// Callbacks for level events
  void Function(Level level)? onLevelComplete;
  void Function(Level level)? onLevelLoaded;
  void Function()? onGameOver;

  LevelOrchestrator({
    ILevelManager? levelManager,
    ISaveSystem? saveSystem,
    required IEntityManager entityManager,
  })  : _levelManager = levelManager,
        _saveSystem = saveSystem,
        _entityManager = entityManager;

  /// Initialize level orchestrator
  void initialize() {
    // Set up level manager callbacks if available
    if (_levelManager != null) {
      _levelManager.onLevelComplete = _handleLevelComplete;
      _levelManager.onLevelLoaded = _handleLevelLoaded;
    }
  }

  /// Load a specific level
  Future<void> loadLevel(int levelId) async {
    await _levelManager?.loadLevel(levelId);
  }

  /// Restart current level
  Future<void> restartLevel() async {
    // TODO: Implement restart level when level manager is available
    // await _levelManager?.restartLevel();
  }

  /// Save game progress
  Future<void> saveProgress({
    required int currentLevel,
    Set<int>? unlockedLevels,
  }) async {
    await _saveSystem?.saveProgress(
      currentLevel: currentLevel,
      unlockedLevels: unlockedLevels,
    );
  }

  /// Load game progress
  Future<dynamic> loadProgress() async {
    return await _saveSystem?.loadProgress();
  }

  /// Handle level completion
  void _handleLevelComplete(dynamic level) {
    if (level is Level) {
      // Save progress automatically
      _saveProgressForLevel(level);
      
      // Notify listeners
      onLevelComplete?.call(level);
    }
  }

  /// Handle level loaded
  void _handleLevelLoaded(dynamic level) {
    if (level is Level) {
      // Notify listeners
      onLevelLoaded?.call(level);
    }
  }

  /// Save progress for completed level
  Future<void> _saveProgressForLevel(Level level) async {
    final currentSaveData = _saveSystem?.currentSaveData;
    if (currentSaveData != null) {
      final nextLevel = level.id + 1;
      final updatedUnlockedLevels = Set<int>.from(currentSaveData.unlockedLevels);
      updatedUnlockedLevels.add(nextLevel);
      
      await saveProgress(
        currentLevel: nextLevel,
        unlockedLevels: updatedUnlockedLevels,
      );
    }
  }

  /// Get current level
  Level? get currentLevel => _levelManager?.currentLevel;

  /// Get current save data
  dynamic get currentSaveData => _saveSystem?.currentSaveData;

  /// Get entity count in current level
  int get entityCount => _entityManager.entityCount;

  /// Clear all entities (for level transitions)
  void clearAllEntities() => _entityManager.clearAllEntities();
}