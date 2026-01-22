import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/domain.dart';

/// Domain-level game controller that coordinates orchestrators
/// Follows SRP - only responsible for high-level game coordination
@LazySingleton(as: IGameController)
class GameController implements IGameController {
  final ECSOrchestrator _ecsOrchestrator;
  final GameStateOrchestrator _stateOrchestrator;
  final LevelOrchestrator _levelOrchestrator;
  
  /// Flag to track if the game has been initialized
  bool _isInitialized = false;
  
  /// Test player entity
  PlayerEntity? _testPlayer;
  
  /// Callbacks for game events
  @override
  void Function(Level level)? onLevelComplete;
  @override
  void Function(Level level)? onLevelLoaded;
  @override
  void Function()? onGameOver;

  GameController({
    required ECSOrchestrator ecsOrchestrator,
    required GameStateOrchestrator stateOrchestrator,
    required LevelOrchestrator levelOrchestrator,
  })  : _ecsOrchestrator = ecsOrchestrator,
        _stateOrchestrator = stateOrchestrator,
        _levelOrchestrator = levelOrchestrator;

  /// Initialize the game
  @override
  Future<void> initializeGame() async {
    if (_isInitialized) return;
    
    debugPrint('GameController: Starting initialization...');
    
    try {
      // Initialize orchestrators
      debugPrint('GameController: Initializing ECS orchestrator...');
      await _ecsOrchestrator.initialize();
      
      debugPrint('GameController: Initializing state orchestrator...');
      _stateOrchestrator.initialize();
      
      debugPrint('GameController: Initializing level orchestrator...');
      _levelOrchestrator.initialize();
      
      // Set up callbacks
      debugPrint('GameController: Setting up callbacks...');
      _setupCallbacks();
      
      // Defer test level setup to avoid blocking initialization
      debugPrint('GameController: Scheduling test level setup...');
      Future.delayed(const Duration(milliseconds: 100), () {
        _setupTestLevel();
      });
      
      _isInitialized = true;
      debugPrint('GameController: Initialization completed successfully!');
    } catch (e) {
      debugPrint('GameController: Error during initialization: $e');
      // Mark as initialized even if test level fails
      _isInitialized = true;
      rethrow;
    }
  }

  /// Setup callbacks between orchestrators
  void _setupCallbacks() {
    _levelOrchestrator.onLevelComplete = _handleLevelComplete;
    _levelOrchestrator.onLevelLoaded = _handleLevelLoaded;
    
    _stateOrchestrator.setRestartCallback(restartLevel);
    _stateOrchestrator.setQuitCallback(goToMenu);
  }

  /// Setup a test level for development
  Future<void> _setupTestLevel() async {
    try {
      debugPrint('GameController: Setting up test level...');
      
      // Create test player with ball and audio callbacks
      _testPlayer = PlayerEntity(
        id: 'test_player',
        position: Vector2(100, 500),
        onBallCreated: _handleBallCreated,
        onBallLaunched: _handleBallLaunched,
        onAudioEvent: _handlePlayerAudioEvent,
      );
      
      debugPrint('GameController: Initializing test player...');
      await _testPlayer!.initializeEntity();
      _ecsOrchestrator.entityManager.addEntity(_testPlayer!);
      
      debugPrint('GameController: Setting up camera...');
      // Setup camera to follow player
      final cameraSystem = _ecsOrchestrator.getSystem<CameraSystem>();
      if (cameraSystem != null) {
        cameraSystem.setTarget(_testPlayer!);
        
        // Set up test level camera bounds
        final testLevel = Level(
          id: 1,
          name: 'Test Level',
          description: 'Test level for development',
          size: Vector2(1600, 800),
          tiles: [],
          playerSpawn: Vector2(100, 500),
          cameraMin: Vector2(0, 0),
          cameraMax: Vector2(1600, 800),
          elements: [],
        );
        
        cameraSystem.setBoundsFromLevel(testLevel);
        debugPrint('GameController: Test level setup completed successfully!');
      } else {
        debugPrint('GameController: Warning - Camera system not available');
      }
    } catch (e) {
      debugPrint('GameController: Warning - Failed to setup test level: $e');
      // Continue without test level if setup fails
    }
  }
  
