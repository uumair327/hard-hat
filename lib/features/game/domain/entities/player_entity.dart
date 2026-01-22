import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../entities/game_entity.dart';
import '../entities/ball.dart';
import '../components/position_component.dart';
import '../components/velocity_component.dart';
import '../components/collision_component.dart';
import '../components/sprite_component.dart';
import '../input/input_component.dart';

/// Player states for state management
enum PlayerState {
  idle,
  moving,
  jumping,
  falling,
  aiming,
  launching,
  // Missing states from Godot implementation
  coyoteTime,    // Grace period for jumping after leaving platform
  jumpQueued,    // Jump buffering for responsive controls
  death,         // Death state and respawn mechanics
  elevator,      // Level transition state
}

/// Player entity that can receive and respond to input with state management
class PlayerEntity extends GameEntity {
  late final PlayerInputComponent _inputComponent;
  late final GamePositionComponent _positionComponent;
  late final VelocityComponent _velocityComponent;
  late final GameCollisionComponent _collisionComponent;
  late final GameSpriteComponent _spriteComponent;
  
  // State management
  PlayerState _currentState = PlayerState.idle;
  PlayerState _previousState = PlayerState.idle;
  double _stateTimer = 0.0;
  
  // Physics constants
  static const double moveSpeed = 200.0;
  static const double jumpForce = 300.0;
  static const double gravity = 980.0;
  static const double friction = 0.8;
  static const double coyoteTime = 0.1; // seconds
  static const double jumpBufferTime = 0.1; // seconds
  
  // Ground detection
  bool _isOnGround = false;
  double _groundY = 400.0; // Temporary ground level
  
  // Animation system
  final Map<PlayerState, List<Sprite>> _animations = {};
  int _currentAnimationFrame = 0;
  double _animationTimer = 0.0;
  static const double animationFrameTime = 0.1;
  
  // Aiming system
  Vector2? _aimDirection;
  bool _canStrike = true;
  BallEntity? _currentBall; // Track the current ball
  
  // Ball creation callback
  void Function(BallEntity ball)? onBallCreated;
  void Function(BallEntity ball)? onBallLaunched;
  
  // Audio system callback
  void Function(String soundName, Vector2? position)? onAudioEvent;
  
  // Coyote time and jump buffering
  double _coyoteTimer = 0.0;
  double _jumpBufferTimer = 0.0;
  bool _wasOnGroundLastFrame = false;
  
  // Death system
  bool _isDead = false;
  Vector2? _respawnPosition;

  PlayerEntity({
    required super.id,
    Vector2? position,
    this.onBallCreated,
    this.onBallLaunched,
    this.onAudioEvent,
  }) {
    // Initialize components
    _positionComponent = GamePositionComponent(
      position: position ?? Vector2.zero(),
      size: Vector2(32, 32),
    );
    
    _velocityComponent = VelocityComponent(
      maxSpeed: moveSpeed * 2, // Allow faster speeds for special cases
      friction: 0.0, // We'll handle friction manually
    );
    
    _inputComponent = PlayerInputComponent();
    
    // Collision component
    _collisionComponent = GameCollisionComponent(
      hitbox: RectangleHitbox(size: Vector2(32, 32)),
      type: GameCollisionType.player,
      collidesWith: {
        GameCollisionType.tile,
        GameCollisionType.wall,
        GameCollisionType.spring,
        GameCollisionType.elevator,
      },
      position: position ?? Vector2.zero(),
      size: Vector2(32, 32),
    );
    
    // Sprite component (will be initialized with actual sprites later)
    _spriteComponent = GameSpriteComponent(
      size: Vector2(32, 32),
      renderLayer: 1,
    );
  }

  @override
  Future<void> initializeEntity() async {
    // Add components to the entity
    addEntityComponent(_positionComponent);
    addEntityComponent(_velocityComponent);
    addEntityComponent(_inputComponent);
    addEntityComponent(_collisionComponent);
    addEntityComponent(_spriteComponent);
    
    // Initialize animations (placeholder - will be loaded from assets)
    await _initializeAnimations();
    
    // Set initial sprite
    _updateSpriteForState(_currentState);
    
    // Position the sprite component
    _spriteComponent.position = _positionComponent.position;
  }
  
