import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/features/game/domain/systems/input_system.dart';
import 'package:hard_hat/features/game/domain/input/input_component.dart';
import 'package:hard_hat/features/game/domain/input/input_event.dart' as input_events;
import 'package:hard_hat/features/game/domain/input/input_event.dart' show MovementInputEvent, JumpInputEvent, AimInputEvent, LaunchInputEvent, KeyboardMapping;
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';

void main() {
  group('InputSystem Tests', () {
    late InputSystem inputSystem;
    late PlayerEntity testPlayer;

    setUp(() async {
      inputSystem = InputSystem();
      await inputSystem.initialize();
      
      testPlayer = PlayerEntity(
        id: 'test_player',
      );
    });

    tearDown(() {
      inputSystem.dispose();
    });

    test('should initialize input system correctly', () {
      expect(inputSystem.isInputEnabled, isTrue);
      expect(inputSystem.currentInputState, equals(GameInputState.playing));
    });

    test('should handle keyboard input events', () {
      // Simulate keyboard input directly through the handler
      inputSystem.inputHandler.keyboardHandler.handleKeyDown(LogicalKeyboardKey.keyA);
      
      // Update the system to process queued events
      inputSystem.updateSystem(0.016); // 60 FPS
      
      // Verify input was processed (queue should be empty after processing)
      expect(inputSystem.getInputStats()['queueSize'], equals(0));
    });

    test('should process movement input correctly', () {
      final inputComponent = testPlayer.inputComponent;
      
      // Create movement input event
      final movementEvent = MovementInputEvent(
        direction: 1.0,
        source: input_events.InputSource.keyboard,
        timestamp: DateTime.now(),
      );
      
      // Process the event directly
      inputSystem.inputHandler.keyboardHandler.handleKeyDown(LogicalKeyboardKey.keyD);
      
      // Update the system to process queued events
      inputSystem.updateSystem(0.016); // 60 FPS
      
      // The input should be processed in the next frame
      expect(inputComponent.lastInputSource, equals(input_events.InputSource.keyboard));
    });

    test('should handle input state changes', () {
      expect(inputSystem.currentInputState, equals(GameInputState.playing));
      
      inputSystem.setGameInputState(GameInputState.paused);
      expect(inputSystem.currentInputState, equals(GameInputState.paused));
      
      inputSystem.setGameInputState(GameInputState.playing);
      expect(inputSystem.currentInputState, equals(GameInputState.playing));
    });

    test('should disable input when requested', () {
      expect(inputSystem.isInputEnabled, isTrue);
      
      inputSystem.setInputEnabled(false);
      expect(inputSystem.isInputEnabled, isFalse);
      
      inputSystem.setInputEnabled(true);
      expect(inputSystem.isInputEnabled, isTrue);
    });

    test('should clear input state correctly', () {
      // Add some input events
      inputSystem.inputHandler.keyboardHandler.handleKeyDown(LogicalKeyboardKey.keyA);
      inputSystem.updateSystem(0.016);
      
      // Clear input state
      inputSystem.clearInputState();
      
      // Verify state is cleared
      expect(inputSystem.getInputStats()['queueSize'], equals(0));
    });

    test('should handle input prioritization', () {
      final handler = inputSystem.inputHandler;
      
      // Test that keyboard has higher priority than touch
      expect(
        handler.shouldPrioritize(input_events.InputSource.keyboard, input_events.InputSource.touch),
        isTrue,
      );
      
      // Test that touch has higher priority than gamepad
      expect(
        handler.shouldPrioritize(input_events.InputSource.touch, input_events.InputSource.gamepad),
        isTrue,
      );
    });
  });

  group('InputComponent Tests', () {
    late PlayerInputComponent inputComponent;

    setUp(() {
      inputComponent = PlayerInputComponent();
    });

    test('should initialize with default values', () {
      expect(inputComponent.movementDirection, equals(0.0));
      expect(inputComponent.isJumpPressed, isFalse);
      expect(inputComponent.isAiming, isFalse);
      expect(inputComponent.shouldLaunch, isFalse);
      expect(inputComponent.pauseRequested, isFalse);
    });

    test('should handle coyote time correctly', () {
      expect(inputComponent.canJumpWithCoyoteTime(), isTrue);
      
      // Simulate being in air
      inputComponent.updateCoyoteTime(false);
      expect(inputComponent.canJumpWithCoyoteTime(), isTrue); // Still within coyote time
      
      // Simulate many frames in air
      for (int i = 0; i < 10; i++) {
        inputComponent.updateCoyoteTime(false);
      }
      expect(inputComponent.canJumpWithCoyoteTime(), isFalse); // Coyote time expired
    });

    test('should handle jump buffering correctly', () {
      expect(inputComponent.hasJumpBuffer(), isFalse);
      
      inputComponent.updateJumpBuffer(true);
      expect(inputComponent.hasJumpBuffer(), isTrue);
      
      inputComponent.consumeJumpBuffer();
      expect(inputComponent.hasJumpBuffer(), isFalse);
    });

    test('should reset frame inputs correctly', () {
      inputComponent.shouldLaunch = true;
      inputComponent.pauseRequested = true;
      
      inputComponent.resetFrameInputs();
      
      expect(inputComponent.shouldLaunch, isFalse);
      expect(inputComponent.pauseRequested, isFalse);
    });

    test('should detect movement input correctly', () {
      expect(inputComponent.hasMovementInput, isFalse);
      
      inputComponent.movementDirection = 0.5;
      expect(inputComponent.hasMovementInput, isTrue);
      
      inputComponent.movementDirection = 0.0;
      expect(inputComponent.hasMovementInput, isFalse);
    });
  });

  group('InputEvent Tests', () {
    test('should create movement input event correctly', () {
      final event = MovementInputEvent(
        direction: 1.0,
        source: input_events.InputSource.keyboard,
        timestamp: DateTime.now(),
      );
      
      expect(event.direction, equals(1.0));
      expect(event.source, equals(input_events.InputSource.keyboard));
      expect(event.timestamp, isA<DateTime>());
    });

    test('should create jump input event correctly', () {
      final event = JumpInputEvent(
        isPressed: true,
        source: input_events.InputSource.keyboard,
        timestamp: DateTime.now(),
      );
      
      expect(event.isPressed, isTrue);
      expect(event.source, equals(input_events.InputSource.keyboard));
    });

    test('should create aim input event correctly', () {
      final event = AimInputEvent(
        isAiming: true,
        aimX: 100.0,
        aimY: 200.0,
        source: input_events.InputSource.touch,
        timestamp: DateTime.now(),
      );
      
      expect(event.isAiming, isTrue);
      expect(event.aimX, equals(100.0));
      expect(event.aimY, equals(200.0));
      expect(event.source, equals(input_events.InputSource.touch));
    });

    test('should create launch input event correctly', () {
      final event = LaunchInputEvent(
        directionX: 0.5,
        directionY: -0.5,
        power: 0.8,
        source: input_events.InputSource.touch,
        timestamp: DateTime.now(),
      );
      
      expect(event.directionX, equals(0.5));
      expect(event.directionY, equals(-0.5));
      expect(event.power, equals(0.8));
      expect(event.source, equals(input_events.InputSource.touch));
    });
  });

  group('KeyboardMapping Tests', () {
    test('should map keys to commands correctly', () {
      expect(
        KeyboardMapping.getCommand(LogicalKeyboardKey.keyA),
        equals(input_events.InputCommand.moveLeft),
      );
      
      expect(
        KeyboardMapping.getCommand(LogicalKeyboardKey.keyD),
        equals(input_events.InputCommand.moveRight),
      );
      
      expect(
        KeyboardMapping.getCommand(LogicalKeyboardKey.space),
        equals(input_events.InputCommand.jump),
      );
      
      expect(
        KeyboardMapping.getCommand(LogicalKeyboardKey.escape),
        equals(input_events.InputCommand.pause),
      );
    });

    test('should return null for unmapped keys', () {
      expect(
        KeyboardMapping.getCommand(LogicalKeyboardKey.keyZ),
        isNull,
      );
    });

    test('should check if key is mapped correctly', () {
      expect(KeyboardMapping.isMapped(LogicalKeyboardKey.keyA), isTrue);
      expect(KeyboardMapping.isMapped(LogicalKeyboardKey.keyZ), isFalse);
    });
  });
}