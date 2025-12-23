import 'package:flame/components.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_system_interfaces.dart';
import 'package:hard_hat/features/game/domain/components/position_component.dart';
import 'package:hard_hat/features/game/domain/components/velocity_component.dart';
import 'package:hard_hat/features/game/domain/components/collision_component.dart';

/// System responsible for handling movement physics with realistic gravity, friction, and special mechanics
class MovementSystem extends GameSystem implements IMovementSystem {
  @override
  int get priority => 100; // Execute after input but before collision

  /// Gravity constant (pixels per second squared)
  static const double gravity = 980.0;
  
  /// Default ground friction coefficient
  static const double groundFriction = 0.85;
  
  /// Default air friction coefficient
  static const double airFriction = 0.98;
  
  /// Terminal velocity (max falling speed)
  static const double terminalVelocity = 1000.0;
  
  /// Map to track ground state for entities (for coyote time)
  final Map<Component, GroundState> _groundStates = {};
  
  /// Map to track jump buffer for entities
  final Map<Component, JumpBuffer> _jumpBuffers = {};

  @override
  Future<void> initialize() async {
    // Initialize movement system
  }

  @override
  void updateMovement(double dt) {
    updateSystem(dt);
  }

  @override
  void updateSystem(double dt) {
    // Get all entities with both position and velocity components
    final entities = getComponents<Component>()
        .where((entity) => 
            entity.children.any((c) => c is GamePositionComponent) &&
            entity.children.any((c) => c is VelocityComponent))
        .toList();

    for (final entity in entities) {
      _updateEntityMovement(entity, dt);
    }
    
    // Update ground states and jump buffers
    _updateGroundStates(dt);
    _updateJumpBuffers(dt);
  }

  void _updateEntityMovement(Component entity, double dt) {
    final positionComponent = entity.children
        .whereType<GamePositionComponent>()
        .firstOrNull;
    final velocityComponent = entity.children
        .whereType<VelocityComponent>()
        .firstOrNull;
    final collisionComponent = entity.children
        .whereType<GameCollisionComponent>()
        .firstOrNull;

    if (positionComponent == null || velocityComponent == null) {
      return;
    }

    // Store previous position for collision resolution
    positionComponent.previousPosition.setFrom(positionComponent.position);

    // Apply gravity (only if entity has collision component and is not a sensor)
    if (collisionComponent != null && !collisionComponent.isSensor) {
      _applyGravity(velocityComponent, dt);
    }

    // Apply acceleration to velocity
    velocityComponent.velocity.add(velocityComponent.acceleration * dt);

    // Apply friction based on ground state
    final groundState = _groundStates[entity];
    if (groundState != null && groundState.isOnGround) {
      _applyGroundFriction(velocityComponent, dt);
    } else {
      _applyAirFriction(velocityComponent, dt);
    }

    // Clamp to max speed (horizontal only to allow gravity)
    if (velocityComponent.maxSpeed > 0) {
      final horizontalSpeed = velocityComponent.velocity.x.abs();
      if (horizontalSpeed > velocityComponent.maxSpeed) {
        velocityComponent.velocity.x = velocityComponent.velocity.x.sign * velocityComponent.maxSpeed;
      }
    }

    // Clamp vertical velocity to terminal velocity
    if (velocityComponent.velocity.y > terminalVelocity) {
      velocityComponent.velocity.y = terminalVelocity;
    }

    // Apply velocity to position
    final deltaPosition = velocityComponent.velocity * dt;
    positionComponent.position.add(deltaPosition);
  }

  void _applyGravity(VelocityComponent velocity, double dt) {
    velocity.velocity.y += gravity * dt;
  }

  void _applyGroundFriction(VelocityComponent velocity, double dt) {
    // Apply ground friction to horizontal movement
    velocity.velocity.x *= groundFriction;
    
    // Stop if velocity is very small
    if (velocity.velocity.x.abs() < 0.1) {
      velocity.velocity.x = 0;
    }
  }

  void _applyAirFriction(VelocityComponent velocity, double dt) {
    // Apply air friction (less than ground friction)
    velocity.velocity.x *= airFriction;
  }

  void _updateGroundStates(double dt) {
    // Update coyote time for all tracked entities
    final entitiesToRemove = <Component>[];
    
    for (final entry in _groundStates.entries) {
      final entity = entry.key;
      final state = entry.value;
      
      // Check if entity still exists
      if (entity.isRemoved) {
        entitiesToRemove.add(entity);
        continue;
      }
      
      // Update coyote time
      if (!state.isOnGround && state.coyoteTimeRemaining > 0) {
        state.coyoteTimeRemaining -= dt;
      }
    }
    
    // Clean up removed entities
    for (final entity in entitiesToRemove) {
      _groundStates.remove(entity);
    }
  }

