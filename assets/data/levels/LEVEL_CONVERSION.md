# Level Data Conversion Documentation

This document describes the conversion of level data from Godot scene files (.tscn) to Flutter JSON format.

## Overview

Levels have been converted from Godot 3D scenes to 2D Flutter JSON data structures. The conversion process extracts tile layouts, interactive elements, camera segments, and objectives from Godot's GridMap system and transforms them into a format suitable for the Flutter Flame engine.

## Conversion Process

### 1. Godot Level Structure

Godot levels use:
- **GridMap**: 3D tile-based level layout
- **Node3D Segments**: Camera boundary regions
- **PackedScenes**: Interactive elements (elevators, springs, etc.)
- **GDScript**: Level logic and objectives

### 2. Flutter Level Structure

Flutter levels use:
- **JSON Data**: Tile positions and properties
- **2D Coordinates**: Converted from Godot's 3D grid
- **Element Definitions**: Interactive element configurations
- **Objective System**: Level completion criteria

## Level Data Format

### Top-Level Structure

```json
{
  "id": 1,
  "name": "Level Name",
  "description": "Level description",
  "size": {"x": 2400, "y": 800},
  "playerSpawn": {"x": 100, "y": 500},
  "cameraMin": {"x": 0, "y": 0},
  "cameraMax": {"x": 2400, "y": 800},
  "tiles": [...],
  "elements": [...],
  "segments": [...],
  "objectives": [...],
  "metadata": {...}
}
```

### Tile Format

```json
{
  "position": {"x": 200, "y": 400},
  "type": "scaffolding",
  "durability": 1,
  "maxDurability": 1,
  "isDestructible": true
}
```

### Element Format

```json
{
  "type": "elevator",
  "position": {"x": 600, "y": 500},
  "properties": {
    "speed": 2.0,
    "range": 160.0
  }
}
```

### Segment Format

```json
{
  "id": 0,
  "bounds": {
    "min": {"x": 0, "y": 0},
    "max": {"x": 800, "y": 600}
  }
}
```

### Objective Format

```json
{
  "type": "reach_elevator",
  "description": "Reach the elevator to complete the level",
  "position": {"x": 2544, "y": 96}
}
```

## Tile Type Mapping

Godot mesh library IDs are mapped to Flutter tile types:

| Godot ID | Flutter Type | Durability | Destructible |
|----------|--------------|------------|--------------|
| 0 | scaffolding | 1 | Yes |
| 1 | timber | 2 | Yes |
| 2 | timber_one_hit | 1 | Yes |
| 3 | bricks | 3 | Yes |
| 4 | bricks_one_hit | 2 | Yes |
| 5 | bricks_two_hits | 1 | Yes |
| 6 | beam | -1 | No |
| 65537 | girder | -1 | No |
| 131078 | support | -1 | No |
| 196614 | beam | -1 | No |

## Coordinate Conversion

### Godot to Flutter Coordinates

Godot uses a 3D coordinate system with:
- X: Horizontal (left-right)
- Y: Vertical (up-down)
- Z: Depth (forward-back)

Flutter uses a 2D coordinate system with:
- X: Horizontal (left-right)
- Y: Vertical (top-bottom, inverted from Godot)

Conversion formula:
```dart
flutterX = godotX * 32.0  // Grid cell size
flutterY = -godotY * 32.0 // Inverted Y axis
```

### Grid to Pixel Conversion

Godot GridMap uses integer grid coordinates. Flutter uses pixel coordinates:
- Each grid cell = 32x32 pixels
- Grid position (10, 5) = Pixel position (320, 160)

## Interactive Elements

### Elevator

Converted from Godot's Elevator PackedScene:
```json
{
  "type": "elevator",
  "position": {"x": 2544, "y": 96},
  "properties": {
    "speed": 2.0,
    "range": 160.0
  }
}
```

### Spring

Converted from Godot's Spring mesh:
```json
{
  "type": "spring",
  "position": {"x": 800, "y": 400},
  "properties": {
    "force": 500.0,
    "cooldown": 0.5
  }
}
```

### Target

Converted from Godot's Target mesh:
```json
{
  "type": "target",
  "position": {"x": 1200, "y": 300},
  "properties": {
    "radius": 20.0,
    "points": 100
  }
}
```

## Camera Segments

Camera segments define regions where the camera follows the player with specific boundaries:

```json
{
  "id": 0,
  "bounds": {
    "min": {"x": -400, "y": -300},
    "max": {"x": 400, "y": 300}
  }
}
```

When the player enters a segment, the camera adjusts its boundaries to match that segment.

## Objectives

Objectives define level completion criteria:

### Reach Elevator
```json
{
  "type": "reach_elevator",
  "description": "Reach the elevator to complete the level",
  "position": {"x": 2544, "y": 96}
}
```

### Clear Path
```json
{
  "type": "clear_path",
  "description": "Clear the path and reach the end"
}
```

