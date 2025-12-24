import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../entities/level.dart';
import '../entities/save_data.dart';
import '../repositories/save_repository.dart';
import 'game_system.dart';
import 'level_manager.dart';
import 'camera_system.dart';

/// Enum for different transition types
enum TransitionType {
  fadeOut,
  fadeIn,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
}

/// Enum for transition states
enum TransitionState {
  idle,
  transitioning,
  complete,
}

/// Data class for level progression
class LevelProgression {
  final int currentLevel;
  final Set<int> unlockedLevels;
  final int maxLevel;
  
  const LevelProgression({
    required this.currentLevel,
    required this.unlockedLevels,
    required this.maxLevel,
  });
  
  LevelProgression copyWith({
    int? currentLevel,
    Set<int>? unlockedLevels,
    int? maxLevel,
  }) {
    return LevelProgression(
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      maxLevel: maxLevel ?? this.maxLevel,
    );
  }
  
  bool isLevelUnlocked(int levelId) {
    return unlockedLevels.contains(levelId);
  }
}

/// System responsible for managing level transitions and progression
class LevelTransitionSystem extends GameSystem {
  final LevelManager _levelManager;
  final CameraSystem _cameraSystem;
  final SaveRepository _saveRepository;
  
  /// Current transition state
  TransitionState _transitionState = TransitionState.idle;
  
  /// Current transition type
  TransitionType _currentTransitionType = TransitionType.fadeOut;
  
  /// Transition progress (0.0 to 1.0)
  double _transitionProgress = 0.0;
  
  /// Transition duration in seconds
  double _transitionDuration = 1.0;
  
  /// Current transition timer
  double _transitionTimer = 0.0;
  
  /// Level progression data
  LevelProgression _progression = const LevelProgression(
    currentLevel: 1,
    unlockedLevels: {1},
    maxLevel: 10,
  );
  
  /// Pending level to transition to
  int? _pendingLevelId;
  
  /// Transition callbacks
  void Function()? onTransitionStart;
  void Function()? onTransitionComplete;
  void Function(int levelId)? onLevelUnlocked;
  void Function(LevelProgression progression)? onProgressionUpdated;
  
  /// Camera segment switching
  final Map<String, Vector2> _cameraSegments = {};
  String? _currentSegment;
  
  /// Segment transition settings
  static const double segmentTransitionSpeed = 200.0;
  bool _isSegmentTransitioning = false;
  Vector2? _segmentTransitionTarget;

  LevelTransitionSystem({
    required LevelManager levelManager,
    required CameraSystem cameraSystem,
    required SaveRepository saveRepository,
  }) : _levelManager = levelManager,
       _cameraSystem = cameraSystem,
       _saveRepository = saveRepository;

  @override
  int get priority => -400; // Execute after level manager

  @override
  Future<void> initialize() async {
    // Load progression from save data
    await _loadProgression();
    
    // Set up level manager callbacks
    _levelManager.onLevelComplete = _onLevelComplete;
  }

  /// Load progression data from save repository
  Future<void> _loadProgression() async {
    final result = await _saveRepository.getSaveData();
    result.fold(
      (failure) {
        // Use default progression if loading fails
        _progression = const LevelProgression(
          currentLevel: 1,
          unlockedLevels: {1},
          maxLevel: 10,
        );
      },
      (saveData) {
        if (saveData != null) {
          _progression = LevelProgression(
            currentLevel: saveData.currentLevel,
            unlockedLevels: saveData.unlockedLevels,
            maxLevel: 10, // Could be loaded from config
          );
        } else {
          // Use default progression if save data is null
          _progression = const LevelProgression(
            currentLevel: 1,
            unlockedLevels: {1},
            maxLevel: 10,
          );
        }
      },
    );
    
    onProgressionUpdated?.call(_progression);
  }

  /// Save progression data
  Future<void> _saveProgression() async {
    final saveData = SaveData(
      currentLevel: _progression.currentLevel,
      unlockedLevels: _progression.unlockedLevels,
      settings: <String, dynamic>{}, // Empty settings for now
      lastPlayed: DateTime.now(),
    );
    
    await _saveRepository.saveSaveData(saveData);
  }

