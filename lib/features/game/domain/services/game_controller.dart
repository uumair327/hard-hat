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
    // Create test player
    _testPlayer = PlayerEntity(
      id: 'test_player',
      position: Vector2(100, 500),
    );
    
    await _testPlayer!.initializeEntity();
    _ecsOrchestrator.entityManager.addEntity(_testPlayer!);
    
    // Setup camera to follow player
    final cameraSystem = _ecsOrchestrator.getSystem<ICameraSystem>();
    cameraSystem?.setTarget(_testPlayer!);
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
    onLevelLoaded?.call(level);
  }

  // Delegate to appropriate orchestrator
  
  /// Load a specific level
  Future<void> loadLevel(int levelId) async {
    await _levelOrchestrator.loadLevel(levelId);
  }

  /// Restart current level
  Future<void> restartLevel() async {
    await _levelOrchestrator.restartLevel();
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