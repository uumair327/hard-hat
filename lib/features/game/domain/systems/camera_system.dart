import 'dart:ui';
import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Camera system for following player and managing viewport
class CameraSystem extends GameSystem implements ICameraSystem {
  late EntityManager _entityManager;
  
  // Camera state
  Vector2 _position = Vector2.zero();
  Vector2 _targetPosition = Vector2.zero();
  Vector2 _viewportSize = Vector2(800, 600);
  
  // Camera settings
  double _followSpeed = 5.0;
  Vector2 _offset = Vector2.zero();
  Vector2? _minBounds;
  Vector2? _maxBounds;
  
  // Screen shake
  bool _isShaking = false;
  double _shakeIntensity = 0.0;
  double _shakeDuration = 0.0;
  double _shakeTimer = 0.0;
  Vector2 _shakeOffset = Vector2.zero();
  
  // Zoom
  double _zoom = 1.0;
  double _targetZoom = 1.0;
  final double _zoomSpeed = 2.0;
  
  // Player following
  PlayerEntity? _targetPlayer;
  bool _followingPlayer = true;
  
  // Level boundaries and segments
  Level? _currentLevel;
  String? _currentSegment;
  final Map<String, CameraSegment> _segments = {};
  bool _isSegmentTransitioning = false;
  Vector2? _segmentTransitionTarget;
  static const double segmentTransitionSpeed = 200.0;
  
  // Position transition for level progression
  bool _isTransitioning = false;
  Vector2? _transitionTarget;
  double _transitionSpeed = 300.0;
  
  @override
  int get priority => 7; // Process after physics but before rendering

  @override
  Future<void> initialize() async {
    // Camera system initialization
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }

  @override
  void update(double dt) {
    updateCamera(dt);
    _updatePlayerFollowing(dt);
    _updateSegmentTransitions(dt);
    _updatePositionTransitions(dt);
  }
  
  @override
  void setTarget(dynamic target) {
    if (target is PlayerEntity) {
      _targetPlayer = target;
      _followingPlayer = true;
    }
  }
  
  @override
  void updateCamera(double dt) {
    _updateCameraTarget(dt);
    _updateCameraPosition(dt);
    _updateScreenShake(dt);
    _updateZoom(dt);
    _applyBounds();
  }
  
  @override
  void setViewport(double width, double height) {
    setViewportSize(Vector2(width, height));
  }
  
  /// Update camera target based on player position
  void _updateCameraTarget(double dt) {
    // If we have a specific target player, use that
    if (_targetPlayer != null && _followingPlayer) {
      final playerPosition = _targetPlayer!.positionComponent.position;
      
      // Calculate target position (center player in viewport)
      _targetPosition = Vector2(
        playerPosition.x - _viewportSize.x / 2,
        playerPosition.y - _viewportSize.y / 2,
      );
      
      // Apply offset
      _targetPosition += _offset;
      return;
    }
    
    // Fallback: find first player entity
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    if (players.isEmpty) return;
    
    final player = players.first;
    final playerPosition = player.positionComponent.position;
    
    // Calculate target position (center player in viewport)
    _targetPosition = Vector2(
      playerPosition.x - _viewportSize.x / 2,
      playerPosition.y - _viewportSize.y / 2,
    );
    
    // Apply offset
    _targetPosition += _offset;
  }
  
  /// Update player following logic
  void _updatePlayerFollowing(double dt) {
    if (!_followingPlayer || _targetPlayer == null) return;
    
    // Check if player moved significantly to trigger camera update
    final playerPosition = _targetPlayer!.positionComponent.position;
    final currentPlayerScreenPos = worldToScreen(playerPosition);
    final screenCenter = _viewportSize / 2;
    
    // If player is getting close to screen edges, adjust camera more aggressively
    final edgeThreshold = 100.0; // pixels from edge
    final distanceFromCenter = (currentPlayerScreenPos - screenCenter).length;
    
    if (distanceFromCenter > edgeThreshold) {
      // Increase follow speed when player is near edges
      _followSpeed = 8.0;
    } else {
      // Normal follow speed
      _followSpeed = 5.0;
    }
  }
  
  /// Update camera position with smooth following
  void _updateCameraPosition(double dt) {
    // Smooth camera movement
    final difference = _targetPosition - _position;
    final movement = difference * _followSpeed * dt;
    
    _position += movement;
  }
  
  /// Update screen shake effect
  void _updateScreenShake(double dt) {
    if (!_isShaking) {
      _shakeOffset = Vector2.zero();
      return;
    }
    
    _shakeTimer += dt;
    
    if (_shakeTimer >= _shakeDuration) {
      _isShaking = false;
      _shakeOffset = Vector2.zero();
      return;
    }
    
    // Calculate shake intensity (decreases over time)
    final progress = _shakeTimer / _shakeDuration;
    final currentIntensity = _shakeIntensity * (1.0 - progress);
    
    // Generate random shake offset
    _shakeOffset = Vector2(
      (Math.random() - 0.5) * 2 * currentIntensity,
      (Math.random() - 0.5) * 2 * currentIntensity,
    );
  }
  
