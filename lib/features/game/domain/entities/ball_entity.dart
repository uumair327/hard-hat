import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../entities/game_entity.dart';
import '../components/position_component.dart';
import '../components/velocity_component.dart';
import '../components/collision_component.dart';
import '../components/sprite_component.dart';

/// Ball states for state management
enum BallState {
  inactive,
  launching,
  flying,
  bouncing,
  destroying,
  recycling,
}

/// Ball entity with physics and trajectory tracking
class BallEntity extends GameEntity {
  late final GamePositionComponent _positionComponent;
  late final VelocityComponent _velocityComponent;
  late final GameCollisionComponent _collisionComponent;
  late final GameSpriteComponent _spriteComponent;
  
  // State management
  BallState _currentState = BallState.inactive;
  double _stateTimer = 0.0;
  
  // Physics constants
  static const double gravity = 980.0;
  static const double bounceDamping = 0.7;
  static const double minBounceVelocity = 50.0;
  static const double maxLifetime = 10.0;
  static const double ballRadius = 8.0;
  
  // Trajectory tracking
  final List<Vector2> _trajectoryPoints = [];
  static const int maxTrajectoryPoints = 100;
  bool _isTracking = false;
  
  // Launch parameters
  Vector2 _launchDirection = Vector2.zero();
  double _launchSpeed = 0.0;
  static const double defaultLaunchSpeed = 500.0;
  
  // Lifetime management
  double _lifetime = 0.0;
  bool _shouldRecycle = false;
  
  // Collision tracking
  int _bounceCount = 0;
  static const int maxBounces = 10;
  
  // Destruction tracking
  final Set<String> _destroyedTileIds = <String>{};
  
  // Callback for when ball should be recycled
  void Function(BallEntity ball)? onRecycle;
  
  // Callback for tile destruction
  void Function(BallEntity ball, String tileId)? onTileDestroyed;

