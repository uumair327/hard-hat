import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

/// Service for converting Godot level scenes to Flutter JSON format
class GodotLevelConverter {
  static const String _godotLevelsPath = 'godot_Hard-Hat/game/level';
  static const String _flutterLevelsPath = 'assets/data/levels';

  /// Convert all Godot levels to Flutter format
  static Future<void> convertAllLevels() async {
    if (kDebugMode) {
      print('Starting level conversion from Godot to Flutter...');
    }

    // Convert individual levels
    await _convertLevel(1, 'Tutorial Level');
    await _convertLevel(2, 'Construction Site');
    await _convertLevel(3, 'High Rise Challenge');
    await _convertLevel(4, 'Final Tower');

    // Create levels index
    await _createLevelsIndex();

    if (kDebugMode) {
      print('Level conversion completed successfully!');
    }
  }

  /// Convert a single Godot level to Flutter format
  static Future<void> _convertLevel(int levelId, String levelName) async {
    try {
      final tscnFile = File(path.join(_godotLevelsPath, '$levelId.tscn'));
      
      if (!await tscnFile.exists()) {
        if (kDebugMode) {
          print('Warning: Godot level file not found: ${tscnFile.path}');
        }
        return;
      }

      final tscnContent = await tscnFile.readAsString();
      final levelData = _parseTscnToLevelData(levelId, levelName, tscnContent);
      
      final jsonFile = File(path.join(_flutterLevelsPath, 'level_$levelId.json'));
      await jsonFile.parent.create(recursive: true);
      await jsonFile.writeAsString(_formatLevelJson(levelData));

      if (kDebugMode) {
        print('Converted level $levelId: $levelName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error converting level $levelId: $e');
      }
    }
  }

  /// Parse Godot .tscn content to level data
  static Map<String, dynamic> _parseTscnToLevelData(
    int levelId,
    String levelName,
    String tscnContent,
  ) {
    // Extract GridMap data from the .tscn file
    final gridMapData = _extractGridMapData(tscnContent);
    final segments = _extractSegments(tscnContent);
    final interactiveElements = _extractInteractiveElements(tscnContent);

    // Convert Godot coordinates to Flutter coordinates
    final tiles = _convertGridMapToTiles(gridMapData);
    final playerSpawn = _extractPlayerSpawn(segments);
    final cameraSegments = _extractCameraSegments(segments);

    // Calculate level bounds based on tile positions
    final bounds = _calculateLevelBounds(tiles, segments);

    return {
      'id': levelId,
      'name': levelName,
      'size': bounds['size'],
      'playerSpawn': playerSpawn,
      'cameraMin': bounds['cameraMin'],
      'cameraMax': bounds['cameraMax'],
      'tiles': tiles,
      'elements': interactiveElements,
      'segments': cameraSegments,
      'objectives': _getObjectivesForLevel(levelId),
    };
  }

  /// Extract GridMap data from .tscn content
  static Map<String, List<int>> _extractGridMapData(String tscnContent) {
    final gridMaps = <String, List<int>>{};
    
    // Find GridMap sections
    final gridMapRegex = RegExp(r'\[node name="(\w*GridMap).*?\].*?data = \{[^}]*"cells": PackedInt32Array\(([^)]+)\)', dotAll: true);
    final matches = gridMapRegex.allMatches(tscnContent);

    for (final match in matches) {
      final gridMapName = match.group(1) ?? 'GridMap';
      final cellsData = match.group(2) ?? '';
      
      // Parse the packed int array
      final cells = cellsData
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s) ?? 0)
          .toList();

