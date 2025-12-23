import 'package:flame/components.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Camera component for managing viewport and camera behavior
class GameCameraComponent extends Component {
  /// Current camera position in world coordinates
  Vector2 position;
  
  /// Camera target position (usually player position)
  Vector2? target;
  
  /// Camera boundaries (min and max world coordinates)
  Vector2? boundaryMin;
  Vector2? boundaryMax;
  
  /// Camera follow speed (interpolation factor)
  double followSpeed;
  
  /// Camera shake properties
  Vector2 shakeOffset = Vector2.zero();
  double shakeIntensity = 0.0;
  double shakeDuration = 0.0;
  double shakeTimer = 0.0;
  
  /// Camera zoom level
  double zoom;
  
  /// Whether camera should follow target
  bool isFollowing;
  
  /// Viewport size (screen size)
  Vector2 viewportSize;
  
  /// Dead zone for camera following (area where camera doesn't move)
  Vector2 deadZone;
  
  GameCameraComponent({
    Vector2? initialPosition,
    this.followSpeed = 5.0,
    this.zoom = 1.0,
    this.isFollowing = true,
    Vector2? viewportSize,
    Vector2? deadZone,
  }) : position = initialPosition ?? Vector2.zero(),
       viewportSize = viewportSize ?? Vector2(800, 600),
       deadZone = deadZone ?? Vector2(100, 50);
  
  /// Set the camera target to follow
  void setTarget(Vector2 targetPosition) {
    target = targetPosition.clone();
  }
  
  /// Set camera boundaries
  void setBoundaries(Vector2 min, Vector2 max) {
    boundaryMin = min.clone();
    boundaryMax = max.clone();
  }
  
  /// Clear camera boundaries
  void clearBoundaries() {
    boundaryMin = null;
    boundaryMax = null;
  }
  
  /// Start camera shake effect
  void shake(double intensity, double duration) {
    shakeIntensity = intensity;
    shakeDuration = duration;
    shakeTimer = 0.0;
  }
  
  /// Stop camera shake immediately
  void stopShake() {
    shakeIntensity = 0.0;
    shakeDuration = 0.0;
    shakeTimer = 0.0;
    shakeOffset.setZero();
  }
  
  /// Update camera position and effects
  void updateCamera(double dt) {
    // Update camera following
    if (isFollowing && target != null) {
      _updateFollowing(dt);
    }
    
    // Update camera shake
    if (shakeTimer < shakeDuration) {
      _updateShake(dt);
    } else if (shakeIntensity > 0) {
      stopShake();
    }
    
    // Apply boundaries
    _applyBoundaries();
  }
  
  /// Update camera following logic with dead zone
  void _updateFollowing(double dt) {
    if (target == null) return;
    
    final targetPosition = target!;
    final cameraCenter = position + (viewportSize / 2);
    final deltaToTarget = targetPosition - cameraCenter;
    
    // Check if target is outside dead zone
    Vector2 moveDirection = Vector2.zero();
    
    if (deltaToTarget.x.abs() > deadZone.x) {
      moveDirection.x = deltaToTarget.x > 0 
          ? deltaToTarget.x - deadZone.x 
          : deltaToTarget.x + deadZone.x;
    }
    
    if (deltaToTarget.y.abs() > deadZone.y) {
      moveDirection.y = deltaToTarget.y > 0 
          ? deltaToTarget.y - deadZone.y 
          : deltaToTarget.y + deadZone.y;
    }
    
    // Apply smooth interpolation
    if (!moveDirection.isZero()) {
      final targetCameraPosition = position + moveDirection;
      position = position + (targetCameraPosition - position) * followSpeed * dt;
    }
  }
  
  /// Update camera shake effect
  void _updateShake(double dt) {
    shakeTimer += dt;
    
    if (shakeTimer < shakeDuration) {
      // Calculate shake intensity with decay
      final progress = shakeTimer / shakeDuration;
      final currentIntensity = shakeIntensity * (1.0 - progress);
      
      // Generate random shake offset
      final angle = (shakeTimer * 50) % (2 * math.pi); // Pseudo-random angle
      shakeOffset.x = (currentIntensity * math.sin(angle));
      shakeOffset.y = (currentIntensity * math.cos(angle));
    }
  }
  
  /// Apply camera boundaries to keep camera within level bounds
  void _applyBoundaries() {
    if (boundaryMin == null || boundaryMax == null) return;
    
    final min = boundaryMin!;
    final max = boundaryMax!;
    
    // Calculate effective boundaries considering viewport size
    final effectiveMin = min;
    final effectiveMax = max - viewportSize;
    
    // Clamp camera position
    position.x = position.x.clamp(effectiveMin.x, effectiveMax.x);
    position.y = position.y.clamp(effectiveMin.y, effectiveMax.y);
  }
  
  /// Get the final camera position including shake offset
  Vector2 getFinalPosition() {
    return position + shakeOffset;
  }
  
  /// Convert world coordinates to screen coordinates
  Vector2 worldToScreen(Vector2 worldPosition) {
    final finalCameraPosition = getFinalPosition();
    return (worldPosition - finalCameraPosition) * zoom;
  }
  
  /// Convert screen coordinates to world coordinates
  Vector2 screenToWorld(Vector2 screenPosition) {
    final finalCameraPosition = getFinalPosition();
    return (screenPosition / zoom) + finalCameraPosition;
  }
  
  /// Check if a world position is visible on screen
  bool isVisible(Vector2 worldPosition, {Vector2? size}) {
    final screenPos = worldToScreen(worldPosition);
    final objectSize = size ?? Vector2.zero();
    
    return screenPos.x + objectSize.x >= 0 &&
           screenPos.x <= viewportSize.x &&
           screenPos.y + objectSize.y >= 0 &&
           screenPos.y <= viewportSize.y;
  }
  
  /// Get the camera's view rectangle in world coordinates
  Rect getViewRect() {
    final finalPosition = getFinalPosition();
    return Rect.fromLTWH(
      finalPosition.x,
      finalPosition.y,
      viewportSize.x / zoom,
      viewportSize.y / zoom,
    );
  }
  
  /// Set camera position directly (for immediate positioning)
  void setPosition(Vector2 newPosition) {
    position.setFrom(newPosition);
  }
  
  /// Set viewport size (usually called when screen size changes)
  void setViewportSize(Vector2 size) {
    viewportSize.setFrom(size);
  }
  
  /// Set zoom level
  void setZoom(double newZoom) {
    zoom = newZoom.clamp(0.1, 5.0); // Reasonable zoom limits
  }
  
  /// Enable/disable camera following
  void setFollowing(bool following) {
    isFollowing = following;
  }
  
  /// Set dead zone size
  void setDeadZone(Vector2 newDeadZone) {
    deadZone.setFrom(newDeadZone);
  }
  
  /// Set follow speed
  void setFollowSpeed(double speed) {
    followSpeed = speed.clamp(0.1, 20.0); // Reasonable speed limits
  }
}