  BallEntity({
    required super.id,
    Vector2? position,
    this.onRecycle,
    this.onTileDestroyed,
  }) {
    // Initialize components
    _positionComponent = GamePositionComponent(
      position: position ?? Vector2.zero(),
      size: Vector2(ballRadius * 2, ballRadius * 2),
    );
    
    _velocityComponent = VelocityComponent(
      maxSpeed: 1000.0, // High max speed for ball physics
      friction: 0.0, // No friction for realistic physics
    );
    
    // Collision component
    _collisionComponent = GameCollisionComponent(
      hitbox: CircleHitbox(radius: ballRadius),
      type: GameCollisionType.ball,
      collidesWith: {
        GameCollisionType.tile,
        GameCollisionType.wall,
        GameCollisionType.player,
      },
      onCollision: _handleCollision,
      position: position ?? Vector2.zero(),
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
    
    // Start in inactive state
    _changeState(BallState.inactive);
  }
  
  /// Initialize ball sprite
  Future<void> _initializeSprite() async {
    // Create placeholder ball sprite
    final ballSprite = await _createBallSprite();
    _spriteComponent.sprite = ballSprite;
  }
  
  /// Create a ball sprite
  Future<Sprite> _createBallSprite() async {
    // This is a placeholder - in a real implementation, sprites would be loaded from assets
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
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
    
    final picture = recorder.endRecording();
    final image = await picture.toImage((ballRadius * 2).toInt(), (ballRadius * 2).toInt());
    return Sprite(image);
  }

  @override
  void updateEntity(double dt) {
    _stateTimer += dt;
    _lifetime += dt;
    
    // Update state machine
    _updateStateMachine(dt);
    
    // Update physics based on current state
    _updatePhysics(dt);
    
    // Update position
    _updatePosition(dt);
    
    // Update trajectory tracking
    _updateTrajectoryTracking();
    
    // Update sprite position
    _spriteComponent.position = _positionComponent.position;
    
    // Check for recycling conditions
    _checkRecyclingConditions();
  }
  
  /// Update the state machine
  void _updateStateMachine(double dt) {
    switch (_currentState) {
      case BallState.inactive:
        // Ball is not active, waiting to be launched
        break;
        
      case BallState.launching:
        // Brief launch state
        if (_stateTimer > 0.1) {
          _changeState(BallState.flying);
        }
        break;
        
      case BallState.flying:
        // Check if ball should start bouncing (low velocity or ground contact)
        if (_velocityComponent.velocity.length < minBounceVelocity * 2) {
          _changeState(BallState.bouncing);
        }
        break;
        
      case BallState.bouncing:
        // Ball is bouncing with reduced energy
        if (_velocityComponent.velocity.length < minBounceVelocity) {
          _changeState(BallState.recycling);
        }
        break;
        
      case BallState.destroying:
        // Brief destruction effect state
        if (_stateTimer > 0.2) {
          _changeState(BallState.recycling);
        }
        break;
        
      case BallState.recycling:
        // Ball should be recycled
        _shouldRecycle = true;
        break;
    }
  }
  
  /// Update physics based on current state
  void _updatePhysics(double dt) {
    switch (_currentState) {
      case BallState.inactive:
        // No physics when inactive
        _velocityComponent.velocity.setZero();
        break;
        
      case BallState.launching:
      case BallState.flying:
      case BallState.bouncing:
        // Apply gravity
        _velocityComponent.velocity.y += gravity * dt;
        break;
        
      case BallState.destroying:
        // Slow down during destruction
        _velocityComponent.velocity.scale(0.95);
        break;
        
      case BallState.recycling:
        // Stop all movement
        _velocityComponent.velocity.setZero();
        break;
    }
  }
  
  /// Update position based on velocity
  void _updatePosition(double dt) {
    if (_currentState != BallState.inactive && _currentState != BallState.recycling) {
      final deltaPosition = _velocityComponent.velocity * dt;
      _positionComponent.updatePosition(_positionComponent.position + deltaPosition);
    }
  }
  
  /// Update trajectory tracking
  void _updateTrajectoryTracking() {
    if (_isTracking && _currentState != BallState.inactive) {
      _trajectoryPoints.add(_positionComponent.position.clone());
      
      // Limit trajectory points
      if (_trajectoryPoints.length > maxTrajectoryPoints) {
        _trajectoryPoints.removeAt(0);
      }
    }
  }
  
  /// Check if ball should be recycled
  void _checkRecyclingConditions() {
    // Recycle if lifetime exceeded
    if (_lifetime > maxLifetime) {
      _changeState(BallState.recycling);
    }
    
    // Recycle if too many bounces
    if (_bounceCount > maxBounces) {
      _changeState(BallState.recycling);
    }
    
    // Recycle if ball is out of bounds (simple check)
    if (_positionComponent.position.y > 1000 || 
        _positionComponent.position.x < -100 || 
        _positionComponent.position.x > 900) {
      _changeState(BallState.recycling);
    }
    
    // Call recycle callback if needed
    if (_shouldRecycle && onRecycle != null) {
      onRecycle!(this);
    }
  }
  
  /// Handle collision with other entities
  void _handleCollision(GameCollisionComponent other) {
    switch (other.type) {
      case GameCollisionType.tile:
        _handleTileCollision(other);
        break;
      case GameCollisionType.wall:
        _handleWallCollision(other);
        break;
      case GameCollisionType.player:
        // Ball doesn't affect player directly
        break;
      default:
        break;
    }
  }
  
  /// Handle collision with tiles
  void _handleTileCollision(GameCollisionComponent tileCollision) {
    // Apply bounce physics
    _applyBounce();
    
    // Notify about tile destruction (if tile is destructible)
    // This would be determined by the tile's properties
    final tileId = "tile_${tileCollision.hashCode}"; // Placeholder ID
    if (!_destroyedTileIds.contains(tileId)) {
      _destroyedTileIds.add(tileId);
      onTileDestroyed?.call(this, tileId);
      
      // Change to destroying state briefly
      if (_currentState != BallState.destroying) {
        _changeState(BallState.destroying);
      }
    }
  }
  
  /// Handle collision with walls
  void _handleWallCollision(GameCollisionComponent wallCollision) {
    _applyBounce();
  }
  
  /// Apply bounce physics
  void _applyBounce() {
    _bounceCount++;
    
    // Simple bounce - reverse and dampen velocity
    // In a real implementation, this would use proper collision normals
    _velocityComponent.velocity.y *= -bounceDamping;
    _velocityComponent.velocity.x *= bounceDamping;
    
    // Change state if not already bouncing
    if (_currentState == BallState.flying) {
      _changeState(BallState.bouncing);
    }
  }
  
  /// Change the ball state
  void _changeState(BallState newState) {
    if (newState != _currentState) {
      _currentState = newState;
      _stateTimer = 0.0;
    }
  }
  
  // Public methods for external systems
  
  /// Launch the ball with given direction and speed
  void launch(Vector2 direction, {double? speed}) {
    if (_currentState == BallState.inactive) {
      _launchDirection = direction.normalized();
      _launchSpeed = speed ?? defaultLaunchSpeed;
      
      // Set initial velocity
      _velocityComponent.velocity = _launchDirection * _launchSpeed;
      
      // Reset tracking data
      _trajectoryPoints.clear();
      _destroyedTileIds.clear();
      _bounceCount = 0;
      _lifetime = 0.0;
      _shouldRecycle = false;
      
      // Start tracking
      _isTracking = true;
      
      // Change to launching state
      _changeState(BallState.launching);
    }
  }
  
  /// Reset ball to inactive state
  void reset({Vector2? position}) {
    if (position != null) {
      _positionComponent.position.setFrom(position);
    }
    
    _velocityComponent.velocity.setZero();
    _trajectoryPoints.clear();
    _destroyedTileIds.clear();
    _bounceCount = 0;
    _lifetime = 0.0;
    _shouldRecycle = false;
    _isTracking = false;
    
    _changeState(BallState.inactive);
  }
  
  /// Force recycling of the ball
  void forceRecycle() {
    _changeState(BallState.recycling);
  }
  
  // Getters for components and state
  
  /// Get the position component
  @override
  GamePositionComponent get positionComponent => _positionComponent;
  
  /// Get the velocity component
  @override
  VelocityComponent get velocityComponent => _velocityComponent;
  
  /// Get the collision component
  @override
  GameCollisionComponent get collisionComponent => _collisionComponent;
  
  /// Get the sprite component
  @override
  GameSpriteComponent get spriteComponent => _spriteComponent;
  
  /// Get the current ball state
  BallState get currentState => _currentState;
  
  /// Get the current state timer
  double get stateTimer => _stateTimer;
  
  /// Get the ball lifetime
  double get lifetime => _lifetime;
  
  /// Check if ball is tracking trajectory
  bool get isTracking => _isTracking;
  
  /// Get trajectory points (read-only)
  List<Vector2> get trajectoryPoints => List.unmodifiable(_trajectoryPoints);
  
  /// Get launch direction
  Vector2 get launchDirection => _launchDirection.clone();
  
  /// Get launch speed
  double get launchSpeed => _launchSpeed;
  
  /// Get bounce count
  int get bounceCount => _bounceCount;
  
  /// Check if ball should be recycled
  bool get shouldRecycle => _shouldRecycle;
  
  /// Get destroyed tile IDs
  Set<String> get destroyedTileIds => Set.unmodifiable(_destroyedTileIds);
  
  /// Check if ball is active (not inactive or recycling)
  @override
  bool get isActive => _currentState != BallState.inactive && _currentState != BallState.recycling;
}