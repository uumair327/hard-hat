import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/components/input_component.dart';

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
    final inputComponent = player.getComponent<InputComponent>();
    if (inputComponent == null) return;
    
    // Update state timers
    player.incrementStateTimer(dt);
    
    // Process state machine
    final newState = _processStateMachine(player, inputComponent);
    
    if (newState != player.currentState) {
      _changePlayerState(player, newState);
    }
  }

  /// Process the player state machine
  PlayerState _processStateMachine(PlayerEntity player, InputComponent input) {
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
  PlayerState _processIdleState(PlayerEntity player, InputComponent input) {
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
  PlayerState _processMovingState(PlayerEntity player, InputComponent input) {
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
  PlayerState _processJumpingState(PlayerEntity player, InputComponent input) {
    // Check if we've reached the peak of the jump (velocity becomes positive/downward)
    if (player.velocityY >= 0) {
      return PlayerState.falling;
    }
    
    return PlayerState.jumping;
  }

  /// Process falling state
  PlayerState _processFallingState(PlayerEntity player, InputComponent input) {
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
  PlayerState _processAimingState(PlayerEntity player, InputComponent input) {
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
  PlayerState _processLaunchingState(PlayerEntity player, InputComponent input) {
    // Return to normal state after launch animation
    if (player.stateTimer > 0.3) { // Launch animation duration
      player.setCanStrike(true);
      
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
    
    // Set new state
    player.setState(newState);
    
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
        // Reset aiming state
        player.resetAiming();
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
        // Start idle animation
        player.startIdleAnimation();
        break;
      case PlayerState.moving:
        // Start movement animation
        player.startMovementAnimation();
        break;
      case PlayerState.jumping:
        // Apply jump force and start animation
        player.applyJumpForce();
        player.startJumpAnimation();
        break;
      case PlayerState.falling:
        // Start falling animation
        player.startFallingAnimation();
        break;
      case PlayerState.aiming:
        // Start aiming mode
        player.startAiming();
        break;
      case PlayerState.launching:
        // Execute launch and start animation
        player.executeLaunch();
        player.startLaunchAnimation();
        player.setCanStrike(false);
        break;
    }
  }

  /// Handle state change events
  void _onStateChanged(PlayerEntity player, PlayerState oldState, PlayerState newState) {
    // Trigger audio events
    _triggerAudioEvents(player, oldState, newState);
    
    // Trigger visual effects
    _triggerVisualEffects(player, oldState, newState);
    
    // Update animation state
    _updateAnimationState(player, newState);
  }

  /// Trigger audio events for state changes
  void _triggerAudioEvents(PlayerEntity player, PlayerState oldState, PlayerState newState) {
    switch (newState) {
      case PlayerState.jumping:
        // Play jump sound
        player.playSound('jump');
        break;
      case PlayerState.launching:
        // Play launch sound
        player.playSound('launch');
        break;
      case PlayerState.idle:
        if (oldState == PlayerState.falling) {
          // Play landing sound
          player.playSound('land');
        }
        break;
      case PlayerState.moving:
        if (oldState == PlayerState.falling) {
          // Play landing sound
          player.playSound('land');
        }
        break;
      default:
        // No audio for other transitions
        break;
    }
  }

  /// Trigger visual effects for state changes
  void _triggerVisualEffects(PlayerEntity player, PlayerState oldState, PlayerState newState) {
    switch (newState) {
      case PlayerState.jumping:
        // Spawn jump particles
        player.spawnParticles('jump_dust');
        break;
      case PlayerState.launching:
        // Spawn launch particles
        player.spawnParticles('launch_effect');
        break;
      case PlayerState.idle:
      case PlayerState.moving:
        if (oldState == PlayerState.falling) {
          // Spawn landing particles
          player.spawnParticles('landing_dust');
        }
        break;
      default:
        // No effects for other transitions
        break;
    }
  }

  /// Update animation state
  void _updateAnimationState(PlayerEntity player, PlayerState state) {
    // This would typically update the sprite animation controller
    player.setAnimationState(state.toString());
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
    super.dispose();
  }
}

/// Extension methods for PlayerEntity to support state system
extension PlayerEntityStateExtensions on PlayerEntity {
  /// Start idle animation
  void startIdleAnimation() {
    // Implementation would start idle sprite animation
  }

  /// Start movement animation
  void startMovementAnimation() {
    // Implementation would start walking/running animation
  }

  /// Start jump animation
  void startJumpAnimation() {
    // Implementation would start jump animation
  }

  /// Start falling animation
  void startFallingAnimation() {
    // Implementation would start falling animation
  }

  /// Start aiming mode
  void startAiming() {
    // Implementation would show aiming reticle, change sprite, etc.
  }

  /// Start launch animation
  void startLaunchAnimation() {
    // Implementation would start launch animation
  }

  /// Reset aiming state
  void resetAiming() {
    // Implementation would hide aiming reticle, reset aim direction, etc.
  }

  /// Apply jump force
  void applyJumpForce() {
    // Implementation would apply upward velocity
  }

  /// Execute launch
  void executeLaunch() {
    // Implementation would launch the ball/projectile
  }

  /// Play sound effect
  void playSound(String soundName) {
    // Implementation would trigger audio system
  }

  /// Spawn particle effects
  void spawnParticles(String particleType) {
    // Implementation would trigger particle system
  }

  /// Set animation state
  void setAnimationState(String animationName) {
    // Implementation would update sprite animation
  }

  /// Get velocity Y component
  double get velocityY {
    // Implementation would return Y velocity from velocity component
    return 0.0; // Placeholder
  }

  /// Check if player is on ground
  bool get isOnGround {
    // Implementation would check collision with ground
    return true; // Placeholder
  }

  /// Check if player can strike
  bool get canStrike {
    // Implementation would check strike cooldown/availability
    return true; // Placeholder
  }

  /// Set can strike flag
  void setCanStrike(bool canStrike) {
    // Implementation would set strike availability
  }

  /// Get current state timer
  double get stateTimer {
    // Implementation would return time in current state
    return 0.0; // Placeholder
  }

  /// Increment state timer
  void incrementStateTimer(double dt) {
    // Implementation would increment state timer
  }
}