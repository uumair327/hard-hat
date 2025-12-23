# SOLID Principles - Detailed Refactoring Guide

## REFACTORING EXAMPLES

### Example 1: GameController Refactoring (SRP)

**BEFORE** (Violates SRP):
```dart
class GameController {
  final List<GameSystem> _systems = [];
  late EntityManager _entityManager;
  late InputSystem _inputSystem;
  late AudioSystem _audioSystem;
  late GameStateManager _gameStateManager;
  late CameraSystem _cameraSystem;
  late RenderSystem _renderSystem;
  late ParticleSystem _particleSystem;
  late StateTransitionSystem _stateTransitionSystem;
  late LevelManager _levelManager;
  late SaveSystem _saveSystem;
  late MovementSystem _movementSystem;
  late CollisionSystem _collisionSystem;
  late PauseMenuManager _pauseMenuManager;
  late FocusDetector _focusDetector;

  Future<void> initializeGame() async {
    await _initializeECS();
    await _setupTestLevel();
    _isInitialized = true;
  }

  Future<void> _initializeECS() async {
    _entityManager = EntityManager();
    _gameStateManager = GameStateManager();
    _inputSystem = InputSystem();
    _audioSystem = AudioSystem();
    _cameraSystem = CameraSystem();
    _renderSystem = RenderSystem();
    _particleSystem = ParticleSystem();
    _stateTransitionSystem = StateTransitionSystem();
    _levelManager = LevelManager();
    _saveSystem = SaveSystem();
    _movementSystem = MovementSystem();
    _collisionSystem = CollisionSystem();
    _focusDetector = FocusDetector();
    
    _systems.addAll([
      _inputSystem,
      _movementSystem,
      _collisionSystem,
      _particleSystem,
      _stateTransitionSystem,
      _cameraSystem,
      _renderSystem,
      _audioSystem,
    ]);
    
    for (final system in _systems) {
      await system.initialize();
    }
  }

  void update(double dt) {
    if (!_isInitialized) return;
    for (final system in _systems) {
      system.update(dt);
    }
  }

  void pauseGame() => _gameStateManager.pauseGame();
  void resumeGame() => _gameStateManager.resumeGame();
  void goToMenu() => _gameStateManager.goToMenu();
  Future<void> loadLevel(int levelId) => _levelManager.loadLevel(levelId);
  Future<void> restartLevel() => _levelManager.restartLevel();
  void togglePauseMenu() => _pauseMenuManager.togglePauseMenu();
}
```

