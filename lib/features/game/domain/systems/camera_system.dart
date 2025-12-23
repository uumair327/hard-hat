import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../systems/game_system.dart';
import '../systems/game_state_manager.dart';
import '../components/camera_component.dart' as game_camera;
import '../entities/player_entity.dart';
import '../entities/ball_entity.dart';
import '../../data/models/level_model.dart';
import '../../../../core/constants/game_constants.dart';

/// Camera system that handles viewport management, following behavior, and camera effects
class CameraSystem extends GameSystem {
  /// The main camera component
  late game_camera.GameCameraComponent _camera;
  
  /// Game state manager for state-aware camera behavior
  GameStateManager? _gameStateManager;
  
  /// Reference to the player entity for following
  PlayerEntity? _playerTarget;
  
  /// Current level data for boundaries
  LevelModel? _currentLevel;
  
  /// Whether camera shake is enabled
  bool _shakeEnabled = true;
  
  /// Last ball impact position for shake effects
  Vector2? _lastImpactPosition;
  
  /// Camera transition state
  bool _isTransitioning = false;
  Vector2? _transitionTarget;
  double _transitionSpeed = 10.0;
  
  /// State-specific camera behaviors
  final Map<GameState, CameraBehavior> _stateBehaviors = {};
  
  @override
  int get priority => 100; // Update after movement but before rendering
  
  @override
  Future<void> initialize() async {
    // Initialize camera with default settings
    _camera = game_camera.GameCameraComponent(
      initialPosition: Vector2.zero(),
      followSpeed: GameConstants.cameraFollowSpeed,
      viewportSize: Vector2(800, 600), // Default size, will be updated
      deadZone: Vector2(100, 50),
    );
    
    // Find player entity if it exists
    _findPlayerTarget();
    
    // Initialize state-specific camera behaviors
    _initializeCameraBehaviors();
  }
  
  /// Set the game state manager for state-aware camera behavior
  void setGameStateManager(GameStateManager gameStateManager) {
    _gameStateManager = gameStateManager;
    
    // Register for state change callbacks
    _gameStateManager?.addStateChangeCallback(_onGameStateChanged);
  }
  
  /// Initialize state-specific camera behaviors
  void _initializeCameraBehaviors() {
    _stateBehaviors[GameState.playing] = CameraBehavior(
      allowFollowing: true,
      allowShake: true,
      allowTransitions: true,
      followSpeed: GameConstants.cameraFollowSpeed,
    );
    
    _stateBehaviors[GameState.paused] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: false,
      followSpeed: 0.0,
    );
    
