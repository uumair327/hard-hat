// Game Domain Systems barrel export

// Core System
export 'game_system.dart';

// Entity Management
export 'entity_manager.dart';
export 'entity_manager_impl.dart';

// Game State Management
export 'game_state_manager.dart' hide GameState;
export 'game_state_manager_impl.dart';
export 'game_state_types.dart'; // Separate export for GameState enum

// Audio Systems
export 'audio_state_manager.dart';
export 'audio_system.dart';

// Core Game Systems
export 'camera_system.dart';
export 'collision_system.dart';
export 'input_system.dart';
export 'movement_system.dart';
export 'particle_system.dart';
export 'render_system.dart';

// Level Management
export 'level_manager.dart';
export 'level_transition_system.dart';
export 'save_system.dart';

// Player Systems
export 'player_physics_system.dart';
export 'player_state_system.dart';

// State Management
export 'state_transition_system.dart';

// Tile Systems
export 'tile_damage_system.dart';
export 'tile_state_system.dart';