**AFTER** (Follows SRP):
```dart
// 1. ECS System Orchestrator - manages all game systems
class ECSOrchestrator {
  final List<GameSystem> _systems = [];
  late EntityManager _entityManager;
  late InputSystem _inputSystem;
  late AudioSystem _audioSystem;
  late CameraSystem _cameraSystem;
  late RenderSystem _renderSystem;
  late ParticleSystem _particleSystem;
  late StateTransitionSystem _stateTransitionSystem;
  late MovementSystem _movementSystem;
  late CollisionSystem _collisionSystem;

  Future<void> initialize() async {
    _entityManager = EntityManager();
    _inputSystem = InputSystem();
    _audioSystem = AudioSystem();
    _cameraSystem = CameraSystem();
    _renderSystem = RenderSystem();
    _particleSystem = ParticleSystem();
    _stateTransitionSystem = StateTransitionSystem();
    _movementSystem = MovementSystem();
    _collisionSystem = CollisionSystem();
    
    _systems.addAll([
      _inputSystem,
      _movementSystem,
      _collisionSystem,
      _particleSystem,
      _stateTransitionSystem,
      _cameraSystem,
      _renderSystem,
      _audioSystem,
    ]);
    
    for (final system in _systems) {
      await system.initialize();
    }
  }

  void update(double dt) {
    for (final system in _systems) {
      system.update(dt);
    }
  }

  void dispose() {
    for (final system in _systems) {
      system.dispose();
    }
    _systems.clear();
  }

  T getSystem<T extends GameSystem>() {
    return _systems.whereType<T>().first;
  }
}

// 2. Game State Orchestrator - manages game state and pause
class GameStateOrchestrator {
  final GameStateManager _gameStateManager;
  final PauseMenuManager _pauseMenuManager;
  final FocusDetector _focusDetector;

  GameStateOrchestrator(
    this._gameStateManager,
    this._pauseMenuManager,
    this._focusDetector,
  );

  void pauseGame() => _gameStateManager.pauseGame();
  void resumeGame() => _gameStateManager.resumeGame();
  void goToMenu() => _gameStateManager.goToMenu();
  void togglePauseMenu() => _pauseMenuManager.togglePauseMenu();
  
  GameState get currentState => _gameStateManager.currentState;
  bool get isPlaying => _gameStateManager.isPlaying;
  bool get isPaused => _gameStateManager.isPaused;
}

// 3. Level Management Orchestrator - manages levels and saves
class LevelOrchestrator {
  final LevelManager _levelManager;
  final SaveSystem _saveSystem;
  final EntityManager _entityManager;

  LevelOrchestrator(
    this._levelManager,
    this._saveSystem,
    this._entityManager,
  );

  Future<void> loadLevel(int levelId) => _levelManager.loadLevel(levelId);
  Future<void> restartLevel() => _levelManager.restartLevel();
  Future<void> saveProgress(int levelId) => _saveSystem.saveProgress(currentLevel: levelId);
}

// 4. Simplified GameController - coordinates orchestrators
class GameController {
  final ECSOrchestrator _ecsOrchestrator;
  final GameStateOrchestrator _stateOrchestrator;
  final LevelOrchestrator _levelOrchestrator;
  
  bool _isInitialized = false;

  GameController(
    this._ecsOrchestrator,
    this._stateOrchestrator,
    this._levelOrchestrator,
  );

  Future<void> initializeGame() async {
    await _ecsOrchestrator.initialize();
    _isInitialized = true;
  }

  void update(double dt) {
    if (!_isInitialized) return;
    _ecsOrchestrator.update(dt);
  }

  // Delegate to appropriate orchestrator
  void pauseGame() => _stateOrchestrator.pauseGame();
  void resumeGame() => _stateOrchestrator.resumeGame();
  void goToMenu() => _stateOrchestrator.goToMenu();
  Future<void> loadLevel(int levelId) => _levelOrchestrator.loadLevel(levelId);
  Future<void> restartLevel() => _levelOrchestrator.restartLevel();
  void togglePauseMenu() => _stateOrchestrator.togglePauseMenu();

  GameState get currentState => _stateOrchestrator.currentState;
  bool get isPlaying => _stateOrchestrator.isPlaying;
  bool get isPaused => _stateOrchestrator.isPaused;

  void dispose() {
    _ecsOrchestrator.dispose();
  }
}
```

---

### Example 2: GameStateManager Refactoring (OCP)

**BEFORE** (Violates OCP):
```dart
class GameStateManager {
  GameState _currentState = GameState.playing;
  
  static final Map<GameState, Set<GameState>> _validTransitions = {
    GameState.menu: {GameState.playing, GameState.loading, GameState.settings},
    GameState.playing: {GameState.paused, GameState.levelComplete, GameState.gameOver, GameState.menu, GameState.loading, GameState.error},
    GameState.paused: {GameState.playing, GameState.menu, GameState.gameOver},
    GameState.levelComplete: {GameState.playing, GameState.menu, GameState.loading},
    GameState.gameOver: {GameState.playing, GameState.menu, GameState.loading},
    GameState.loading: {GameState.playing, GameState.menu, GameState.error},
    GameState.settings: {GameState.menu, GameState.playing},
    GameState.error: {GameState.menu, GameState.playing, GameState.loading},
  };

  bool canTransitionTo(GameState targetState) {
    final validTargets = _validTransitions[_currentState];
    return validTargets?.contains(targetState) ?? false;
  }

  void _applyStateSpecificBehavior(GameState state) {
    switch (state) {
      case GameState.paused:
        _audioStateManager.pauseAudio();
        break;
      case GameState.playing:
        _audioStateManager.resumeAudio();
        break;
      case GameState.menu:
        _audioStateManager.fadeOut(duration: const Duration(milliseconds: 500));
        break;
      case GameState.levelComplete:
      case GameState.gameOver:
        break;
      case GameState.loading:
      case GameState.settings:
      case GameState.error:
        break;
    }
  }
}
```