  /// Initialize animation sprites for different states
  Future<void> _initializeAnimations() async {
    // Placeholder animations - in a real implementation, these would be loaded from assets
    // For now, we'll create simple colored rectangles to represent different states
    
    // Create placeholder sprites for each state
    final idleSprite = await _createPlaceholderSprite(Colors.blue);
    final movingSprite = await _createPlaceholderSprite(Colors.green);
    final jumpingSprite = await _createPlaceholderSprite(Colors.yellow);
    final fallingSprite = await _createPlaceholderSprite(Colors.orange);
    final aimingSprite = await _createPlaceholderSprite(Colors.red);
    final launchingSprite = await _createPlaceholderSprite(Colors.purple);
    final coyoteSprite = await _createPlaceholderSprite(Colors.cyan);
    final jumpQueuedSprite = await _createPlaceholderSprite(Colors.pink);
    final deathSprite = await _createPlaceholderSprite(Colors.black);
    final elevatorSprite = await _createPlaceholderSprite(Colors.grey);
    
    _animations[PlayerState.idle] = [idleSprite];
    _animations[PlayerState.moving] = [movingSprite];
    _animations[PlayerState.jumping] = [jumpingSprite];
    _animations[PlayerState.falling] = [fallingSprite];
    _animations[PlayerState.aiming] = [aimingSprite];
    _animations[PlayerState.launching] = [launchingSprite];
    _animations[PlayerState.coyoteTime] = [coyoteSprite];
    _animations[PlayerState.jumpQueued] = [jumpQueuedSprite];
    _animations[PlayerState.death] = [deathSprite];
    _animations[PlayerState.elevator] = [elevatorSprite];
  }
  
