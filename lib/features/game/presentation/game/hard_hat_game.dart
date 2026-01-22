import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/features/game/domain/interfaces/interfaces.dart';
import 'package:hard_hat/features/game/domain/entities/entities.dart';
import 'package:hard_hat/features/game/domain/systems/systems.dart';
import 'package:hard_hat/features/game/presentation/services/services.dart';
import 'package:hard_hat/core/di/manual_injection.dart' as manual_di;

/// Flutter Flame game implementation - handles only presentation concerns
/// Game logic is managed by GameController in the domain layer
class HardHatGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  /// Domain-level game controller
  late IGameController _gameController;
  
  /// Pause menu service implementation
  late PauseMenuServiceImpl _pauseMenuService;
  
  /// Performance monitoring
  int _frameCount = 0;
  double _totalFrameTime = 0.0;
  double _lastPerformanceReport = 0.0;
  double _lastUpdateTime = 0.0;
  static const double performanceReportInterval = 5.0; // Report every 5 seconds
  static const double targetFrameTime = 1.0 / 60.0; // Target 60 FPS

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    try {
      debugPrint('HardHatGame: Starting onLoad...');
      
      // Initialize presentation layer services
      debugPrint('HardHatGame: Initializing presentation layer...');
      await _initializePresentationLayer();
      
      // Initialize domain layer through controller
      debugPrint('HardHatGame: Initializing domain layer...');
      await _initializeDomainLayer();
      
      debugPrint('HardHatGame: Adding instruction text...');
      // Add instruction text
      add(TextComponent(
        text: 'Use WASD or Arrow Keys to move, Space to jump, ESC to pause',
        position: Vector2(size.x / 2, 50),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      
      debugPrint('HardHatGame: onLoad completed successfully!');
    } catch (e) {
      debugPrint('HardHatGame: Error initializing game: $e');
      // Add error message to screen
      add(TextComponent(
        text: 'Error initializing game: $e',
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 18,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
    }
  }

  /// Initialize presentation layer services
  Future<void> _initializePresentationLayer() async {
    debugPrint('HardHatGame: Initializing pause menu service...');
    // Initialize pause menu service
    _pauseMenuService = PauseMenuServiceImpl();
    debugPrint('HardHatGame: Presentation layer initialized');
  }

  /// Initialize domain layer through game controller
  Future<void> _initializeDomainLayer() async {
    try {
      debugPrint('HardHatGame: Running in simplified mode without game controller');
      // Create a dummy controller to prevent crashes
      _gameController = _createDummyController();
      debugPrint('HardHatGame: Simplified domain layer initialized');
    } catch (e) {
      debugPrint('HardHatGame: Error initializing domain layer: $e');
      // Create a dummy controller to prevent crashes
      _gameController = _createDummyController();
    }
  }
  
  /// Create a dummy controller for minimal functionality
  IGameController _createDummyController() {
    return _DummyGameController();
  }

  @override
  void update(double dt) {
    // More aggressive frame rate limiting to prevent excessive updates
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (currentTime - _lastUpdateTime < targetFrameTime * 1.5) {
      return; // Skip more frames to reduce load
    }
    _lastUpdateTime = currentTime;
    
    // Performance monitoring
    _frameCount++;
    _totalFrameTime += dt;
    
    // More aggressive delta time clamping
    final clampedDt = dt.clamp(0.0, 1.0 / 20.0); // Max 20 FPS equivalent for stability
    
    super.update(clampedDt);
    
    // Update domain layer with clamped delta time
    _gameController.update(clampedDt);
    
    // Report performance periodically
    if (_totalFrameTime - _lastPerformanceReport >= performanceReportInterval) {
      final avgFrameTime = _totalFrameTime / _frameCount;
      final fps = 1.0 / avgFrameTime;
      debugPrint('Game Performance: ${fps.toStringAsFixed(1)} FPS (avg frame time: ${(avgFrameTime * 1000).toStringAsFixed(2)}ms)');
      
      _lastPerformanceReport = _totalFrameTime;
      _frameCount = 0;
      _totalFrameTime = 0.0;
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Handle pause key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _gameController.togglePauseMenu();
      return KeyEventResult.handled;
    }
    
    // Let other systems handle remaining input
    return super.onKeyEvent(event, keysPressed);
  }

  /// Set overlay context for pause menu
  void setOverlayContext(BuildContext context) {
    _pauseMenuService.setOverlayContext(context);
  }

  /// Handle level completion
  void _handleLevelComplete(Level level) {
    // Show level complete overlay
    overlays.add('LevelCompleteOverlay');
  }

  /// Handle level loaded
  void _handleLevelLoaded(Level level) {
    // Update UI with level info
    // This could trigger overlay updates, HUD changes, etc.
  }

  /// Handle game over
  void _handleGameOver() {
    // Show game over overlay
    overlays.add('GameOverOverlay');
  }

  /// Restart current level (called from UI)
  Future<void> restartLevel() async {
    await _gameController.restartLevel();
  }

  /// Load specific level (called from UI)
  Future<void> loadLevel(int levelId) async {
    await _gameController.loadLevel(levelId);
  }

  /// Go to main menu (called from UI)
  void goToMainMenu() {
    _gameController.goToMenu();
  }

  /// Pause the game (called from UI)
  void pauseGame() {
    _gameController.pauseGame();
  }

  /// Resume the game (called from UI)
  void resumeGame() {
    _gameController.resumeGame();
  }

  /// Get current game state
  GameState get currentState => _gameController.currentState;

  /// Check if game is playing
  bool get isPlaying => _gameController.isPlaying;

  /// Check if game is paused
  bool get isPaused => _gameController.isPaused;

  // System access for testing - get systems directly from DI container
  IEntityManager get entityManager => manual_di.getIt<IEntityManager>();
  IInputSystem? get inputSystem => manual_di.getIt<IInputSystem>();
  IAudioSystem? get audioSystem => manual_di.getIt<IAudioSystem>();
  IGameStateManager get gameStateManager => manual_di.getIt<IGameStateManager>();
  ICameraSystem? get cameraSystem => manual_di.getIt<ICameraSystem>();
  IRenderSystem? get renderSystem => manual_di.getIt<IRenderSystem>();
  IParticleSystem? get particleSystem => manual_di.getIt<IParticleSystem>();
  IStateTransitionSystem? get stateTransitionSystem => manual_di.getIt<IStateTransitionSystem>();
  ILevelManager? get levelManager => null; // Not implemented yet
  ISaveSystem? get saveSystem => null; // Not implemented yet
  IMovementSystem? get movementSystem => manual_di.getIt<IMovementSystem>();
  ICollisionSystem? get collisionSystem => manual_di.getIt<ICollisionSystem>();
  IPauseMenuManager? get pauseMenuManager => manual_di.getIt.isRegistered<IPauseMenuManager>() ? manual_di.getIt<IPauseMenuManager>() : null;

  @override
  void onRemove() {
    // Dispose domain layer
    _gameController.dispose();
    
    // Dispose presentation layer
    _pauseMenuService.dispose();
    
    super.onRemove();
  }
}

/// Dummy game controller for minimal functionality when full controller is not available
class _DummyGameController implements IGameController {
  @override
  void Function(Level level)? onLevelComplete;
  @override
  void Function(Level level)? onLevelLoaded;
  @override
  void Function()? onGameOver;

  @override
  Future<void> initializeGame() async {
    // Do nothing - minimal implementation
  }

  @override
  void update(double dt) {
    // Do nothing - minimal implementation
  }

  @override
  Future<void> loadLevel(int levelId) async {
    // Do nothing - minimal implementation
  }

  @override
  Future<void> restartLevel() async {
    // Do nothing - minimal implementation
  }

  @override
  void pauseGame() {
    // Do nothing - minimal implementation
  }

  @override
  void resumeGame() {
    // Do nothing - minimal implementation
  }

  @override
  void goToMenu() {
    // Do nothing - minimal implementation
  }

  @override
  void togglePauseMenu() {
    // Do nothing - minimal implementation
  }

  @override
  GameState get currentState => GameState.menu;

  @override
  bool get isPlaying => false;

  @override
  bool get isPaused => false;

  @override
  bool get isInitialized => true;

  @override
  void dispose() {
    // Do nothing - minimal implementation
  }
}