import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/domain/input/input_event.dart' as input_events;
import 'package:hard_hat/features/game/domain/input/input_validator.dart';
import 'package:hard_hat/features/game/domain/input/input_sanitizer.dart';
import 'package:hard_hat/features/game/domain/input/input_remapper.dart';
import 'package:hard_hat/features/game/domain/input/accessibility_input_handler.dart';

/// Input system for handling keyboard and touch input with ECS integration
class InputSystem extends GameSystem implements IInputSystem {
  late EntityManager _entityManager;
  
  // Input state
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  Vector2? _mousePosition;
  Vector2? _touchPosition;
  bool _isMousePressed = false;
  bool _isTouchPressed = false;
  
  // Input buffering and command queuing
  final List<InputCommand> _inputCommandQueue = [];
  final Map<String, double> _inputTimers = {};
  static const double inputBufferTime = 0.1; // 100ms buffer
  static const int maxQueueSize = 50;
  
  // Game state management
  GameInputState _currentGameState = GameInputState.playing;
  bool _inputEnabled = true;
  
  // Input source prioritization
  input_events.InputSource _lastInputSource = input_events.InputSource.keyboard;
  final Map<input_events.InputSource, double> _inputSourceTimestamps = {};
  
  // Input validation and sanitization
  final InputValidator _inputValidator = InputValidator();
  final InputSanitizer _inputSanitizer = InputSanitizer();
  
  // Input remapping and configuration
  final InputRemapper _inputRemapper = InputRemapper();
  
  // Accessibility features
  final AccessibilityInputHandler _accessibilityHandler = AccessibilityInputHandler();
  
  // Input callbacks (legacy support)
  void Function(Vector2 direction)? onAimingInput;
  void Function()? onShootInput;
  void Function()? onJumpInput;
  void Function(double direction)? onMovementInput;
  void Function()? onPauseInput;
  
  @override
  int get priority => 1; // Process first to capture input

  @override
  Future<void> initialize() async {
    // Initialize input source timestamps
    _inputSourceTimestamps[input_events.InputSource.keyboard] = 0.0;
    _inputSourceTimestamps[input_events.InputSource.mouse] = 0.0;
    _inputSourceTimestamps[input_events.InputSource.touch] = 0.0;
    _inputSourceTimestamps[input_events.InputSource.gamepad] = 0.0;
    
    // Initialize input remapping with default configuration
    await _inputRemapper.initialize();
    
    // Initialize accessibility features
    await _accessibilityHandler.initialize();
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }
  
  /// Set current game state for input filtering
  void setGameState(GameInputState state) {
    _currentGameState = state;
  }
  
  /// Enable or disable input processing
  void setInputEnabled(bool enabled) {
    _inputEnabled = enabled;
    if (!enabled) {
      _clearInputState();
    }
  }
  
  /// Clear all input state
  void _clearInputState() {
    _pressedKeys.clear();
    _inputCommandQueue.clear();
    _inputTimers.clear();
    _mousePosition = null;
    _touchPosition = null;
    _isMousePressed = false;
    _isTouchPressed = false;
  }

  @override
  void update(double dt) {
    if (!_inputEnabled) return;
    
    // Update accessibility timers
    _accessibilityHandler.update(dt);
    
    // Update input timers
    _updateInputTimers(dt);
    
    // Process input events and generate commands
    _processInputEvents(dt);
    
    // Execute queued input commands
    _executeInputCommands(dt);
    
    // Update entity input components
    _updateEntityInputComponents(dt);
    
    // Clean up expired commands
    _cleanupExpiredCommands();
  }
  
  /// Update input timers for buffering
  void _updateInputTimers(double dt) {
    final keysToRemove = <String>[];
    
    for (final entry in _inputTimers.entries) {
      _inputTimers[entry.key] = entry.value - dt;
      if (_inputTimers[entry.key]! <= 0) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _inputTimers.remove(key);
    }
  }
  