  /// Create a placeholder sprite with the given color
  Future<Sprite> _createPlaceholderSprite(Color color) async {
    // This is a placeholder - in a real implementation, sprites would be loaded from assets
    final paint = Paint()..color = color;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 32);
    return Sprite(image);
  }

  @override
  void updateEntity(double dt) {
    // Skip expensive operations if delta time is too small
    if (dt < 0.001) return;
    
    _stateTimer += dt;
    _animationTimer += dt;
    
    // Update input state
    _updateInputProcessing(dt);
    
    // Update state machine
    _updateStateMachine(dt);
    
    // Update physics based on current state
    _updatePhysics(dt);
    
    // Update position
    _updatePosition(dt);
    
    // Update collision detection (simplified)
    _updateCollisions();
    
    // Update animations (less frequently)
    if (_animationTimer >= animationFrameTime) {
      _updateAnimations(dt);
    }
    
    // Update ball tracking during aiming
    if (_currentState == PlayerState.aiming) {
      _updateBallTracking();
    }
    
    // Update sprite position
    _spriteComponent.position = _positionComponent.position;
  }
  
  /// Update input processing based on current state
  void _updateInputProcessing(double dt) {
    // Update coyote time
    _updateCoyoteTime(dt);
    
    // Update jump buffer
    _updateJumpBuffer(dt);
    
    // Handle aiming input
    if (_inputComponent.isAiming && _currentState != PlayerState.aiming && _canStrike && !_isDead) {
      _changeState(PlayerState.aiming);
      _createBall(); // Create ball when entering aiming state
    } else if (!_inputComponent.isAiming && _currentState == PlayerState.aiming) {
      if (_inputComponent.shouldLaunch) {
        _changeState(PlayerState.launching);
        _launchBall(); // Launch ball when exiting aiming state
      } else {
        _changeState(_isOnGround ? PlayerState.idle : PlayerState.falling);
        _destroyBall(); // Destroy ball if aiming cancelled
      }
    }
  }
  
  /// Update coyote time for grace period jumping
  void _updateCoyoteTime(double dt) {
    if (_isOnGround) {
      _coyoteTimer = coyoteTime;
    } else if (_wasOnGroundLastFrame && !_isOnGround) {
      // Just left the ground, start coyote time
      _coyoteTimer = coyoteTime;
    } else if (_coyoteTimer > 0) {
      _coyoteTimer -= dt;
    }
    
    _wasOnGroundLastFrame = _isOnGround;
  }
  
  /// Update jump buffer for responsive controls
  void _updateJumpBuffer(double dt) {
    if (_inputComponent.isJumpPressed) {
      _jumpBufferTimer = jumpBufferTime;
    } else if (_jumpBufferTimer > 0) {
      _jumpBufferTimer -= dt;
    }
  }
  
  /// Check if player can jump with coyote time
  bool _canJumpWithCoyoteTime() {
    return (_isOnGround || _coyoteTimer > 0) && _jumpBufferTimer > 0;
  }
  
  /// Update the state machine
  void _updateStateMachine(double dt) {
    // Don't process state changes if dead
    if (_isDead && _currentState != PlayerState.death) {
      _changeState(PlayerState.death);
      return;
    }
    
    switch (_currentState) {
      case PlayerState.idle:
        if (!_isOnGround) {
          _changeState(PlayerState.coyoteTime);
        } else if (_inputComponent.hasMovementInput) {
          _changeState(PlayerState.moving);
        } else if (_canJumpWithCoyoteTime()) {
          _changeState(PlayerState.jumping);
        }
        break;
        
      case PlayerState.moving:
        if (!_isOnGround) {
          _changeState(PlayerState.coyoteTime);
        } else if (!_inputComponent.hasMovementInput) {
          _changeState(PlayerState.idle);
        } else if (_canJumpWithCoyoteTime()) {
          _changeState(PlayerState.jumping);
        }
        break;
        
      case PlayerState.jumping:
        if (_velocityComponent.velocity.y >= 0) {
          _changeState(PlayerState.falling);
        }
        break;
        
      case PlayerState.falling:
        if (_isOnGround) {
          if (_inputComponent.hasMovementInput) {
            _changeState(PlayerState.moving);
          } else {
            _changeState(PlayerState.idle);
          }
        } else if (_jumpBufferTimer > 0 && _inputComponent.isJumpPressed) {
          _changeState(PlayerState.jumpQueued);
        }
        break;
        
      case PlayerState.coyoteTime:
        if (_isOnGround) {
          if (_inputComponent.hasMovementInput) {
            _changeState(PlayerState.moving);
          } else {
            _changeState(PlayerState.idle);
          }
        } else if (_canJumpWithCoyoteTime()) {
          _changeState(PlayerState.jumping);
        } else if (_coyoteTimer <= 0) {
          _changeState(PlayerState.falling);
        }
        break;
        
      case PlayerState.jumpQueued:
        if (_isOnGround) {
          _changeState(PlayerState.jumping);
        } else if (_jumpBufferTimer <= 0) {
          _changeState(PlayerState.falling);
        }
        break;
        
      case PlayerState.aiming:
        // Handled in input processing
        break;
        
      case PlayerState.launching:
        // Return to normal state after launch animation
        if (_stateTimer > 0.3) { // Launch animation duration
          _canStrike = true;
          if (_isOnGround) {
            _changeState(_inputComponent.hasMovementInput ? PlayerState.moving : PlayerState.idle);
          } else {
            _changeState(PlayerState.falling);
          }
        }
        break;
        
      case PlayerState.death:
        // Handle death state - could trigger respawn after timer
        if (_stateTimer > 2.0) { // Death animation duration
          _respawn();
        }
        break;
        
      case PlayerState.elevator:
        // Freeze all movement during elevator transition
        _velocityComponent.velocity.setZero();
        // Elevator state would be controlled by level system
        break;
    }
  }
  
  /// Update physics based on current state
  void _updatePhysics(double dt) {
    switch (_currentState) {
      case PlayerState.idle:
        // Apply friction
        _velocityComponent.velocity.x *= friction;
        break;
        
      case PlayerState.moving:
        // Apply movement input
        if (_inputComponent.canMove) {
          final targetVelocity = _inputComponent.movementDirection * moveSpeed * _inputComponent.movementSpeedMultiplier;
          _velocityComponent.velocity.x = targetVelocity;
        }
        break;
        
      case PlayerState.jumping:
        // Handle jump input
        if (_stateTimer < 0.1 && _canJumpWithCoyoteTime()) { // Allow jump input for first 0.1 seconds
          _velocityComponent.velocity.y = -jumpForce * _inputComponent.jumpForceMultiplier;
          _jumpBufferTimer = 0.0; // Consume jump buffer
          _coyoteTimer = 0.0; // Consume coyote time
          
          // Play jump sound
          onAudioEvent?.call('jump', _positionComponent.position);
        }
        // Allow air control
        if (_inputComponent.hasMovementInput && _inputComponent.canMove) {
          _velocityComponent.velocity.x = _inputComponent.movementDirection * moveSpeed * 0.7; // Reduced air control
        }
        break;
        
      case PlayerState.falling:
        // Allow air control
        if (_inputComponent.hasMovementInput && _inputComponent.canMove) {
          _velocityComponent.velocity.x = _inputComponent.movementDirection * moveSpeed * 0.7; // Reduced air control
        }
        break;
        
      case PlayerState.coyoteTime:
        // Same as falling but with jump grace period
        if (_inputComponent.hasMovementInput && _inputComponent.canMove) {
          _velocityComponent.velocity.x = _inputComponent.movementDirection * moveSpeed * 0.7;
        }
        break;
        
      case PlayerState.jumpQueued:
        // Same as falling but ready to jump when landing
        if (_inputComponent.hasMovementInput && _inputComponent.canMove) {
          _velocityComponent.velocity.x = _inputComponent.movementDirection * moveSpeed * 0.7;
        }
        break;
        
      case PlayerState.aiming:
        // Freeze movement during aiming
        _velocityComponent.velocity.x = 0;
        // Update aim direction
        if (_inputComponent.aimX != null && _inputComponent.aimY != null) {
          final aimTarget = Vector2(_inputComponent.aimX!, _inputComponent.aimY!);
          _aimDirection = (aimTarget - _positionComponent.position).normalized();
        }
        break;
        
      case PlayerState.launching:
        // Freeze movement during launch animation
        _velocityComponent.velocity.x = 0;
        _canStrike = false;
        break;
        
      case PlayerState.death:
        // Death physics - could add death animation movement
        _velocityComponent.velocity.x = 0;
        break;
        
      case PlayerState.elevator:
        // Freeze all movement during elevator
        _velocityComponent.velocity.setZero();
        break;
    }
    
    // Apply gravity (except when aiming, launching, dead, or on elevator)
    if (_currentState != PlayerState.aiming && 
        _currentState != PlayerState.launching && 
        _currentState != PlayerState.death &&
        _currentState != PlayerState.elevator) {
      _velocityComponent.velocity.y += gravity * dt;
    }
  }
  
  /// Update position based on velocity
  void _updatePosition(double dt) {
    final deltaPosition = _velocityComponent.velocity * dt;
    _positionComponent.updatePosition(_positionComponent.position + deltaPosition);
    
    // Keep player on screen horizontally
    if (_positionComponent.position.x < 0) {
      _positionComponent.position.x = 0;
      _velocityComponent.velocity.x = 0;
    } else if (_positionComponent.position.x > 800 - 32) {
      _positionComponent.position.x = 800 - 32;
      _velocityComponent.velocity.x = 0;
    }
  }
  
  /// Update collision detection (simplified for now)
  void _updateCollisions() {
    // Simple ground collision (temporary)
    final wasOnGround = _isOnGround;
    _isOnGround = _positionComponent.position.y >= _groundY;
    
    if (_isOnGround && !wasOnGround) {
      // Just landed
      _positionComponent.position.y = _groundY;
      _velocityComponent.velocity.y = 0;
      
      // Play landing sound
      onAudioEvent?.call('land', _positionComponent.position);
    } else if (_isOnGround) {
      // Stay on ground
      _positionComponent.position.y = _groundY;
      if (_velocityComponent.velocity.y > 0) {
        _velocityComponent.velocity.y = 0;
      }
    }
  }
  
  /// Update animations
  void _updateAnimations(double dt) {
    if (_animationTimer >= animationFrameTime) {
      _animationTimer = 0.0;
      
      final currentAnimation = _animations[_currentState];
      if (currentAnimation != null && currentAnimation.isNotEmpty) {
        _currentAnimationFrame = (_currentAnimationFrame + 1) % currentAnimation.length;
        _spriteComponent.sprite = currentAnimation[_currentAnimationFrame];
      }
    }
  }
  
  /// Change the player state
  void _changeState(PlayerState newState) {
    if (newState != _currentState) {
      _previousState = _currentState;
      _currentState = newState;
      _stateTimer = 0.0;
      _updateSpriteForState(newState);
    }
  }
  
  /// Update sprite for the current state
  void _updateSpriteForState(PlayerState state) {
    final animation = _animations[state];
    if (animation != null && animation.isNotEmpty) {
      _currentAnimationFrame = 0;
      _spriteComponent.sprite = animation[0];
    }
  }

  // Getters for components and state
  
  /// Get the input component
  PlayerInputComponent get inputComponent => _inputComponent;
  
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
  
  /// Get the current player state
  PlayerState get currentState => _currentState;
  
  /// Get the previous player state
  PlayerState get previousState => _previousState;
  
  /// Get the current state timer
  double get stateTimer => _stateTimer;
  
  /// Check if player is on ground
  bool get isOnGround => _isOnGround;
  
  /// Check if player can strike (launch ball)
  bool get canStrike => _canStrike;
  
  /// Get the current aim direction
  Vector2? get aimDirection => _aimDirection?.clone();
  
  /// Get the current ball (if any)
  BallEntity? get currentBall => _currentBall;
  
  /// Check if player has an active ball
  bool get hasBall => _currentBall != null;
  
  // Public methods for external systems
  
  /// Force a state change (for external systems)
  void forceStateChange(PlayerState newState) {
    _changeState(newState);
  }
  
  /// Set ground level (for level system)
  void setGroundLevel(double groundY) {
    _groundY = groundY;
  }
  
  /// Reset player to initial state
  void resetPlayer({Vector2? position}) {
    if (position != null) {
      _positionComponent.position.setFrom(position);
    }
    _velocityComponent.velocity.setZero();
    _changeState(PlayerState.idle);
    _canStrike = true;
    _aimDirection = null;
    
    // Clean up any existing ball
    _destroyBall();
  }
  
  /// Handle collision with other entities
  void handleCollision(GameCollisionComponent other) {
    // This will be expanded when collision system is fully implemented
    switch (other.type) {
      case GameCollisionType.spring:
        // Apply spring force
        _velocityComponent.velocity.y = -jumpForce * 1.5;
        _changeState(PlayerState.jumping);
        break;
      case GameCollisionType.elevator:
        // Handle elevator interaction
        break;
      default:
        break;
    }
  }
  
  /// Set player on ground state
  void setOnGround(bool onGround) {
    _isOnGround = onGround;
  }
  
  /// Kill the player (trigger death state)
  void kill() {
    _isDead = true;
    _changeState(PlayerState.death);
  }
  
  /// Respawn the player
  void _respawn() {
    _isDead = false;
    if (_respawnPosition != null) {
      _positionComponent.position.setFrom(_respawnPosition!);
    }
    _velocityComponent.velocity.setZero();
    _changeState(PlayerState.idle);
    _canStrike = true;
    _aimDirection = null;
    
    // Clean up any existing ball
    _destroyBall();
  }
  
  /// Set respawn position
  void setRespawnPosition(Vector2 position) {
    _respawnPosition = position.clone();
  }
  
  /// Create a ball for aiming
  void _createBall() {
    if (_currentBall != null) {
      _destroyBall(); // Clean up existing ball
    }
    
    // Create ball at player position (slightly offset)
    final ballPosition = _positionComponent.position + Vector2(16, 8); // Center of player
    _currentBall = BallEntity(
      id: '${id}_ball_${DateTime.now().millisecondsSinceEpoch}',
      position: ballPosition,
      onCameraShakeRequest: (direction) {
        // Camera shake will be handled by camera system
      },
      onForceQuitAiming: () {
        // Force quit aiming if ball hits something
        if (_currentState == PlayerState.aiming) {
          _changeState(_isOnGround ? PlayerState.idle : PlayerState.falling);
        }
      },
      onTileHit: (tile, position, normal) {
        // Tile hit will be handled by collision system
      },
    );
    
    // Initialize the ball
    _currentBall!.initializeEntity();
    
    // Set ball to tracking state
    _currentBall!.startTracking();
    
    // Notify callback
    onBallCreated?.call(_currentBall!);
  }
  
  /// Launch the current ball
  void _launchBall() {
    if (_currentBall != null && _aimDirection != null) {
      // Set ball direction and shoot
      _currentBall!.setDirection(_aimDirection!);
      _currentBall!.shoot();
      
      // Play strike sound
      onAudioEvent?.call('strike', _positionComponent.position);
      
      // Notify callback
      onBallLaunched?.call(_currentBall!);
      
      // Clear current ball reference (it's now flying independently)
      _currentBall = null;
      
      // Reset aim direction
      _aimDirection = null;
    }
  }
  
  /// Destroy the current ball
  void _destroyBall() {
    if (_currentBall != null) {
      _currentBall!.kill();
      _currentBall = null;
    }
    _aimDirection = null;
  }
  
  /// Update ball position during aiming
  void _updateBallTracking() {
    if (_currentBall != null && _currentState == PlayerState.aiming) {
      // Update ball position to follow player
      final ballPosition = _positionComponent.position + Vector2(16, 8);
      _currentBall!.positionComponent.updatePosition(ballPosition);
      
      // Update ball direction based on aim
      if (_aimDirection != null) {
        _currentBall!.setDirection(_aimDirection!);
      }
    }
  }
}