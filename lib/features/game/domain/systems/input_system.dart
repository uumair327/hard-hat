import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import '../systems/game_system.dart';
import '../systems/game_state_manager.dart';
import '../input/input_handler.dart';
import '../input/input_event.dart';
import '../input/input_component.dart';

/// System that handles input processing and distributes input events to entities
class InputSystem extends GameSystem {
  late final CrossPlatformInputHandler _inputHandler;
  late final StreamSubscription<InputEvent> _inputSubscription;
  
  /// Game state manager for state-aware input processing
  GameStateManager? _gameStateManager;
  
  /// Input command queue for buffering inputs
  final List<InputEvent> _commandQueue = [];
  static const int maxQueueSize = 50;
  
  /// Input state management
  final GameStateInputComponent _gameStateInput = GameStateInputComponent();
  
  /// State-specific input behavior
  final Map<GameState, InputBehavior> _stateBehaviors = {};
  
  @override
  int get priority => 10; // High priority - process input early

  @override
  Future<void> initialize() async {
    _inputHandler = CrossPlatformInputHandler();
    await _inputHandler.initialize();
    
    // Subscribe to input events
    _inputSubscription = _inputHandler.inputStream.listen(_queueInputEvent);
    
    // Add game state input component to the game
    add(_gameStateInput);
    
    // Initialize state-specific input behaviors
    _initializeStateBehaviors();
  }
  
  /// Set the game state manager for state-aware input processing
  void setGameStateManager(GameStateManager gameStateManager) {
    _gameStateManager = gameStateManager;
    
    // Register for state change callbacks
    _gameStateManager?.addStateChangeCallback(_onGameStateChanged);
  }
  
  /// Initialize state-specific input behaviors
  void _initializeStateBehaviors() {
    _stateBehaviors[GameState.playing] = InputBehavior(
      allowMovement: true,
      allowJumping: true,
      allowAiming: true,
      allowPause: true,
    );
    
    _stateBehaviors[GameState.paused] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: true, // Allow unpause
    );
    
