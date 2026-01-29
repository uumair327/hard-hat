import 'package:flutter_test/flutter_test.dart';
import 'package:flame/extensions.dart';
import 'package:hard_hat/core/services/level_data.dart';
import 'package:hard_hat/core/services/level_manager.dart';
import 'package:hard_hat/core/services/level_loader.dart';

void main() {
  group('LevelData', () {
    test('fromJson creates valid LevelData', () {
      final json = {
        'id': 1,
        'name': 'Test Level',
        'description': 'A test level',
        'size': {'x': 1000.0, 'y': 800.0},
        'playerSpawn': {'x': 100.0, 'y': 50.0},
        'cameraMin': {'x': -200.0, 'y': -300.0},
        'cameraMax': {'x': 800.0, 'y': 500.0},
        'segments': [
          {
            'id': 0,
            'bounds': {
              'min': {'x': -200.0, 'y': -300.0},
              'max': {'x': 400.0, 'y': 300.0},
            },
          },
        ],
        'tiles': [
          {
            'position': {'x': 0.0, 'y': 0.0},
            'type': 'beam',
            'durability': -1,
            'maxDurability': -1,
            'isDestructible': false,
          },
        ],
        'elements': [
          {
            'type': 'elevator',
            'position': {'x': 500.0, 'y': 100.0},
            'properties': {'speed': 2.0, 'range': 160.0},
          },
        ],
      };

      final levelData = LevelData.fromJson(json);

      expect(levelData.id, 1);
      expect(levelData.name, 'Test Level');
      expect(levelData.description, 'A test level');
      expect(levelData.size, Vector2(1000.0, 800.0));
      expect(levelData.playerSpawn, Vector2(100.0, 50.0));
      expect(levelData.cameraMin, Vector2(-200.0, -300.0));
      expect(levelData.cameraMax, Vector2(800.0, 500.0));
      expect(levelData.segments.length, 1);
      expect(levelData.tiles.length, 1);
      expect(levelData.props.length, 1);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 1,
        'name': 'Minimal Level',
        'size': {'x': 1000.0, 'y': 800.0},
        'playerSpawn': {'x': 0.0, 'y': 0.0},
        'cameraMin': {'x': 0.0, 'y': 0.0},
        'cameraMax': {'x': 1000.0, 'y': 800.0},
      };

      final levelData = LevelData.fromJson(json);

      expect(levelData.id, 1);
      expect(levelData.name, 'Minimal Level');
      expect(levelData.description, null);
      expect(levelData.segments, isEmpty);
      expect(levelData.tiles, isEmpty);
      expect(levelData.props, isEmpty);
    });
  });

  group('SegmentData', () {
    test('fromJson creates valid SegmentData', () {
      final json = {
        'id': 0,
        'spawnPoint': {'x': 100.0, 'y': 50.0},
        'bounds': {
          'min': {'x': -200.0, 'y': -300.0},
          'max': {'x': 400.0, 'y': 300.0},
        },
        'triggers': [],
      };

      final segmentData = SegmentData.fromJson(json);

      expect(segmentData.id, 0);
      expect(segmentData.spawnPoint, Vector2(100.0, 50.0));
      expect(segmentData.cameraMin, Vector2(-200.0, -300.0));
      expect(segmentData.cameraMax, Vector2(400.0, 300.0));
      expect(segmentData.triggers, isEmpty);
    });
  });

  group('TileData', () {
    test('fromJson creates valid TileData', () {
      final json = {
        'position': {'x': 32.0, 'y': 64.0},
        'type': 'scaffolding',
        'durability': 1,
        'maxDurability': 1,
        'isDestructible': true,
      };

      final tileData = TileData.fromJson(json);

      expect(tileData.position, Vector2(32.0, 64.0));
      expect(tileData.type, 'scaffolding');
      expect(tileData.durability, 1);
      expect(tileData.maxDurability, 1);
      expect(tileData.isDestructible, true);
    });
  });

  group('PropData', () {
    test('fromJson creates valid PropData', () {
      final json = {
        'type': 'elevator',
        'position': {'x': 500.0, 'y': 100.0},
        'properties': {'speed': 2.0, 'range': 160.0},
      };

      final propData = PropData.fromJson(json);

      expect(propData.type, 'elevator');
      expect(propData.position, Vector2(500.0, 100.0));
      expect(propData.properties['speed'], 2.0);
      expect(propData.properties['range'], 160.0);
    });

    test('fromJson handles missing properties', () {
      final json = {
        'type': 'spring',
        'position': {'x': 200.0, 'y': 50.0},
      };

      final propData = PropData.fromJson(json);

      expect(propData.type, 'spring');
      expect(propData.position, Vector2(200.0, 50.0));
      expect(propData.properties, isEmpty);
    });
  });

  group('LevelManager', () {
    late LevelManager levelManager;
    late MockLevelLoader mockLoader;

    setUp(() {
      mockLoader = MockLevelLoader();
      levelManager = LevelManager(levelLoader: mockLoader);
    });

    test('loadLevel sets current level data', () async {
      await levelManager.loadLevel(1);

      expect(levelManager.currentLevel, 1);
      expect(levelManager.currentLevelData, isNotNull);
      expect(levelManager.currentSegment, 0);
      expect(levelManager.ballSegment, 0);
    });

    test('getCurrentSpawnPoint returns player spawn when no segments', () async {
      await levelManager.loadLevel(1);

      final spawnPoint = levelManager.getCurrentSpawnPoint();

      expect(spawnPoint, Vector2(-288.0, 32.0));
    });

    test('getCurrentCameraMin returns segment camera min when segments exist', () async {
      await levelManager.loadLevel(1);

      final cameraMin = levelManager.getCurrentCameraMin();

      // Should use segment 0 camera min
      expect(cameraMin, Vector2(-400.0, -300.0));
    });

    test('getCurrentCameraMax returns segment camera max when segments exist', () async {
      await levelManager.loadLevel(1);

      final cameraMax = levelManager.getCurrentCameraMax();

      // Should use segment 0 camera max, not level camera max
      expect(cameraMax, Vector2(400.0, 300.0));
    });

    test('switchSegment updates current segment', () async {
      await levelManager.loadLevel(1);

      levelManager.switchSegment(1);

      expect(levelManager.currentSegment, 1);
    });

    test('switchSegment with killBall=false updates ball segment', () async {
      await levelManager.loadLevel(1);

      levelManager.switchSegment(1, killBall: false);

      expect(levelManager.currentSegment, 1);
      expect(levelManager.ballSegment, 1);
    });

    test('switchSegment throws on invalid segment', () async {
      await levelManager.loadLevel(1);

      expect(
        () => levelManager.switchSegment(99),
        throwsA(isA<LevelManagerException>()),
      );
    });

    test('dispose clears level data', () async {
      await levelManager.loadLevel(1);

      levelManager.dispose();

      expect(levelManager.currentLevelData, isNull);
      expect(levelManager.currentLevel, 0);
      expect(levelManager.currentSegment, 0);
    });
  });
}

/// Mock level loader for testing
class MockLevelLoader extends LevelLoader {
  @override
  Future<LevelData> loadLevel(int levelId) async {
    // Return mock level data
    return LevelData(
      id: levelId,
      name: 'Test Level $levelId',
      segments: [
        SegmentData(
          id: 0,
          spawnPoint: Vector2(-288.0, 32.0),
          cameraMin: Vector2(-400.0, -300.0),
          cameraMax: Vector2(400.0, 300.0),
          triggers: [],
        ),
        SegmentData(
          id: 1,
          spawnPoint: Vector2(400.0, 32.0),
          cameraMin: Vector2(352.0, -300.0),
          cameraMax: Vector2(1152.0, 300.0),
          triggers: [],
        ),
      ],
      tiles: [],
      props: [],
      size: Vector2(2400.0, 800.0),
      playerSpawn: Vector2(-288.0, 32.0),
      cameraMin: Vector2(-400.0, -300.0),
      cameraMax: Vector2(2000.0, 500.0),
    );
  }
}
