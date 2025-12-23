import 'package:hard_hat/features/game/domain/domain.dart';

/// System responsible for managing player state transitions
/// Separates state machine logic from player entity (proper ECS pattern)
class PlayerStateSystem extends GameSystem {
  late EntityManager _entityManager;
  
  @override
  int get priority => 3; // Process after input but before physics

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
      _updatePlayerState(player, dt);
    }
  }

  /// Update individual player state
  void _updatePlayerState(PlayerEntity player, double dt) {
    final inputComponent = player.inputComponent;
    
    // Process state machine
    final newState = _processStateMachine(player, inputComponent);
    
    if (newState != player.currentState) {
      _changePlayerState(player, newState);
    }
  }

  /// Process the player state machine
  PlayerState _processStateMachine(PlayerEntity player, PlayerInputComponent input) {
    switch (player.currentState) {
      case PlayerState.idle:
        return _processIdleState(player, input);
      case PlayerState.moving:
        return _processMovingState(player, input);
      case PlayerState.jumping:
        return _processJumpingState(player, input);
      case PlayerState.falling:
        return _processFallingState(player, input);
      case PlayerState.aiming:
        return _processAimingState(player, input);
      case PlayerState.launching:
        return _processLaunchingState(player, input);
    }
  }

  /// Process idle state
  PlayerState _processIdleState(PlayerEntity player, PlayerInputComponent input) {
    if (!player.isOnGround) {
      return PlayerState.falling;
    }
    
    if (input.hasMovementInput) {
      return PlayerState.moving;
    }
    
    if (input.isJumpPressed && input.canJumpWithCoyoteTime()) {
      return PlayerState.jumping;
    }
    
    if (input.isAiming && player.canStrike) {
      return PlayerState.aiming;
    }
    
    return PlayerState.idle;
  }

  /// Process moving state
  PlayerState _processMovingState(PlayerEntity player, PlayerInputComponent input) {
    if (!player.isOnGround) {
      return PlayerState.falling;
    }
    
    if (!input.hasMovementInput) {
      return PlayerState.idle;
    }
    
    if (input.isJumpPressed && input.canJumpWithCoyoteTime()) {
      return PlayerState.jumping;
    }
    
    if (input.isAiming && player.canStrike) {
      return PlayerState.aiming;
    }
    
    return PlayerState.moving;
  }

  /// Process jumping state
  PlayerState _processJumpingState(PlayerEntity player, PlayerInputComponent input) {
    // Check if we've reached the peak of the jump (velocity becomes positive/downward)
    if (player.velocityComponent.velocity.y >= 0) {
      return PlayerState.falling;
    }
    
    return PlayerState.jumping;
  }

  /// Process falling state
  PlayerState _processFallingState(PlayerEntity player, PlayerInputComponent input) {
    if (player.isOnGround) {
      if (input.hasMovementInput) {
        return PlayerState.moving;
      } else {
        return PlayerState.idle;
      }
    }
    
    return PlayerState.falling;
  }

  /// Process aiming state
  PlayerState _processAimingState(PlayerEntity player, PlayerInputComponent input) {
    if (!input.isAiming) {
      if (input.shouldLaunch) {
        return PlayerState.launching;
      } else {
        return player.isOnGround ? PlayerState.idle : PlayerState.falling;
      }
    }
    
    return PlayerState.aiming;
  }

  /// Process launching state
  PlayerState _processLaunchingState(PlayerEntity player, PlayerInputComponent input) {
    // Return to normal state after launch animation
    if (player.stateTimer > 0.3) { // Launch animation duration
      
      if (player.isOnGround) {
        return input.hasMovementInput ? PlayerState.moving : PlayerState.idle;
      } else {
        return PlayerState.falling;
      }
    }
    
    return PlayerState.launching;
  }

  /// Change player state
  void _changePlayerState(PlayerEntity player, PlayerState newState) {
    final oldState = player.currentState;
    
    // Exit old state
    _exitState(player, oldState);
    
    // Set new state using the correct method
    player.forceStateChange(newState);
    
    // Enter new state
    _enterState(player, newState);
    
    // Trigger state change events
    _onStateChanged(player, oldState, newState);
  }

  /// Handle exiting a state
  void _exitState(PlayerEntity player, PlayerState state) {
    switch (state) {
      case PlayerState.idle:
        // No special exit logic
        break;
      case PlayerState.moving:
        // No special exit logic
        break;
      case PlayerState.jumping:
        // No special exit logic
        break;
      case PlayerState.falling:
        // No special exit logic
        break;
      case PlayerState.aiming:
        // Reset aiming state - handled by PlayerEntity internally
        break;
      case PlayerState.launching:
        // No special exit logic
        break;
    }
  }

  /// Handle entering a state
  void _enterState(PlayerEntity player, PlayerState state) {
    switch (state) {
      case PlayerState.idle:
        // State-specific logic handled by PlayerEntity itself
        break;
      case PlayerState.moving:
        // State-specific logic handled by PlayerEntity itself
        break;
      case PlayerState.jumping:
        // State-specific logic handled by PlayerEntity itself
        break;
      case PlayerState.falling:
        // State-specific logic handled by PlayerEntity itself
        break;
      case PlayerState.aiming:
        // State-specific logic handled by PlayerEntity itself
        break;
      case PlayerState.launching:
        // State-specific logic handled by PlayerEntity itself
        break;
    }
  }

  /// Handle state change events
  void _onStateChanged(PlayerEntity player, PlayerState oldState, PlayerState newState) {
    // State change events can be handled here or delegated to other systems
    // For now, we'll keep it simple and let the PlayerEntity handle its own state changes
  }

  /// Force a player to a specific state (for testing/debugging)
  void forcePlayerState(String playerId, PlayerState state) {
    final player = _entityManager.getEntity(playerId) as PlayerEntity?;
    if (player != null) {
      _changePlayerState(player, state);
    }
  }

  /// Get all players in a specific state
  List<PlayerEntity> getPlayersInState(PlayerState state) {
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    return players.where((player) => player.currentState == state).toList();
  }

  @override
  void dispose() {
    // Clean up resources
  }
}