    _stateBehaviors[GameState.menu] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: false,
    );
    
    _stateBehaviors[GameState.levelComplete] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: true,
    );
    
    _stateBehaviors[GameState.gameOver] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: true,
    );
    
    _stateBehaviors[GameState.loading] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: false,
    );
    
    _stateBehaviors[GameState.settings] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: false,
    );
    
    _stateBehaviors[GameState.error] = InputBehavior(
      allowMovement: false,
      allowJumping: false,
      allowAiming: false,
      allowPause: true,
    );
  }
  
  /// Handle game state changes
  void _onGameStateChanged(GameState newState, GameState? previousState) {
    final behavior = _stateBehaviors[newState];
    if (behavior != null) {
      _applyInputBehavior(behavior);
    }
    
    // Clear input queue when transitioning to non-playing states
    if (newState != GameState.playing) {
      _commandQueue.clear();
      clearInputState();
    }
  }
  
  /// Apply input behavior based on current state
  void _applyInputBehavior(InputBehavior behavior) {
    _gameStateInput.inputEnabled = behavior.allowMovement || behavior.allowJumping || behavior.allowAiming;
    _inputHandler.isActive = _gameStateInput.inputEnabled || behavior.allowPause;
  }
  
  /// Get current input behavior based on game state
  InputBehavior _getCurrentInputBehavior() {
    final currentState = _gameStateManager?.currentState ?? GameState.playing;
    return _stateBehaviors[currentState] ?? _stateBehaviors[GameState.playing]!;
  }

  /// Queue an input event for processing
  void _queueInputEvent(InputEvent event) {
    _commandQueue.add(event);
    if (_commandQueue.length > maxQueueSize) {
      _commandQueue.removeAt(0);
    }
  }

  @override
  void updateSystem(double dt) {
    // Process queued input events
    _processInputQueue();
    
    // Update input components
    _updateInputComponents(dt);
    
    // Reset frame-specific input flags
    _resetFrameInputs();
  }

  /// Process all queued input events
  void _processInputQueue() {
    final behavior = _getCurrentInputBehavior();
    
    if (!_gameStateInput.shouldProcessInput() && !behavior.allowPause) {
      _commandQueue.clear();
      return;
    }

    for (final event in _commandQueue) {
      _processInputEvent(event, behavior);
    }
    _commandQueue.clear();
  }

  /// Process a single input event with state-aware behavior
  void _processInputEvent(InputEvent event, InputBehavior behavior) {
    // Get all entities with input components
    final inputEntities = getComponents<InputComponent>();
    
    for (final inputComponent in inputEntities) {
      // Add event to input buffer
      inputComponent.addInputEvent(event);
      inputComponent.lastInputSource = _getEventSource(event);
      
      // Process specific event types based on current behavior
      if (event is MovementInputEvent && behavior.allowMovement && _gameStateInput.shouldProcessMovement()) {
        _processMovementInput(inputComponent, event);
      } else if (event is JumpInputEvent && behavior.allowJumping) {
        _processJumpInput(inputComponent, event);
      } else if (event is AimInputEvent && behavior.allowAiming && _gameStateInput.shouldProcessAiming()) {
        _processAimInput(inputComponent, event);
      } else if (event is LaunchInputEvent && behavior.allowAiming && _gameStateInput.shouldProcessAiming()) {
        _processLaunchInput(inputComponent, event);
      } else if (event is PauseInputEvent && behavior.allowPause) {
        _processPauseInput(inputComponent, event);
      }
    }
  }

  /// Process movement input events
  void _processMovementInput(InputComponent inputComponent, MovementInputEvent event) {
    if (inputComponent is PlayerInputComponent && !inputComponent.canMove) {
      return;
    }
    
    inputComponent.movementDirection = event.direction;
  }

  /// Process jump input events
  void _processJumpInput(InputComponent inputComponent, JumpInputEvent event) {
    if (inputComponent is PlayerInputComponent) {
      if (!inputComponent.canJump) return;
      
      inputComponent.isJumpPressed = event.isPressed;
      
      // Update jump buffer
      inputComponent.updateJumpBuffer(event.isPressed);
    } else {
      inputComponent.isJumpPressed = event.isPressed;
    }
  }

  /// Process aim input events
  void _processAimInput(InputComponent inputComponent, AimInputEvent event) {
    if (inputComponent is PlayerInputComponent && !inputComponent.canAim) {
      return;
    }
    
    inputComponent.isAiming = event.isAiming;
    inputComponent.aimX = event.aimX;
    inputComponent.aimY = event.aimY;
    
    // Update game state based on aiming
    if (event.isAiming) {
      _gameStateInput.changeState(GameInputState.aiming);
    } else if (_gameStateInput.currentState == GameInputState.aiming) {
      _gameStateInput.changeState(GameInputState.playing);
    }
  }

  /// Process launch input events
  void _processLaunchInput(InputComponent inputComponent, LaunchInputEvent event) {
    if (inputComponent is PlayerInputComponent && !inputComponent.canAim) {
      return;
    }
    
    inputComponent.shouldLaunch = true;
    inputComponent.launchDirectionX = event.directionX;
    inputComponent.launchDirectionY = event.directionY;
    inputComponent.launchPower = event.power;
    
    // Update game state
    _gameStateInput.changeState(GameInputState.launching);
  }

  /// Process pause input events
  void _processPauseInput(InputComponent inputComponent, PauseInputEvent event) {
    inputComponent.pauseRequested = true;
    
    // Delegate pause handling to GameStateManager
    if (_gameStateManager != null) {
      if (_gameStateManager!.isPaused) {
        _gameStateManager!.resumeGame();
      } else {
        _gameStateManager!.pauseGame();
      }
    } else {
      // Fallback to local state management
      if (_gameStateInput.currentState == GameInputState.paused) {
        _gameStateInput.changeState(GameInputState.playing);
      } else {
        _gameStateInput.changeState(GameInputState.paused);
      }
    }
  }

  /// Update input components with frame-specific logic
  void _updateInputComponents(double dt) {
    final inputComponents = getComponents<InputComponent>();
    
    for (final inputComponent in inputComponents) {
      if (inputComponent is PlayerInputComponent) {
        // Update coyote time (requires ground state from physics system)
        // This will be implemented when we have the physics system
        // inputComponent.updateCoyoteTime(isGrounded);
      }
    }
  }

  /// Reset frame-specific input flags
  void _resetFrameInputs() {
    final inputComponents = getComponents<InputComponent>();
    
    for (final inputComponent in inputComponents) {
      inputComponent.resetFrameInputs();
    }
  }

  /// Get the input source from an event
  InputSource _getEventSource(InputEvent event) {
    if (event is MovementInputEvent) return event.source;
    if (event is JumpInputEvent) return event.source;
    if (event is AimInputEvent) return event.source;
    if (event is LaunchInputEvent) return event.source;
    if (event is PauseInputEvent) return event.source;
    return InputSource.keyboard;
  }

  // Input event handlers that delegate to our input handlers

  /// Handle keyboard events from the game
  void handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _inputHandler.keyboardHandler.handleKeyDown(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _inputHandler.keyboardHandler.handleKeyUp(event.logicalKey);
    }
  }

  /// Handle tap down events from the game
  void handleTapDown(TapDownInfo info) {
    _inputHandler.touchHandler.handleTapDown(info);
  }

  /// Handle tap up events from the game
  void handleTapUp(TapUpInfo info) {
    _inputHandler.touchHandler.handleTapUp(info);
  }

  /// Handle tap cancel events from the game
  void handleTapCancel() {
    _inputHandler.touchHandler.handleTapCancel();
  }

  /// Handle drag update events from the game
  void handleDragUpdate(DragUpdateInfo info) {
    _inputHandler.touchHandler.handleDragUpdate(info);
  }

  /// Set the game input state
  void setGameInputState(GameInputState state) {
    _gameStateInput.changeState(state);
  }

  /// Get the current game input state
  GameInputState get currentInputState => _gameStateInput.currentState;

  /// Enable or disable input processing
  void setInputEnabled(bool enabled) {
    _gameStateInput.inputEnabled = enabled;
    _inputHandler.isActive = enabled;
  }

  /// Check if input is currently enabled
  bool get isInputEnabled => _gameStateInput.inputEnabled;

  /// Get the cross-platform input handler
  CrossPlatformInputHandler get inputHandler => _inputHandler;

  /// Get input statistics for debugging
  Map<String, dynamic> getInputStats() {
    return {
      'queueSize': _commandQueue.length,
      'inputEnabled': _gameStateInput.inputEnabled,
      'currentState': _gameStateInput.currentState.toString(),
      'lastInputSource': _inputHandler.lastInputSource.toString(),
      'inputEntities': getComponents<InputComponent>().length,
    };
  }

  /// Clear all input state
  void clearInputState() {
    _commandQueue.clear();
    
    final inputComponents = getComponents<InputComponent>();
    for (final inputComponent in inputComponents) {
      inputComponent.clearInputBuffer();
      inputComponent.movementDirection = 0.0;
      inputComponent.isJumpPressed = false;
      inputComponent.isAiming = false;
      inputComponent.shouldLaunch = false;
      inputComponent.pauseRequested = false;
    }
  }

  @override
  void dispose() {
    _gameStateManager?.removeStateChangeCallback(_onGameStateChanged);
    _inputSubscription.cancel();
    _inputHandler.dispose();
    _commandQueue.clear();
    _stateBehaviors.clear();
    super.dispose();
  }
}

/// Defines input behavior for different game states
class InputBehavior {
  final bool allowMovement;
  final bool allowJumping;
  final bool allowAiming;
  final bool allowPause;
  
  const InputBehavior({
    required this.allowMovement,
    required this.allowJumping,
    required this.allowAiming,
    required this.allowPause,
  });
}