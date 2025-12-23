import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/features/game/domain/interfaces/interfaces.dart';
import 'package:hard_hat/features/game/domain/entities/entities.dart';
import 'package:hard_hat/features/game/domain/systems/systems.dart';
import 'package:hard_hat/features/game/presentation/services/services.dart';
import 'package:hard_hat/core/di/di.dart';

/// Flutter Flame game implementation - handles only presentation concerns
/// Game logic is managed by GameController in the domain layer
class HardHatGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  /// Domain-level game controller
  late IGameController _gameController;
  
  /// Pause menu service implementation
  late PauseMenuServiceImpl _pauseMenuService;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize presentation layer services
    await _initializePresentationLayer();
    
    // Initialize domain layer through controller
    await _initializeDomainLayer();
    
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
  }

  /// Initialize presentation layer services
  Future<void> _initializePresentationLayer() async {
    // Initialize pause menu service
    _pauseMenuService = PauseMenuServiceImpl();
    
    // Register pause menu service and manager
    registerPauseMenuManager(_pauseMenuService);
  }

  /// Initialize domain layer through game controller
  Future<void> _initializeDomainLayer() async {
    // Get game controller from DI
    _gameController = getIt<IGameController>();
    
    // Set up callbacks
    _gameController.onLevelComplete = _handleLevelComplete;
    _gameController.onLevelLoaded = _handleLevelLoaded;
    _gameController.onGameOver = _handleGameOver;
    
    // Initialize the game
    await _gameController.initializeGame();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update domain layer
    _gameController.update(dt);
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

  @override
  void onRemove() {
    // Dispose domain layer
    _gameController.dispose();
    
    // Dispose presentation layer
    _pauseMenuService.dispose();
    
    super.onRemove();
  }
}