  /// Execute queued input commands
  void _executeInputCommands(double dt) {
    for (final command in _inputCommandQueue) {
      if (command.timestamp + inputBufferTime >= DateTime.now().millisecondsSinceEpoch / 1000.0) {
        _executeCommand(command, dt);
      }
    }
  }
  
  /// Execute a single input command
  void _executeCommand(InputCommand command, double dt) {
    switch (command.type) {
      case InputCommandType.movement:
        _handleMovementCommand(command);
        break;
      case InputCommandType.jump:
        _handleJumpCommand(command);
        break;
      case InputCommandType.aim:
        _handleAimCommand(command);
        break;
      case InputCommandType.shoot:
        _handleShootCommand(command);
        break;
      case InputCommandType.pause:
        _handlePauseCommand(command);
        break;
    }
  }
  
  /// Clean up expired commands from queue
  void _cleanupExpiredCommands() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _inputCommandQueue.removeWhere((command) => 
        command.timestamp + inputBufferTime < currentTime);
    
    // Limit queue size
    if (_inputCommandQueue.length > maxQueueSize) {
      _inputCommandQueue.removeRange(0, _inputCommandQueue.length - maxQueueSize);
    }
  }
  
  /// Update entity input components with current input state
  void _updateEntityInputComponents(double dt) {
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    
    for (final player in players) {
      final inputComponent = player.inputComponent;
      final gameStateComponent = player.getEntityComponent<GameStateInputComponent>();
      
      // Update game state input component if it exists
      if (gameStateComponent != null) {
        gameStateComponent.changeState(_currentGameState);
        if (!gameStateComponent.shouldProcessInput()) continue;
      }
      
      // Update input component based on current input state and game state
      _updatePlayerInputComponent(inputComponent, dt);
      
      // Update input buffering and coyote time
      inputComponent.updateCoyoteTime(player.isOnGround);
      inputComponent.updateJumpBuffer(inputComponent.isJumpPressed);
    }
  }
  
  /// Update a player's input component with validation and sanitization
  void _updatePlayerInputComponent(InputComponent inputComponent, double dt) {
    // Reset frame-specific inputs
    inputComponent.resetFrameInputs();
    
    // Update movement input with validation and sanitization
    if (_shouldProcessMovementInput()) {
      final rawMovement = _getHorizontalInput();
      final validatedMovement = _inputValidator.validateMovementInput(rawMovement);
      final sanitizedMovement = _inputSanitizer.sanitizeMovementInput(validatedMovement);
      inputComponent.movementDirection = sanitizedMovement;
    } else {
      inputComponent.movementDirection = 0.0;
    }
    
    // Update jump input with validation
    if (_shouldProcessJumpInput()) {
      final rawJump = _isJumpInputActive();
      final validatedJump = _inputValidator.validateJumpInput(rawJump);
      inputComponent.isJumpPressed = validatedJump;
    } else {
      inputComponent.isJumpPressed = false;
    }
    
    // Update aiming input with validation and sanitization
    if (_shouldProcessAimingInput()) {
      final rawAiming = _isAimingInputActive();
      final validatedAiming = _inputValidator.validateAimingInput(rawAiming);
      inputComponent.isAiming = validatedAiming;
      
      if (inputComponent.isAiming) {
        final aimPosition = _getAimPosition();
        if (aimPosition != null) {
          final sanitizedPosition = _inputSanitizer.sanitizeAimPosition(aimPosition);
          inputComponent.aimX = sanitizedPosition.x;
          inputComponent.aimY = sanitizedPosition.y;
        }
      }
    } else {
      inputComponent.isAiming = false;
      inputComponent.aimX = null;
      inputComponent.aimY = null;
    }
    
    // Update launch input with validation
    if (_shouldProcessShootInput()) {
      final rawLaunch = _isShootInputActive();
      final validatedLaunch = _inputValidator.validateLaunchInput(rawLaunch);
      inputComponent.shouldLaunch = validatedLaunch;
    } else {
      inputComponent.shouldLaunch = false;
    }
    
    // Update pause input
    inputComponent.pauseRequested = _isPauseInputActive();
    
    // Update last input source
    inputComponent.lastInputSource = _lastInputSource;
  }
  
  /// Check if movement input should be processed based on game state
  bool _shouldProcessMovementInput() {
    return _currentGameState == GameInputState.playing ||
           _currentGameState == GameInputState.aiming;
  }
  
  /// Check if jump input should be processed based on game state
  bool _shouldProcessJumpInput() {
    return _currentGameState == GameInputState.playing;
  }
  
  /// Check if aiming input should be processed based on game state
  bool _shouldProcessAimingInput() {
    return _currentGameState == GameInputState.playing ||
           _currentGameState == GameInputState.aiming;
  }
  
  /// Check if shoot input should be processed based on game state
  bool _shouldProcessShootInput() {
    return _currentGameState == GameInputState.playing ||
           _currentGameState == GameInputState.aiming;
  }
  
  /// Get the current horizontal input value with remapping
  double _getHorizontalInput() {
    double input = 0.0;
    
    // Get remapped keys for movement
    final leftKeys = _inputRemapper.getKeysForAction(InputAction.moveLeft);
    final rightKeys = _inputRemapper.getKeysForAction(InputAction.moveRight);
    
    // Check left movement keys
    for (final key in leftKeys) {
      if (_pressedKeys.contains(key)) {
        input -= 1.0;
        break;
      }
    }
    
    // Check right movement keys
    for (final key in rightKeys) {
      if (_pressedKeys.contains(key)) {
        input += 1.0;
        break;
      }
    }
    
    return input;
  }
  
  /// Check if jump input is currently active with remapping
  bool _isJumpInputActive() {
    final jumpKeys = _inputRemapper.getKeysForAction(InputAction.jump);
    
    for (final key in jumpKeys) {
      if (_pressedKeys.contains(key)) {
        return true;
      }
    }
    
    return _inputTimers.containsKey('jump');
  }
  
  /// Check if aiming input is currently active
  bool _isAimingInputActive() {
    return _isMousePressed || _isTouchPressed;
  }
  
  /// Check if shoot input is currently active with remapping
  bool _isShootInputActive() {
    final shootKeys = _inputRemapper.getKeysForAction(InputAction.shoot);
    
    for (final key in shootKeys) {
      if (_pressedKeys.contains(key)) {
        return true;
      }
    }
    
    return _inputTimers.containsKey('shoot');
  }
  
  /// Check if pause input is currently active with remapping
  bool _isPauseInputActive() {
    final pauseKeys = _inputRemapper.getKeysForAction(InputAction.pause);
    
    for (final key in pauseKeys) {
      if (_pressedKeys.contains(key)) {
        return true;
      }
    }
    
    return _inputTimers.containsKey('pause');
  }
  
  /// Get the current aim position
  Vector2? _getAimPosition() {
    // Prioritize most recent input source
    if (_touchPosition != null && 
        (_inputSourceTimestamps[input_events.InputSource.touch] ?? 0) > 
        (_inputSourceTimestamps[input_events.InputSource.mouse] ?? 0)) {
      return _touchPosition;
    } else if (_mousePosition != null) {
      return _mousePosition;
    }
    
    return null;
  }
  
  /// Queue an input command with timestamp
  void _queueInputCommand(InputCommandType type, {Map<String, dynamic>? data}) {
    final command = InputCommand(
      type: type,
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      source: _lastInputSource,
      data: data ?? {},
    );
    
    _inputCommandQueue.add(command);
  }
  
  /// Handle movement command
  void _handleMovementCommand(InputCommand command) {
    final direction = command.data['direction'] as double? ?? 0.0;
    onMovementInput?.call(direction);
  }
  
  /// Handle jump command
  void _handleJumpCommand(InputCommand command) {
    _inputTimers['jump'] = inputBufferTime;
    onJumpInput?.call();
  }
  
  /// Handle aim command
  void _handleAimCommand(InputCommand command) {
    final direction = command.data['direction'] as Vector2?;
    if (direction != null) {
      onAimingInput?.call(direction);
    }
  }
  
  /// Handle shoot command
  void _handleShootCommand(InputCommand command) {
    _inputTimers['shoot'] = inputBufferTime;
    onShootInput?.call();
  }
  
  /// Handle pause command
  void _handlePauseCommand(InputCommand command) {
    _inputTimers['pause'] = inputBufferTime;
    onPauseInput?.call();
  }
  
  @override
  void handleKeyEvent(dynamic event, Set<dynamic> keysPressed) {
    if (event is KeyEvent) {
      _updateInputSource(input_events.InputSource.keyboard);
      onKeyEvent(event, keysPressed as Set<LogicalKeyboardKey>);
    }
  }
  
  @override
  void processInputEvents(double dt) {
    _processInputEvents(dt);
  }
  
  /// Update the last input source and timestamp
  void _updateInputSource(input_events.InputSource source) {
    _lastInputSource = source;
    _inputSourceTimestamps[source] = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }
  
  /// Process input events and generate commands
  void _processInputEvents(double dt) {
    _processKeyboardInput(dt);
    _processMouseInput(dt);
    _processTouchInput(dt);
    _processGamepadInput(dt);
  }
  
  /// Process keyboard input with enhanced validation
  void _processKeyboardInput(double dt) {
    if (!_inputEnabled) return;
    
    // Apply accessibility modifications
    final modifiedKeys = _accessibilityHandler.processKeyboardInput(_pressedKeys);
    
    // Movement input
    double horizontalInput = 0.0;
    
    final leftKeys = _inputRemapper.getKeysForAction(InputAction.moveLeft);
    final rightKeys = _inputRemapper.getKeysForAction(InputAction.moveRight);
    
    // Check left movement
    for (final key in leftKeys) {
      if (modifiedKeys.contains(key)) {
        horizontalInput -= 1.0;
        break;
      }
    }
    
    // Check right movement
    for (final key in rightKeys) {
      if (modifiedKeys.contains(key)) {
        horizontalInput += 1.0;
        break;
      }
    }
    
    // Queue movement command if there's input
    if (horizontalInput != 0.0) {
      _queueInputCommand(InputCommandType.movement, data: {'direction': horizontalInput});
    }
    
    // Jump input
    final jumpKeys = _inputRemapper.getKeysForAction(InputAction.jump);
    for (final key in jumpKeys) {
      if (modifiedKeys.contains(key)) {
        _queueInputCommand(InputCommandType.jump);
        break;
      }
    }
    
    // Shoot/Strike input
    final shootKeys = _inputRemapper.getKeysForAction(InputAction.shoot);
    for (final key in shootKeys) {
      if (modifiedKeys.contains(key)) {
        _queueInputCommand(InputCommandType.shoot);
        break;
      }
    }
    
    // Pause input
    final pauseKeys = _inputRemapper.getKeysForAction(InputAction.pause);
    for (final key in pauseKeys) {
      if (modifiedKeys.contains(key)) {
        _queueInputCommand(InputCommandType.pause);
        break;
      }
    }
  }
  
  /// Process mouse input for aiming
  void _processMouseInput(double dt) {
    if (!_inputEnabled || _mousePosition == null) return;
    
    if (_isMousePressed) {
      final sanitizedPosition = _inputSanitizer.sanitizeAimPosition(_mousePosition!);
      _processAimingInput(sanitizedPosition);
    }
  }
  
  /// Process touch input for mobile with accessibility support
  void _processTouchInput(double dt) {
    if (!_inputEnabled || _touchPosition == null) return;
    
    if (_isTouchPressed) {
      final accessiblePosition = _accessibilityHandler.processTouchInput(_touchPosition!);
      final sanitizedPosition = _inputSanitizer.sanitizeAimPosition(accessiblePosition);
      _processAimingInput(sanitizedPosition);
    }
  }
  
  /// Process gamepad input (enhanced implementation)
  void _processGamepadInput(double dt) {
    // Enhanced gamepad input processing would go here
    // This includes deadzone handling, button remapping, and accessibility features
  }
  
  /// Process aiming input from mouse or touch
  void _processAimingInput(Vector2 screenPosition) {
    // Find ball entity for aiming
    final balls = _entityManager.getEntitiesOfType<BallEntity>();
    if (balls.isEmpty) return;
    
    final ball = balls.first;
    if (!ball.isTracking) return;
    
    // Calculate direction from ball to cursor/touch
    final ballPosition = ball.positionComponent.position + Vector2(BallEntity.ballRadius, BallEntity.ballRadius);
    final direction = (screenPosition - ballPosition).normalized();
    
    // Queue aiming command
    _queueInputCommand(InputCommandType.aim, data: {'direction': direction});
  }
  
  /// Handle key down events
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _updateInputSource(input_events.InputSource.keyboard);
    
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // Handle pause immediately for responsiveness
      final pauseKeys = _inputRemapper.getKeysForAction(InputAction.pause);
      if (pauseKeys.contains(event.logicalKey)) {
        _queueInputCommand(InputCommandType.pause);
        return true;
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    
    return false;
  }
  
  /// Handle mouse move events
  void onMouseMove(Vector2 position) {
    _updateInputSource(input_events.InputSource.mouse);
    _mousePosition = _inputSanitizer.sanitizeAimPosition(position);
  }
  
  /// Handle mouse button events
  void onMouseButton(Vector2 position, bool pressed) {
    _updateInputSource(input_events.InputSource.mouse);
    _mousePosition = _inputSanitizer.sanitizeAimPosition(position);
    _isMousePressed = pressed;
    
    if (pressed) {
      _queueInputCommand(InputCommandType.shoot);
    }
  }
  
  /// Handle touch events
  void onTouchStart(Vector2 position) {
    _updateInputSource(input_events.InputSource.touch);
    final accessiblePosition = _accessibilityHandler.processTouchInput(position);
    _touchPosition = _inputSanitizer.sanitizeAimPosition(accessiblePosition);
    _isTouchPressed = true;
  }
  
  /// Handle touch move events
  void onTouchMove(Vector2 position) {
    _updateInputSource(input_events.InputSource.touch);
    final accessiblePosition = _accessibilityHandler.processTouchInput(position);
    _touchPosition = _inputSanitizer.sanitizeAimPosition(accessiblePosition);
  }
  
  /// Handle touch end events
  void onTouchEnd() {
    _isTouchPressed = false;
    _queueInputCommand(InputCommandType.shoot);
  }
  
  // Public API methods for input configuration
  
  /// Configure input remapping
  void configureInputRemapping(Map<InputAction, List<LogicalKeyboardKey>> mapping) {
    _inputRemapper.setCustomMapping(mapping);
  }
  
  /// Enable/disable accessibility features
  void setAccessibilityEnabled(bool enabled) {
    _accessibilityHandler.setEnabled(enabled);
  }
  
  /// Configure accessibility settings
  void configureAccessibility(AccessibilitySettings settings) {
    _accessibilityHandler.configure(settings);
  }
  
  /// Get current input configuration
  Map<String, dynamic> getInputConfiguration() {
    return {
      'remapping': _inputRemapper.getCurrentMapping(),
      'accessibility': _accessibilityHandler.getSettings(),
      'validation': _inputValidator.getSettings(),
      'sanitization': _inputSanitizer.getSettings(),
    };
  }
  
  /// Load input configuration from settings
  void loadInputConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('remapping')) {
      _inputRemapper.loadMapping(config['remapping']);
    }
    if (config.containsKey('accessibility')) {
      _accessibilityHandler.loadSettings(config['accessibility']);
    }
    if (config.containsKey('validation')) {
      _inputValidator.loadSettings(config['validation']);
    }
    if (config.containsKey('sanitization')) {
      _inputSanitizer.loadSettings(config['sanitization']);
    }
  }
  
  // Legacy getters for backward compatibility
  
  /// Check if a key is currently pressed
  bool isKeyPressed(LogicalKeyboardKey key) {
    return _pressedKeys.contains(key);
  }
  
  /// Get current mouse position
  Vector2? get mousePosition => _mousePosition;
  
  /// Get current touch position
  Vector2? get touchPosition => _touchPosition;
  
  /// Check if mouse is pressed
  bool get isMousePressed => _isMousePressed;
  
  /// Check if touch is active
  bool get isTouchPressed => _isTouchPressed;
  
  /// Get horizontal movement input (-1.0 to 1.0)
  double get horizontalInput => _getHorizontalInput();
  
  /// Check if jump is pressed
  bool get isJumpPressed => _isJumpInputActive();
  
  /// Check if strike is pressed
  bool get isStrikePressed => _isShootInputActive();
  
  // Test-specific methods for backward compatibility
  
  /// Check if input is enabled (for tests)
  bool get isInputEnabled => _inputEnabled;
  
  /// Get current input state (for tests)
  GameInputState get currentInputState => _currentGameState;
  
  /// Set game input state (for tests)
  void setGameInputState(GameInputState state) {
    setGameState(state);
  }
  
  /// Clear input state (for tests)
  void clearInputState() {
    _clearInputState();
  }
  
  /// Get input statistics (for tests)
  Map<String, dynamic> getInputStats() {
    return {
      'queueSize': _inputCommandQueue.length,
      'pressedKeys': _pressedKeys.length,
      'timers': _inputTimers.length,
      'lastInputSource': _lastInputSource.toString(),
    };
  }
  
  /// Get input handler (for tests) - mock object
  MockInputHandler get inputHandler => MockInputHandler(this);

  @override
  void dispose() {
    _pressedKeys.clear();
    _inputCommandQueue.clear();
    _inputTimers.clear();
    _inputSourceTimestamps.clear();
    _inputRemapper.dispose();
    _accessibilityHandler.dispose();
    // Note: GameSystem doesn't have dispose method, so we don't call super.dispose()
  }
}

