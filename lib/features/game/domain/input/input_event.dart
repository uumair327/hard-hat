import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// Base class for all input events in the game
abstract class InputEvent extends Equatable {
  const InputEvent();
}

/// Represents a movement input event
class MovementInputEvent extends InputEvent {
  final double direction; // -1.0 for left, 1.0 for right, 0.0 for no movement
  final InputSource source;
  final DateTime timestamp;

  const MovementInputEvent({
    required this.direction,
    required this.source,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [direction, source, timestamp];
}

/// Represents a jump input event
class JumpInputEvent extends InputEvent {
  final bool isPressed;
  final InputSource source;
  final DateTime timestamp;

  const JumpInputEvent({
    required this.isPressed,
    required this.source,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [isPressed, source, timestamp];
}

/// Represents an aim input event
class AimInputEvent extends InputEvent {
  final bool isAiming;
  final double? aimX;
  final double? aimY;
  final InputSource source;
  final DateTime timestamp;

  const AimInputEvent({
    required this.isAiming,
    this.aimX,
    this.aimY,
    required this.source,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [isAiming, aimX, aimY, source, timestamp];
}

/// Represents a ball launch input event
class LaunchInputEvent extends InputEvent {
  final double directionX;
  final double directionY;
  final double power; // 0.0 to 1.0
  final InputSource source;
  final DateTime timestamp;

  const LaunchInputEvent({
    required this.directionX,
    required this.directionY,
    required this.power,
    required this.source,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [directionX, directionY, power, source, timestamp];
}

/// Represents a pause input event
class PauseInputEvent extends InputEvent {
  final InputSource source;
  final DateTime timestamp;

  const PauseInputEvent({
    required this.source,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [source, timestamp];
}

/// Represents the source of an input event
enum InputSource {
  keyboard,
  touch,
  gamepad,
}

/// Input command types for mapping inputs to game actions
enum InputCommand {
  moveLeft,
  moveRight,
  jump,
  startAim,
  endAim,
  launch,
  pause,
}

/// Maps keyboard keys to input commands
class KeyboardMapping {
  static final Map<LogicalKeyboardKey, InputCommand> defaultMapping = {
    LogicalKeyboardKey.arrowLeft: InputCommand.moveLeft,
    LogicalKeyboardKey.keyA: InputCommand.moveLeft,
    LogicalKeyboardKey.arrowRight: InputCommand.moveRight,
    LogicalKeyboardKey.keyD: InputCommand.moveRight,
    LogicalKeyboardKey.space: InputCommand.jump,
    LogicalKeyboardKey.arrowUp: InputCommand.jump,
    LogicalKeyboardKey.keyW: InputCommand.jump,
    LogicalKeyboardKey.escape: InputCommand.pause,
    LogicalKeyboardKey.keyP: InputCommand.pause,
  };

  /// Get the input command for a given key
  static InputCommand? getCommand(LogicalKeyboardKey key) {
    return defaultMapping[key];
  }

  /// Check if a key is mapped to a command
  static bool isMapped(LogicalKeyboardKey key) {
    return defaultMapping.containsKey(key);
  }
}

/// Touch gesture types for input mapping
enum TouchGesture {
  tap,
  longPress,
  drag,
  swipe,
}

/// Gamepad button mapping
class GamepadMapping {
  static final Map<int, InputCommand> defaultMapping = {
    0: InputCommand.jump, // A button
    1: InputCommand.launch, // B button
    9: InputCommand.pause, // Start button
  };

  /// Get the input command for a gamepad button
  static InputCommand? getCommand(int buttonId) {
    return defaultMapping[buttonId];
  }

  /// Check if a button is mapped to a command
  static bool isMapped(int buttonId) {
    return defaultMapping.containsKey(buttonId);
  }
}