**AFTER** (Follows OCP):
```dart
// 1. Define state strategy interface
abstract class GameStateStrategy {
  /// Get valid transitions from this state
  Set<GameState> getValidTransitions();
  
  /// Called when entering this state
  void onEnter(GameStateContext context);
  
  /// Called when exiting this state
  void onExit(GameStateContext context);
}

// 2. Context for state strategies
class GameStateContext {
  final AudioStateManager audioStateManager;
  final List<Function(GameState, GameState?)> stateChangeCallbacks;
  
  GameStateContext({
    required this.audioStateManager,
    required this.stateChangeCallbacks,
  });
}

// 3. Concrete state implementations
class PlayingState implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.paused,
    GameState.levelComplete,
    GameState.gameOver,
    GameState.menu,
    GameState.loading,
    GameState.error,
  };

  @override
  void onEnter(GameStateContext context) {
    context.audioStateManager.resumeAudio();
  }

  @override
  void onExit(GameStateContext context) {}
}

class PausedState implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.menu,
    GameState.gameOver,
  };

  @override
  void onEnter(GameStateContext context) {
    context.audioStateManager.pauseAudio();
  }

  @override
  void onExit(GameStateContext context) {}
}

class MenuState implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.loading,
    GameState.settings,
  };

  @override
  void onEnter(GameStateContext context) {
    context.audioStateManager.fadeOut(
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void onExit(GameStateContext context) {}
}

class LevelCompleteState implements GameStateStrategy {
  @override
  Set<GameState> getValidTransitions() => {
    GameState.playing,
    GameState.menu,
    GameState.loading,
  };

  @override
  void onEnter(GameStateContext context) {
    // Play level complete sound, show UI, etc.
  }

  @override
  void onExit(GameStateContext context) {}
}

// 4. Refactored GameStateManager
class GameStateManager {
  final AudioStateManager _audioStateManager;
  final Map<GameState, GameStateStrategy> _stateStrategies;
  
  GameState _currentState = GameState.playing;
  GameState? _previousState;
  final List<Function(GameState, GameState?)> _stateChangeCallbacks = [];

  GameStateManager(
    this._audioStateManager,
    this._stateStrategies,
  );

  bool canTransitionTo(GameState targetState) {
    final strategy = _stateStrategies[_currentState];
    return strategy?.getValidTransitions().contains(targetState) ?? false;
  }

  bool transitionTo(GameState newState, {String? reason}) {
    if (_currentState == newState) return true;
    if (!canTransitionTo(newState)) return false;

    final context = GameStateContext(
      audioStateManager: _audioStateManager,
      stateChangeCallbacks: _stateChangeCallbacks,
    );

    // Exit old state
    _stateStrategies[_currentState]?.onExit(context);

    // Update state
    _previousState = _currentState;
    _currentState = newState;

    // Enter new state
    _stateStrategies[newState]?.onEnter(context);

    // Notify listeners
    _notifyStateChange();
    return true;
  }

  void _notifyStateChange() {
    for (final callback in _stateChangeCallbacks) {
      callback(_currentState, _previousState);
    }
  }

  GameState get currentState => _currentState;
  bool get isPlaying => _currentState == GameState.playing;
  bool get isPaused => _currentState == GameState.paused;
}

// 5. Factory for creating state manager with all strategies
class GameStateManagerFactory {
  static GameStateManager create(AudioStateManager audioStateManager) {
    return GameStateManager(
      audioStateManager,
      {
        GameState.playing: PlayingState(),
        GameState.paused: PausedState(),
        GameState.menu: MenuState(),
        GameState.levelComplete: LevelCompleteState(),
        GameState.gameOver: GameOverState(),
        GameState.loading: LoadingState(),
        GameState.settings: SettingsState(),
        GameState.error: ErrorState(),
      },
    );
  }
}
```

