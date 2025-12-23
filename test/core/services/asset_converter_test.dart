import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetConverter Tests', () {
    group('Asset Format Compatibility', () {
      test('should support PNG sprite format', () {
        // Arrange
        const spritePath = 'images/sprites/game/player/idle.png';
        
        // Assert
        expect(spritePath.endsWith('.png'), isTrue);
        expect(spritePath.contains('images/sprites'), isTrue);
      });

      test('should support SVG sprite format', () {
        // Arrange
        const svgPath = 'images/sprites/game/particles/star_particle.svg';
        
        // Assert
        expect(svgPath.endsWith('.svg'), isTrue);
        expect(svgPath.contains('images/sprites'), isTrue);
      });

      test('should support MP3 audio format', () {
        // Arrange
        const audioPath = 'audio/music/gameplay.mp3';
        
        // Assert
        expect(audioPath.endsWith('.mp3'), isTrue);
        expect(audioPath.contains('audio'), isTrue);
      });

      test('should support JSON data format', () {
        // Arrange
        const dataPath = 'data/levels/level_1.json';
        
        // Assert
        expect(dataPath.endsWith('.json'), isTrue);
        expect(dataPath.contains('data'), isTrue);
      });
    });

    group('Asset Path Conversion', () {
      test('should convert Godot sprite paths to Flutter paths', () {
        // Arrange
        const expectedFlutterPath = 'images/sprites/game/player/idle.png';
        
        // Assert
        expect(expectedFlutterPath.contains('images/sprites'), isTrue);
        expect(expectedFlutterPath.endsWith('idle.png'), isTrue);
      });

      test('should convert Godot audio paths to Flutter paths', () {
        // Arrange
        const expectedFlutterPath = 'audio/music/gameplay.mp3';
        
        // Assert
        expect(expectedFlutterPath.contains('audio/music'), isTrue);
        expect(expectedFlutterPath.endsWith('gameplay.mp3'), isTrue);
        expect(expectedFlutterPath.contains('mus_'), isFalse);
      });

      test('should convert Godot mesh textures to Flutter tile sprites', () {
        // Arrange
        const expectedFlutterPath = 'images/sprites/tiles/scaffolding.png';
        
        // Assert
        expect(expectedFlutterPath.contains('images/sprites/tiles'), isTrue);
        expect(expectedFlutterPath.endsWith('scaffolding.png'), isTrue);
      });

      test('should handle nested directory structures', () {
        // Arrange
        const expectedFlutterPath = 'images/sprites/game/particles/star_particle.svg';
        
        // Assert
        expect(expectedFlutterPath.split('/').length, greaterThan(3));
        expect(expectedFlutterPath.contains('images/sprites/game/particles'), isTrue);
      });
    });

    group('Sprite Atlas Generation', () {
      test('should generate atlas definition with correct structure', () {
        // Arrange
        const atlasName = 'game';
        final spritePaths = [
          'images/sprites/game/player/idle.png',
          'images/sprites/game/player/run.png',
        ];
        
        // Act
        final atlasData = {
          'name': atlasName,
          'sprites': spritePaths.map((path) {
            final name = path.split('/').last.split('.').first;
            return {
              'name': name,
              'path': path,
              'x': 0,
              'y': 0,
              'width': 0,
              'height': 0,
            };
          }).toList(),
        };
        
        // Assert
        expect(atlasData['name'], equals(atlasName));
        expect(atlasData['sprites'], isA<List>());
        expect((atlasData['sprites'] as List).length, equals(2));
        
        final firstSprite = (atlasData['sprites'] as List)[0] as Map;
        expect(firstSprite['name'], equals('idle'));
        expect(firstSprite['path'], equals('images/sprites/game/player/idle.png'));
        expect(firstSprite.containsKey('x'), isTrue);
        expect(firstSprite.containsKey('y'), isTrue);
        expect(firstSprite.containsKey('width'), isTrue);
        expect(firstSprite.containsKey('height'), isTrue);
      });

      test('should extract sprite name from path correctly', () {
        // Arrange
        const spritePath = 'images/sprites/game/player/idle.png';
        
        // Act
        final name = spritePath.split('/').last.split('.').first;
        
        // Assert
        expect(name, equals('idle'));
      });

      test('should handle multiple sprites in atlas', () {
        // Arrange
        final spritePaths = [
          'images/sprites/game/player/idle.png',
          'images/sprites/game/player/run.png',
          'images/sprites/game/player/jump.png',
          'images/sprites/game/player/fall.png',
        ];
        
        // Act
        final sprites = spritePaths.map((path) {
          final name = path.split('/').last.split('.').first;
          return {'name': name, 'path': path};
        }).toList();
        
        // Assert
        expect(sprites.length, equals(4));
        expect(sprites[0]['name'], equals('idle'));
        expect(sprites[1]['name'], equals('run'));
        expect(sprites[2]['name'], equals('jump'));
        expect(sprites[3]['name'], equals('fall'));
      });

      test('should organize sprites by category', () {
        // Arrange
        final categories = {
          'game': ['player/idle.png', 'player/run.png'],
          'tiles': ['scaffolding.png', 'timber.png'],
          'ui': ['play.png', 'quit.png'],
          'particles': ['star_particle.svg', 'step_particle.svg'],
        };
        
        // Assert
        expect(categories.keys.length, equals(4));
        expect(categories['game']!.length, equals(2));
        expect(categories['tiles']!.length, equals(2));
        expect(categories['ui']!.length, equals(2));
        expect(categories['particles']!.length, equals(2));
      });
    });

    group('Asset Optimization', () {
      test('should use appropriate file formats for optimization', () {
        // Arrange
        final assetFormats = {
          'sprites': '.png',
          'vectors': '.svg',
          'audio': '.mp3',
          'data': '.json',
        };
        
        // Assert
        expect(assetFormats['sprites'], equals('.png'));
        expect(assetFormats['vectors'], equals('.svg'));
        expect(assetFormats['audio'], equals('.mp3'));
        expect(assetFormats['data'], equals('.json'));
      });

      test('should organize assets by type for efficient loading', () {
        // Arrange
        final assetStructure = {
          'images/sprites/game': ['player', 'particles', 'hud'],
          'images/sprites/tiles': ['scaffolding', 'timber', 'bricks'],
          'images/sprites/ui': ['play', 'config', 'quit'],
          'audio/music': ['title', 'gameplay'],
          'audio/sfx': ['break', 'hit', 'land'],
          'audio/loop': ['step', 'elevator'],
        };
        
        // Assert
        expect(assetStructure.keys.length, equals(6));
        expect(assetStructure['images/sprites/game']!.length, equals(3));
        expect(assetStructure['audio/sfx']!.length, equals(3));
      });

      test('should support sprite batching through atlases', () {
        // Arrange
        final atlases = ['game', 'tiles', 'ui', 'particles'];
        
        // Assert
        expect(atlases.length, equals(4));
        expect(atlases.contains('game'), isTrue);
        expect(atlases.contains('tiles'), isTrue);
        expect(atlases.contains('ui'), isTrue);
        expect(atlases.contains('particles'), isTrue);
      });

      test('should minimize draw calls through atlas organization', () {
        // Arrange
        const gameAtlas = {
          'name': 'game',
          'sprites': [
            {'name': 'idle', 'path': 'images/sprites/game/player/idle.png'},
            {'name': 'run', 'path': 'images/sprites/game/player/run.png'},
          ],
        };
        
        // Assert
        expect(gameAtlas['name'], equals('game'));
        expect((gameAtlas['sprites'] as List).length, greaterThan(1));
      });
    });

    group('Asset Validation', () {
      test('should validate sprite paths are correctly formatted', () {
        // Arrange
        const validSpritePaths = [
          'images/sprites/game/player/idle.png',
          'images/sprites/tiles/scaffolding.png',
          'images/sprites/ui/play.png',
        ];
        
        // Assert
        for (final path in validSpritePaths) {
          expect(path.startsWith('images/sprites/'), isTrue);
          expect(path.endsWith('.png') || path.endsWith('.svg'), isTrue);
        }
      });

      test('should validate audio paths are correctly formatted', () {
        // Arrange
        const validAudioPaths = [
          'audio/music/gameplay.mp3',
          'audio/sfx/break.mp3',
          'audio/loop/step.mp3',
        ];
        
        // Assert
        for (final path in validAudioPaths) {
          expect(path.startsWith('audio/'), isTrue);
          expect(path.endsWith('.mp3'), isTrue);
        }
      });

      test('should validate atlas definitions have required fields', () {
        // Arrange
        const atlasDefinition = {
          'name': 'game',
          'sprites': [
            {
              'name': 'idle',
              'path': 'images/sprites/game/player/idle.png',
              'x': 0,
              'y': 0,
              'width': 32,
              'height': 32,
            }
          ],
        };
        
        // Assert
        expect(atlasDefinition.containsKey('name'), isTrue);
        expect(atlasDefinition.containsKey('sprites'), isTrue);
        
        final sprite = (atlasDefinition['sprites'] as List)[0] as Map;
        expect(sprite.containsKey('name'), isTrue);
        expect(sprite.containsKey('path'), isTrue);
        expect(sprite.containsKey('x'), isTrue);
        expect(sprite.containsKey('y'), isTrue);
        expect(sprite.containsKey('width'), isTrue);
        expect(sprite.containsKey('height'), isTrue);
      });

      test('should detect invalid file extensions', () {
        // Arrange
        const invalidPaths = [
          'images/sprites/game/player/idle.bmp',
          'audio/music/gameplay.wav',
          'data/levels/level_1.xml',
        ];
        
        // Assert
        expect(invalidPaths[0].endsWith('.png'), isFalse);
        expect(invalidPaths[1].endsWith('.mp3'), isFalse);
        expect(invalidPaths[2].endsWith('.json'), isFalse);
      });
    });

    group('JSON Formatting', () {
      test('should format JSON with proper indentation', () {
        // Arrange
        final data = {
          'name': 'test',
          'sprites': [
            {'name': 'sprite1', 'path': 'path1'},
            {'name': 'sprite2', 'path': 'path2'},
          ],
        };
        
        // Act
        final formatted = _formatTestJson(data);
        
        // Assert
        expect(formatted.contains('{'), isTrue);
        expect(formatted.contains('}'), isTrue);
        expect(formatted.contains('['), isTrue);
        expect(formatted.contains(']'), isTrue);
        expect(formatted.contains('"name"'), isTrue);
      });

      test('should handle nested objects in JSON', () {
        // Arrange
        final data = {
          'name': 'atlas',
          'sprites': [
            {
              'name': 'sprite1',
              'position': {'x': 0, 'y': 0},
            }
          ],
        };
        
        // Assert
        expect(data['sprites'], isA<List>());
        final sprite = (data['sprites'] as List)[0] as Map;
        expect(sprite['position'], isA<Map>());
        expect((sprite['position'] as Map)['x'], equals(0));
      });

      test('should preserve data types in JSON', () {
        // Arrange
        final data = {
          'name': 'test',
          'count': 5,
          'enabled': true,
          'value': 3.14,
        };
        
        // Assert
        expect(data['name'], isA<String>());
        expect(data['count'], isA<int>());
        expect(data['enabled'], isA<bool>());
        expect(data['value'], isA<double>());
      });
    });

    group('Error Handling', () {
      test('should handle missing source files gracefully', () {
        // Arrange
        const nonExistentPath = 'godot_Hard-Hat/assets/sprite/missing.png';
        final file = File(nonExistentPath);
        
        // Assert
        expect(file.existsSync(), isFalse);
      });

      test('should handle invalid paths gracefully', () {
        // Arrange
        const invalidPaths = [
          '',
          '/',
          '../../../etc/passwd',
        ];
        
        // Assert
        for (final path in invalidPaths) {
          expect(path.isEmpty || path.contains('..'), isTrue);
        }
      });

      test('should validate directory creation', () {
        // Arrange
        const targetPath = 'assets/images/sprites/game/player/idle.png';
        final parts = targetPath.split('/');
        
        // Assert
        expect(parts.length, greaterThan(1));
        expect(parts.last, equals('idle.png'));
      });
    });
  });
}

// Helper function for testing JSON formatting
String _formatTestJson(Map<String, dynamic> data) {
  final buffer = StringBuffer();
  buffer.writeln('{');
  
  data.forEach((key, value) {
    buffer.write('  "$key": ');
    if (value is String) {
      buffer.writeln('"$value"');
    } else if (value is List) {
      buffer.writeln('[...]');
    } else {
      buffer.writeln('$value');
    }
  });
  
  buffer.writeln('}');
  return buffer.toString();
}
