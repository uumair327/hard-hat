import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Level editor utility for creating and modifying game levels
/// Moved from core to game domain as it's game-specific functionality
class LevelEditor {
  static const String _levelsPath = 'assets/data/levels';

  /// Create a new level with basic structure
  static Future<Map<String, dynamic>> createNewLevel({
    required int id,
    required String name,
    String description = '',
    double width = 1600,
    double height = 1200,
    double playerSpawnX = 100,
    double playerSpawnY = 500,
  }) async {
    final levelData = {
      'id': id,
      'name': name,
      'description': description,
      'size': {'x': width, 'y': height},
      'playerSpawn': {'x': playerSpawnX, 'y': playerSpawnY},
      'cameraMin': {'x': 0.0, 'y': 0.0},
      'cameraMax': {'x': width, 'y': height},
      'tiles': <Map<String, dynamic>>[],
      'elements': <Map<String, dynamic>>[],
      'segments': <Map<String, dynamic>>[],
      'objectives': <Map<String, dynamic>>[],
      'metadata': {
        'created': DateTime.now().toIso8601String(),
        'version': '1.0',
        'author': 'Level Editor',
      },
    };

    await saveLevelData(levelData);
    return levelData;
  }

  /// Add a tile to the level
  static Map<String, dynamic> addTile(
    Map<String, dynamic> levelData, {
    required double x,
    required double y,
    required String type,
    int? durability,
    int? maxDurability,
    bool? isDestructible,
  }) {
    final tileProperties = _getTileProperties(type);
    
    final tile = {
      'position': {'x': x, 'y': y},
      'type': type,
      'durability': durability ?? tileProperties['durability'],
      'maxDurability': maxDurability ?? tileProperties['maxDurability'],
      'isDestructible': isDestructible ?? tileProperties['isDestructible'],
    };

    final tiles = List<Map<String, dynamic>>.from(levelData['tiles'] ?? []);
    tiles.add(tile);
    levelData['tiles'] = tiles;

    return levelData;
  }

  /// Remove a tile from the level
  static Map<String, dynamic> removeTile(
    Map<String, dynamic> levelData, {
    required double x,
    required double y,
    double tolerance = 16.0,
  }) {
    final tiles = List<Map<String, dynamic>>.from(levelData['tiles'] ?? []);
    
    tiles.removeWhere((tile) {
      final tileX = tile['position']['x'];
      final tileY = tile['position']['y'];
      final distance = ((tileX - x) * (tileX - x) + (tileY - y) * (tileY - y));
      return distance <= tolerance * tolerance;
    });

    levelData['tiles'] = tiles;
    return levelData;
  }

  /// Add an interactive element to the level
  static Map<String, dynamic> addElement(
    Map<String, dynamic> levelData, {
    required String type,
    required double x,
    required double y,
    Map<String, dynamic>? properties,
  }) {
    final element = {
      'type': type,
      'position': {'x': x, 'y': y},
      'properties': properties ?? _getDefaultElementProperties(type),
    };

    final elements = List<Map<String, dynamic>>.from(levelData['elements'] ?? []);
    elements.add(element);
    levelData['elements'] = elements;

    return levelData;
  }

  /// Add a camera segment to the level
  static Map<String, dynamic> addCameraSegment(
    Map<String, dynamic> levelData, {
    required int id,
    required double x,
    required double y,
    double width = 800,
    double height = 600,
  }) {
    final segment = {
      'id': id,
      'bounds': {
        'min': {'x': x - width / 2, 'y': y - height / 2},
        'max': {'x': x + width / 2, 'y': y + height / 2},
      },
    };

    final segments = List<Map<String, dynamic>>.from(levelData['segments'] ?? []);
    segments.add(segment);
    levelData['segments'] = segments;

    return levelData;
  }

  /// Add an objective to the level
  static Map<String, dynamic> addObjective(
    Map<String, dynamic> levelData, {
    required String type,
    required String description,
    Map<String, dynamic>? properties,
  }) {
    final objective = {
      'type': type,
      'description': description,
      'properties': properties ?? {},
    };

    final objectives = List<Map<String, dynamic>>.from(levelData['objectives'] ?? []);
    objectives.add(objective);
    levelData['objectives'] = objectives;

    return levelData;
  }

  /// Create a rectangular area of tiles
  static Map<String, dynamic> addTileRectangle(
    Map<String, dynamic> levelData, {
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required String tileType,
    double tileSize = 32.0,
  }) {
    final minX = startX < endX ? startX : endX;
    final maxX = startX > endX ? startX : endX;
    final minY = startY < endY ? startY : endY;
    final maxY = startY > endY ? startY : endY;

    for (double x = minX; x <= maxX; x += tileSize) {
      for (double y = minY; y <= maxY; y += tileSize) {
        levelData = addTile(levelData, x: x, y: y, type: tileType);
      }
    }

    return levelData;
  }

