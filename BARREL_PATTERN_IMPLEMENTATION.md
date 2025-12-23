# Barrel Pattern Implementation Guide

## Overview
This document outlines the barrel pattern implementation across the Hard Hat Flutter project and the fixes applied to ensure consistent usage.

## Barrel Pattern Structure

### Core Barrel (`lib/core/core.dart`)
Exports all core functionality:
- App configuration
- Constants
- Dependency injection
- Error handling
- Navigation
- Services
- Utilities

### Features Barrel (`lib/features/features.dart`)
Exports all feature modules:
- Game feature
- Menu feature
- Settings feature

### Game Feature Barrel Structure

#### Main Game Barrel (`lib/features/game/game.dart`)
```dart
export 'data/data.dart';
export 'domain/domain.dart';
export 'presentation/presentation.dart';
export 'di/di.dart';
```

#### Domain Layer (`lib/features/game/domain/domain.dart`)
```dart
export 'components/components.dart';
export 'entities/entities.dart';
export 'input/input.dart';
export 'interfaces/interfaces.dart';
export 'orchestrators/orchestrators.dart';
export 'repositories/repositories.dart';
export 'services/services.dart';
export 'strategies/strategies.dart';
export 'systems/systems.dart';
export 'usecases/usecases.dart';
export 'ecs.dart';
```

#### Data Layer (`lib/features/game/data/data.dart`)
```dart
export 'datasources/datasources.dart';
export 'models/models.dart';
export 'repositories/repositories.dart';
```

#### Presentation Layer (`lib/features/game/presentation/presentation.dart`)
```dart
export 'bloc/bloc.dart';
export 'game/game.dart';
export 'overlays/overlays.dart';
export 'pages/pages.dart';
export 'services/services.dart';
export 'widgets/widgets.dart';
```

## Violations Fixed

### 1. Naming Conflicts
**Issue**: `TileType` enum was defined in both:
- `lib/features/game/domain/entities/tile.dart`
- `lib/features/game/domain/systems/particle_system.dart`

**Fix**: Removed duplicate `TileType` from `particle_system.dart` and imported it from `tile.dart`.

**Issue**: `GameState` class/enum conflict between:
- `lib/features/game/domain/systems/game_state_manager.dart` (enum)
- `lib/features/game/presentation/bloc/game_state.dart` (class)

**Fix**: 
- Created separate export file `game_state_types.dart` for GameState enum
- Used `hide GameState` directive in domain barrel to prevent conflict
- Presentation layer uses its own GameState class while domain can access enum

**Issue**: `TransitionType` enum was defined in both:
- `lib/features/game/domain/systems/level_transition_system.dart`
- `lib/features/game/domain/systems/state_transition_system.dart`

**Fix**: Renamed `TransitionType` to `StateTransitionType` in `state_transition_system.dart`

### 2. Duplicate Components
**Issue**: `DamageComponent` was defined in both:
- `lib/features/game/domain/components/damage_component.dart`
- `lib/features/game/domain/systems/tile_damage_system.dart`

**Fix**: 
- Removed duplicate from `tile_damage_system.dart`
- Added `damage_component.dart` to components barrel
- Updated imports to use barrel exports

### 3. Direct Imports Instead of Barrel Exports
**Issue**: Many files were importing directly from specific files instead of using barrel exports.

**Files Fixed**:
- `lib/features/game/di/game_injection.dart`
- `lib/features/game/di/game_module.dart`
- `lib/features/game/data/repositories/level_repository_impl.dart`
- `lib/features/game/data/repositories/save_repository_impl.dart`
- `lib/features/game/domain/orchestrators/level_orchestrator.dart`
- `lib/features/game/domain/services/game_controller.dart`
- `lib/features/game/domain/systems/player_physics_system.dart`
- `lib/features/game/domain/systems/player_state_system.dart`
- `lib/features/game/domain/systems/tile_damage_system.dart`
- `lib/features/game/domain/systems/tile_state_system.dart`

**Fix**: Replaced direct imports with barrel imports:
```dart
// Before
import 'package:hard_hat/features/game/domain/systems/entity_manager.dart';
import 'package:hard_hat/features/game/domain/systems/game_system.dart';
// ... many more direct imports

// After
import 'package:hard_hat/features/game/domain/domain.dart';
```

### 4. Missing Component Files
**Issue**: `input_component.dart` was referenced from wrong location.

**Fix**: Updated import paths to reference correct location:
```dart
// Before
import 'package:hard_hat/features/game/domain/components/input_component.dart';

// After
import 'package:hard_hat/features/game/domain/input/input_component.dart';
```

### 5. Missing Barrel Exports
**Issue**: Some files were missing from barrel exports.

**Fix**: Added missing exports to appropriate barrel files:
- Added `damage_component.dart` to `components/components.dart`

## Barrel Pattern Rules

### 1. Import Hierarchy
- Always import from the highest level barrel possible
- Use feature-level barrels (`game.dart`) for cross-feature imports
- Use layer-level barrels (`domain.dart`, `data.dart`, `presentation.dart`) for cross-layer imports
- Use specific barrels (`components.dart`, `entities.dart`) only when needed

### 2. Export Organization
- Group related exports together with comments
- Maintain alphabetical order within groups
- Include all public files in appropriate barrels

### 3. Naming Conventions
- Barrel files should be named after their directory
- Use descriptive comments for each export group
- Maintain consistent export patterns across features

### 4. Conflict Resolution Strategies
- **Separate Type Exports**: Created `game_state_types.dart` for exporting only specific types
- **Hide Directives**: Used `export 'file.dart' hide ClassName;` to prevent conflicts
- **Rename Conflicting Types**: Renamed `TransitionType` to `StateTransitionType` for clarity
- **Layer Separation**: Domain and presentation layers can have different classes with same names

## Benefits Achieved

1. **Reduced Import Complexity**: Single import statements replace multiple direct imports
2. **Better Maintainability**: Changes to file locations only require barrel updates
3. **Cleaner Code**: Less import clutter at the top of files
4. **Consistent Structure**: Standardized import patterns across the project
5. **Easier Refactoring**: Barrel exports provide abstraction layer for internal changes

## Verification

All barrel pattern violations have been identified and fixed. The project now follows consistent barrel pattern usage throughout all features and layers.