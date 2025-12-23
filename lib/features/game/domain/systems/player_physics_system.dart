import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// System responsible for player physics calculations
/// Separates physics logic from player entity (proper ECS pattern)
class PlayerPhysicsSystem extends GameSystem {
  late EntityManager _entityManager;
  
  // Physics constants
  static const double gravity = 980.0; // pixels/second²
  static const double groundFriction = 0.8;
  static const double airFriction = 0.95;
  static const double moveSpeed = 200.0; // pixels/second
  static const double jumpForce = -400.0; // negative for upward
  static const double maxFallSpeed = 500.0;
  static const double coyoteTime = 0.1; // seconds
  static const double jumpBufferTime = 0.1; // seconds
  
  @override
  int get priority => 4; // Process after state system but before collision

  @override
  Future<void> initialize() async {
    // Will be injected
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }

  @override
  void update(double dt) {
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    
    for (final player in players) {
      _updatePlayerPhysics(player, dt);
    }
  }

  /// Update physics for individual player
  void _updatePlayerPhysics(PlayerEntity player, double dt) {
    final inputComponent = player.inputComponent;
    final velocityComponent = player.velocityComponent;
    final positionComponent = player.positionComponent;
    
    // Update physics based on current state
    switch (player.currentState) {
      case PlayerState.idle:
        _updateIdlePhysics(player, inputComponent, velocityComponent, dt);
        break;
      case PlayerState.moving:
        _updateMovingPhysics(player, inputComponent, velocityComponent, dt);
        break;
      case PlayerState.jumping:
        _updateJumpingPhysics(player, inputComponent, velocityComponent, dt);
        break;
      case PlayerState.falling:
        _updateFallingPhysics(player, inputComponent, velocityComponent, dt);
        break;
      case PlayerState.aiming:
        _updateAimingPhysics(player, inputComponent, velocityComponent, dt);
        break;
      case PlayerState.launching:
        _updateLaunchingPhysics(player, inputComponent, velocityComponent, dt);
        break;
    }
    
    // Apply gravity (except when on ground and not jumping)
    if (!player.isOnGround || player.currentState == PlayerState.jumping) {
      _applyGravity(velocityComponent, dt);
    }
    
    // Clamp velocities to reasonable limits
    _clampVelocities(velocityComponent);
    
    // Update position based on velocity
    _updatePosition(positionComponent, velocityComponent, dt);
  }

  /// Update physics for idle state
  void _updateIdlePhysics(PlayerEntity player, PlayerInputComponent input, VelocityComponent velocity, double dt) {
    // Apply friction to horizontal movement
    velocity.velocity.x *= groundFriction;
    
    // Stop very small movements
    if (velocity.velocity.x.abs() < 1.0) {
      velocity.velocity.x = 0.0;
    }
    
    // Zero vertical velocity when on ground
    if (player.isOnGround) {
      velocity.velocity.y = 0.0;
    }
  }

  /// Update physics for moving state
  void _updateMovingPhysics(PlayerEntity player, PlayerInputComponent input, VelocityComponent velocity, double dt) {
    if (input.canMove) {
      // Apply horizontal movement
      final targetVelocity = input.movementDirection * moveSpeed;
      velocity.velocity.x = targetVelocity;
    } else {
      // Apply friction if no input
      velocity.velocity.x *= groundFriction;
    }
    
    // Zero vertical velocity when on ground
    if (player.isOnGround) {
      velocity.velocity.y = 0.0;
    }
  }

  /// Update physics for jumping state
  void _updateJumpingPhysics(PlayerEntity player, PlayerInputComponent input, VelocityComponent velocity, double dt) {
    // Apply horizontal movement in air
    if (input.canMove) {
      final targetVelocity = input.movementDirection * moveSpeed;
      // Blend current velocity with target for air control
      velocity.velocity.x = _lerpDouble(velocity.velocity.x, targetVelocity, 0.1);
    } else {
      // Apply air friction
      velocity.velocity.x *= airFriction;
    }
    
    // Variable jump height - reduce upward velocity if jump is released early
    if (!input.isJumpPressed && velocity.velocity.y < 0) {
      velocity.velocity.y *= 0.5;
    }
  }

  /// Update physics for falling state
  void _updateFallingPhysics(PlayerEntity player, PlayerInputComponent input, VelocityComponent velocity, double dt) {
    // Apply horizontal movement in air (same as jumping)
    if (input.canMove) {
      final targetVelocity = input.movementDirection * moveSpeed;
      velocity.velocity.x = _lerpDouble(velocity.velocity.x, targetVelocity, 0.1);
    } else {
      velocity.velocity.x *= airFriction;
    }
  }