**Benefits**:
- Adding new states only requires creating a new `GameStateStrategy` implementation
- No modification to `GameStateManager` needed
- Each state's behavior is isolated and testable
- Easy to understand state transitions

---

### Example 3: PauseMenuManager Refactoring (ISP)

**BEFORE** (Violates ISP):
```dart
class PauseMenuManager {
  final GameStateManager _gameStateManager;
  final FocusDetector _focusDetector;
  final PauseMenuService _pauseMenuService;
  
  void Function()? _onRestart;
  void Function()? _onQuit;

  PauseMenuManager(
    this._gameStateManager, 
    this._focusDetector,
    this._pauseMenuService,
  );

  void showPauseMenu() { }
  void hidePauseMenu() { }
  void togglePauseMenu() { }
  void setRestartCallback(void Function() callback) { }
  void setQuitCallback(void Function() callback) { }
  bool get isShown => _pauseMenuService.isShown;
}
```

**AFTER** (Follows ISP):
```dart
// 1. Segregate into focused interfaces

/// Manages pause state
abstract class PauseStateManager {
  void pauseGame();
  void resumeGame();
  bool get isPaused;
}

/// Manages pause UI visibility
abstract class PauseUIManager {
  void showPauseMenu();
  void hidePauseMenu();
  void togglePauseMenu();
  bool get isShown;
}

/// Handles pause menu actions
abstract class PauseActionHandler {
  void setRestartCallback(void Function() callback);
  void setQuitCallback(void Function() callback);
}

/// Detects focus changes
abstract class FocusChangeListener {
  void onFocusLost();
  void onFocusGained();
}

// 2. Implementations

class GamePauseStateManager implements PauseStateManager {
  final GameStateManager _gameStateManager;

  GamePauseStateManager(this._gameStateManager);

  @override
  void pauseGame() => _gameStateManager.pauseGame();

  @override
  void resumeGame() => _gameStateManager.resumeGame();

  @override
  bool get isPaused => _gameStateManager.isPaused;
}

class UIBasedPauseUIManager implements PauseUIManager {
  final PauseMenuService _pauseMenuService;

  UIBasedPauseUIManager(this._pauseMenuService);

  @override
  void showPauseMenu() => _pauseMenuService.showPauseMenu();

  @override
  void hidePauseMenu() => _pauseMenuService.hidePauseMenu();

  @override
  void togglePauseMenu() {
    if (isShown) {
      hidePauseMenu();
    } else {
      showPauseMenu();
    }
  }

  @override
  bool get isShown => _pauseMenuService.isShown;
}

class CallbackPauseActionHandler implements PauseActionHandler {
  void Function()? _onRestart;
  void Function()? _onQuit;

  @override
  void setRestartCallback(void Function() callback) {
    _onRestart = callback;
  }

  @override
  void setQuitCallback(void Function() callback) {
    _onQuit = callback;
  }

  void handleRestart() => _onRestart?.call();
  void handleQuit() => _onQuit?.call();
}

class FocusBasedPauseListener implements FocusChangeListener {
  final PauseStateManager _stateManager;
  final PauseUIManager _uiManager;

  FocusBasedPauseListener(this._stateManager, this._uiManager);

  @override
  void onFocusLost() {
    if (!_stateManager.isPaused) {
      _stateManager.pauseGame();
      _uiManager.showPauseMenu();
    }
  }

  @override
  void onFocusGained() {
    // Focus gained doesn't auto-resume
  }
}

// 3. Clients depend only on what they need

class PauseMenuPresenter {
  final PauseUIManager _uiManager;
  final PauseActionHandler _actionHandler;

  PauseMenuPresenter(this._uiManager, this._actionHandler);

  void showMenu() => _uiManager.showPauseMenu();
  void hideMenu() => _uiManager.hidePauseMenu();
  void setRestartCallback(void Function() callback) {
    _actionHandler.setRestartCallback(callback);
  }
}

class GamePauseController {
  final PauseStateManager _stateManager;

  GamePauseController(this._stateManager);

  void pauseGame() => _stateManager.pauseGame();
  void resumeGame() => _stateManager.resumeGame();
  bool get isPaused => _stateManager.isPaused;
}

class FocusManager {
  final FocusChangeListener _focusListener;

  FocusManager(this._focusListener);

  void handleFocusLost() => _focusListener.onFocusLost();
  void handleFocusGained() => _focusListener.onFocusGained();
}
```