/// Mock input handler for test compatibility
class MockInputHandler {
  final InputSystem _inputSystem;
  
  MockInputHandler(this._inputSystem);
  
  MockKeyboardHandler get keyboardHandler => MockKeyboardHandler(_inputSystem);
  
  /// Mock method for testing input source prioritization
  bool shouldPrioritize(input_events.InputSource source1, input_events.InputSource source2) {
    // Simple priority order: keyboard > touch > gamepad > mouse
    const priorityOrder = {
      input_events.InputSource.keyboard: 3,
      input_events.InputSource.touch: 2,
      input_events.InputSource.gamepad: 1,
      input_events.InputSource.mouse: 0,
    };
    
    final priority1 = priorityOrder[source1] ?? 0;
    final priority2 = priorityOrder[source2] ?? 0;
    
    return priority1 > priority2;
  }
}

/// Mock keyboard handler for test compatibility
class MockKeyboardHandler {
  final InputSystem _inputSystem;
  
  MockKeyboardHandler(this._inputSystem);
  
  void handleKeyDown(LogicalKeyboardKey key) {
    _inputSystem._pressedKeys.add(key);
  }
  
  void handleKeyUp(LogicalKeyboardKey key) {
    _inputSystem._pressedKeys.remove(key);
  }
}

/// Input command for queuing and buffering
class InputCommand {
  final InputCommandType type;
  final double timestamp;
  final input_events.InputSource source;
  final Map<String, dynamic> data;
  
  InputCommand({
    required this.type,
    required this.timestamp,
    required this.source,
    required this.data,
  });
}

/// Types of input commands
enum InputCommandType {
  movement,
  jump,
  aim,
  shoot,
  pause,
}