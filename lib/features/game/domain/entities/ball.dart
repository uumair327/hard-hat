import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Ball states for tracking behavior
enum BallState {
  idle,
  tracking,
  flying,
  dead,
}

/// Ball entity with physics and collision detection
class BallEntity extends GameEntity {
  late final GamePositionComponent _positionComponent;
  late final GameCollisionComponent _collisionComponent;
  late final GameSpriteComponent _spriteComponent;
  late final VelocityComponent _velocityComponent;
  
  // Ball properties
  BallState _currentState = BallState.idle;
  double _stateTimer = 0.0;
  Vector2 _directionVector = Vector2(1, 0);
  bool _tracking = false;
  
  // Physics constants
  static const double ballSpeed = 640.0; // 16.0 * 40 (scaled from Godot)
  static const double ballRadius = 8.0;
  
  // Callbacks
  void Function(Vector2 direction)? onCameraShakeRequest;
  void Function()? onForceQuitAiming;
  void Function(TileEntity? tile, Vector2 position, Vector2 normal)? onTileHit;
  
  BallEntity({
    required super.id,
    required Vector2 position,
    this.onCameraShakeRequest,
    this.onForceQuitAiming,
    this.onTileHit,
  }) {
    // Initialize components
    _positionComponent = GamePositionComponent(
      position: position,
      size: Vector2(ballRadius * 2, ballRadius * 2),
    );
    
    _velocityComponent = VelocityComponent();
    
    // Collision component
    _collisionComponent = GameCollisionComponent(
      hitbox: CircleHitbox(radius: ballRadius),
      type: GameCollisionType.ball,
      collidesWith: {
        GameCollisionType.tile,
        GameCollisionType.player,
        GameCollisionType.wall,
      },
      onCollision: _handleCollision,
      position: position,
      size: Vector2(ballRadius * 2, ballRadius * 2),
    );
    
    // Sprite component
    _spriteComponent = GameSpriteComponent(
      size: Vector2(ballRadius * 2, ballRadius * 2),
      renderLayer: 2, // Render above tiles and player
    );
  }

  @override
  Future<void> initializeEntity() async {
    // Add components to the entity
    addEntityComponent(_positionComponent);
    addEntityComponent(_velocityComponent);
    addEntityComponent(_collisionComponent);
    addEntityComponent(_spriteComponent);
    
    // Initialize sprite
    await _initializeSprite();
    
    // Position the sprite component
    _spriteComponent.position = _positionComponent.position;
  }
  
  /// Initialize ball sprite
  Future<void> _initializeSprite() async {
    // Create a simple ball sprite (placeholder)
    final sprite = await _createBallSprite();
    _spriteComponent.sprite = sprite;
  }
  
  /// Create ball sprite
  Future<Sprite> _createBallSprite() async {
    // Create a simple circular ball sprite
    final paint = Paint()..color = Colors.orange;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Draw ball
    canvas.drawCircle(
      Offset(ballRadius, ballRadius),
      ballRadius - 1,
      paint,
    );
    canvas.drawCircle(
      Offset(ballRadius, ballRadius),
      ballRadius - 1,
      strokePaint,
    );
    
    // Add highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(
      Offset(ballRadius - 2, ballRadius - 2),
      ballRadius / 3,
      highlightPaint,
    );
    
