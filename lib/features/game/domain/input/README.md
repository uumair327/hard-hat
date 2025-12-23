# Input System Documentation

## Overview

The input handling system provides a comprehensive, cross-platform solution for processing user input in the Hard Hat Havoc game. It supports keyboard, touch, and gamepad inputs with proper prioritization and event streaming.

## Architecture

### Components

1. **InputEvent** (`input_event.dart`)
   - Base class for all input events
   - Specific event types: MovementInputEvent, JumpInputEvent, AimInputEvent, LaunchInputEvent, PauseInputEvent
   - Input source tracking (keyboard, touch, gamepad)
   - Command mapping for keyboard and gamepad inputs

2. **InputHandler** (`input_handler.dart`)
   - Abstract base class for input handlers
   - KeyboardInputHandler: Processes keyboard events with key state tracking
   - TouchInputHandler: Handles touch gestures including tap, drag, and swipe
   - GamepadInputHandler: Manages gamepad buttons and analog sticks
   - CrossPlatformInputHandler: Coordinates all input sources with prioritization

3. **InputComponent** (`input_component.dart`)
   - Stores input state for entities
   - PlayerInputComponent: Extended component with coyote time and jump buffering
   - GameStateInputComponent: Manages input state across different game states
   - Input buffering for storing recent inputs

4. **InputSystem** (`input_system.dart`)
   - ECS system that processes input events
   - Distributes input to entities with InputComponents
   - Command queuing and buffering
   - Game state-aware input processing

## Features

### Cross-Platform Input Support

- **Keyboard**: WASD and arrow keys for movement, Space for jump, Escape/P for pause
- **Touch**: Tap and drag for aiming, swipe for movement and jumping
- **Gamepad**: Analog sticks for movement and aiming, buttons for actions

### Input Prioritization

The system prioritizes input sources based on the most recent input:
1. Keyboard (highest priority)
2. Touch
3. Gamepad (lowest priority)

### Advanced Input Features

- **Coyote Time**: Allows jumping for a few frames after leaving the ground
- **Jump Buffering**: Remembers jump input for a few frames before landing
- **Input Buffering**: Stores recent inputs for processing
- **State Management**: Different input behavior based on game state (playing, paused, aiming, etc.)

### Event Streaming

All input handlers provide event streams that can be subscribed to:
```dart
inputHandler.inputStream.listen((event) {
  // Process input event
});
```

## Usage

### Basic Setup

```dart
// Initialize the input system
final inputSystem = InputSystem();
await inputSystem.initialize();

// Add to game
await game.addSystem(inputSystem);
```

### Creating an Input-Enabled Entity

```dart
class PlayerEntity extends GameEntity {
  late final PlayerInputComponent _inputComponent;
  
  PlayerEntity({required String id}) : super(id: id) {
    _inputComponent = PlayerInputComponent();
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(_inputComponent);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Process input
    if (_inputComponent.hasMovementInput) {
      // Move based on input direction
      velocity.x = _inputComponent.movementDirection * moveSpeed;
    }
    
    if (_inputComponent.isJumpPressed && _inputComponent.canJumpWithCoyoteTime()) {
      // Perform jump
      velocity.y = -jumpForce;
      _inputComponent.consumeJumpBuffer();
    }
  }
}
```

### Handling Game State Changes

```dart
// Pause the game
inputSystem.setGameInputState(GameInputState.paused);

// Resume the game
inputSystem.setGameInputState(GameInputState.playing);

// Disable input completely
inputSystem.setInputEnabled(false);
```

### Custom Input Mapping

You can extend the keyboard mapping by modifying the `KeyboardMapping` class:

```dart
class KeyboardMapping {
  static final Map<LogicalKeyboardKey, InputCommand> defaultMapping = {
    LogicalKeyboardKey.keyA: InputCommand.moveLeft,
    LogicalKeyboardKey.keyD: InputCommand.moveRight,
    // Add more mappings...
  };
}
```

## Testing

The input system includes comprehensive unit tests covering:
- Input event creation and processing
- Keyboard, touch, and gamepad input handling
- Input prioritization
- Coyote time and jump buffering
- State management
- Command mapping

Run tests with:
```bash
flutter test test/features/game/domain/input_system_test.dart
```

## Integration with Game

The input system is integrated with the main game through event handlers:

```dart
class HardHatGame extends FlameGame with HasKeyboardHandlerComponents {
  late InputSystem _inputSystem;
  
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    _inputSystem.handleKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }
}
```

## Requirements Validation

This implementation satisfies the following requirements:

- **10.1**: Keyboard input processing for movement and actions
- **10.2**: Touch input translation to game commands
- **10.3**: Gamepad input support (placeholder implementation)
- **10.4**: Input source prioritization based on most recent input
- **10.5**: Rapid input processing without dropping commands

## Future Enhancements

- Full gamepad support with actual gamepad plugin integration
- Customizable key bindings
- Input recording and playback for testing
- Gesture recognition for complex touch patterns
- Haptic feedback for touch and gamepad inputs