  void _updateJumpBuffers(double dt) {
    // Update jump buffer timers
    final entitiesToRemove = <Component>[];
    
    for (final entry in _jumpBuffers.entries) {
      final entity = entry.key;
      final buffer = entry.value;
      
      // Check if entity still exists
      if (entity.isRemoved) {
        entitiesToRemove.add(entity);
        continue;
      }
      
      // Update buffer time
      if (buffer.isBuffered && buffer.bufferTimeRemaining > 0) {
        buffer.bufferTimeRemaining -= dt;
        if (buffer.bufferTimeRemaining <= 0) {
          buffer.isBuffered = false;
        }
      }
    }
    
    // Clean up removed entities
    for (final entity in entitiesToRemove) {
      _jumpBuffers.remove(entity);
    }
  }

  /// Set ground state for an entity
  void setGroundState(Component entity, bool isOnGround) {
    final state = _groundStates.putIfAbsent(entity, () => GroundState());
    
    if (isOnGround) {
      state.isOnGround = true;
      state.coyoteTimeRemaining = GroundState.coyoteTimeDuration;
    } else {
      state.isOnGround = false;
    }
  }

  /// Check if entity can jump (considering coyote time)
  bool canJump(Component entity) {
    final state = _groundStates[entity];
    if (state == null) return false;
    
    return state.isOnGround || state.coyoteTimeRemaining > 0;
  }

  /// Buffer a jump input for an entity
  void bufferJump(Component entity) {
    final buffer = _jumpBuffers.putIfAbsent(entity, () => JumpBuffer());
    buffer.isBuffered = true;
    buffer.bufferTimeRemaining = JumpBuffer.bufferDuration;
  }

  /// Check if entity has a buffered jump
  bool hasBufferedJump(Component entity) {
    final buffer = _jumpBuffers[entity];
    return buffer != null && buffer.isBuffered && buffer.bufferTimeRemaining > 0;
  }

  /// Consume a buffered jump
  void consumeBufferedJump(Component entity) {
    final buffer = _jumpBuffers[entity];
    if (buffer != null) {
      buffer.isBuffered = false;
      buffer.bufferTimeRemaining = 0;
    }
  }

  /// Apply jump force to an entity
  void applyJump(Component entity, double jumpForce) {
    final velocityComponent = entity.children
        .whereType<VelocityComponent>()
        .firstOrNull;
    
    if (velocityComponent != null) {
      velocityComponent.velocity.y = -jumpForce;
      
      // Reset ground state
      final state = _groundStates[entity];
      if (state != null) {
        state.isOnGround = false;
        state.coyoteTimeRemaining = 0;
      }
      
      // Consume buffered jump
      consumeBufferedJump(entity);
    }
  }

  /// Apply spring force to an entity
  void applySpringForce(Component entity, double springForce) {
    final velocityComponent = entity.children
        .whereType<VelocityComponent>()
        .firstOrNull;
    
    if (velocityComponent != null) {
      // Spring applies upward force
      velocityComponent.velocity.y = -springForce;
      
      // Reset ground state
      final state = _groundStates[entity];
      if (state != null) {
        state.isOnGround = false;
        state.coyoteTimeRemaining = 0;
      }
    }
  }

  /// Apply elevator velocity to an entity
  void applyElevatorVelocity(Component entity, Vector2 elevatorVelocity) {
    final velocityComponent = entity.children
        .whereType<VelocityComponent>()
        .firstOrNull;
    
    if (velocityComponent != null) {
      // Add elevator velocity to entity velocity
      velocityComponent.velocity.add(elevatorVelocity);
    }
  }

  /// Get ground state for an entity
  GroundState? getGroundState(Component entity) {
    return _groundStates[entity];
  }

  @override
  void dispose() {
    _groundStates.clear();
    _jumpBuffers.clear();
  }
}

/// Tracks ground state and coyote time for an entity
class GroundState {
  /// Duration of coyote time in seconds
  static const double coyoteTimeDuration = 0.1;
  
  bool isOnGround = false;
  double coyoteTimeRemaining = 0.0;
}

/// Tracks jump buffer for an entity
class JumpBuffer {
  /// Duration of jump buffer in seconds
  static const double bufferDuration = 0.1;
  
  bool isBuffered = false;
  double bufferTimeRemaining = 0.0;
}