  /// Create a platform of tiles
  static Map<String, dynamic> addPlatform(
    Map<String, dynamic> levelData, {
    required double x,
    required double y,
    required int width,
    required String tileType,
    double tileSize = 32.0,
  }) {
    for (int i = 0; i < width; i++) {
      levelData = addTile(
        levelData,
        x: x + (i * tileSize),
        y: y,
        type: tileType,
      );
    }

    return levelData;
  }

  /// Create a wall of tiles
  static Map<String, dynamic> addWall(
    Map<String, dynamic> levelData, {
    required double x,
    required double y,
    required int height,
    required String tileType,
    double tileSize = 32.0,
  }) {
    for (int i = 0; i < height; i++) {
      levelData = addTile(
        levelData,
        x: x,
        y: y + (i * tileSize),
        type: tileType,
      );
    }

    return levelData;
  }

  /// Validate level data structure
  static List<String> validateLevel(Map<String, dynamic> levelData) {
    final errors = <String>[];

    // Check required fields
    final requiredFields = ['id', 'name', 'size', 'playerSpawn', 'tiles'];
    for (final field in requiredFields) {
      if (!levelData.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }

    // Validate player spawn
    final playerSpawn = levelData['playerSpawn'];
    if (playerSpawn is Map) {
      if (!playerSpawn.containsKey('x') || !playerSpawn.containsKey('y')) {
        errors.add('Player spawn must have x and y coordinates');
      }
    }

    // Validate tiles
    final tiles = levelData['tiles'];
    if (tiles is List) {
      for (int i = 0; i < tiles.length; i++) {
        final tile = tiles[i];
        if (tile is Map<String, dynamic>) {
          final tileErrors = _validateTile(tile, i);
          errors.addAll(tileErrors);
        }
      }
    }

    // Check for overlapping tiles
    final overlaps = _findOverlappingTiles(levelData);
    if (overlaps.isNotEmpty) {
      errors.add('Found ${overlaps.length} overlapping tiles');
    }

    // Validate level bounds
    final boundsErrors = _validateLevelBounds(levelData);
    errors.addAll(boundsErrors);

    return errors;
  }

  /// Get default properties for tile types
  static Map<String, dynamic> _getTileProperties(String type) {
    switch (type) {
      case 'scaffolding':
        return {'durability': 1, 'maxDurability': 1, 'isDestructible': true};
      case 'timber':
        return {'durability': 2, 'maxDurability': 2, 'isDestructible': true};
      case 'timber_one_hit':
        return {'durability': 1, 'maxDurability': 2, 'isDestructible': true};
      case 'bricks':
        return {'durability': 3, 'maxDurability': 3, 'isDestructible': true};
      case 'bricks_one_hit':
        return {'durability': 2, 'maxDurability': 3, 'isDestructible': true};
      case 'bricks_two_hits':
        return {'durability': 1, 'maxDurability': 3, 'isDestructible': true};
      case 'beam':
      case 'girder':
      case 'support':
        return {'durability': -1, 'maxDurability': -1, 'isDestructible': false};
      default:
        return {'durability': 1, 'maxDurability': 1, 'isDestructible': true};
    }
  }

  /// Get default properties for interactive elements
  static Map<String, dynamic> _getDefaultElementProperties(String type) {
    switch (type) {
      case 'elevator':
        return {'speed': 2.0, 'range': 160.0};
      case 'spring':
        return {'force': 500.0, 'cooldown': 0.5};
      case 'target':
        return {'radius': 20.0, 'points': 100};
      case 'spikes':
        return {'damage': 1, 'retractTime': 2.0};
      default:
        return {};
    }
  }

  /// Validate a single tile
  static List<String> _validateTile(Map<String, dynamic> tile, int index) {
    final errors = <String>[];

    // Check required tile fields
    final requiredFields = ['position', 'type', 'durability', 'isDestructible'];
    for (final field in requiredFields) {
      if (!tile.containsKey(field)) {
        errors.add('Tile $index missing required field: $field');
      }
    }

    // Validate position
    final position = tile['position'];
    if (position is Map) {
      if (!position.containsKey('x') || !position.containsKey('y')) {
        errors.add('Tile $index position must have x and y coordinates');
      }
    }

    // Validate tile type
    final validTypes = [
      'scaffolding', 'timber', 'timber_one_hit', 'bricks', 'bricks_one_hit',
      'bricks_two_hits', 'beam', 'girder', 'support', 'spikes', 'shutter'
    ];
    if (!validTypes.contains(tile['type'])) {
      errors.add('Tile $index has invalid type: ${tile['type']}');
    }

    return errors;
  }

  /// Find overlapping tiles
  static List<Map<String, dynamic>> _findOverlappingTiles(Map<String, dynamic> levelData) {
    final overlaps = <Map<String, dynamic>>[];
    final tiles = List<Map<String, dynamic>>.from(levelData['tiles'] ?? []);

    for (int i = 0; i < tiles.length; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        final tile1 = tiles[i];
        final tile2 = tiles[j];
        
        final pos1 = tile1['position'];
        final pos2 = tile2['position'];
        
        if (pos1['x'] == pos2['x'] && pos1['y'] == pos2['y']) {
          overlaps.add({'tile1': i, 'tile2': j, 'position': pos1});
        }
      }
    }

    return overlaps;
  }

