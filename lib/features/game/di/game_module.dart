import 'package:injectable/injectable.dart';
import 'package:flame/cache.dart';
import 'package:hard_hat/features/game/domain/domain.dart';
import 'package:hard_hat/core/services/audio_manager.dart';

@module
abstract class GameModule {
  // Flame Images cache
  @lazySingleton
  Images get images => Images();

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
    IAudioSystem audioSystem,
    AudioManager audioManager,
  ) => AudioStateManager(audioSystem as AudioSystem, audioManager);

  // Focus Detector (Singleton)
  @lazySingleton
  FocusDetector get focusDetector => FocusDetector.instance;

  // Orchestrators
  @lazySingleton
  ECSOrchestrator ecsOrchestrator(
    IEntityManager entityManager,
    IMovementSystem movementSystem,
    ICollisionSystem collisionSystem,
    IInputSystem inputSystem,
    IAudioSystem audioSystem,
    ICameraSystem cameraSystem,
    IRenderSystem renderSystem,
    IParticleSystem particleSystem,
    IStateTransitionSystem stateTransitionSystem,
    IPlayerStateSystem playerStateSystem,
    IPlayerPhysicsSystem playerPhysicsSystem,
    ITileDamageSystem tileDamageSystem,
    ITileStateSystem tileStateSystem,
  ) => ECSOrchestrator(
    entityManager: entityManager as EntityManager,
    movementSystem: movementSystem,
    collisionSystem: collisionSystem,
    inputSystem: inputSystem,
    audioSystem: audioSystem,
    cameraSystem: cameraSystem,
    renderSystem: renderSystem,
    particleSystem: particleSystem,
    stateTransitionSystem: stateTransitionSystem,
    playerStateSystem: playerStateSystem,
    playerPhysicsSystem: playerPhysicsSystem,
    tileDamageSystem: tileDamageSystem,
    tileStateSystem: tileStateSystem,
  );

  @lazySingleton
  GameStateOrchestrator gameStateOrchestrator(
    IGameStateManager gameStateManager,
    FocusDetector focusDetector,
  ) => GameStateOrchestrator(
    gameStateManager: gameStateManager,
    pauseMenuManager: null, // Will be set later when pause menu service is available
    focusDetector: focusDetector,
  );

  @lazySingleton
  LevelOrchestrator levelOrchestrator(
    ILevelManager levelManager,
    ISaveSystem saveSystem,
    IEntityManager entityManager,
  ) => LevelOrchestrator(
    levelManager: levelManager,
    saveSystem: saveSystem,
    entityManager: entityManager,
  );
}