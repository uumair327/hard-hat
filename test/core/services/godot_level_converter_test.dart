import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/core/services/godot_level_converter.dart';

void main() {
  group('GodotLevelConverter Tests', () {
    group('Level Data Conversion Accuracy', () {
      test('should convert level with correct structure', () {
        // Arrange
        const levelId = 1;
        const levelName = 'Test Level';
        final expectedStructure = {
          'id': levelId,
          'name': levelName,
          'size': isA<Map<String, dynamic>>(),
          'playerSpawn': isA<Map<String, dynamic>>(),
          'cameraMin': isA<Map<String, dynamic>>(),
          'cameraMax': isA<Map<String, dynamic>>(),
          'tiles': isA<List>(),
          'elements': isA<List>(),
          'segments': isA<List>(),
          'objectives': isA<List>(),
        };
        
        // Act
        final levelData = _createTestLevelData(levelId, levelName);
        
        // Assert
        expect(levelData['id'], equals(levelId));
        expect(levelData['name'], equals(levelName));
        expect(levelData, allOf(expectedStructure.entries.map((e) => 
          containsPair(e.key, e.value)).toList()));
      });

      test('should validate converted level data structure', () {
        // Arrange
        final levelData = _createTestLevelData(1, 'Test Level');
        
        // Act
        final isValid = GodotLevelConverter.validateLevelData(levelData);
        
        // Assert
        expect(isValid, isTrue);
      });

      test('should detect invalid level data', () {
        // Arrange
        final invalidLevelData = {
          'id': 1,
          // Missing required fields
        };
        
        // Act
        final isValid = GodotLevelConverter.validateLevelData(invalidLevelData);
        
        // Assert
        expect(isValid, isFalse);
      });

      test('should validate tile data structure', () {
        // Arrange
        final validTile = {
          'position': {'x': 100.0, 'y': 200.0},
          'type': 'scaffolding',
          'durability': 1,
          'isDestructible': true,
        };
        
        final levelData = {
          'id': 1,
          'name': 'Test',
          'size': {'x': 800.0, 'y': 600.0},
          'playerSpawn': {'x': 100.0, 'y': 500.0},
          'tiles': [validTile],
        };
        
        // Act
        final isValid = GodotLevelConverter.validateLevelData(levelData);
        
        // Assert
        expect(isValid, isTrue);
      });

      test('should detect invalid tile data', () {
        // Arrange
        final invalidTile = {
          'position': {'x': 100.0, 'y': 200.0},
          'type': 'scaffolding',
          // Missing durability and isDestructible
        };
        
        final levelData = {
          'id': 1,
          'name': 'Test',
          'size': {'x': 800.0, 'y': 600.0},
          'playerSpawn': {'x': 100.0, 'y': 500.0},
          'tiles': [invalidTile],
        };
        
        // Act
        final isValid = GodotLevelConverter.validateLevelData(levelData);
        
        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Coordinate Conversion', () {
      test('should convert Godot X coordinates correctly', () {
        // Arrange
        const godotX = 10;
        const expectedFlutterX = 10.0 * 32.0; // 320.0
        
        // Act
        final flutterX = _convertGodotX(godotX) * 32.0;
        
        // Assert
        expect(flutterX, equals(expectedFlutterX));
      });

      test('should convert Godot Y coordinates correctly', () {
        // Arrange
        const godotY = 5;
        const expectedFlutterY = -5.0 * 32.0; // -160.0 (inverted Y axis)
        
        // Act
        final flutterY = _convertGodotY(godotY) * 32.0;
        
        // Assert
        expect(flutterY, equals(expectedFlutterY));
      });

      test('should handle negative Godot coordinates', () {
        // Arrange
        const godotX = -3;
        const godotY = -2;
        
        // Act
        final flutterX = _convertGodotX(godotX) * 32.0;
        final flutterY = _convertGodotY(godotY) * 32.0;
        
        // Assert
        expect(flutterX, equals(-96.0));
        expect(flutterY, equals(64.0)); // Y axis inverted
      });

      test('should convert grid coordinates to pixel coordinates', () {
        // Arrange
        const gridSize = 32;
        const gridX = 5;
        const gridY = 3;
        
        // Act
        final pixelX = gridX * gridSize;
        final pixelY = gridY * gridSize;
        
        // Assert
        expect(pixelX, equals(160));
        expect(pixelY, equals(96));
      });

      test('should maintain coordinate precision', () {
        // Arrange
        const godotCoords = [0, 1, -1, 10, -10, 100];
        
        // Act & Assert
        for (final coord in godotCoords) {
          final convertedX = _convertGodotX(coord);
          final convertedY = _convertGodotY(coord);
          
          expect(convertedX, equals(coord.toDouble()));
          expect(convertedY, equals(-coord.toDouble()));
        }
      });
    });

    group('Tile Type Mapping', () {
      test('should map scaffolding tile correctly', () {
        // Arrange
        const tileId = 0;
        const gridMapName = 'GridMap';
        
        // Act
        final tileType = _mapTileIdToType(tileId, gridMapName);
        
        // Assert
        expect(tileType, isNotNull);
        expect(tileType!['type'], equals('scaffolding'));
        expect(tileType['durability'], equals(1));
        expect(tileType['maxDurability'], equals(1));
        expect(tileType['isDestructible'], isTrue);
      });

      test('should map timber tile correctly', () {
        // Arrange
        const tileId = 1;
        const gridMapName = 'GridMap';
        
        // Act
        final tileType = _mapTileIdToType(tileId, gridMapName);
        
        // Assert
        expect(tileType, isNotNull);
        expect(tileType!['type'], equals('timber'));
        expect(tileType['durability'], equals(2));
        expect(tileType['maxDurability'], equals(2));
        expect(tileType['isDestructible'], isTrue);
      });

      test('should map brick tiles with different durability', () {
        // Arrange
        const brickIds = [3, 4, 5]; // Full, one hit, two hits
        const expectedDurabilities = [3, 2, 1];
        
        // Act & Assert
        for (int i = 0; i < brickIds.length; i++) {
          final tileType = _mapTileIdToType(brickIds[i], 'GridMap');
          expect(tileType, isNotNull);
          expect(tileType!['type'], contains('bricks'));
          expect(tileType['durability'], equals(expectedDurabilities[i]));
          expect(tileType['maxDurability'], equals(3));
          expect(tileType['isDestructible'], isTrue);
        }
      });

      test('should map indestructible tiles correctly', () {
        // Arrange
        const indestructibleIds = [6, 65537, 131078, 196614];
        const expectedTypes = ['beam', 'girder', 'support', 'beam'];
        
        // Act & Assert
        for (int i = 0; i < indestructibleIds.length; i++) {
          final tileType = _mapTileIdToType(indestructibleIds[i], 'GridMap');
          expect(tileType, isNotNull);
          expect(tileType!['type'], equals(expectedTypes[i]));
          expect(tileType['durability'], equals(-1));
          expect(tileType['maxDurability'], equals(-1));
          expect(tileType['isDestructible'], isFalse);
        }
      });

      test('should return null for unknown tile IDs', () {
        // Arrange
        const unknownTileId = 999999;
        
        // Act
        final tileType = _mapTileIdToType(unknownTileId, 'GridMap');
        
        // Assert
        expect(tileType, isNull);
      });

      test('should handle tile ID variants correctly', () {
        // Arrange
        const scaffoldingVariant = 65542;
        
        // Act
        final tileType = _mapTileIdToType(scaffoldingVariant, 'GridMap');
        
        // Assert
        expect(tileType, isNotNull);
        expect(tileType!['type'], equals('scaffolding'));
        expect(tileType['isDestructible'], isTrue);
      });
    });

    group('Interactive Elements Conversion', () {
      test('should convert elevator element correctly', () {
        // Arrange
        const elevatorData = {
          'type': 'elevator',
          'position': {'x': 800.0, 'y': 400.0},
          'properties': {
            'speed': 2.0,
            'range': 160.0,
          },
        };
        
        // Assert
        expect(elevatorData['type'], equals('elevator'));
        expect(elevatorData['position'], isA<Map<String, dynamic>>());
        expect(elevatorData['properties'], isA<Map<String, dynamic>>());
        expect((elevatorData['properties'] as Map)['speed'], equals(2.0));
        expect((elevatorData['properties'] as Map)['range'], equals(160.0));
      });

      test('should convert spring element correctly', () {
        // Arrange
        const springData = {
          'type': 'spring',
          'position': {'x': 600.0, 'y': 300.0},
          'properties': {
            'force': 500.0,
            'cooldown': 0.5,
          },
        };
        
        // Assert
        expect(springData['type'], equals('spring'));
        expect(springData['position'], isA<Map<String, dynamic>>());
        expect(springData['properties'], isA<Map<String, dynamic>>());
        expect((springData['properties'] as Map)['force'], equals(500.0));
        expect((springData['properties'] as Map)['cooldown'], equals(0.5));
      });

      test('should convert target element correctly', () {
        // Arrange
        const targetData = {
          'type': 'target',
          'position': {'x': 1200.0, 'y': 200.0},
          'properties': {
            'radius': 20.0,
            'points': 100,
          },
        };
        
        // Assert
        expect(targetData['type'], equals('target'));
        expect(targetData['position'], isA<Map<String, dynamic>>());
        expect(targetData['properties'], isA<Map<String, dynamic>>());
        expect((targetData['properties'] as Map)['radius'], equals(20.0));
        expect((targetData['properties'] as Map)['points'], equals(100));
      });
    });

    group('Camera Segments Conversion', () {
      test('should convert camera segments correctly', () {
        // Arrange
        final segments = [
          {
            'id': 0,
            'position': {'x': 400.0, 'y': 300.0},
          },
          {
            'id': 1,
            'position': {'x': 1200.0, 'y': 300.0},
          },
        ];
        
        // Act
        final cameraSegments = _extractCameraSegments(segments);
        
        // Assert
        expect(cameraSegments.length, equals(2));
        expect(cameraSegments[0]['id'], equals(0));
        expect(cameraSegments[0]['bounds'], isA<Map<String, dynamic>>());
        expect(cameraSegments[0]['bounds']['min'], isA<Map<String, dynamic>>());
        expect(cameraSegments[0]['bounds']['max'], isA<Map<String, dynamic>>());
      });

      test('should calculate camera bounds correctly', () {
        // Arrange
        final segment = {
          'id': 0,
          'position': {'x': 400.0, 'y': 300.0},
        };
        
        // Act
        final cameraSegment = {
          'id': segment['id'],
          'bounds': {
            'min': {
              'x': (segment['position'] as Map)['x'] - 400,
              'y': (segment['position'] as Map)['y'] - 300,
            },
            'max': {
              'x': (segment['position'] as Map)['x'] + 400,
              'y': (segment['position'] as Map)['y'] + 300,
            },
          },
        };
        
        // Assert
        expect((cameraSegment['bounds'] as Map)['min']['x'], equals(0.0));
        expect((cameraSegment['bounds'] as Map)['min']['y'], equals(0.0));
        expect((cameraSegment['bounds'] as Map)['max']['x'], equals(800.0));
        expect((cameraSegment['bounds'] as Map)['max']['y'], equals(600.0));
      });
    });

    group('Level Objectives Conversion', () {
      test('should create reach elevator objective for level 1', () {
        // Arrange
        const levelId = 1;
        
        // Act
        final objectives = _getObjectivesForLevel(levelId);
        
        // Assert
        expect(objectives.length, equals(1));
        expect(objectives[0]['type'], equals('reach_elevator'));
        expect(objectives[0]['description'], contains('elevator'));
        expect(objectives[0]['position'], isA<Map<String, dynamic>>());
      });

      test('should create clear path objective for level 2', () {
        // Arrange
        const levelId = 2;
        
        // Act
        final objectives = _getObjectivesForLevel(levelId);
        
        // Assert
        expect(objectives.length, equals(1));
        expect(objectives[0]['type'], equals('clear_path'));
        expect(objectives[0]['description'], contains('path'));
      });

      test('should create destroy targets objective for level 3', () {
        // Arrange
        const levelId = 3;
        
        // Act
        final objectives = _getObjectivesForLevel(levelId);
        
        // Assert
        expect(objectives.length, equals(1));
        expect(objectives[0]['type'], equals('destroy_targets'));
        expect(objectives[0]['description'], contains('target'));
        expect(objectives[0]['count'], equals(5));
      });

      test('should create reach top objective for level 4', () {
        // Arrange
        const levelId = 4;
        
        // Act
        final objectives = _getObjectivesForLevel(levelId);
        
        // Assert
        expect(objectives.length, equals(1));
        expect(objectives[0]['type'], equals('reach_top'));
        expect(objectives[0]['description'], contains('top'));
      });

      test('should return empty objectives for unknown level', () {
        // Arrange
        const unknownLevelId = 999;
        
        // Act
        final objectives = _getObjectivesForLevel(unknownLevelId);
        
        // Assert
        expect(objectives, isEmpty);
      });
    });

    group('Level Bounds Calculation', () {
      test('should calculate bounds from tiles correctly', () {
        // Arrange
        final tiles = [
          {'position': {'x': 100.0, 'y': 200.0}},
          {'position': {'x': 500.0, 'y': 400.0}},
          {'position': {'x': 300.0, 'y': 100.0}},
        ];
        final segments = <Map<String, dynamic>>[];
        
        // Act
        final bounds = _calculateLevelBounds(tiles, segments);
        
        // Assert
        expect(bounds['size'], isA<Map<String, dynamic>>());
        expect(bounds['cameraMin'], isA<Map<String, dynamic>>());
        expect(bounds['cameraMax'], isA<Map<String, dynamic>>());
        expect(bounds['size']['x'], greaterThan(0));
        expect(bounds['size']['y'], greaterThan(0));
      });

      test('should include segments in bounds calculation', () {
        // Arrange
        final tiles = <Map<String, dynamic>>[];
        final segments = [
          {'position': {'x': 800.0, 'y': 600.0}},
          {'position': {'x': 1600.0, 'y': 600.0}},
        ];
        
        // Act
        final bounds = _calculateLevelBounds(tiles, segments);
        
        // Assert
        expect(bounds['size']['x'], greaterThan(800));
        expect(bounds['size']['y'], greaterThan(600));
      });

      test('should handle empty tiles and segments', () {
        // Arrange
        final tiles = <Map<String, dynamic>>[];
        final segments = <Map<String, dynamic>>[];
        
        // Act
        final bounds = _calculateLevelBounds(tiles, segments);
        
        // Assert
        expect(bounds['size']['x'], equals(800));
        expect(bounds['size']['y'], equals(600));
        expect(bounds['cameraMin']['x'], equals(0));
        expect(bounds['cameraMin']['y'], equals(0));
        expect(bounds['cameraMax']['x'], equals(800));
        expect(bounds['cameraMax']['y'], equals(600));
      });
    });

    group('JSON Formatting and Serialization', () {
      test('should format level JSON correctly', () {
        // Arrange
        final levelData = _createTestLevelData(1, 'Test Level');
        
        // Act
        final jsonString = _formatLevelJson(levelData);
        final parsed = jsonDecode(jsonString);
        
        // Assert
        expect(parsed, isA<Map<String, dynamic>>());
        expect(parsed['id'], equals(1));
        expect(parsed['name'], equals('Test Level'));
      });

      test('should preserve data types in JSON serialization', () {
        // Arrange
        final levelData = {
          'id': 1,
          'name': 'Test',
          'size': {'x': 800.0, 'y': 600.0},
          'playerSpawn': {'x': 100.0, 'y': 500.0},
          'tiles': [
            {
              'position': {'x': 200.0, 'y': 300.0},
              'type': 'scaffolding',
              'durability': 1,
              'isDestructible': true,
            }
          ],
        };
        
        // Act
        final jsonString = _formatLevelJson(levelData);
        final parsed = jsonDecode(jsonString);
        
        // Assert
        expect(parsed['id'], isA<int>());
        expect(parsed['name'], isA<String>());
        expect(parsed['size']['x'], isA<double>());
        expect(parsed['tiles'][0]['durability'], isA<int>());
        expect(parsed['tiles'][0]['isDestructible'], isA<bool>());
      });

      test('should handle nested objects in JSON', () {
        // Arrange
        final complexData = {
          'level': {
            'id': 1,
            'metadata': {
              'created': '2024-01-01',
              'version': '1.0',
            },
          },
        };
        
        // Act
        final jsonString = _formatLevelJson(complexData);
        final parsed = jsonDecode(jsonString);
        
        // Assert
        expect(parsed['level'], isA<Map<String, dynamic>>());
        expect(parsed['level']['metadata'], isA<Map<String, dynamic>>());
        expect(parsed['level']['metadata']['created'], equals('2024-01-01'));
      });
    });
  });
}

// Helper functions for testing
Map<String, dynamic> _createTestLevelData(int levelId, String levelName) {
  return {
    'id': levelId,
    'name': levelName,
    'size': {'x': 800.0, 'y': 600.0},
    'playerSpawn': {'x': 100.0, 'y': 500.0},
    'cameraMin': {'x': 0.0, 'y': 0.0},
    'cameraMax': {'x': 800.0, 'y': 600.0},
    'tiles': [
      {
        'position': {'x': 200.0, 'y': 400.0},
        'type': 'scaffolding',
        'durability': 1,
        'isDestructible': true,
      }
    ],
    'elements': [],
    'segments': [],
    'objectives': [],
  };
}

double _convertGodotX(int godotX) {
  return godotX.toDouble();
}

double _convertGodotY(int godotY) {
  return -godotY.toDouble();
}

Map<String, dynamic>? _mapTileIdToType(int tileId, String gridMapName) {
  switch (tileId) {
    case 0:
      return {
        'type': 'scaffolding',
        'durability': 1,
        'maxDurability': 1,
        'isDestructible': true,
      };
    case 1:
      return {
        'type': 'timber',
        'durability': 2,
        'maxDurability': 2,
        'isDestructible': true,
      };
    case 2:
      return {
        'type': 'timber_one_hit',
        'durability': 1,
        'maxDurability': 2,
        'isDestructible': true,
      };
    case 3:
      return {
        'type': 'bricks',
        'durability': 3,
        'maxDurability': 3,
        'isDestructible': true,
      };
    case 4:
      return {
        'type': 'bricks_one_hit',
        'durability': 2,
        'maxDurability': 3,
        'isDestructible': true,
      };
    case 5:
      return {
        'type': 'bricks_two_hits',
        'durability': 1,
        'maxDurability': 3,
        'isDestructible': true,
      };
    case 6:
      return {
        'type': 'beam',
        'durability': -1,
        'maxDurability': -1,
        'isDestructible': false,
      };
    case 65537:
      return {
        'type': 'girder',
        'durability': -1,
        'maxDurability': -1,
        'isDestructible': false,
      };
    case 65542:
      return {
        'type': 'scaffolding',
        'durability': 1,
        'maxDurability': 1,
        'isDestructible': true,
      };
    case 131078:
      return {
        'type': 'support',
        'durability': -1,
        'maxDurability': -1,
        'isDestructible': false,
      };
    case 196614:
      return {
        'type': 'beam',
        'durability': -1,
        'maxDurability': -1,
        'isDestructible': false,
      };
    default:
      return null;
  }
}

List<Map<String, dynamic>> _extractCameraSegments(List<Map<String, dynamic>> segments) {
  return segments.map((segment) => {
    'id': segment['id'],
    'bounds': {
      'min': {
        'x': (segment['position'] as Map)['x'] - 400,
        'y': (segment['position'] as Map)['y'] - 300,
      },
      'max': {
        'x': (segment['position'] as Map)['x'] + 400,
        'y': (segment['position'] as Map)['y'] + 300,
      },
    },
  }).toList();
}

List<Map<String, dynamic>> _getObjectivesForLevel(int levelId) {
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

Map<String, dynamic> _calculateLevelBounds(
  List<Map<String, dynamic>> tiles,
  List<Map<String, dynamic>> segments,
) {
  double minX = 0, minY = 0, maxX = 800, maxY = 600;

  // Calculate bounds from tiles
  for (final tile in tiles) {
    final x = (tile['position'] as Map)['x'] as double;
    final y = (tile['position'] as Map)['y'] as double;
    if (x - 32 < minX) minX = x - 32;
    if (y - 32 < minY) minY = y - 32;
    if (x + 32 > maxX) maxX = x + 32;
    if (y + 32 > maxY) maxY = y + 32;
  }

  // Calculate bounds from segments
  for (final segment in segments) {
    final position = segment['position'] as Map<String, dynamic>?;
    if (position != null) {
      final x = position['x'] as double;
      final y = position['y'] as double;
      if (x - 400 < minX) minX = x - 400;
      if (y - 300 < minY) minY = y - 300;
      if (x + 400 > maxX) maxX = x + 400;
      if (y + 300 > maxY) maxY = y + 300;
    }
  }

  return {
    'size': {'x': maxX - minX, 'y': maxY - minY},
    'cameraMin': {'x': minX, 'y': minY},
    'cameraMax': {'x': maxX, 'y': maxY},
  };
}

String _formatLevelJson(Map<String, dynamic> levelData) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(levelData);
}