    _stateBehaviors[GameState.menu] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: true,
      followSpeed: 0.0,
    );
    
    _stateBehaviors[GameState.levelComplete] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: true,
      followSpeed: 0.0,
    );
    
    _stateBehaviors[GameState.gameOver] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: true,
      followSpeed: 0.0,
    );
    
    _stateBehaviors[GameState.loading] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: false,
      followSpeed: 0.0,
    );
    
    _stateBehaviors[GameState.settings] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: false,
      followSpeed: 0.0,
    );
    
    _stateBehaviors[GameState.error] = CameraBehavior(
      allowFollowing: false,
      allowShake: false,
      allowTransitions: false,
      followSpeed: 0.0,
    );
  }
  
  /// Handle game state changes
  void _onGameStateChanged(GameState newState, GameState? previousState) {
    final behavior = _stateBehaviors[newState];
    if (behavior != null) {
      _applyCameraBehavior(behavior);
    }
    
    // Handle specific state transitions
    switch (newState) {
      case GameState.paused:
        _camera.setFollowing(false);
        _camera.stopShake();
        break;
      case GameState.playing:
        _camera.setFollowing(true);
        break;
      case GameState.levelComplete:
      case GameState.gameOver:
        _camera.setFollowing(false);
        // Optionally zoom out or transition to a specific view
        break;
      case GameState.menu:
        _camera.setFollowing(false);
        _camera.stopShake();
        break;
      default:
        break;
    }
  }
  
  /// Apply camera behavior based on current state
  void _applyCameraBehavior(CameraBehavior behavior) {
    _camera.setFollowing(behavior.allowFollowing);
    _camera.setFollowSpeed(behavior.followSpeed);
    _shakeEnabled = behavior.allowShake;
    
    if (!behavior.allowShake) {
      _camera.stopShake();
    }
    
    if (!behavior.allowTransitions) {
      _isTransitioning = false;
      _transitionTarget = null;
    }
  }
  
  /// Get current camera behavior based on game state
  CameraBehavior _getCurrentCameraBehavior() {
    final currentState = _gameStateManager?.currentState ?? GameState.playing;
    return _stateBehaviors[currentState] ?? _stateBehaviors[GameState.playing]!;
  }
  
  @override
  void updateSystem(double dt) {
    final behavior = _getCurrentCameraBehavior();
    
    // Find player target if we don't have one
    if (_playerTarget == null) {
      _findPlayerTarget();
    }
    
    // Update camera target to player position (only if following is allowed)
    if (_playerTarget != null && behavior.allowFollowing) {
      _camera.setTarget(_playerTarget!.positionComponent.position);
    }
    
    // Handle camera transitions (only if allowed)
    if (_isTransitioning && _transitionTarget != null && behavior.allowTransitions) {
      _updateTransition(dt);
    }
    
    // Check for ball impacts to trigger screen shake (only if allowed)
    if (behavior.allowShake) {
      _checkForBallImpacts();
    }
    
    // Update camera component
    _camera.updateCamera(dt);
    
    // Apply camera transform to the game
    _applyCameraTransform();
  }
  
  /// Find the player entity to follow
  void _findPlayerTarget() {
    final players = getComponents<PlayerEntity>();
    if (players.isNotEmpty) {
      _playerTarget = players.first;
    }
  }
  
  /// Check for ball impacts to trigger screen shake
  void _checkForBallImpacts() {
    if (!_shakeEnabled) return;
    
    final balls = getComponents<BallEntity>();
    for (final ball in balls) {
      // Check if ball just collided (this would be set by collision system)
      // For now, we'll use a simple velocity-based detection
      if (ball.velocityComponent.velocity.length < 50 && 
          ball.velocityComponent.velocity.length > 0) {
        
        final impactPosition = ball.positionComponent.position;
        
        // Only shake if this is a new impact position
        if (_lastImpactPosition == null || 
            impactPosition.distanceTo(_lastImpactPosition!) > 10) {
          
          _lastImpactPosition = impactPosition.clone();
          
          // Calculate shake intensity based on ball velocity
          final intensity = (ball.velocityComponent.velocity.length / 200.0)
              .clamp(0.0, 1.0) * GameConstants.screenShakeIntensity;
          
          triggerScreenShake(intensity, 0.3);
        }
      }
    }
  }
  
  /// Update camera transition
  void _updateTransition(double dt) {
    if (_transitionTarget == null) return;
    
    final currentPos = _camera.position;
    final targetPos = _transitionTarget!;
    final distance = currentPos.distanceTo(targetPos);
    
    if (distance < 5.0) {
      // Transition complete
      _camera.setPosition(targetPos);
      _isTransitioning = false;
      _transitionTarget = null;
    } else {
      // Move towards target
      final direction = (targetPos - currentPos).normalized();
      final moveDistance = _transitionSpeed * distance * dt;
      final newPosition = currentPos + (direction * moveDistance);
      _camera.setPosition(newPosition);
    }
  }
  
  /// Apply camera transform to the game world
  void _applyCameraTransform() {
    final game = findGame();
    if (game == null) return;
    
    final cameraPosition = _camera.getFinalPosition();
    
    // Apply camera transform to the game's camera
    // In Flame, we use the camera's viewfinder to control the viewport
    if (game.camera.viewfinder.visibleGameSize != null) {
      game.camera.viewfinder.position = cameraPosition;
    }
  }
  
  // Public interface methods
  
  /// Set the player entity to follow
  void setPlayerTarget(PlayerEntity player) {
    _playerTarget = player;
  }
  
  /// Set camera boundaries
  void setBounds(Vector2 min, Vector2 max) {
    _camera.setBoundaries(min, max);
  }
  
  /// Load level data and set camera boundaries
  void loadLevel(LevelModel level) {
    _currentLevel = level;
    _camera.setBoundaries(level.cameraMin, level.cameraMax);
    
    // Position camera at player spawn initially
    _camera.setPosition(level.playerSpawn - (_camera.viewportSize / 2));
  }
  
  /// Clear current level and boundaries
  void clearLevel() {
    _currentLevel = null;
    _camera.clearBoundaries();
  }
  
  /// Trigger screen shake effect
  void triggerScreenShake(double intensity, double duration) {
    final behavior = _getCurrentCameraBehavior();
    if (_shakeEnabled && behavior.allowShake) {
      _camera.shake(intensity, duration);
    }
  }
  
  /// Enable or disable screen shake
  void setShakeEnabled(bool enabled) {
    _shakeEnabled = enabled;
    if (!enabled) {
      _camera.stopShake();
    }
  }
  
  /// Transition camera to a specific position
  void transitionToPosition(Vector2 targetPosition, {double speed = 10.0}) {
    final behavior = _getCurrentCameraBehavior();
    if (behavior.allowTransitions) {
      _transitionTarget = targetPosition.clone();
      _transitionSpeed = speed;
      _isTransitioning = true;
    }
  }
  
  /// Transition camera to follow a specific entity
  void transitionToEntity(Component entity, {double speed = 10.0}) {
    if (entity is PlayerEntity) {
      transitionToPosition(entity.positionComponent.position, speed: speed);
    }
  }
  
  /// Set camera zoom level
  void setZoom(double zoom) {
    _camera.setZoom(zoom);
  }
  
  /// Set camera follow speed
  void setFollowSpeed(double speed) {
    _camera.setFollowSpeed(speed);
  }
  
  /// Set camera dead zone
  void setDeadZone(Vector2 deadZone) {
    _camera.setDeadZone(deadZone);
  }
  
  /// Enable or disable camera following
  void setFollowing(bool following) {
    _camera.setFollowing(following);
  }
  
  /// Set viewport size (called when screen size changes)
  void setViewportSize(Vector2 size) {
    _camera.setViewportSize(size);
  }
  
  /// Get current camera position
  Vector2 getCameraPosition() {
    return _camera.getFinalPosition();
  }
  
  /// Get camera view rectangle in world coordinates
  Rect getCameraViewRect() {
    return _camera.getViewRect();
  }
  
  /// Convert world coordinates to screen coordinates
  Vector2 worldToScreen(Vector2 worldPosition) {
    return _camera.worldToScreen(worldPosition);
  }
  
  /// Convert screen coordinates to world coordinates
  Vector2 screenToWorld(Vector2 screenPosition) {
    return _camera.screenToWorld(screenPosition);
  }
  
  /// Check if a world position is visible on screen
  bool isVisible(Vector2 worldPosition, {Vector2? size}) {
    return _camera.isVisible(worldPosition, size: size);
  }
  
  /// Handle level segment transitions
  void handleLevelSegmentTransition(Vector2 newBoundaryMin, Vector2 newBoundaryMax) {
    _camera.setBoundaries(newBoundaryMin, newBoundaryMax);
    
    // Update current level boundaries if we have a level loaded
    if (_currentLevel != null) {
      // This would update the level model if needed
      // For now, we just use the camera boundaries
    }
    
    // Smoothly transition camera if needed
    final currentPos = _camera.position;
    final viewRect = _camera.getViewRect();
    
    // Check if current camera position is outside new boundaries
    if (currentPos.x < newBoundaryMin.x || 
        currentPos.y < newBoundaryMin.y ||
        viewRect.right > newBoundaryMax.x ||
        viewRect.bottom > newBoundaryMax.y) {
      
      // Calculate new camera position within boundaries
      final newCameraPos = Vector2(
        currentPos.x.clamp(newBoundaryMin.x, newBoundaryMax.x - _camera.viewportSize.x),
        currentPos.y.clamp(newBoundaryMin.y, newBoundaryMax.y - _camera.viewportSize.y),
      );
      
      transitionToPosition(newCameraPos, speed: 15.0);
    }
  }
  
  /// Handle pause state - stop camera updates but maintain position
  void onGamePaused() {
    _camera.setFollowing(false);
    _camera.stopShake();
  }
  
  /// Handle resume state - resume camera updates
  void onGameResumed() {
    _camera.setFollowing(true);
  }
  
  /// Get camera component for direct access (use carefully)
  game_camera.GameCameraComponent get camera => _camera;
  
  @override
  void dispose() {
    _gameStateManager?.removeStateChangeCallback(_onGameStateChanged);
    _playerTarget = null;
    _currentLevel = null;
    _lastImpactPosition = null;
    _transitionTarget = null;
    _stateBehaviors.clear();
    super.dispose();
  }
}

/// Defines camera behavior for different game states
class CameraBehavior {
  final bool allowFollowing;
  final bool allowShake;
  final bool allowTransitions;
  final double followSpeed;
  
  const CameraBehavior({
    required this.allowFollowing,
    required this.allowShake,
    required this.allowTransitions,
    required this.followSpeed,
  });
}