      gridMaps[gridMapName] = cells;
    }

    return gridMaps;
  }

  /// Extract segment data from .tscn content
  static List<Map<String, dynamic>> _extractSegments(String tscnContent) {
    final segments = <Map<String, dynamic>>[];
    
    // Find segment nodes
    final segmentRegex = RegExp(r'\[node name="(\d+)" type="Node3D" parent="Segments"\].*?transform = Transform3D\([^)]+\)', dotAll: true);
    final matches = segmentRegex.allMatches(tscnContent);

    for (final match in matches) {
      final segmentId = int.tryParse(match.group(1) ?? '0') ?? 0;
      
      // Extract transform data (simplified)
      final transformMatch = RegExp(r'transform = Transform3D\([^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,\s*([^,]+),\s*([^,]+),\s*([^)]+)\)').firstMatch(match.group(0) ?? '');
      
      double x = 0, y = 0, z = 0;
      if (transformMatch != null) {
        x = double.tryParse(transformMatch.group(1) ?? '0') ?? 0;
        y = double.tryParse(transformMatch.group(2) ?? '0') ?? 0;
        z = double.tryParse(transformMatch.group(3) ?? '0') ?? 0;
      }

      segments.add({
        'id': segmentId,
        'position': {'x': x * 32, 'y': -y * 32}, // Convert to 2D Flutter coordinates
        'spawnPoint': {'x': (x - 9) * 32, 'y': -(y - 1) * 32},
      });
    }

    return segments;
  }

  /// Extract interactive elements from .tscn content
  static List<Map<String, dynamic>> _extractInteractiveElements(String tscnContent) {
    final elements = <Map<String, dynamic>>[];

    // Extract elevator
    final elevatorMatch = RegExp(r'\[node name="Elevator".*?transform = Transform3D\([^)]+,\s*([^,]+),\s*([^,]+),\s*([^)]+)\)').firstMatch(tscnContent);
    if (elevatorMatch != null) {
      final x = double.tryParse(elevatorMatch.group(1) ?? '0') ?? 0;
      final y = double.tryParse(elevatorMatch.group(2) ?? '0') ?? 0;
      
      elements.add({
        'type': 'elevator',
        'position': {'x': x * 32, 'y': -y * 32},
        'properties': {
          'speed': 2.0,
          'range': 160.0,
        },
      });
    }

    // Extract other interactive elements (springs, targets, etc.)
    // This would be expanded based on the specific elements in each level

    return elements;
  }

  /// Convert GridMap data to tile list
  static List<Map<String, dynamic>> _convertGridMapToTiles(Map<String, List<int>> gridMaps) {
    final tiles = <Map<String, dynamic>>[];

    for (final entry in gridMaps.entries) {
      final gridMapName = entry.key;
      final cells = entry.value;

      // Process cells in groups of 3 (x, y, tile_id)
      for (int i = 0; i < cells.length; i += 3) {
        if (i + 2 >= cells.length) break;

        final x = cells[i];
        final y = cells[i + 1];
        final tileId = cells[i + 2];

        // Convert Godot grid coordinates to Flutter pixel coordinates
        final flutterX = _convertGodotX(x) * 32.0;
        final flutterY = _convertGodotY(y) * 32.0;

        // Map tile IDs to tile types
        final tileType = _mapTileIdToType(tileId, gridMapName);
        if (tileType != null) {
          tiles.add({
            'position': {'x': flutterX, 'y': flutterY},
            'type': tileType['type'],
            'durability': tileType['durability'],
            'maxDurability': tileType['maxDurability'],
            'isDestructible': tileType['isDestructible'],
          });
        }
      }
    }

    return tiles;
  }

  /// Convert Godot X coordinate to Flutter coordinate
  static double _convertGodotX(int godotX) {
    // Godot uses signed integers for grid positions
    // Convert to positive Flutter coordinates
    return godotX.toDouble();
  }

  /// Convert Godot Y coordinate to Flutter coordinate
  static double _convertGodotY(int godotY) {
    // Flip Y axis (Godot Y+ is up, Flutter Y+ is down)
    return -godotY.toDouble();
  }

  /// Map Godot tile ID to Flutter tile type
  static Map<String, dynamic>? _mapTileIdToType(int tileId, String gridMapName) {
    // Based on Godot mesh library IDs
    switch (tileId) {
      case 0: // Scaffolding
        return {
          'type': 'scaffolding',
          'durability': 1,
          'maxDurability': 1,
          'isDestructible': true,
        };
      case 1: // Timber
        return {
          'type': 'timber',
          'durability': 2,
          'maxDurability': 2,
          'isDestructible': true,
        };
      case 2: // Timber (one hit)
        return {
          'type': 'timber_one_hit',
          'durability': 1,
          'maxDurability': 2,
          'isDestructible': true,
        };
      case 3: // Bricks
        return {
          'type': 'bricks',
          'durability': 3,
          'maxDurability': 3,
          'isDestructible': true,
        };
      case 4: // Bricks (one hit)
        return {
          'type': 'bricks_one_hit',
          'durability': 2,
          'maxDurability': 3,
          'isDestructible': true,
        };
      case 5: // Bricks (two hits)
        return {
          'type': 'bricks_two_hits',
          'durability': 1,
          'maxDurability': 3,
          'isDestructible': true,
        };
      case 6: // Support/Beam (indestructible)
        return {
          'type': 'beam',
          'durability': -1,
          'maxDurability': -1,
          'isDestructible': false,
        };
      case 65537: // Girder
        return {
          'type': 'girder',
          'durability': -1,
          'maxDurability': -1,
          'isDestructible': false,
        };
      case 65542: // Another scaffolding variant
        return {
          'type': 'scaffolding',
          'durability': 1,
          'maxDurability': 1,
          'isDestructible': true,
        };
      case 131078: // Support
        return {
          'type': 'support',
          'durability': -1,
          'maxDurability': -1,
          'isDestructible': false,
        };
      case 196614: // Beam variant
        return {
          'type': 'beam',
          'durability': -1,
          'maxDurability': -1,
          'isDestructible': false,
        };
      default:
        // Unknown tile type, skip
        return null;
    }
  }

  /// Extract player spawn point from segments
  static Map<String, double> _extractPlayerSpawn(List<Map<String, dynamic>> segments) {
    if (segments.isNotEmpty) {
      final firstSegment = segments.first;
      return {
        'x': firstSegment['spawnPoint']['x'],
        'y': firstSegment['spawnPoint']['y'],
      };
    }
    
    return {'x': 100.0, 'y': 500.0}; // Default spawn
  }

  /// Extract camera segments for level boundaries
  static List<Map<String, dynamic>> _extractCameraSegments(List<Map<String, dynamic>> segments) {
    return segments.map((segment) => {
      'id': segment['id'],
      'bounds': {
        'min': {'x': segment['position']['x'] - 400, 'y': segment['position']['y'] - 300},
        'max': {'x': segment['position']['x'] + 400, 'y': segment['position']['y'] + 300},
      },
    }).toList();
  }

  /// Calculate level bounds based on tiles and segments
  static Map<String, dynamic> _calculateLevelBounds(
    List<Map<String, dynamic>> tiles,
    List<Map<String, dynamic>> segments,
  ) {
    double minX = 0, minY = 0, maxX = 800, maxY = 600;

    // Calculate bounds from tiles
    for (final tile in tiles) {
      final x = tile['position']['x'];
      final y = tile['position']['y'];
      minX = min(minX, x - 32);
      minY = min(minY, y - 32);
      maxX = max(maxX, x + 32);
      maxY = max(maxY, y + 32);
    }

    // Calculate bounds from segments
    for (final segment in segments) {
      final x = segment['position']['x'];
      final y = segment['position']['y'];
      minX = min(minX, x - 400);
      minY = min(minY, y - 300);
      maxX = max(maxX, x + 400);
      maxY = max(maxY, y + 300);
    }

    return {
      'size': {'x': maxX - minX, 'y': maxY - minY},
      'cameraMin': {'x': minX, 'y': minY},
      'cameraMax': {'x': maxX, 'y': maxY},
    };
  }

  /// Get objectives for a specific level
  static List<Map<String, dynamic>> _getObjectivesForLevel(int levelId) {
    switch (levelId) {
      case 1:
        return [
          {
            'type': 'reach_elevator',
            'description': 'Reach the elevator to complete the level',
            'position': {'x': 79.5 * 32, 'y': -3 * 32},
          }
        ];
      case 2:
        return [
          {
            'type': 'clear_path',
            'description': 'Clear the path and reach the end',
          }
        ];
      case 3:
        return [
          {
            'type': 'destroy_targets',
            'description': 'Destroy all target blocks',
            'count': 5,
          }
        ];
      case 4:
        return [
          {
            'type': 'reach_top',
            'description': 'Reach the top of the tower',
          }
        ];
      default:
        return [];
    }
  }

  /// Create levels index file
  static Future<void> _createLevelsIndex() async {
    final levelsIndex = {
      'levels': [
        {
          'id': 1,
          'name': 'Tutorial Level',
          'description': 'Learn the basic mechanics',
          'unlocked': true,
          'dataPath': 'data/levels/level_1.json',
        },
        {
          'id': 2,
          'name': 'Construction Site',
          'description': 'Navigate through the construction site',
          'unlocked': false,
          'dataPath': 'data/levels/level_2.json',
        },
        {
          'id': 3,
          'name': 'High Rise Challenge',
          'description': 'Climb the high rise building',
          'unlocked': false,
          'dataPath': 'data/levels/level_3.json',
        },
        {
          'id': 4,
          'name': 'Final Tower',
          'description': 'Conquer the final tower',
          'unlocked': false,
          'dataPath': 'data/levels/level_4.json',
        },
      ],
    };

    final indexFile = File(path.join(_flutterLevelsPath, 'levels.json'));
    await indexFile.writeAsString(_formatJson(levelsIndex));

    if (kDebugMode) {
      print('Created levels index file');
    }
  }

  /// Format level data as JSON
  static String _formatLevelJson(Map<String, dynamic> levelData) {
    return _formatJson(levelData);
  }

  /// Format JSON data for writing to file
  static String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Validate converted level data
  static bool validateLevelData(Map<String, dynamic> levelData) {
    // Check required fields
    final requiredFields = ['id', 'name', 'size', 'playerSpawn', 'tiles'];
    for (final field in requiredFields) {
      if (!levelData.containsKey(field)) {
        if (kDebugMode) {
          print('Validation error: Missing required field: $field');
        }
        return false;
      }
    }

    // Validate tiles
    final tiles = levelData['tiles'] as List?;
    if (tiles != null) {
      for (final tile in tiles) {
        if (tile is! Map<String, dynamic>) continue;
        
        final requiredTileFields = ['position', 'type', 'durability', 'isDestructible'];
        for (final field in requiredTileFields) {
          if (!tile.containsKey(field)) {
            if (kDebugMode) {
              print('Validation error: Tile missing required field: $field');
            }
            return false;
          }
        }
      }
    }

    return true;
  }
}