import 'package:flame/components.dart';
import 'input_event.dart';

/// Component that stores input state for entities
class InputComponent extends Component {
  /// Current movement direction (-1.0 to 1.0)
  double movementDirection = 0.0;
  
  /// Whether jump is currently pressed
  bool isJumpPressed = false;
  
  /// Whether the entity is currently aiming
  bool isAiming = false;
  
  /// Aim position (screen coordinates)
  double? aimX;
  double? aimY;
  
  /// Whether a launch command was issued this frame
  bool shouldLaunch = false;
  
  /// Launch direction and power
  double launchDirectionX = 0.0;
  double launchDirectionY = 0.0;
  double launchPower = 0.0;
  
  /// Whether pause was requested this frame
  bool pauseRequested = false;
  
  /// Last input source used
  InputSource lastInputSource = InputSource.keyboard;
  
  /// Input buffer for storing recent inputs
  final List<InputEvent> _inputBuffer = [];
  static const int maxBufferSize = 10;
  
  /// Add an input event to the buffer
  void addInputEvent(InputEvent event) {
    _inputBuffer.add(event);
    if (_inputBuffer.length > maxBufferSize) {
      _inputBuffer.removeAt(0);
    }
  }
  
  /// Get recent input events
  List<InputEvent> getRecentInputs() {
    return List.unmodifiable(_inputBuffer);
  }
  
  /// Clear the input buffer
  void clearInputBuffer() {
    _inputBuffer.clear();
  }
  
  /// Reset frame-specific input flags
  void resetFrameInputs() {
    shouldLaunch = false;
    pauseRequested = false;
  }
  
  /// Check if any movement input is active
  bool get hasMovementInput => movementDirection.abs() > 0.01;
  
  /// Check if any input is active
  bool get hasAnyInput => 
      hasMovementInput || 
      isJumpPressed || 
      isAiming || 
      shouldLaunch || 
      pauseRequested;
}

/// Component for entities that can receive input (typically the player)
class PlayerInputComponent extends InputComponent {
  /// Whether the player can currently move
  bool canMove = true;
  
  /// Whether the player can currently jump
  bool canJump = true;
  
  /// Whether the player can currently aim/launch
  bool canAim = true;
  
  /// Movement speed multiplier
  double movementSpeedMultiplier = 1.0;
  
  /// Jump force multiplier
  double jumpForceMultiplier = 1.0;
  
  /// Coyote time for jumping (frames after leaving ground where jump is still allowed)
  int coyoteTimeFrames = 6;
  int _framesSinceGrounded = 0;
  
  /// Jump buffering (frames before landing where jump input is remembered)
  int jumpBufferFrames = 6;
  int _framesWithJumpBuffer = 0;
  
  /// Update coyote time
  void updateCoyoteTime(bool isGrounded) {
    if (isGrounded) {
      _framesSinceGrounded = 0;
    } else {
      _framesSinceGrounded++;
    }
  }
  
  /// Update jump buffer
  void updateJumpBuffer(bool jumpPressed) {
    if (jumpPressed) {
      _framesWithJumpBuffer = jumpBufferFrames;
    } else if (_framesWithJumpBuffer > 0) {
      _framesWithJumpBuffer--;
    }
  }
  
  /// Check if jump is allowed (considering coyote time)
  bool canJumpWithCoyoteTime() {
    return canJump && _framesSinceGrounded <= coyoteTimeFrames;
  }
  
  /// Check if jump buffer is active
  bool hasJumpBuffer() {
    return _framesWithJumpBuffer > 0;
  }
  
  /// Consume jump buffer
  void consumeJumpBuffer() {
    _framesWithJumpBuffer = 0;
  }
  
  @override
  void resetFrameInputs() {
    super.resetFrameInputs();
    // Don't reset jump buffer here as it persists across frames
  }
}

/// Component for managing input state across different game states
class GameStateInputComponent extends Component {
  /// Current game state that affects input handling
  GameInputState currentState = GameInputState.playing;
  
  /// Previous game state
  GameInputState previousState = GameInputState.playing;
  
  /// Whether input is currently enabled
  bool inputEnabled = true;
  
  /// Input state transition timestamp
  DateTime? lastStateChange;
  
  /// Change the input state
  void changeState(GameInputState newState) {
    if (newState != currentState) {
      previousState = currentState;
      currentState = newState;
      lastStateChange = DateTime.now();
    }
  }
  
  /// Check if input should be processed based on current state
  bool shouldProcessInput() {
    return inputEnabled && currentState != GameInputState.paused;
  }
  
  /// Check if movement input should be processed
  bool shouldProcessMovement() {
    return shouldProcessInput() && 
           currentState != GameInputState.aiming &&
           currentState != GameInputState.launching;
  }
  
  /// Check if aiming input should be processed
  bool shouldProcessAiming() {
    return shouldProcessInput() && 
           (currentState == GameInputState.playing || 
            currentState == GameInputState.aiming);
  }
}

/// Different input states for the game
enum GameInputState {
  playing,
  aiming,
  launching,
  paused,
  menu,
  gameOver,
}