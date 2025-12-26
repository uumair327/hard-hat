import 'package:get_it/get_it.dart';
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/systems/audio_system.dart';
import 'package:hard_hat/features/game/domain/systems/render_system.dart';
import 'package:hard_hat/features/game/domain/systems/input_system.dart';
import 'package:hard_hat/features/game/domain/systems/collision_system.dart';
import 'package:hard_hat/features/game/domain/systems/movement_system.dart';
import 'package:hard_hat/features/game/domain/systems/camera_system.dart';
import 'package:hard_hat/features/game/domain/systems/particle_system.dart';
import 'package:hard_hat/features/game/domain/systems/player_physics_system.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Register EntityManager
  sl.registerLazySingleton<EntityManager>(() => EntityManager());
  
  // Register Systems
  sl.registerLazySingleton<AudioSystem>(() => AudioSystem());
  sl.registerLazySingleton<RenderSystem>(() => RenderSystem());
  sl.registerLazySingleton<InputSystem>(() => InputSystem());
  sl.registerLazySingleton<CollisionSystem>(() => CollisionSystem());
  sl.registerLazySingleton<MovementSystem>(() => MovementSystem());
  sl.registerLazySingleton<CameraSystem>(() => CameraSystem());
  sl.registerLazySingleton<ParticleSystem>(() => ParticleSystem());
  sl.registerLazySingleton<PlayerPhysicsSystem>(() => PlayerPhysicsSystem());
}

/// Reset all dependencies (for testing)
void resetDependencies() {
  sl.reset();
}