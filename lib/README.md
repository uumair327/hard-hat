# Hard Hat Havoc - Project Structure

This Flutter project follows Clean Architecture principles with a feature-based directory structure.

## Directory Structure

```
lib/
├── core/                          # Core functionality shared across features
│   ├── app/                       # App initialization and configuration
│   ├── config/                    # Environment and build configuration
│   ├── constants/                 # Game constants and configuration values
│   ├── di/                        # Dependency injection setup
│   ├── errors/                    # Error handling (failures & exceptions)
│   ├── navigation/                # App routing configuration
│   └── services/                  # Core services (asset, audio management)
│
├── features/                      # Feature modules
│   ├── game/                      # Main game feature
│   │   ├── data/                  # Data layer
│   │   │   ├── datasources/       # Local/remote data sources
│   │   │   ├── models/            # Data models with JSON serialization
│   │   │   └── repositories/      # Repository implementations
│   │   ├── domain/                # Domain layer (business logic)
│   │   │   ├── entities/          # Domain entities
│   │   │   ├── repositories/      # Repository interfaces
│   │   │   └── usecases/          # Use cases (business operations)
│   │   └── presentation/          # Presentation layer
│   │       ├── bloc/              # BLoC state management
│   │       ├── game/              # Flame game implementation
│   │       ├── pages/             # UI pages
│   │       └── widgets/           # Reusable widgets
│   │
│   ├── menu/                      # Main menu feature
│   │   └── presentation/
│   │
│   └── settings/                  # Settings feature
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart                      # App entry point (development)
    main_development.dart          # Development flavor entry point
    main_production.dart           # Production flavor entry point

assets/
├── images/                        # Sprite and image assets
├── audio/                         # Sound effects and music
└── data/                          # Level data and configurations
```

## Architecture Layers

### 1. Presentation Layer
- **BLoC**: State management using flutter_bloc
- **Pages**: Full-screen UI components
- **Widgets**: Reusable UI components
- **Game**: Flame game engine components

### 2. Domain Layer
- **Entities**: Core business objects
- **Repositories**: Abstract interfaces for data access
- **Use Cases**: Single-responsibility business operations

### 3. Data Layer
- **Models**: Data transfer objects with JSON serialization
- **Data Sources**: Local storage and asset loading
- **Repositories**: Concrete implementations of domain repositories

## Key Dependencies

- **flame**: Game engine for 2D game development
- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **go_router**: Navigation and routing
- **dartz**: Functional programming (Either type for error handling)
- **equatable**: Value equality for entities and states
- **json_annotation**: JSON serialization

## Build Flavors

The project supports two build flavors:

1. **Development**: `flutter run -t lib/main_development.dart`
   - Debug logging enabled
   - Development API endpoints
   - Debug UI elements visible

2. **Production**: `flutter run -t lib/main_production.dart`
   - Optimized for release
   - Production API endpoints
   - Debug features disabled

## Next Steps

1. Implement ECS architecture (Task 2)
2. Create asset management system (Task 3)
3. Implement input handling (Task 4)
4. Build physics and collision systems (Task 5)
5. Create game entities (Task 6)