  /// Update zoom level
  void _updateZoom(double dt) {
    if (_zoom != _targetZoom) {
      final difference = _targetZoom - _zoom;
      final movement = difference * _zoomSpeed * dt;
      _zoom += movement;
      
      // Clamp zoom to reasonable values
      _zoom = _zoom.clamp(0.1, 5.0);
    }
  }
  
  /// Apply camera bounds to keep camera within level
  void _applyBounds() {
    if (_minBounds != null) {
      _position.x = _position.x.clamp(_minBounds!.x, double.infinity);
      _position.y = _position.y.clamp(_minBounds!.y, double.infinity);
    }
    
    if (_maxBounds != null) {
      _position.x = _position.x.clamp(double.negativeInfinity, _maxBounds!.x);
      _position.y = _position.y.clamp(double.negativeInfinity, _maxBounds!.y);
    }
  }
  
  /// Start screen shake effect
  void startScreenShake(double intensity, double duration) {
    _isShaking = true;
    _shakeIntensity = intensity;
    _shakeDuration = duration;
    _shakeTimer = 0.0;
  }
  
  /// Start screen shake from ball collision
  void shakeFromBallCollision(Vector2 ballVelocity) {
    final intensity = (ballVelocity.length / 1000.0).clamp(5.0, 20.0);
    startScreenShake(intensity, 0.2);
  }
  
  /// Start screen shake from ball impact (enhanced version)
  void shakeFromBallImpact(Vector2 impactPosition, Vector2 ballVelocity) {
    // Calculate intensity based on ball velocity and distance from camera center
    final baseIntensity = (ballVelocity.length / 800.0).clamp(3.0, 15.0);
    
    // Reduce intensity based on distance from camera center
    final cameraCenter = _position + (_viewportSize / 2);
    final distanceFromCenter = (impactPosition - cameraCenter).length;
    final maxDistance = _viewportSize.length / 2;
    final distanceFactor = (1.0 - (distanceFromCenter / maxDistance)).clamp(0.2, 1.0);
    
    final finalIntensity = baseIntensity * distanceFactor;
    final duration = (finalIntensity / 15.0 * 0.3).clamp(0.1, 0.4);
    
    startScreenShake(finalIntensity, duration);
  }
  
  /// Set camera bounds
  void setBounds(Vector2? minBounds, Vector2? maxBounds) {
    _minBounds = minBounds;
    _maxBounds = maxBounds;
  }
  
  /// Set camera bounds from level data
  void setBoundsFromLevel(Level level) {
    _currentLevel = level;
    setBounds(level.cameraMin, level.cameraMax);
    
    // Clear existing segments and create default segment
    _segments.clear();
    _segments['main'] = CameraSegment(
      id: 'main',
      bounds: Rect.fromPoints(
        Offset(level.cameraMin.x, level.cameraMin.y),
        Offset(level.cameraMax.x, level.cameraMax.y),
      ),
    );
    _currentSegment = 'main';
  }
  
  /// Add a camera segment for level progression
  void addCameraSegment(String segmentId, Vector2 topLeft, Vector2 bottomRight) {
    _segments[segmentId] = CameraSegment(
      id: segmentId,
      bounds: Rect.fromPoints(
        Offset(topLeft.x, topLeft.y),
        Offset(bottomRight.x, bottomRight.y),
      ),
    );
  }
  
  /// Switch to a specific camera segment
  void switchToCameraSegment(String segmentId) {
    final segment = _segments[segmentId];
    if (segment == null || segmentId == _currentSegment) return;
    
    _currentSegment = segmentId;
    
    // Set new bounds
    setBounds(
      Vector2(segment.bounds.left, segment.bounds.top),
      Vector2(segment.bounds.right, segment.bounds.bottom),
    );
    
    // Start transition to new segment
    _segmentTransitionTarget = Vector2(
      segment.bounds.left + segment.bounds.width / 2 - _viewportSize.x / 2,
      segment.bounds.top + segment.bounds.height / 2 - _viewportSize.y / 2,
    );
    _isSegmentTransitioning = true;
  }
  
  /// Update segment transitions
  void _updateSegmentTransitions(double dt) {
    if (!_isSegmentTransitioning || _segmentTransitionTarget == null) return;
    
    final direction = _segmentTransitionTarget! - _position;
    final distance = direction.length;
    
    if (distance < 1.0) {
      // Transition complete
      _position = _segmentTransitionTarget!;
      _isSegmentTransitioning = false;
      _segmentTransitionTarget = null;
      return;
    }
    
    // Move camera towards target
    final moveDistance = segmentTransitionSpeed * dt;
    final normalizedDirection = direction.normalized();
    final movement = normalizedDirection * moveDistance;
    
    _position += movement;
  }
  
  /// Transition camera to a specific position (for level progression)
  void transitionToPosition(Vector2 targetPosition, {double? speed}) {
    _transitionTarget = targetPosition;
    _isTransitioning = true;
    if (speed != null) {
      _transitionSpeed = speed;
    }
  }
  