### Destroy Targets
```json
{
  "type": "destroy_targets",
  "description": "Destroy all target blocks",
  "count": 5
}
```

### Reach Top
```json
{
  "type": "reach_top",
  "description": "Reach the top of the tower"
}
```

## Conversion Tools

### GodotLevelConverter

Located in `lib/core/services/godot_level_converter.dart`, this service:
- Parses Godot .tscn files
- Extracts GridMap data
- Converts coordinates
- Maps tile IDs to types
- Generates Flutter JSON

Usage:
```dart
await GodotLevelConverter.convertAllLevels();
```

### LevelEditor

Located in `lib/core/services/level_editor.dart`, this utility:
- Creates new levels
- Adds/removes tiles
- Adds interactive elements
- Validates level structure
- Saves level data

Usage:
```dart
var level = await LevelEditor.createNewLevel(
  id: 5,
  name: 'Custom Level',
  width: 1600,
  height: 1200,
);

level = LevelEditor.addTile(level, x: 200, y: 400, type: 'scaffolding');
level = LevelEditor.addElement(level, type: 'elevator', x: 800, y: 500);

await LevelEditor.saveLevelData(level);
```

### LevelValidator

Located in `lib/core/services/level_validator.dart`, this utility:
- Validates level structure
- Checks for design issues
- Tests playability
- Provides suggestions

Usage:
```dart
final result = LevelValidator.validateLevel(levelData);
print(result.toString());

final playability = LevelValidator.testPlayability(levelData);
print(playability.toString());
```

## Level Index

The `levels.json` file contains metadata for all levels:

```json
{
  "levels": [
    {
      "id": 1,
      "name": "Tutorial Level",
      "description": "Learn the basic mechanics",
      "unlocked": true,
      "dataPath": "data/levels/level_1.json"
    },
    ...
  ]
}
```

## Creating New Levels

### Manual Creation

1. Create a new JSON file: `level_X.json`
2. Follow the level data format
3. Add tiles, elements, and objectives
4. Validate using `LevelValidator`
5. Update `levels.json` index

### Using Level Editor

```dart
// Create new level
var level = await LevelEditor.createNewLevel(
  id: 5,
  name: 'My Custom Level',
);

// Add ground platform
level = LevelEditor.addPlatform(
  level,
  x: 0,
  y: 500,
  width: 20,
  tileType: 'beam',
);

// Add destructible obstacles
level = LevelEditor.addWall(
  level,
  x: 400,
  y: 300,
  height: 5,
  tileType: 'scaffolding',
);

// Add elevator
level = LevelEditor.addElement(
  level,
  type: 'elevator',
  x: 1200,
  y: 400,
);

// Add objective
level = LevelEditor.addObjective(
  level,
  type: 'reach_elevator',
  description: 'Reach the elevator',
);

// Validate and save
final validation = LevelValidator.validateLevel(level);
if (validation.isValid) {
  await LevelEditor.saveLevelData(level);
}
```

## Testing Levels

### Validation

```dart
final result = LevelValidator.validateLevel(levelData);

if (!result.isValid) {
  print('Errors:');
  for (final error in result.errors) {
    print('  - $error');
  }
}

if (result.warnings.isNotEmpty) {
  print('Warnings:');
  for (final warning in result.warnings) {
    print('  - $warning');
  }
}
```

### Playability Testing

```dart
final playability = LevelValidator.testPlayability(levelData);

if (!playability.isPlayable) {
  print('Level is not playable:');
  for (final issue in playability.issues) {
    print('  - $issue');
  }
}

if (!playability.completionPossible) {
  print('Level completion may not be possible');
}
```

## Best Practices

1. **Start with player spawn**: Ensure the player has a safe spawn point with ground support
2. **Add ground level**: Provide a base platform for the player to stand on
3. **Create progression**: Design a clear path from start to finish
4. **Balance difficulty**: Mix destructible and indestructible tiles
5. **Add variety**: Use different tile types and interactive elements
6. **Test thoroughly**: Validate and playtest before finalizing
7. **Set clear objectives**: Give players a goal to work towards
8. **Use camera segments**: Define camera boundaries for better player experience

## Troubleshooting

### Player Falls Through World
- Add ground tiles at the bottom of the level
- Ensure player spawn has support below it

### Level Too Easy/Hard
- Adjust destructible/indestructible tile ratio
- Add or remove interactive elements
- Modify tile durability values

### Performance Issues
- Reduce total tile count (keep under 500)
- Limit interactive elements (keep under 20)
- Optimize level size

### Objectives Not Working
- Ensure objective positions match element positions
- Verify objective types are implemented
- Check objective properties are correct

## Future Improvements

- Visual level editor UI
- Automated playability testing
- Level difficulty calculator
- Tile pattern templates
- Level generation algorithms
- Multi-layer level support
- Dynamic level loading
