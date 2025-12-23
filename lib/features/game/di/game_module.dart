import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_system_interfaces.dart';
import 'package:hard_hat/features/game/domain/interfaces/entity_manager_interface.dart';
import 'package:hard_hat/features/game/domain/interfaces/game_state_manager_interface.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager_impl.dart';
import 'package:hard_hat/features/game/domain/systems/game_state_manager_impl.dart';
import 'package:hard_hat/features/game/domain/systems/movement_system.dart';
import 'package:hard_hat/features/game/domain/systems/collision_system.dart';
import 'package:hard_hat/features/game/domain/systems/input_system.dart';
import 'package:hard_hat/features/game/domain/systems/audio_system.dart';
import 'package:hard_hat/features/game/domain/systems/camera_system.dart';
import 'package:hard_hat/features/game/domain/systems/render_system.dart';
import 'package:hard_hat/features/game/domain/systems/particle_system.dart';
import 'package:hard_hat/features/game/domain/systems/state_transition_system.dart';
import 'package:hard_hat/features/game/domain/systems/level_manager.dart';
import 'package:hard_hat/features/game/domain/systems/save_system.dart';
import 'package:hard_hat/features/game/domain/systems/player_state_system.dart';
import 'package:hard_hat/features/game/domain/systems/player_physics_system.dart';
import 'package:hard_hat/features/game/domain/systems/tile_damage_system.dart';
import 'package:hard_hat/features/game/domain/systems/tile_state_system.dart';
import 'package:hard_hat/features/game/domain/systems/audio_state_manager.dart';
import 'package:hard_hat/features/game/domain/services/focus_detector.dart';
import 'package:hard_hat/features/game/domain/repositories/level_repository.dart';
import 'package:hard_hat/features/game/domain/repositories/save_repository.dart';
import 'package:hard_hat/core/services/asset_manager.dart';
import 'package:hard_hat/core/services/audio_manager.dart';

@module
abstract class GameModule {
  // Entity Manager
  @LazySingleton(as: IEntityManager)
  EntityManagerImpl get entityManager => EntityManagerImpl();

  // Game State Manager  
  @LazySingleton(as: IGameStateManager)
  GameStateManagerImpl gameStateManager(AudioStateManager audioStateManager) => 
      GameStateManagerImpl(audioStateManager);

  // Game Systems - Register concrete implementations for interfaces
  
  @LazySingleton(as: IMovementSystem)
  MovementSystem get movementSystem => MovementSystem();

  @LazySingleton(as: ICollisionSystem)
  CollisionSystem get collisionSystem => CollisionSystem();

  @LazySingleton(as: IInputSystem)
  InputSystem get inputSystem => InputSystem();

  @LazySingleton(as: IAudioSystem)
  AudioSystem audioSystem(AssetManager assetManager) => AudioSystem(assetManager);

  @LazySingleton(as: ICameraSystem)
  CameraSystem get cameraSystem => CameraSystem();

  @LazySingleton(as: IRenderSystem)
  RenderSystem get renderSystem => RenderSystem(
    enableBatching: true,
    maxBatchSize: 1000,
    enableParticlePooling: true,
  );

  @LazySingleton(as: IParticleSystem)
  ParticleSystem get particleSystem => ParticleSystem();

  @LazySingleton(as: IStateTransitionSystem)
  StateTransitionSystem get stateTransitionSystem => StateTransitionSystem();

  @LazySingleton(as: ILevelManager)
  LevelManager levelManager(
    LevelRepository levelRepository,
    IEntityManager entityManager,
  ) => LevelManager(
    levelRepository: levelRepository,
    entityManager: entityManager,
  );

  @LazySingleton(as: ISaveSystem)
  SaveSystem saveSystem(SaveRepository saveRepository) => SaveSystem(saveRepository);

  @LazySingleton(as: IPlayerStateSystem)
  PlayerStateSystem get playerStateSystem => PlayerStateSystem();

  @LazySingleton(as: IPlayerPhysicsSystem)
  PlayerPhysicsSystem get playerPhysicsSystem => PlayerPhysicsSystem();

  @LazySingleton(as: ITileDamageSystem)
  TileDamageSystem get tileDamageSystem => TileDamageSystem();

  @LazySingleton(as: ITileStateSystem)
  TileStateSystem get tileStateSystem => TileStateSystem();

  // Audio State Manager
  @lazySingleton
  AudioStateManager audioStateManager(
    IAudioSystem audioSystem,
    AudioManager audioManager,
  ) => AudioStateManager(audioSystem, audioManager);

  // Focus Detector (Singleton)
  @lazySingleton
  FocusDetector get focusDetector => FocusDetector.instance;
}