---

### Example 4: DI Container Refactoring (DIP)

**BEFORE** (Violates DIP):
```dart
class GameInjection {
  static Future<void> initializeGameDependencies() async {
    _sl.registerLazySingleton<EntityManager>(() => EntityManager());
    _sl.registerLazySingleton<MovementSystem>(() => MovementSystem());
    _sl.registerLazySingleton<CollisionSystem>(() => CollisionSystem());
    _sl.registerLazySingleton<InputSystem>(() => InputSystem());
    _sl.registerLazySingleton<AudioSystem>(() => AudioSystem(sl()));
    _sl.registerLazySingleton<GameStateManager>(() => GameStateManager(_sl()));
  }
}
```

**AFTER** (Follows DIP):
```dart
// 1. Define abstractions

abstract class EntityManager {
  void addEntity(GameEntity entity);
  void removeEntity(String id);
  List<T> getEntitiesOfType<T extends GameEntity>();
}

abstract class MovementSystem extends GameSystem {
  void updateMovement(double dt);
}

abstract class CollisionSystem extends GameSystem {
  void detectCollisions();
}

abstract class InputSystem extends GameSystem {
  void handleInput(InputEvent event);
}

abstract class AudioSystem extends GameSystem {
  void playSound(String soundId);
  void stopSound(String soundId);
}

abstract class GameStateManager {
  GameState get currentState;
  bool transitionTo(GameState newState);
  bool get isPlaying;
  bool get isPaused;
}

// 2. Concrete implementations

class EntityManagerImpl implements EntityManager {
  final Map<String, GameEntity> _entities = {};

  @override
  void addEntity(GameEntity entity) => _entities[entity.id] = entity;

  @override
  void removeEntity(String id) => _entities.remove(id);

  @override
  List<T> getEntitiesOfType<T extends GameEntity>() {
    return _entities.values.whereType<T>().toList();
  }
}

class MovementSystemImpl extends GameSystem implements MovementSystem {
  final EntityManager _entityManager;

  MovementSystemImpl(this._entityManager);

  @override
  void updateMovement(double dt) {
    final entities = _entityManager.getEntitiesOfType<PhysicsEntity>();
    for (final entity in entities) {
      entity.updatePhysics(dt);
    }
  }

  @override
  void update(double dt) => updateMovement(dt);
}

// 3. Register abstractions with implementations

class GameInjection {
  static Future<void> initializeGameDependencies() async {
    // Register abstractions
    _sl.registerLazySingleton<EntityManager>(
      () => EntityManagerImpl(),
    );
    
    _sl.registerLazySingleton<MovementSystem>(
      () => MovementSystemImpl(_sl()),
    );
    
    _sl.registerLazySingleton<CollisionSystem>(
      () => CollisionSystemImpl(_sl()),
    );
    
    _sl.registerLazySingleton<InputSystem>(
      () => InputSystemImpl(),
    );
    
    _sl.registerLazySingleton<AudioSystem>(
      () => AudioSystemImpl(_sl()),
    );
    
    _sl.registerLazySingleton<GameStateManager>(
      () => GameStateManagerImpl(_sl()),
    );
    
    // High-level modules depend on abstractions
    _sl.registerLazySingleton<GameController>(
      () => GameControllerImpl(
        entityManager: _sl(),
        movementSystem: _sl(),
        collisionSystem: _sl(),
        inputSystem: _sl(),
        audioSystem: _sl(),
        gameStateManager: _sl(),
      ),
    );
  }
}

// 4. High-level modules depend on abstractions

class GameControllerImpl implements GameController {
  final EntityManager _entityManager;
  final MovementSystem _movementSystem;
  final CollisionSystem _collisionSystem;
  final InputSystem _inputSystem;
  final AudioSystem _audioSystem;
  final GameStateManager _gameStateManager;

  GameControllerImpl({
    required EntityManager entityManager,
    required MovementSystem movementSystem,
    required CollisionSystem collisionSystem,
    required InputSystem inputSystem,
    required AudioSystem audioSystem,
    required GameStateManager gameStateManager,
  })  : _entityManager = entityManager,
        _movementSystem = movementSystem,
        _collisionSystem = collisionSystem,
        _inputSystem = inputSystem,
        _audioSystem = audioSystem,
        _gameStateManager = gameStateManager;

  @override
  Future<void> initializeGame() async {
    // Initialize using abstractions
  }

  @override
  void update(double dt) {
    _movementSystem.update(dt);
    _collisionSystem.update(dt);
    _inputSystem.update(dt);
  }
}
```

