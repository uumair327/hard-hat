import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/core/services/asset_manager.dart';
import 'package:hard_hat/core/services/asset_definition.dart';
import 'package:hard_hat/core/services/asset_registry.dart';

void main() {
  group('AssetManager Tests', () {
    late AssetManager assetManager;

    setUp(() {
      assetManager = AssetManager();
    });

    test('should register asset definitions', () {
      // Arrange
      final definitions = [
        const AssetDefinition(
          id: 'test_sprite',
          path: 'images/test.png',
          type: AssetType.sprite,
          preload: true,
        ),
      ];

      // Act
      assetManager.registerAssetDefinitions(definitions);

      // Assert
      expect(assetManager.getCacheStats()['preloadedAssets'], equals(0));
    });

    test('should provide cache statistics', () {
      // Act
      final stats = assetManager.getCacheStats();

      // Assert
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('spriteSheets'), isTrue);
      expect(stats.containsKey('spriteAtlases'), isTrue);
      expect(stats.containsKey('audioCache'), isTrue);
      expect(stats.containsKey('preloadedAssets'), isTrue);
    });

    test('should clear cache', () {
      // Act
      assetManager.clearCache();
      final stats = assetManager.getCacheStats();

      // Assert
      expect(stats['spriteSheets'], equals(0));
      expect(stats['spriteAtlases'], equals(0));
      expect(stats['audioCache'], equals(0));
      expect(stats['preloadedAssets'], equals(0));
    });

    test('should handle audio path caching', () {
      // Act
      final path1 = assetManager.getAudioPath('test_audio');
      final path2 = assetManager.getAudioPath('test_audio');

      // Assert
      expect(path1, equals('audio/test_audio.mp3'));
      expect(path2, equals(path1)); // Should return cached value
    });
  });

  group('AssetRegistry Tests', () {
    test('should contain predefined game assets', () {
      // Act
      final assets = AssetRegistry.gameAssets;

      // Assert
      expect(assets, isNotEmpty);
      expect(assets.any((asset) => asset.id == 'player_idle'), isTrue);
      expect(assets.any((asset) => asset.id == 'ball'), isTrue);
    });

    test('should get assets by type', () {
      // Act
      final spriteAssets = AssetRegistry.getSpriteAssets();
      final audioAssets = AssetRegistry.getAudioAssets();

      // Assert
      expect(spriteAssets, isNotEmpty);
      expect(audioAssets, isNotEmpty);
      expect(spriteAssets.every((asset) => asset.type == AssetType.sprite), isTrue);
      expect(audioAssets.every((asset) => asset.type == AssetType.audio), isTrue);
    });

    test('should get preload assets', () {
      // Act
      final preloadAssets = AssetRegistry.getPreloadAssets();

      // Assert
      expect(preloadAssets, isNotEmpty);
      expect(preloadAssets.every((asset) => asset.preload), isTrue);
    });

    test('should get asset definition by ID', () {
      // Act
      final asset = AssetRegistry.getAssetDefinition('player_idle');

      // Assert
      expect(asset, isNotNull);
      expect(asset!.id, equals('player_idle'));
      expect(asset.type, equals(AssetType.sprite));
    });

    test('should return null for non-existent asset', () {
      // Act
      final asset = AssetRegistry.getAssetDefinition('non_existent');

      // Assert
      expect(asset, isNull);
    });
  });

  group('AssetDefinition Tests', () {
    test('should create asset definition with correct properties', () {
      // Arrange & Act
      const definition = AssetDefinition(
        id: 'test_asset',
        path: 'images/test.png',
        type: AssetType.sprite,
        metadata: {'width': 32, 'height': 32},
        preload: true,
      );

      // Assert
      expect(definition.id, equals('test_asset'));
      expect(definition.path, equals('images/test.png'));
      expect(definition.type, equals(AssetType.sprite));
      expect(definition.metadata['width'], equals(32));
      expect(definition.preload, isTrue);
    });

    test('should create copy with modified properties', () {
      // Arrange
      const original = AssetDefinition(
        id: 'test_asset',
        path: 'images/test.png',
        type: AssetType.sprite,
      );

      // Act
      final copy = original.copyWith(preload: true);

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.path, equals(original.path));
      expect(copy.type, equals(original.type));
      expect(copy.preload, isTrue);
      expect(original.preload, isFalse);
    });

    test('should serialize to and from JSON', () {
      // Arrange
      const definition = AssetDefinition(
        id: 'test_asset',
        path: 'images/test.png',
        type: AssetType.sprite,
        metadata: {'width': 32},
        preload: true,
      );

      // Act
      final json = definition.toJson();
      final restored = AssetDefinition.fromJson(json);

      // Assert
      expect(restored.id, equals(definition.id));
      expect(restored.path, equals(definition.path));
      expect(restored.type, equals(definition.type));
      expect(restored.metadata, equals(definition.metadata));
      expect(restored.preload, equals(definition.preload));
    });
  });
}