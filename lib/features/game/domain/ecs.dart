// ECS Architecture Exports
// This file provides a single import point for all ECS-related classes

// Components
export 'components/position_component.dart';
export 'components/velocity_component.dart';
export 'components/collision_component.dart';
export 'components/sprite_component.dart';

// Systems
export 'systems/game_system.dart';
export 'systems/entity_manager.dart';

// Entities
export 'entities/game_entity.dart';

// Services
export 'services/game_service_locator.dart';

// Dependency Injection
export '../di/game_injection.dart';