  /// Update physics for aiming state
  void _updateAimingPhysics(PlayerEntity player, PlayerInputComponent input, VelocityComponent velocity, double dt) {
    // Reduce movement while aiming
    velocity.velocity.x *= 0.5;
    
    // Zero vertical velocity when on ground
    if (player.isOnGround) {
      velocity.velocity.y = 0.0;
    }
  }

  /// Update physics for launching state
  void _updateLaunchingPhysics(PlayerEntity player, PlayerInputComponent input, VelocityComponent velocity, double dt) {
    // Apply recoil force from launch
    if (player.stateTimer < 0.1) { // Apply recoil for first 100ms
      final recoilForce = _calculateLaunchRecoil(player);
      velocity.velocity.x += recoilForce.x * dt;
      velocity.velocity.y += recoilForce.y * dt;
    }
    
    // Normal physics after recoil
    if (player.isOnGround) {
      velocity.velocity.x *= groundFriction;
      if (player.stateTimer > 0.1) {
        velocity.velocity.y = 0.0;
      }
    } else {
      velocity.velocity.x *= airFriction;
    }
  }

  /// Apply gravity to velocity
  void _applyGravity(VelocityComponent velocity, double dt) {
    velocity.velocity.y += gravity * dt;
  }

  /// Clamp velocities to reasonable limits
  void _clampVelocities(VelocityComponent velocity) {
    // Clamp horizontal velocity
    velocity.velocity.x = velocity.velocity.x.clamp(-moveSpeed * 1.5, moveSpeed * 1.5);
    
    // Clamp vertical velocity
    velocity.velocity.y = velocity.velocity.y.clamp(jumpForce * 1.2, maxFallSpeed);
  }

  /// Update position based on velocity
  void _updatePosition(GamePositionComponent position, VelocityComponent velocity, double dt) {
    final deltaPosition = velocity.velocity * dt;
    position.updatePosition(position.position + deltaPosition);
  }

  /// Calculate launch recoil force
  Vector2 _calculateLaunchRecoil(PlayerEntity player) {
    // This would calculate recoil based on launch direction and power
    // For now, return a simple backward force
    return Vector2(-50.0, 0.0); // Placeholder
  }

  /// Apply jump force to player
  void applyJumpForce(PlayerEntity player) {
    final velocityComponent = player.velocityComponent;
    velocityComponent.velocity.y = jumpForce;
  }

  /// Apply external force to player (e.g., from explosions, springs)
  void applyExternalForce(PlayerEntity player, Vector2 force) {
    final velocityComponent = player.velocityComponent;
    velocityComponent.velocity += force;
  }

  /// Set player velocity directly
  void setPlayerVelocity(PlayerEntity player, Vector2 velocity) {
    final velocityComponent = player.velocityComponent;
    velocityComponent.velocity = velocity;
  }

  /// Get player velocity
  Vector2? getPlayerVelocity(PlayerEntity player) {
    final velocityComponent = player.velocityComponent;
    return velocityComponent.velocity;
  }

  /// Check if player is moving horizontally
  bool isPlayerMovingHorizontally(PlayerEntity player) {
    final velocity = getPlayerVelocity(player);
    return velocity != null && velocity.x.abs() > 1.0;
  }

  /// Check if player is moving vertically
  bool isPlayerMovingVertically(PlayerEntity player) {
    final velocity = getPlayerVelocity(player);
    return velocity != null && velocity.y.abs() > 1.0;
  }

  /// Get player speed (magnitude of velocity)
  double getPlayerSpeed(PlayerEntity player) {
    final velocity = getPlayerVelocity(player);
    return velocity?.length ?? 0.0;
  }

  /// Linear interpolation helper
  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Physics configuration for different player states
class PlayerPhysicsConfig {
  final double friction;
  final double airControl;
  final double maxSpeed;
  final bool applyGravity;

  const PlayerPhysicsConfig({
    required this.friction,
    required this.airControl,
    required this.maxSpeed,
    required this.applyGravity,
  });

  static const idle = PlayerPhysicsConfig(
    friction: 0.8,
    airControl: 0.0,
    maxSpeed: 0.0,
    applyGravity: false,
  );

  static const moving = PlayerPhysicsConfig(
    friction: 0.8,
    airControl: 0.0,
    maxSpeed: 200.0,
    applyGravity: false,
  );

  static const jumping = PlayerPhysicsConfig(
    friction: 0.95,
    airControl: 0.1,
    maxSpeed: 200.0,
    applyGravity: true,
  );

  static const falling = PlayerPhysicsConfig(
    friction: 0.95,
    airControl: 0.1,
    maxSpeed: 200.0,
    applyGravity: true,
  );

  static const aiming = PlayerPhysicsConfig(
    friction: 0.5,
    airControl: 0.0,
    maxSpeed: 100.0,
    applyGravity: false,
  );

  static const launching = PlayerPhysicsConfig(
    friction: 0.8,
    airControl: 0.05,
    maxSpeed: 200.0,
    applyGravity: true,
  );
}