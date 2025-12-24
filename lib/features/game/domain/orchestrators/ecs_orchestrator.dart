import 'package:hard_hat/features/game/domain/interfaces/entity_manager_interface.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_system_interfaces.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';

/// ECS System Orchestrator - manages all game systems
/// Follows SRP - only responsible for ECS system coordination
class ECSOrchestrator {
  final List<GameSystem> _systems = [];
  final IEntityManager _entityManager;
  final IMovementSystem? _movementSystem;
  final ICollisionSystem? _collisionSystem;
  final IInputSystem? _inputSystem;
  final IAudioSystem? _audioSystem;
  final ICameraSystem? _cameraSystem;
  final IRenderSystem? _renderSystem;
  final IParticleSystem? _particleSystem;
  final IStateTransitionSystem? _stateTransitionSystem;
  final IPlayerStateSystem? _playerStateSystem;
  final IPlayerPhysicsSystem? _playerPhysicsSystem;
  final ITileDamageSystem? _tileDamageSystem;
  final ITileStateSystem? _tileStateSystem;

  bool _isInitialized = false;

  ECSOrchestrator({
    required IEntityManager entityManager,
    IMovementSystem? movementSystem,
    ICollisionSystem? collisionSystem,
    IInputSystem? inputSystem,
    IAudioSystem? audioSystem,
    ICameraSystem? cameraSystem,
    IRenderSystem? renderSystem,
    IParticleSystem? particleSystem,
    IStateTransitionSystem? stateTransitionSystem,
    IPlayerStateSystem? playerStateSystem,
    IPlayerPhysicsSystem? playerPhysicsSystem,
    ITileDamageSystem? tileDamageSystem,
    ITileStateSystem? tileStateSystem,
  })  : _entityManager = entityManager,
        _movementSystem = movementSystem,
        _collisionSystem = collisionSystem,
        _inputSystem = inputSystem,
        _audioSystem = audioSystem,
        _cameraSystem = cameraSystem,
        _renderSystem = renderSystem,
        _particleSystem = particleSystem,
        _stateTransitionSystem = stateTransitionSystem,
        _playerStateSystem = playerStateSystem,
        _playerPhysicsSystem = playerPhysicsSystem,
        _tileDamageSystem = tileDamageSystem,
        _tileStateSystem = tileStateSystem;

  /// Initialize all ECS systems
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Add systems in update order (priority-based) - only if they exist
    final systemsToAdd = [
      _inputSystem,           // Priority 10 - process input first
      _playerStateSystem,     // Priority 3 - after input
      _playerPhysicsSystem,   // Priority 4 - after state
      _movementSystem,        // Priority 5 - after physics
      _collisionSystem,       // Priority 6 - after movement
      _tileDamageSystem,      // Priority 5 - after collision
      _tileStateSystem,       // Priority 6 - after damage
      _stateTransitionSystem, // Priority 7 - after state changes
      _particleSystem,        // Priority 8 - visual effects
      _cameraSystem,          // Priority 9 - before rendering
      _renderSystem,          // Priority 10 - render last
      _audioSystem,           // Priority 11 - audio last
    ].where((system) => system != null).cast<GameSystem>();

    _systems.addAll(systemsToAdd);

    // Sort systems by priority
    _systems.sort((a, b) => a.priority.compareTo(b.priority));

    // Initialize all systems
    for (final system in _systems) {
      await system.initialize();
    }
    
    // Connect systems for integration
    _connectSystems();

    _isInitialized = true;
  }
  
  /// Connect systems together for integration
  void _connectSystems() {
    // Set entity manager for all systems that need it
    for (final system in _systems) {
      if (system is InputSystem) {
        system.setEntityManager(_entityManager);
      } else if (system is CollisionSystem) {
        system.setEntityManager(_entityManager);
        // Connect collision system to other systems
        if (_tileDamageSystem != null) {
          system.setTileDamageSystem(_tileDamageSystem!);
        }
        if (_particleSystem != null) {
          system.setParticleSystem(_particleSystem!);
        }
        if (_audioSystem != null) {
          system.setAudioSystem(_audioSystem!);
        }
        if (_cameraSystem != null) {
          system.setCameraSystem(_cameraSystem!);
        }
      } else if (system is PlayerPhysicsSystem) {
        system.setEntityManager(_entityManager);
        // Connect player physics to audio system
        if (_audioSystem != null) {
          system.setAudioSystem(_audioSystem!);
        }
      } else if (system is TileDamageSystem) {
        // Connect tile damage system to particle and audio systems
        if (_particleSystem != null) {
          system.setParticleSystem(_particleSystem!);
        }
        if (_audioSystem != null) {
          system.setAudioSystem(_audioSystem!);
        }
      } else if (system is AudioSystem) {
        system.setEntityManager(_entityManager);
      } else if (system is CameraSystem) {
        system.setEntityManager(_entityManager);
      } else if (system is ParticleSystem) {
        system.setEntityManager(_entityManager);
      } else if (system is RenderSystem) {
        system.setEntityManager(_entityManager);
      }
    }
  }

  /// Update all ECS systems
  void update(double dt) {
    if (!_isInitialized) return;

    for (final system in _systems) {
      if (system.isActive) {
        system.update(dt);
      }
    }
  }

  /// Get a specific system by type
  T? getSystem<T extends GameSystem>() {
    return _systems.whereType<T>().firstOrNull;
  }

  /// Get entity manager
  IEntityManager get entityManager => _entityManager;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose all systems
  void dispose() {
    for (final system in _systems) {
      system.dispose();
    }
    _systems.clear();
    _isInitialized = false;
  }
}