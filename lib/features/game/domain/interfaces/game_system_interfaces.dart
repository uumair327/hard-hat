import 'package:hard_hat/features/game/domain/systems/game_system.dart';
import 'package:hard_hat/features/game/domain/entities/player_entity.dart';
import 'package:hard_hat/features/game/domain/entities/tile.dart';

/// Abstract interface for movement system
abstract class IMovementSystem extends GameSystem {
  void updateMovement(double dt);
}

/// Abstract interface for collision system
abstract class ICollisionSystem extends GameSystem {
  void detectCollisions();
  void processCollisions(double dt);
}

/// Abstract interface for input system
abstract class IInputSystem extends GameSystem {
  void handleKeyEvent(dynamic event, Set<dynamic> keysPressed);
  void processInputEvents(double dt);
}

/// Abstract interface for audio system
abstract class IAudioSystem extends GameSystem {
  void playSound(String soundId);
  void stopSound(String soundId);
  void pauseAudio();
  void resumeAudio();
  void setVolume(double volume);
}

/// Abstract interface for camera system
abstract class ICameraSystem extends GameSystem {
  void setTarget(dynamic target);
  void updateCamera(double dt);
  void setViewport(double width, double height);
}

/// Abstract interface for render system
abstract class IRenderSystem extends GameSystem {
  void renderEntities(double dt);
  void enableBatching(bool enabled);
  void setMaxBatchSize(int size);
}

/// Abstract interface for particle system
abstract class IParticleSystem extends GameSystem {
  void spawnParticles(String type, dynamic position);
  void updateParticles(double dt);
  void clearParticles();
}

/// Abstract interface for state transition system
abstract class IStateTransitionSystem extends GameSystem {
  void processStateTransitions(double dt);
  void queueStateTransition(dynamic entity, dynamic newState);
}

/// Abstract interface for level manager
abstract class ILevelManager extends GameSystem {
  Future<void> loadLevel(int levelId);
  Future<void> restartLevel();
  dynamic get currentLevel;
  void Function(dynamic level)? onLevelComplete;
  void Function(dynamic level)? onLevelLoaded;
}

/// Abstract interface for save system
abstract class ISaveSystem extends GameSystem {
  Future<void> saveProgress({required int currentLevel, Set<int>? unlockedLevels});
  Future<dynamic> loadProgress();
  dynamic get currentSaveData;
}

/// Abstract interface for player state system
abstract class IPlayerStateSystem extends GameSystem {
  void updatePlayerStates(double dt);
  void forcePlayerState(String playerId, PlayerState state);
  List<PlayerEntity> getPlayersInState(PlayerState state);
}

/// Abstract interface for player physics system
abstract class IPlayerPhysicsSystem extends GameSystem {
  void updatePlayerPhysics(double dt);
  void applyJumpForce(PlayerEntity player);
  void applyExternalForce(PlayerEntity player, dynamic force);
}

/// Abstract interface for tile damage system
abstract class ITileDamageSystem extends GameSystem {
  void queueDamage(TileEntity tile, int damage, {String? source});
  void processDamageEvents(double dt);
}

/// Abstract interface for tile state system
abstract class ITileStateSystem extends GameSystem {
  void updateTileStates(double dt);
  void queueStateTransition(TileEntity tile, TileState newState, {double delay = 0.0});
  List<TileEntity> getTilesInState(TileState state);
}