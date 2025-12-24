import 'package:flame/components.dart';
import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_types.dart';

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
  void Function(Level level)? onLevelComplete;
  void Function(Level level)? onLevelLoaded;
  void Function()? onGameOver;

  GameController({
    required ECSOrchestrator ecsOrchestrator,
    required GameStateOrchestrator stateOrchestrator,
    required LevelOrchestrator levelOrchestrator,
  })  : _ecsOrchestrator = ecsOrchestrator,
        _stateOrchestrator = stateOrchestrator,
        _levelOrchestrator = levelOrchestrator;

  /// Initialize the game
  Future<void> initializeGame() async {
    if (_isInitialized) return;
    
    // Initialize orchestrators
    await _ecsOrchestrator.initialize();
    _stateOrchestrator.initialize();
    _levelOrchestrator.initialize();
    
    // Set up callbacks
    _setupCallbacks();
    
    // Setup test level
    await _setupTestLevel();
    
    _isInitialized = true;
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
    // Create test player with ball and audio callbacks
    _testPlayer = PlayerEntity(
      id: 'test_player',
      position: Vector2(100, 500),
      onBallCreated: _handleBallCreated,
      onBallLaunched: _handleBallLaunched,
      onAudioEvent: _handlePlayerAudioEvent,
    );
    
    await _testPlayer!.initializeEntity();
    _ecsOrchestrator.entityManager.addEntity(_testPlayer!);
    
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
    }
  }
  
  /// Handle ball creation from player
  void _handleBallCreated(BallEntity ball) {
    // Add ball to entity manager
    _ecsOrchestrator.entityManager.addEntity(ball);
  }
  
  /// Handle ball launch from player
  void _handleBallLaunched(BallEntity ball) {
    // Ball is already in entity manager, just ensure it's tracked
    // The collision system will handle ball-tile interactions
  }
  
  /// Handle audio events from player
  void _handlePlayerAudioEvent(String soundName, Vector2? position) {
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
  }

  /// Update all game systems
  void update(double dt) {
    if (!_isInitialized) return;
    
    // Update ECS systems
    _ecsOrchestrator.update(dt);
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
  void pauseGame() => _stateOrchestrator.pauseGame();

  /// Resume the game
  void resumeGame() => _stateOrchestrator.resumeGame();

  /// Go to main menu
  void goToMenu() => _stateOrchestrator.goToMenu();

  /// Toggle pause menu
  void togglePauseMenu() => _stateOrchestrator.togglePauseMenu();

  /// Get current game state
  GameState get currentState => _stateOrchestrator.currentState;

  /// Check if game is playing
  bool get isPlaying => _stateOrchestrator.isPlaying;

  /// Check if game is paused
  bool get isPaused => _stateOrchestrator.isPaused;

  /// Check if game is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose all resources
  void dispose() {
    _ecsOrchestrator.dispose();
    _stateOrchestrator.dispose();
    
    _isInitialized = false;
  }
}