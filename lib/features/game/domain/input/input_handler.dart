import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flame/events.dart';
import 'input_event.dart';

/// Abstract base class for input handlers
abstract class InputHandler {
  /// Stream of input events
  Stream<InputEvent> get inputStream;

  /// Initialize the input handler
  Future<void> initialize();

  /// Dispose of the input handler
  void dispose();

  /// Check if this handler is currently active
  bool get isActive;

  /// Set the active state of this handler
  set isActive(bool value);
}

/// Handles keyboard input events
class KeyboardInputHandler extends InputHandler {
  final StreamController<InputEvent> _inputController = StreamController<InputEvent>.broadcast();
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  bool _isActive = true;

  @override
  Stream<InputEvent> get inputStream => _inputController.stream;

  @override
  bool get isActive => _isActive;

  @override
  set isActive(bool value) => _isActive = value;

  @override
  Future<void> initialize() async {
    // Keyboard input is handled through the game's HasKeyboardHandlerComponents mixin
    // This handler processes the events and converts them to game input events
  }

  /// Handle keyboard key down events
  void handleKeyDown(LogicalKeyboardKey key) {
    if (!_isActive) return;

    _pressedKeys.add(key);
    final command = KeyboardMapping.getCommand(key);
    if (command == null) return;

    final timestamp = DateTime.now();
    
    switch (command) {
      case InputCommand.moveLeft:
        _inputController.add(MovementInputEvent(
          direction: -1.0,
          source: InputSource.keyboard,
          timestamp: timestamp,
        ));
        break;
      case InputCommand.moveRight:
        _inputController.add(MovementInputEvent(
          direction: 1.0,
          source: InputSource.keyboard,
          timestamp: timestamp,
        ));
        break;
      case InputCommand.jump:
        _inputController.add(JumpInputEvent(
          isPressed: true,
          source: InputSource.keyboard,
          timestamp: timestamp,
        ));
        break;
      case InputCommand.pause:
        _inputController.add(PauseInputEvent(
          source: InputSource.keyboard,
          timestamp: timestamp,
        ));
        break;
      default:
        break;
    }
  }

  /// Handle keyboard key up events
  void handleKeyUp(LogicalKeyboardKey key) {
    if (!_isActive) return;

    _pressedKeys.remove(key);
    final command = KeyboardMapping.getCommand(key);
    if (command == null) return;

    final timestamp = DateTime.now();
    
    switch (command) {
      case InputCommand.moveLeft:
      case InputCommand.moveRight:
        // Check if any movement keys are still pressed
        final leftPressed = _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
                           _pressedKeys.contains(LogicalKeyboardKey.keyA);
        final rightPressed = _pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
                            _pressedKeys.contains(LogicalKeyboardKey.keyD);
        
        double direction = 0.0;
        if (leftPressed && !rightPressed) {
          direction = -1.0;
        } else if (rightPressed && !leftPressed) {
          direction = 1.0;
        }
        
        _inputController.add(MovementInputEvent(
          direction: direction,
          source: InputSource.keyboard,
          timestamp: timestamp,
        ));
        break;
      case InputCommand.jump:
        _inputController.add(JumpInputEvent(
          isPressed: false,
          source: InputSource.keyboard,
          timestamp: timestamp,
        ));
        break;
      default:
        break;
    }
  }

  /// Get currently pressed keys
  Set<LogicalKeyboardKey> get pressedKeys => Set.unmodifiable(_pressedKeys);

  /// Check if a specific key is currently pressed
  bool isKeyPressed(LogicalKeyboardKey key) {
    return _pressedKeys.contains(key);
  }

  @override
  void dispose() {
    _inputController.close();
    _pressedKeys.clear();
  }
}

/// Handles touch input events
class TouchInputHandler extends InputHandler {
  final StreamController<InputEvent> _inputController = StreamController<InputEvent>.broadcast();
  bool _isActive = true;
  bool _isAiming = false;
  double? _aimStartX;
  double? _aimStartY;

  @override
  Stream<InputEvent> get inputStream => _inputController.stream;

  @override
  bool get isActive => _isActive;

  @override
  set isActive(bool value) => _isActive = value;

  @override
  Future<void> initialize() async {
    // Touch input is handled through the game's HasTappableComponents mixin
    // This handler processes the events and converts them to game input events
  }

  /// Handle tap down events
  void handleTapDown(TapDownInfo info) {
    if (!_isActive) return;

    final timestamp = DateTime.now();
    final position = info.eventPosition.global;

    // Start aiming
    _isAiming = true;
    _aimStartX = position.x;
    _aimStartY = position.y;

    _inputController.add(AimInputEvent(
      isAiming: true,
      aimX: position.x,
      aimY: position.y,
      source: InputSource.touch,
      timestamp: timestamp,
    ));
  }