  /// Handle level completion
  void _onLevelComplete(Level level) {
    final nextLevelId = level.id + 1;
    
    // Unlock next level if it exists and isn't already unlocked
    if (nextLevelId <= _progression.maxLevel && 
        !_progression.unlockedLevels.contains(nextLevelId)) {
      _unlockLevel(nextLevelId);
    }
    
    // Auto-transition to next level after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (nextLevelId <= _progression.maxLevel) {
        transitionToLevel(nextLevelId);
      }
    });
  }

  /// Unlock a level
  void _unlockLevel(int levelId) {
    if (levelId > _progression.maxLevel) return;
    
    final newUnlockedLevels = Set<int>.from(_progression.unlockedLevels);
    newUnlockedLevels.add(levelId);
    
    _progression = _progression.copyWith(unlockedLevels: newUnlockedLevels);
    
    onLevelUnlocked?.call(levelId);
    onProgressionUpdated?.call(_progression);
    
    // Save progression
    _saveProgression();
  }

  /// Start transition to a specific level
  Future<void> transitionToLevel(
    int levelId, {
    TransitionType transitionType = TransitionType.fadeOut,
    double duration = 1.0,
  }) async {
    // Check if level is unlocked
    if (!_progression.isLevelUnlocked(levelId)) {
      return;
    }
    
    // Don't start new transition if already transitioning
    if (_transitionState != TransitionState.idle) {
      return;
    }
    
    _pendingLevelId = levelId;
    _currentTransitionType = transitionType;
    _transitionDuration = duration;
    _transitionTimer = 0.0;
    _transitionProgress = 0.0;
    _transitionState = TransitionState.transitioning;
    
    onTransitionStart?.call();
  }

  /// Update transition logic
  void _updateTransition(double dt) {
    if (_transitionState != TransitionState.transitioning) return;
    
    _transitionTimer += dt;
    _transitionProgress = (_transitionTimer / _transitionDuration).clamp(0.0, 1.0);
    
    // Check if transition is halfway (time to load new level)
    if (_transitionProgress >= 0.5 && _pendingLevelId != null) {
      _levelManager.loadLevel(_pendingLevelId!);
      _progression = _progression.copyWith(currentLevel: _pendingLevelId!);
      _pendingLevelId = null;
    }
    
    // Check if transition is complete
    if (_transitionProgress >= 1.0) {
      _transitionState = TransitionState.complete;
      _transitionTimer = 0.0;
      
      // Reset to idle after a brief delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _transitionState = TransitionState.idle;
        onTransitionComplete?.call();
      });
    }
  }

  /// Update camera segment transitions
  void _updateSegmentTransition(double dt) {
    if (!_isSegmentTransitioning || _segmentTransitionTarget == null) return;
    
    final currentBounds = _cameraSystem.getCameraViewRect();
    
    final direction = _segmentTransitionTarget! - Vector2(currentBounds.left, currentBounds.top);
    final distance = direction.length;
    
    if (distance < 1.0) {
      // Transition complete
      _isSegmentTransitioning = false;
      _segmentTransitionTarget = null;
      return;
    }
    
    // Move camera bounds towards target
    final moveDistance = segmentTransitionSpeed * dt;
    final normalizedDirection = direction.normalized();
    final movement = normalizedDirection * moveDistance;
    
    final newPosition = Vector2(currentBounds.left, currentBounds.top) + movement;
    
    _cameraSystem.transitionToPosition(newPosition, speed: segmentTransitionSpeed);
  }

  /// Switch to a camera segment
  void switchToCameraSegment(String segmentId) {
    final segmentBounds = _cameraSegments[segmentId];
    if (segmentBounds == null || segmentId == _currentSegment) return;
    
    _currentSegment = segmentId;
    _segmentTransitionTarget = segmentBounds;
    _isSegmentTransitioning = true;
  }

  /// Register a camera segment
  void registerCameraSegment(String segmentId, Vector2 topLeft, Vector2 bottomRight) {
    _cameraSegments[segmentId] = topLeft;
    
    // If this is the first segment, set it as current
    if (_currentSegment == null) {
      _currentSegment = segmentId;
      _cameraSystem.setBounds(topLeft, bottomRight);
    }
  }

  /// Clear all camera segments
  void clearCameraSegments() {
    _cameraSegments.clear();
    _currentSegment = null;
    _isSegmentTransitioning = false;
    _segmentTransitionTarget = null;
  }

  @override
  void updateSystem(double dt) {
    _updateTransition(dt);
    _updateSegmentTransition(dt);
  }

  @override
  void renderSystem(Canvas canvas) {
    if (_transitionState == TransitionState.idle) return;
    
    // Render transition overlay
    _renderTransitionOverlay(canvas);
  }

  /// Render transition overlay effect
  void _renderTransitionOverlay(Canvas canvas) {
    final gameSize = findGame()?.size ?? Vector2.zero();
    if (gameSize == Vector2.zero()) return;
    
    double opacity;
    
    switch (_currentTransitionType) {
      case TransitionType.fadeOut:
        // Fade out then fade in
        if (_transitionProgress <= 0.5) {
          opacity = _transitionProgress * 2.0; // 0.0 to 1.0
        } else {
          opacity = 2.0 - (_transitionProgress * 2.0); // 1.0 to 0.0
        }
        break;
        
      case TransitionType.fadeIn:
        opacity = 1.0 - _transitionProgress;
        break;
        
      default:
        opacity = _transitionProgress <= 0.5 ? _transitionProgress * 2.0 : 2.0 - (_transitionProgress * 2.0);
        break;
    }
    
    // Draw overlay
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      paint,
    );
  }

  /// Get current progression
  LevelProgression get progression => _progression;
  
  /// Get current transition state
  TransitionState get transitionState => _transitionState;
  
  /// Get transition progress
  double get transitionProgress => _transitionProgress;
  
  /// Check if a level is unlocked
  bool isLevelUnlocked(int levelId) => _progression.isLevelUnlocked(levelId);
  
  /// Get current level ID
  int get currentLevelId => _progression.currentLevel;
  
  /// Get unlocked levels
  Set<int> get unlockedLevels => _progression.unlockedLevels;
  
  /// Get max level
  int get maxLevel => _progression.maxLevel;
  
  /// Check if transitioning
  bool get isTransitioning => _transitionState == TransitionState.transitioning;
  
  /// Get current camera segment
  String? get currentCameraSegment => _currentSegment;
  
  /// Check if camera is transitioning between segments
  bool get isCameraSegmentTransitioning => _isSegmentTransitioning;

  @override
  void dispose() {
    clearCameraSegments();
    super.dispose();
  }
}