  /// Handle ball creation from player
  void _handleBallCreated(BallEntity ball) {
    try {
      // Add ball to entity manager
      _ecsOrchestrator.entityManager.addEntity(ball);
    } catch (e) {
      debugPrint('Warning: Failed to add ball to entity manager: $e');
    }
  }
  
  /// Handle ball launch from player
  void _handleBallLaunched(BallEntity ball) {
    try {
      // Ball is already in entity manager, just ensure it's tracked
      // The collision system will handle ball-tile interactions
    } catch (e) {
      debugPrint('Warning: Failed to handle ball launch: $e');
    }
  }
  
  /// Handle audio events from player
  void _handlePlayerAudioEvent(String soundName, Vector2? position) {
    try {
      final audioSystem = _ecsOrchestrator.getSystem<IAudioSystem>();
      if (audioSystem is AudioSystem) {
        switch (soundName) {
          case 'jump':
            audioSystem.playJumpSound(position);
            break;
          case 'land':
            audioSystem.playLandSound(position);
            break;
          case 'strike':
            audioSystem.playStrikeSound(position);
            break;
          default:
            audioSystem.playSoundEffect(soundName, position: position);
        }
      }
    } catch (e) {
      debugPrint('Warning: Failed to handle audio event $soundName: $e');
    }
  }

  /// Update all game systems
  @override
  void update(double dt) {
    if (!_isInitialized) return;
    
    try {
      // Update ECS systems
      _ecsOrchestrator.update(dt);
    } catch (e) {
      debugPrint('Warning: Error updating ECS systems: $e');
      // Continue running even if update fails
    }
  }

  /// Handle level completion
  void _handleLevelComplete(Level level) {
    _stateOrchestrator.setLevelComplete();
    onLevelComplete?.call(level);
  }

  /// Handle level loaded
  void _handleLevelLoaded(Level level) {
    _stateOrchestrator.setPlaying();
    
    // Update camera system with new level bounds
    final cameraSystem = _ecsOrchestrator.getSystem<CameraSystem>();
    if (cameraSystem != null) {
      cameraSystem.setBoundsFromLevel(level);
      
      // If we have a player, position camera at player spawn
      if (_testPlayer != null) {
        _testPlayer!.positionComponent.updatePosition(level.playerSpawn);
        cameraSystem.focusOn(level.playerSpawn, immediate: true);
      }
    }
    
    onLevelLoaded?.call(level);
  }

  // Delegate to appropriate orchestrator
  
  /// Load a specific level
  @override
  Future<void> loadLevel(int levelId) async {
    await _levelOrchestrator.loadLevel(levelId);
  }

  /// Restart current level
  @override
  Future<void> restartLevel() async {
    await _levelOrchestrator.restartLevel();
  }
  
  /// Switch camera to a specific segment (for level progression)
  void switchCameraSegment(String segmentId) {
    final cameraSystem = _ecsOrchestrator.getSystem<CameraSystem>();
    cameraSystem?.switchToCameraSegment(segmentId);
  }
  
  /// Add camera segment for level progression
  void addCameraSegment(String segmentId, Vector2 topLeft, Vector2 bottomRight) {
    final cameraSystem = _ecsOrchestrator.getSystem<CameraSystem>();
    cameraSystem?.addCameraSegment(segmentId, topLeft, bottomRight);
  }

  /// Pause the game
  @override
  void pauseGame() => _stateOrchestrator.pauseGame();

  /// Resume the game
  @override
  void resumeGame() => _stateOrchestrator.resumeGame();

  /// Go to main menu
  @override
  void goToMenu() => _stateOrchestrator.goToMenu();

  /// Toggle pause menu
  @override
  void togglePauseMenu() => _stateOrchestrator.togglePauseMenu();

  /// Get current game state
  @override
  GameState get currentState => _stateOrchestrator.currentState;

  /// Check if game is playing
  @override
  bool get isPlaying => _stateOrchestrator.isPlaying;

  /// Check if game is paused
  @override
  bool get isPaused => _stateOrchestrator.isPaused;

  /// Check if game is initialized
  @override
  bool get isInitialized => _isInitialized;

  /// Dispose all resources
  @override
  void dispose() {
    _ecsOrchestrator.dispose();
    _stateOrchestrator.dispose();
    
    _isInitialized = false;
  }
}