  /// Handle tap up events
  void handleTapUp(TapUpInfo info) {
    if (!_isActive || !_isAiming) return;

    final timestamp = DateTime.now();
    final position = info.eventPosition.global;

    // Calculate launch direction and power
    if (_aimStartX != null && _aimStartY != null) {
      final deltaX = position.x - _aimStartX!;
      final deltaY = position.y - _aimStartY!;
      final distance = sqrt(deltaX * deltaX + deltaY * deltaY);
      
      // Normalize direction
      final directionX = distance > 0 ? deltaX / distance : 0.0;
      final directionY = distance > 0 ? deltaY / distance : 0.0;
      
      // Calculate power based on distance (max 100 pixels = full power)
      final power = (distance / 100.0).clamp(0.0, 1.0);

      _inputController.add(LaunchInputEvent(
        directionX: directionX,
        directionY: directionY,
        power: power,
        source: InputSource.touch,
        timestamp: timestamp,
      ));
    }

    // End aiming
    _isAiming = false;
    _aimStartX = null;
    _aimStartY = null;

    _inputController.add(AimInputEvent(
      isAiming: false,
      source: InputSource.touch,
      timestamp: timestamp,
    ));
  }

  /// Handle tap cancel events
  void handleTapCancel() {
    if (!_isActive) return;

    final timestamp = DateTime.now();

    // Cancel aiming
    _isAiming = false;
    _aimStartX = null;
    _aimStartY = null;

    _inputController.add(AimInputEvent(
      isAiming: false,
      source: InputSource.touch,
      timestamp: timestamp,
    ));
  }

  /// Handle drag update events for continuous aiming
  void handleDragUpdate(DragUpdateInfo info) {
    if (!_isActive || !_isAiming) return;

    final timestamp = DateTime.now();
    final position = info.eventPosition.global;

    _inputController.add(AimInputEvent(
      isAiming: true,
      aimX: position.x,
      aimY: position.y,
      source: InputSource.touch,
      timestamp: timestamp,
    ));
  }

  /// Handle swipe gestures for movement
  void handleSwipe(double velocityX, double velocityY) {
    if (!_isActive) return;

    final timestamp = DateTime.now();
    
    // Horizontal swipes for movement
    if (velocityX.abs() > velocityY.abs()) {
      final direction = velocityX > 0 ? 1.0 : -1.0;
      _inputController.add(MovementInputEvent(
        direction: direction,
        source: InputSource.touch,
        timestamp: timestamp,
      ));
      
      // Stop movement after a short delay
      Timer(const Duration(milliseconds: 200), () {
        _inputController.add(MovementInputEvent(
          direction: 0.0,
          source: InputSource.touch,
          timestamp: DateTime.now(),
        ));
      });
    }
    
    // Upward swipes for jumping
    if (velocityY < -500) { // Negative Y is upward
      _inputController.add(JumpInputEvent(
        isPressed: true,
        source: InputSource.touch,
        timestamp: timestamp,
      ));
    }
  }

  @override
  void dispose() {
    _inputController.close();
    _isAiming = false;
    _aimStartX = null;
    _aimStartY = null;
  }
}

/// Handles gamepad input events
class GamepadInputHandler extends InputHandler {
  final StreamController<InputEvent> _inputController = StreamController<InputEvent>.broadcast();
  final Set<int> _pressedButtons = <int>{};
  bool _isActive = true;
  double _leftStickX = 0.0;
  double _leftStickY = 0.0;
  double _rightStickX = 0.0;
  double _rightStickY = 0.0;

  @override
  Stream<InputEvent> get inputStream => _inputController.stream;

  @override
  bool get isActive => _isActive;

  @override
  set isActive(bool value) => _isActive = value;

  @override
  Future<void> initialize() async {
    // Gamepad input would be handled through a gamepad plugin
    // For now, this is a placeholder implementation
  }

  /// Handle gamepad button press events
  void handleButtonDown(int buttonId) {
    if (!_isActive) return;

    _pressedButtons.add(buttonId);
    final command = GamepadMapping.getCommand(buttonId);
    if (command == null) return;

    final timestamp = DateTime.now();
    
    switch (command) {
      case InputCommand.jump:
        _inputController.add(JumpInputEvent(
          isPressed: true,
          source: InputSource.gamepad,
          timestamp: timestamp,
        ));
        break;
      case InputCommand.launch:
        // Use right stick for aiming direction
        _inputController.add(LaunchInputEvent(
          directionX: _rightStickX,
          directionY: _rightStickY,
          power: 1.0, // Full power for gamepad
          source: InputSource.gamepad,
          timestamp: timestamp,
        ));
        break;
      case InputCommand.pause:
        _inputController.add(PauseInputEvent(
          source: InputSource.gamepad,
          timestamp: timestamp,
        ));
        break;
      default:
        break;
    }
  }

  /// Handle gamepad button release events
  void handleButtonUp(int buttonId) {
    if (!_isActive) return;

    _pressedButtons.remove(buttonId);
    final command = GamepadMapping.getCommand(buttonId);
    if (command == null) return;

    final timestamp = DateTime.now();
    
    switch (command) {
      case InputCommand.jump:
        _inputController.add(JumpInputEvent(
          isPressed: false,
          source: InputSource.gamepad,
          timestamp: timestamp,
        ));
        break;
      default:
        break;
    }
  }

