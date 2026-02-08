# Transition System

The Transition System provides screen transitions with pop-in/pop-out animations for the Hard Hat game.

## Overview

The transition system consists of three main components:

1. **ITransitionSystem** - Interface defining the transition API
2. **TransitionSystemImpl** - Implementation with AnimationController
3. **TransitionOverlay** - Full-screen overlay widget for rendering transitions
4. **TransitionService** - High-level service for managing transitions in the game

## Features

- **Pop-in animation**: Wipe from edges to center (blocks view)
- **Pop-out animation**: Wipe from center to edges (reveals view)
- **Wait method**: Hold transition screen while loading
- **Input blocking**: Automatically blocks input during transitions
- **Customizable**: Configurable duration and color

## Usage

### Basic Usage with TransitionSystemImpl

```dart
import 'package:flutter/material.dart';
import 'package:hard_hat/core/services/services.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late TransitionSystemImpl _transitionSystem;
  
  @override
  void initState() {
    super.initState();
    _transitionSystem = TransitionSystemImpl(vsync: this);
  }
  
  @override
  void dispose() {
    _transitionSystem.dispose();
    super.dispose();
  }
  
  Future<void> _performTransition() async {
    // Pop in (hide screen)
    await _transitionSystem.popIn();
    
    // Wait while loading
    await _transitionSystem.wait(duration: Duration(milliseconds: 500));
    
    // Pop out (reveal screen)
    await _transitionSystem.popOut();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your content here
        Center(child: Text('Game Content')),
        
        // Transition overlay
        TransitionOverlay(
          animation: _transitionSystem.animation,
          color: Colors.black,
        ),
      ],
    );
  }
}
```

### Using TransitionService (Recommended for Game)

```dart
import 'package:flutter/material.dart';
import 'package:hard_hat/features/game/presentation/services/services.dart';

class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late TransitionService _transitionService;
  
  @override
  void initState() {
    super.initState();
    _transitionService = TransitionService(vsync: this);
    _transitionService.initialize();
  }
  
  @override
  void dispose() {
    _transitionService.dispose();
    super.dispose();
  }
  
  Future<void> _loadLevel() async {
    await _transitionService.performTransition(
      waitDuration: Duration(milliseconds: 500),
      onTransition: () async {
        // Load level data here
        await Future.delayed(Duration(seconds: 1));
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Set overlay context for the service
    _transitionService.setOverlayContext(context);
    
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _loadLevel,
          child: Text('Load Level'),
        ),
      ),
    );
  }
}
```

### Manual Control

```dart
// Pop in
await transitionService.popIn();

// Do something while screen is hidden
await loadGameData();

// Wait
await transitionService.wait(duration: Duration(milliseconds: 500));

// Pop out
await transitionService.popOut();
```

## Animation Sequence

1. **Pop In** (300ms): Screen wipes in from all four edges to center
   - Left and right edges move inward
   - Top and bottom edges move inward
   - Blocks input when animation value > 0

2. **Wait** (configurable): Hold the transition screen
   - Useful for loading assets or data
   - Default: 500ms

3. **Pop Out** (300ms): Screen wipes out from center to edges
   - Reverses the pop-in animation
   - Reveals the game content

## Integration with Sandbox

The transition system is designed to integrate with the Sandbox orchestrator for level loading:

```dart
class Sandbox {
  final TransitionService _transitionService;
  
  Future<void> loadLevel(int levelId) async {
    await _transitionService.performTransition(
      onTransition: () async {
        // Load level data
        await _levelManager.loadLevel(levelId);
        
        // Initialize level entities
        await _initializeLevel();
      },
    );
  }
}
```

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **Requirement 4.1**: Pop-in animation (wipe from edges to center)
- **Requirement 4.2**: Pop-out animation (wipe from center to edges)
- **Requirement 4.3**: Wait method with configurable duration
- **Requirement 4.4**: Full-screen overlay widget for transitions
- **Requirement 4.9**: Block input during transitions
- **Requirement 4.10**: Coordinate with audio fades (ready for integration)

## Testing

Unit tests are provided in `test/core/services/transition_system_test.dart` and widget tests in `test/features/game/presentation/overlays/transition_overlay_test.dart`.

Run tests with:
```bash
flutter test test/core/services/transition_system_test.dart
flutter test test/features/game/presentation/overlays/transition_overlay_test.dart
```