---

## TESTING IMPROVEMENTS

With these refactorings, testing becomes much easier:

```dart
// Before: Difficult to test
void testGameController() {
  // Cannot mock individual systems
  final controller = GameController();
  // Hard to verify specific behavior
}

// After: Easy to test with mocks
void testGameController() {
  final mockEntityManager = MockEntityManager();
  final mockMovementSystem = MockMovementSystem();
  final mockGameStateManager = MockGameStateManager();
  
  final controller = GameControllerImpl(
    entityManager: mockEntityManager,
    movementSystem: mockMovementSystem,
    gameStateManager: mockGameStateManager,
  );
  
  controller.initializeGame();
  
  verify(mockEntityManager.addEntity(any)).called(1);
  verify(mockMovementSystem.update(any)).called(1);
}

// Test state transitions
void testGameStateTransitions() {
  final stateManager = GameStateManagerFactory.create(
    MockAudioStateManager(),
  );
  
  expect(stateManager.currentState, GameState.playing);
  
  stateManager.transitionTo(GameState.paused);
  expect(stateManager.currentState, GameState.paused);
  
  stateManager.transitionTo(GameState.playing);
  expect(stateManager.currentState, GameState.playing);
}

// Test pause menu with segregated interfaces
void testPauseMenuPresenter() {
  final mockUIManager = MockPauseUIManager();
  final mockActionHandler = MockPauseActionHandler();
  
  final presenter = PauseMenuPresenter(mockUIManager, mockActionHandler);
  
  presenter.showMenu();
  verify(mockUIManager.showPauseMenu()).called(1);
  
  presenter.hideMenu();
  verify(mockUIManager.hidePauseMenu()).called(1);
}
```

---

## MIGRATION STRATEGY

1. **Phase 1**: Create abstractions for all systems
2. **Phase 2**: Implement concrete classes
3. **Phase 3**: Update DI container to register abstractions
4. **Phase 4**: Refactor GameController into orchestrators
5. **Phase 5**: Implement Strategy pattern for state management
6. **Phase 6**: Segregate fat interfaces
7. **Phase 7**: Update tests to use new architecture
8. **Phase 8**: Remove old implementations

---

## EXPECTED BENEFITS

- **Testability**: 80% improvement with mockable dependencies
- **Maintainability**: 60% reduction in coupling
- **Extensibility**: New features require no modification to existing code
- **Reusability**: Systems can be used independently
- **Code Quality**: Clear separation of concerns