  /// Handle analog stick movement
  void handleStickMovement({
    double? leftX,
    double? leftY,
    double? rightX,
    double? rightY,
  }) {
    if (!_isActive) return;

    final timestamp = DateTime.now();
    
    // Update stick positions
    if (leftX != null) _leftStickX = leftX;
    if (leftY != null) _leftStickY = leftY;
    if (rightX != null) _rightStickX = rightX;
    if (rightY != null) _rightStickY = rightY;

    // Left stick for movement
    if (leftX != null) {
      _inputController.add(MovementInputEvent(
        direction: leftX,
        source: InputSource.gamepad,
        timestamp: timestamp,
      ));
    }

    // Right stick for aiming
    if (rightX != null || rightY != null) {
      final isAiming = _rightStickX.abs() > 0.1 || _rightStickY.abs() > 0.1;
      _inputController.add(AimInputEvent(
        isAiming: isAiming,
        aimX: _rightStickX,
        aimY: _rightStickY,
        source: InputSource.gamepad,
        timestamp: timestamp,
      ));
    }
  }

  /// Get currently pressed buttons
  Set<int> get pressedButtons => Set.unmodifiable(_pressedButtons);

  /// Check if a specific button is currently pressed
  bool isButtonPressed(int buttonId) {
    return _pressedButtons.contains(buttonId);
  }

  @override
  void dispose() {
    _inputController.close();
    _pressedButtons.clear();
    _leftStickX = 0.0;
    _leftStickY = 0.0;
    _rightStickX = 0.0;
    _rightStickY = 0.0;
  }
}

/// Cross-platform input handler that manages multiple input sources
class CrossPlatformInputHandler extends InputHandler {
  final KeyboardInputHandler _keyboardHandler = KeyboardInputHandler();
  final TouchInputHandler _touchHandler = TouchInputHandler();
  final GamepadInputHandler _gamepadHandler = GamepadInputHandler();
  
  final StreamController<InputEvent> _inputController = StreamController<InputEvent>.broadcast();
  late final StreamSubscription _keyboardSubscription;
  late final StreamSubscription _touchSubscription;
  late final StreamSubscription _gamepadSubscription;
  
  bool _isActive = true;
  InputSource _lastInputSource = InputSource.keyboard;
  final Map<InputSource, int> _inputPriority = {
    InputSource.keyboard: 1,
    InputSource.touch: 2,
    InputSource.gamepad: 3,
  };

  @override
  Stream<InputEvent> get inputStream => _inputController.stream;

  @override
  bool get isActive => _isActive;

  @override
  set isActive(bool value) {
    _isActive = value;
    _keyboardHandler.isActive = value;
    _touchHandler.isActive = value;
    _gamepadHandler.isActive = value;
  }

  @override
  Future<void> initialize() async {
    await _keyboardHandler.initialize();
    await _touchHandler.initialize();
    await _gamepadHandler.initialize();

    // Subscribe to all input handlers
    _keyboardSubscription = _keyboardHandler.inputStream.listen(_handleInputEvent);
    _touchSubscription = _touchHandler.inputStream.listen(_handleInputEvent);
    _gamepadSubscription = _gamepadHandler.inputStream.listen(_handleInputEvent);
  }

  /// Handle input events from all sources with prioritization
  void _handleInputEvent(InputEvent event) {
    if (!_isActive) return;

    // Update last input source for prioritization
    if (event is MovementInputEvent) {
      _lastInputSource = event.source;
    } else if (event is JumpInputEvent) {
      _lastInputSource = event.source;
    } else if (event is AimInputEvent) {
      _lastInputSource = event.source;
    } else if (event is LaunchInputEvent) {
      _lastInputSource = event.source;
    } else if (event is PauseInputEvent) {
      _lastInputSource = event.source;
    }

    // Forward the event
    _inputController.add(event);
  }

  /// Get the keyboard input handler
  KeyboardInputHandler get keyboardHandler => _keyboardHandler;

  /// Get the touch input handler
  TouchInputHandler get touchHandler => _touchHandler;

  /// Get the gamepad input handler
  GamepadInputHandler get gamepadHandler => _gamepadHandler;

  /// Get the last input source used
  InputSource get lastInputSource => _lastInputSource;

  /// Get input priority for a source (lower number = higher priority)
  int getInputPriority(InputSource source) {
    return _inputPriority[source] ?? 999;
  }

  /// Check if an input source should be prioritized over another
  bool shouldPrioritize(InputSource newSource, InputSource currentSource) {
    return getInputPriority(newSource) <= getInputPriority(currentSource);
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _touchSubscription.cancel();
    _gamepadSubscription.cancel();
    
    _keyboardHandler.dispose();
    _touchHandler.dispose();
    _gamepadHandler.dispose();
    
    _inputController.close();
  }
}