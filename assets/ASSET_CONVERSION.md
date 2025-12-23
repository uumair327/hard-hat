# Asset Conversion Documentation

This document describes the conversion of assets from the Godot Hard Hat project to Flutter-compatible formats.

## Overview

Assets have been converted from the Godot project located in `godot_Hard-Hat/assets/` to Flutter-compatible formats in the `assets/` directory. The conversion includes sprites, audio files, and level data.

## Directory Structure

```
assets/
├── images/
│   └── sprites/
│       ├── game/
│       │   ├── player/          # Player animation sprites
│       │   ├── particles/       # Particle effect sprites
│       │   ├── hud/            # HUD elements
│       │   ├── background.png
│       │   └── transition.png
│       ├── tiles/              # Tile textures from Godot meshes
│       └── ui/                 # UI button sprites
├── audio/
│   ├── music/                  # Background music tracks
│   ├── sfx/                    # Sound effects
│   └── loop/                   # Looping audio clips
└── data/
    ├── levels/                 # Level JSON data
    └── atlases/                # Sprite atlas definitions
```

## Asset Conversion Details

### Sprites

#### Player Sprites
Converted from `godot_Hard-Hat/assets/sprite/game/player/`:
- `idle.png` - Idle animation frame
- `run.png` - Running animation frame
- `jump.png` - Jump animation frame
- `fall.png` - Falling animation frame
- `peak.png` - Jump peak animation frame
- `aim.png` - Aiming animation frame
- `strike.png` - Strike animation frame
- `death.png` - Death animation frame

#### Tile Sprites
Converted from `godot_Hard-Hat/assets/mesh/*/texture.png`:
- `scaffolding.png` - Destructible scaffolding tile
- `timber.png` - Timber tile (full health)
- `timber_one_hit.png` - Timber tile (damaged)
- `bricks.png` - Brick tile (full health)
- `bricks_one_hit.png` - Brick tile (1 hit taken)
- `bricks_two_hits.png` - Brick tile (2 hits taken)
- `beam.png` - Indestructible beam
- `girder.png` - Indestructible girder
- `support.png` - Support structure
- `spring.png` - Spring interactive element
- `elevator.png` - Elevator platform
- `spikes.png` - Spike hazard
- `shutter.png` - Shutter element

#### UI Sprites
Converted from `godot_Hard-Hat/assets/sprite/main_menu/` and `pause_menu/`:
- Main menu buttons (play, config, quit)
- Pause menu buttons (resume, restart, quit)
- Button silhouettes for hover states

#### Particle Sprites
Converted from `godot_Hard-Hat/assets/sprite/game/particle/`:
- `star_particle.svg` - Star particle for impacts
- `step_particle.svg` - Step particle for movement

### Audio

#### Music
Converted from `godot_Hard-Hat/assets/audio/music/`:
- `title.mp3` - Main menu music
- `gameplay.mp3` - Gameplay background music

#### Sound Effects
Converted from `godot_Hard-Hat/assets/audio/sfx/`:
- `break.mp3` - Tile breaking sound
- `hit.mp3` - Ball hitting surface
- `land.mp3` - Player landing sound
- `strike.mp3` - Player strike sound
- `boing.mp3` - Spring bounce sound
- `death.mp3` - Player death sound
- `confirm.mp3` - UI confirmation sound
- `ding.mp3` - Success/completion sound
- `tick.mp3` - Timer tick sound
- `fizzle.mp3` - Fizzle effect sound
- `elevator.mp3` - Elevator sound
- `transition_pop_in.mp3` - Transition in sound
- `transition_pop_out.mp3` - Transition out sound

#### Looping Audio
Converted from `godot_Hard-Hat/assets/audio/loop/`:
- `step.mp3` - Looping step sound
- `elevator.mp3` - Looping elevator sound

### Sprite Atlases

For performance optimization, sprites are organized into atlases:

1. **game.json** - Player sprites atlas
2. **tiles.json** - Tile sprites atlas
3. **ui.json** - UI sprites atlas
4. **particles.json** - Particle sprites atlas

Each atlas definition includes:
- Sprite names and paths
- Atlas coordinates (x, y)
- Sprite dimensions (width, height)
- Animation sequences (where applicable)

## Asset Optimization

### Mobile Optimization
- Sprites are sized appropriately for mobile devices
- Audio files use MP3 format for broad compatibility
- Sprite atlases reduce draw calls for better performance

### Web Optimization
- SVG format used for scalable UI elements where possible
- Asset lazy loading implemented for faster initial load
- Sprite batching reduces rendering overhead

## Usage

Assets are registered in `lib/core/services/asset_registry.dart` and can be accessed through the `AssetManager` service:

```dart
// Load a sprite
final sprite = await assetManager.loadSprite('player_idle');

// Load audio
await assetManager.loadAudio('sfx_jump');

// Load level data
final levelData = await assetManager.loadLevelData('level_1');
```

## Asset Converter Tool

The `AssetConverter` class in `lib/core/services/asset_converter.dart` provides utilities for:
- Copying assets from Godot to Flutter directories
- Generating sprite atlas definitions
- Optimizing assets for mobile and web deployment

To run the asset converter:

```dart
await AssetConverter.convertAllAssets();
```

## Manual Conversion Steps

If assets need to be manually copied from Godot:

1. Copy PNG files from `godot_Hard-Hat/assets/sprite/` to `assets/images/sprites/`
2. Copy MP3 files from `godot_Hard-Hat/assets/audio/` to `assets/audio/`
3. Copy mesh textures from `godot_Hard-Hat/assets/mesh/*/texture.png` to `assets/images/sprites/tiles/`
4. Update `pubspec.yaml` to include new asset directories
5. Update `asset_registry.dart` with new asset definitions
6. Generate sprite atlas definitions in `assets/data/atlases/`

## Notes

- Original Godot assets remain in `godot_Hard-Hat/` for reference
- Asset paths in code use Flutter's asset system (no leading slash)
- All assets are declared in `pubspec.yaml` for Flutter to bundle them
- Sprite atlases improve rendering performance through batching
- Asset caching is handled by the `AssetManager` service

## Future Improvements

- Automated sprite atlas packing tool
- Asset compression pipeline
- Texture format optimization (WebP for web, etc.)
- Audio format optimization per platform
- Asset versioning and cache invalidation
