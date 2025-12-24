import 'package:injectable/injectable.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
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
  AudioSystem get audioSystem => AudioSystem();

  @LazySingleton(as: ICameraSystem)
  CameraSystem get cameraSystem => CameraSystem();

  @LazySingleton(as: IRenderSystem)
  RenderSystem get renderSystem => RenderSystem();

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
    AudioSystem audioSystem,
    AudioManager audioManager,
  ) => AudioStateManager(audioSystem, audioManager);

  // Focus Detector (Singleton)
  @lazySingleton
  FocusDetector get focusDetector => FocusDetector.instance;
}