  /// Update position transitions
  void _updatePositionTransitions(double dt) {
    if (!_isTransitioning || _transitionTarget == null) return;
    
    final direction = _transitionTarget! - _position;
    final distance = direction.length;
    
    if (distance < 1.0) {
      // Transition complete
      _position = _transitionTarget!;
      _isTransitioning = false;
      _transitionTarget = null;
      return;
    }
    
    // Move camera towards target
    final moveDistance = _transitionSpeed * dt;
    final normalizedDirection = direction.normalized();
    final movement = normalizedDirection * moveDistance;
    
    _position += movement;
  }
  
  /// Get camera view rectangle for level system integration
  Rect getCameraViewRect() {
    final cameraPosition = _position + _shakeOffset;
    return Rect.fromLTWH(
      cameraPosition.x,
      cameraPosition.y,
      _viewportSize.x / _zoom,
      _viewportSize.y / _zoom,
    );
  }
  
  /// Set viewport size
  void setViewportSize(Vector2 size) {
    _viewportSize = size;
  }
  
  /// Set camera offset from player
  void setOffset(Vector2 offset) {
    _offset = offset;
  }
  
  /// Set camera follow speed
  void setFollowSpeed(double speed) {
    _followSpeed = speed.clamp(0.1, 20.0);
  }
  
  /// Set zoom level
  void setZoom(double zoom) {
    _targetZoom = zoom.clamp(0.1, 5.0);
  }
  
  /// Set zoom level immediately (no smooth transition)
  void setZoomImmediate(double zoom) {
    _zoom = zoom.clamp(0.1, 5.0);
    _targetZoom = _zoom;
  }
  
  /// Convert world position to screen position
  Vector2 worldToScreen(Vector2 worldPosition) {
    final cameraPosition = _position + _shakeOffset;
    return (worldPosition - cameraPosition) * _zoom;
  }
  
  /// Convert screen position to world position
  Vector2 screenToWorld(Vector2 screenPosition) {
    final cameraPosition = _position + _shakeOffset;
    return (screenPosition / _zoom) + cameraPosition;
  }
  
  /// Check if a world position is visible on screen
  bool isVisible(Vector2 worldPosition, Vector2 size) {
    final screenPos = worldToScreen(worldPosition);
    return screenPos.x + size.x >= 0 &&
           screenPos.x <= _viewportSize.x &&
           screenPos.y + size.y >= 0 &&
           screenPos.y <= _viewportSize.y;
  }
  
  /// Get camera bounds in world coordinates
  Rect getCameraBounds() {
    final cameraPosition = _position + _shakeOffset;
    return Rect.fromLTWH(
      cameraPosition.x,
      cameraPosition.y,
      _viewportSize.x / _zoom,
      _viewportSize.y / _zoom,
    );
  }
  
  /// Focus camera on a specific position
  void focusOn(Vector2 worldPosition, {bool immediate = false}) {
    _targetPosition = Vector2(
      worldPosition.x - _viewportSize.x / 2,
      worldPosition.y - _viewportSize.y / 2,
    );
    
    if (immediate) {
      _position = _targetPosition.clone();
    }
  }
  
  /// Reset camera to default state
  void reset() {
    _position = Vector2.zero();
    _targetPosition = Vector2.zero();
    _offset = Vector2.zero();
    _isShaking = false;
    _shakeOffset = Vector2.zero();
    _zoom = 1.0;
    _targetZoom = 1.0;
    _targetPlayer = null;
    _followingPlayer = true;
    _currentLevel = null;
    _currentSegment = null;
    _segments.clear();
    _isSegmentTransitioning = false;
    _segmentTransitionTarget = null;
    _isTransitioning = false;
    _transitionTarget = null;
  }
  
  // Getters
  
  /// Get current camera position
  Vector2 get position => _position + _shakeOffset;
  
  /// Get camera target position
  Vector2 get targetPosition => _targetPosition;
  
  /// Get viewport size
  Vector2 get viewportSize => _viewportSize;
  
  /// Get current zoom level
  double get zoom => _zoom;
  
  /// Get target zoom level
  double get targetZoom => _targetZoom;
  
  /// Check if camera is shaking
  bool get isShaking => _isShaking;
  
  /// Get camera offset
  Vector2 get offset => _offset;
  
  /// Get follow speed
  double get followSpeed => _followSpeed;
  
  /// Get current level
  Level? get currentLevel => _currentLevel;
  
  /// Get current camera segment
  String? get currentSegment => _currentSegment;
  
  /// Check if camera is transitioning between segments
  bool get isSegmentTransitioning => _isSegmentTransitioning;
  
  /// Check if camera is transitioning position
  bool get isTransitioning => _isTransitioning;
  
  /// Get target player
  PlayerEntity? get targetPlayer => _targetPlayer;
  
  /// Check if following player
  bool get isFollowingPlayer => _followingPlayer;

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

/// Camera segment for level progression
class CameraSegment {
  final String id;
  final Rect bounds;
  
  const CameraSegment({
    required this.id,
    required this.bounds,
  });
}

/// Math utility class for random numbers
class Math {
  static double random() => (DateTime.now().microsecondsSinceEpoch % 1000000) / 1000000.0;
}