    final picture = recorder.endRecording();
    final image = await picture.toImage((ballRadius * 2).toInt(), (ballRadius * 2).toInt());
    return Sprite(image);
  }

  @override
  void updateEntity(double dt) {
    _stateTimer += dt;
    
    // Update state machine
    _updateStateMachine(dt);
    
    // Update physics based on state
    switch (_currentState) {
      case BallState.idle:
        _updateIdleState(dt);
        break;
      case BallState.tracking:
        _updateTrackingState(dt);
        break;
      case BallState.flying:
        _updateFlyingState(dt);
        break;
      case BallState.dead:
        _updateDeadState(dt);
        break;
    }
    
    // Update position based on velocity
    if (_currentState == BallState.flying) {
      final deltaPosition = _velocityComponent.velocity * dt;
      _positionComponent.updatePosition(_positionComponent.position + deltaPosition);
      _spriteComponent.position = _positionComponent.position;
    }
  }
  
  /// Update state machine
  void _updateStateMachine(double dt) {
    switch (_currentState) {
      case BallState.idle:
        // Ball is stationary, waiting to be activated
        break;
      case BallState.tracking:
        // Ball is following mouse/touch input for aiming
        break;
      case BallState.flying:
        // Ball is moving through the air
        break;
      case BallState.dead:
        // Ball is being destroyed
        if (_stateTimer > 0.5) {
          // Mark for removal after animation
        }
        break;
    }
  }
  
  /// Update idle state
  void _updateIdleState(double dt) {
    _velocityComponent.velocity = Vector2.zero();
  }
  
  /// Update tracking state (aiming)
  void _updateTrackingState(double dt) {
    _velocityComponent.velocity = Vector2.zero();
    // Tracking logic would be handled by input system
  }
  
  /// Update flying state
  void _updateFlyingState(double dt) {
    // Velocity is maintained, position updated in main update loop
  }
  
  /// Update dead state
  void _updateDeadState(double dt) {
    _velocityComponent.velocity = Vector2.zero();
    
    // Fade out animation
    final opacity = 1.0 - (_stateTimer / 0.5);
    _spriteComponent.setOpacity(opacity.clamp(0.0, 1.0));
  }
  
  /// Handle collision with other entities
  void _handleCollision(GameCollisionComponent other) {
    if (_currentState != BallState.flying) return;
    
    switch (other.type) {
      case GameCollisionType.tile:
        _handleTileCollision(other);
        break;
      case GameCollisionType.wall:
        _handleWallCollision(other);
        break;
      case GameCollisionType.player:
        // Ball doesn't collide with player when flying
        break;
      default:
        break;
    }
  }
  
  /// Handle collision with tiles
  void _handleTileCollision(GameCollisionComponent tileCollision) {
    // Calculate collision normal (simplified)
    final ballCenter = _positionComponent.position + Vector2(ballRadius, ballRadius);
    final tileCenter = tileCollision.position + tileCollision.size / 2;
    final collisionNormal = (ballCenter - tileCenter).normalized();
    
    // Bounce off the tile
    _velocityComponent.velocity = _velocityComponent.velocity.reflected(collisionNormal);
    
    // Request camera shake
    onCameraShakeRequest?.call(_velocityComponent.velocity);
    
    // Notify tile hit for damage and particles
    // Note: Tile damage would be handled by the collision system
    onTileHit?.call(null, ballCenter, collisionNormal);
  }
  
  /// Handle collision with walls
  void _handleWallCollision(GameCollisionComponent wallCollision) {
    // Simple wall bounce (would need proper collision normal calculation)
    final ballCenter = _positionComponent.position + Vector2(ballRadius, ballRadius);
    final wallCenter = wallCollision.position + wallCollision.size / 2;
    final collisionNormal = (ballCenter - wallCenter).normalized();
    
    // Bounce off the wall
    _velocityComponent.velocity = _velocityComponent.velocity.reflected(collisionNormal);
    
    // Request camera shake
    onCameraShakeRequest?.call(_velocityComponent.velocity);
  }
  
  /// Start tracking mode for aiming
  void startTracking() {
    _changeState(BallState.tracking);
    _tracking = true;
  }
  
  /// Shoot the ball in the current direction
  void shoot() {
    _changeState(BallState.flying);
    _tracking = false;
    
    // Set velocity based on direction
    _velocityComponent.velocity = _directionVector.normalized() * ballSpeed;
  }
  
  /// Kill the ball (start death animation)
  void kill() {
    _changeState(BallState.dead);
    _tracking = false;
  }
  
  /// Set the direction vector for aiming
  void setDirection(Vector2 direction) {
    _directionVector = direction;
  }
  
  /// Change ball state
  void _changeState(BallState newState) {
    if (newState != _currentState) {
      _currentState = newState;
      _stateTimer = 0.0;
    }
  }
  
  // Getters for components and state
  
  /// Get the position component
  @override
  GamePositionComponent get positionComponent => _positionComponent;
  
  /// Get the collision component
  @override
  GameCollisionComponent get collisionComponent => _collisionComponent;
  
  /// Get the sprite component
  @override
  GameSpriteComponent get spriteComponent => _spriteComponent;
  
  /// Get the velocity component
  @override
  VelocityComponent get velocityComponent => _velocityComponent;
  
  /// Get current ball state
  BallState get currentState => _currentState;
  
  /// Get direction vector
  Vector2 get directionVector => _directionVector;
  
  /// Check if ball is tracking
  bool get isTracking => _tracking;
  
  /// Check if ball is flying
  bool get isFlying => _currentState == BallState.flying;
  
  /// Check if ball is dead
  bool get isDead => _currentState == BallState.dead;
  
  /// Get ball speed
  double get speed => ballSpeed;
  
  /// Get ball radius
  double get radius => ballRadius;
}