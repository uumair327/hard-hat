import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Input system for handling keyboard and touch input
class InputSystem extends GameSystem implements IInputSystem {
  late EntityManager _entityManager;
  
  // Input state
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  Vector2? _mousePosition;
  Vector2? _touchPosition;
  bool _isMousePressed = false;
  bool _isTouchPressed = false;
  
  // Input callbacks
  void Function(Vector2 direction)? onAimingInput;
  void Function()? onShootInput;
  void Function()? onJumpInput;
  void Function(double direction)? onMovementInput;
  void Function()? onPauseInput;
  
  @override
  int get priority => 1; // Process first to capture input

  @override
  Future<void> initialize() async {
    // Input system initialization
  }

  /// Set entity manager
  void setEntityManager(EntityManager entityManager) {
    _entityManager = entityManager;
  }

  @override
  void update(double dt) {
    processInputEvents(dt);
  }
  
  @override
  void handleKeyEvent(dynamic event, Set<dynamic> keysPressed) {
    if (event is KeyEvent && keysPressed is Set<LogicalKeyboardKey>) {
      onKeyEvent(event, keysPressed);
    }
  }
  
  @override
  void processInputEvents(double dt) {
    _processKeyboardInput(dt);
    _processMouseInput(dt);
    _processTouchInput(dt);
    _updatePlayerInput(dt);
    _updateBallInput(dt);
  }
  
  /// Process keyboard input
  void _processKeyboardInput(double dt) {
    // Movement input
    double horizontalInput = 0.0;
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
        _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      horizontalInput -= 1.0;
    }
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
        _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      horizontalInput += 1.0;
    }
    
    // Send movement input
    if (horizontalInput != 0.0) {
      onMovementInput?.call(horizontalInput);
    }
    
    // Jump input
    if (_pressedKeys.contains(LogicalKeyboardKey.space) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      onJumpInput?.call();
    }
    
    // Shoot/Strike input
    if (_pressedKeys.contains(LogicalKeyboardKey.keyX) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyZ) ||
        _pressedKeys.contains(LogicalKeyboardKey.enter)) {
      onShootInput?.call();
    }
    
    // Pause input
    if (_pressedKeys.contains(LogicalKeyboardKey.escape)) {
      onPauseInput?.call();
    }
  }
  
  /// Process mouse input for aiming
  void _processMouseInput(double dt) {
    if (_mousePosition != null) {
      _processAimingInput(_mousePosition!);
    }
  }
  
  /// Process touch input for mobile
  void _processTouchInput(double dt) {
    if (_touchPosition != null) {
      _processAimingInput(_touchPosition!);
    }
  }
  
  /// Process aiming input from mouse or touch
  void _processAimingInput(Vector2 screenPosition) {
    // Find ball entity for aiming
    final balls = _entityManager.getEntitiesOfType<BallEntity>();
    if (balls.isEmpty) return;
    
    final ball = balls.first;
    if (!ball.isTracking) return;
    
    // Calculate direction from ball to cursor/touch
    final ballPosition = ball.positionComponent!.position + Vector2(BallEntity.ballRadius, BallEntity.ballRadius);
    final direction = (screenPosition - ballPosition).normalized();
    
    // Send aiming input
    onAimingInput?.call(direction);
  }
  
  /// Update player input components
  void _updatePlayerInput(double dt) {
    final players = _entityManager.getEntitiesOfType<PlayerEntity>();
    
    for (final player in players) {
      final inputComponent = player.inputComponent;
      
      // Update movement input
      double horizontalInput = 0.0;
      
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
          _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        horizontalInput -= 1.0;
      }
      
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
          _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        horizontalInput += 1.0;
      }
      
      inputComponent.movementDirection = horizontalInput;
      inputComponent.canMove = horizontalInput != 0.0;
      
      // Update jump input
      final jumpPressed = _pressedKeys.contains(LogicalKeyboardKey.space) ||
                         _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
                         _pressedKeys.contains(LogicalKeyboardKey.keyW);
      
      inputComponent.isJumpPressed = jumpPressed;
      inputComponent.canJump = jumpPressed;
      
      // Update strike input (placeholder for future implementation)
      // Note: These properties would need to be added to PlayerInputComponent
      // final strikePressed = _pressedKeys.contains(LogicalKeyboardKey.keyX) ||
      //                      _pressedKeys.contains(LogicalKeyboardKey.keyZ) ||
      //                      _pressedKeys.contains(LogicalKeyboardKey.enter);
    }
  }
  
  /// Update ball input for aiming
  void _updateBallInput(double dt) {
    final balls = _entityManager.getEntitiesOfType<BallEntity>();
    
    for (final ball in balls) {
      if (!ball.isTracking) continue;
      
      Vector2? aimPosition;
      
      // Use mouse position if available
      if (_mousePosition != null) {
        aimPosition = _mousePosition;
      }
      // Otherwise use touch position
      else if (_touchPosition != null) {
        aimPosition = _touchPosition;
      }
      
      if (aimPosition != null) {
        final ballPosition = ball.positionComponent!.position + Vector2(BallEntity.ballRadius, BallEntity.ballRadius);
        final direction = (aimPosition - ballPosition).normalized();
        ball.setDirection(direction);
      }
    }
  }
  
  /// Handle key down events
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // Handle pause immediately
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        onPauseInput?.call();
        return true;
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    
    return false;
  }
  
  /// Handle mouse move events
  void onMouseMove(Vector2 position) {
    _mousePosition = position;
  }
  
  /// Handle mouse button events
  void onMouseButton(Vector2 position, bool pressed) {
    _mousePosition = position;
    _isMousePressed = pressed;
    
    if (pressed) {
      onShootInput?.call();
    }
  }
  
  /// Handle touch events
  void onTouchStart(Vector2 position) {
    _touchPosition = position;
    _isTouchPressed = true;
  }
  
  /// Handle touch move events
  void onTouchMove(Vector2 position) {
    _touchPosition = position;
  }
  
  /// Handle touch end events
  void onTouchEnd() {
    _isTouchPressed = false;
    onShootInput?.call();
  }
  
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
  double get horizontalInput {
    double input = 0.0;
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
        _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      input -= 1.0;
    }
    
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
        _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      input += 1.0;
    }
    
    return input;
  }
  
  /// Check if jump is pressed
  bool get isJumpPressed {
    return _pressedKeys.contains(LogicalKeyboardKey.space) ||
           _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
           _pressedKeys.contains(LogicalKeyboardKey.keyW);
  }
  
  /// Check if strike is pressed
  bool get isStrikePressed {
    return _pressedKeys.contains(LogicalKeyboardKey.keyX) ||
           _pressedKeys.contains(LogicalKeyboardKey.keyZ) ||
           _pressedKeys.contains(LogicalKeyboardKey.enter);
  }

  @override
  void dispose() {
    _pressedKeys.clear();
    super.dispose();
  }
}