  /// Validate level bounds
  static List<String> _validateLevelBounds(Map<String, dynamic> levelData) {
    final errors = <String>[];
    
    final size = levelData['size'];
    final playerSpawn = levelData['playerSpawn'];
    
    if (size is Map && playerSpawn is Map) {
      final width = size['x'];
      final height = size['y'];
      final spawnX = playerSpawn['x'];
      final spawnY = playerSpawn['y'];
      
      if (spawnX < 0 || spawnX > width) {
        errors.add('Player spawn X is outside level bounds');
      }
      
      if (spawnY < 0 || spawnY > height) {
        errors.add('Player spawn Y is outside level bounds');
      }
    }

    return errors;
  }

  /// Save level data to file
  static Future<void> saveLevelData(Map<String, dynamic> levelData) async {
    final levelId = levelData['id'];
    final fileName = 'level_$levelId.json';
    final filePath = '$_levelsPath/$fileName';
    
    // Note: In a real implementation, this would use proper file I/O
    // For now, we'll just log the operation
    if (kDebugMode) {
      print('Would save level $levelId to $filePath');
    }
  }

  /// Load level data from file
  static Future<Map<String, dynamic>?> loadLevelData(int levelId) async {
    try {
      final fileName = 'level_$levelId.json';
      final filePath = '$_levelsPath/$fileName';
      
      // Note: In a real implementation, this would use proper file I/O
      // For now, we'll return null
      if (kDebugMode) {
        print('Would load level $levelId from $filePath');
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading level $levelId: $e');
      }
      return null;
    }
  }

  /// Get available tile types
  static List<String> getAvailableTileTypes() {
    return [
      'scaffolding',
      'timber',
      'timber_one_hit',
      'bricks',
      'bricks_one_hit',
      'bricks_two_hits',
      'beam',
      'girder',
      'support',
      'spikes',
      'shutter',
    ];
  }

  /// Get available element types
  static List<String> getAvailableElementTypes() {
    return [
      'elevator',
      'spring',
      'target',
      'spikes',
    ];
  }

  /// Generate level preview data
  static Map<String, dynamic> generateLevelPreview(Map<String, dynamic> levelData) {
    final tiles = List<Map<String, dynamic>>.from(levelData['tiles'] ?? []);
    final elements = List<Map<String, dynamic>>.from(levelData['elements'] ?? []);
    
    return {
      'id': levelData['id'],
      'name': levelData['name'],
      'tileCount': tiles.length,
      'elementCount': elements.length,
      'size': levelData['size'],
      'difficulty': _calculateDifficulty(levelData),
      'estimatedTime': _estimateCompletionTime(levelData),
    };
  }

  /// Calculate level difficulty (1-5 scale)
  static int _calculateDifficulty(Map<String, dynamic> levelData) {
    final tiles = List<Map<String, dynamic>>.from(levelData['tiles'] ?? []);
    final elements = List<Map<String, dynamic>>.from(levelData['elements'] ?? []);
    
    int difficulty = 1;
    
    // Increase difficulty based on tile count
    if (tiles.length > 50) difficulty++;
    if (tiles.length > 100) difficulty++;
    
    // Increase difficulty based on destructible tiles
    final destructibleTiles = tiles.where((tile) => tile['isDestructible'] == true).length;
    if (destructibleTiles > 20) difficulty++;
    
    // Increase difficulty based on interactive elements
    if (elements.length > 3) difficulty++;
    
    return difficulty.clamp(1, 5);
  }

  /// Estimate completion time in minutes
  static int _estimateCompletionTime(Map<String, dynamic> levelData) {
    final tiles = List<Map<String, dynamic>>.from(levelData['tiles'] ?? []);
    final elements = List<Map<String, dynamic>>.from(levelData['elements'] ?? []);
    
    // Base time
    int timeMinutes = 2;
    
    // Add time based on tile complexity
    final destructibleTiles = tiles.where((tile) => tile['isDestructible'] == true).length;
    timeMinutes += (destructibleTiles / 10).ceil();
    
    // Add time based on elements
    timeMinutes += elements.length;
    
    return timeMinutes.clamp(1, 30);
  }
}