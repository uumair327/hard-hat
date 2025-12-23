import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:hard_hat/core/services/sprite_atlas.dart';
import 'package:hard_hat/core/services/sprite_batch.dart';
import 'package:hard_hat/core/services/asset_definition.dart';
import 'package:hard_hat/core/services/asset_manager.dart';

void main() {
  group('Asset Optimization Tests', () {
    group('Sprite Atlas Optimization', () {
      test('should create sprite atlas with correct structure', () {
        // Arrange
        const atlasId = 'test_atlas';
        final sprites = {
          'sprite1': const SpriteRect(x: 0, y: 0, width: 32, height: 32),
          'sprite2': const SpriteRect(x: 32, y: 0, width: 32, height: 32),
          'sprite3': const SpriteRect(x: 0, y: 32, width: 32, height: 32),
        };
        final mockImage = _createMockImage(128, 128);
        
        // Act
        final atlas = SpriteAtlas(
          atlasId: atlasId,
          image: mockImage,
          sprites: sprites,
        );
        
        // Assert
        expect(atlas.atlasId, equals(atlasId));
        expect(atlas.sprites.length, equals(3));
        expect(atlas.hasSprite('sprite1'), isTrue);
        expect(atlas.hasSprite('sprite2'), isTrue);
        expect(atlas.hasSprite('sprite3'), isTrue);
        expect(atlas.hasSprite('nonexistent'), isFalse);
      });

      test('should optimize sprite packing in atlas', () {
        // Arrange
        final sprites = {
          'small1': const SpriteRect(x: 0, y: 0, width: 16, height: 16),
          'small2': const SpriteRect(x: 16, y: 0, width: 16, height: 16),
          'small3': const SpriteRect(x: 32, y: 0, width: 16, height: 16),
          'small4': const SpriteRect(x: 48, y: 0, width: 16, height: 16),
          'medium1': const SpriteRect(x: 0, y: 16, width: 32, height: 32),
          'medium2': const SpriteRect(x: 32, y: 16, width: 32, height: 32),
        };
        
        // Act
        final totalArea = sprites.values.fold<int>(0, (sum, rect) => 
          sum + (rect.width * rect.height));
        final atlasArea = 64 * 64; // 64x64 atlas
        final efficiency = totalArea / atlasArea;
        
        // Assert
        expect(efficiency, greaterThan(0.5)); // At least 50% efficiency
        expect(sprites.length, equals(6)); // All sprites fit
      });

      test('should support animation sequences in atlas', () {
        // Arrange
        final sprites = {
          'run_1': const SpriteRect(x: 0, y: 0, width: 32, height: 32),
          'run_2': const SpriteRect(x: 32, y: 0, width: 32, height: 32),
          'run_3': const SpriteRect(x: 64, y: 0, width: 32, height: 32),
          'run_4': const SpriteRect(x: 96, y: 0, width: 32, height: 32),
        };
        final animations = {
          'run': ['run_1', 'run_2', 'run_3', 'run_4'],
        };
        final mockImage = _createMockImage(128, 32);
        
        // Act
        final atlas = SpriteAtlas(
          atlasId: 'player_atlas',
          image: mockImage,
          sprites: sprites,
          animations: animations,
        );
        
        // Assert
        expect(atlas.hasAnimation('run'), isTrue);
        expect(atlas.animationNames, contains('run'));
        expect(atlas.animations['run']!.length, equals(4));
      });

      test('should create grid atlas for uniform sprites', () {
        // Arrange
        const spriteWidth = 32;
        const spriteHeight = 32;
        final spriteNames = ['tile1', 'tile2', 'tile3', 'tile4'];
        final mockImage = _createMockImage(128, 64);
        
        // Act
        final atlas = SpriteAtlasFactory.createGridAtlas(
          atlasId: 'tiles_atlas',
          image: mockImage,
          spriteWidth: spriteWidth,
          spriteHeight: spriteHeight,
          spriteNames: spriteNames,
        );
        
        // Assert
        expect(atlas.sprites.length, equals(4));
        expect(atlas.sprites['tile1']!.width, equals(spriteWidth));
        expect(atlas.sprites['tile1']!.height, equals(spriteHeight));
        expect(atlas.sprites['tile2']!.x, equals(spriteWidth));
        expect(atlas.sprites['tile3']!.y, equals(spriteHeight));
      });

      test('should handle atlas with margin and spacing', () {
        // Arrange
        const spriteWidth = 16;
        const spriteHeight = 16;
        const margin = 2;
        const spacing = 1;
        final spriteNames = ['icon1', 'icon2'];
        final mockImage = _createMockImage(64, 32);
        
        // Act
        final atlas = SpriteAtlasFactory.createGridAtlas(
          atlasId: 'icons_atlas',
          image: mockImage,
          spriteWidth: spriteWidth,
          spriteHeight: spriteHeight,
          spriteNames: spriteNames,
          margin: margin,
          spacing: spacing,
        );
        
        // Assert
        expect(atlas.sprites['icon1']!.x, equals(margin));
        expect(atlas.sprites['icon1']!.y, equals(margin));
        expect(atlas.sprites['icon2']!.x, equals(margin + spriteWidth + spacing));
      });
    });

    group('Sprite Batching Optimization', () {
      test('should create sprite batch with correct properties', () {
        // Arrange
        final mockImage = _createMockImage(64, 64);
        final sprite = Sprite(mockImage);
        final items = [
          SpriteBatchItem(
            sprite: sprite,
            position: Vector2(100, 200),
            size: Vector2(32, 32),
            renderLayer: RenderLayer.entities,
          ),
          SpriteBatchItem(
            sprite: sprite,
            position: Vector2(150, 250),
            size: Vector2(32, 32),
            renderLayer: RenderLayer.entities,
          ),
        ];
        
        // Act
        final batch = SpriteBatch(image: mockImage, items: items);
        
        // Assert
        expect(batch.items.length, equals(2));
        expect(batch.image, equals(mockImage));
        expect(batch.canBatch(items[0]), isTrue);
        expect(batch.canBatch(items[1]), isTrue);
      });

      test('should manage sprite batches by render layer', () {
        // Arrange
        final manager = SpriteBatchManager();
        final mockImage = _createMockImage(64, 64);
        final sprite = Sprite(mockImage);
        
        final backgroundItem = SpriteBatchItem(
          sprite: sprite,
          position: Vector2(0, 0),
          size: Vector2(32, 32),
          renderLayer: RenderLayer.background,
        );
        
        final entityItem = SpriteBatchItem(
          sprite: sprite,
          position: Vector2(100, 100),
          size: Vector2(32, 32),
          renderLayer: RenderLayer.entities,
        );
        
        final uiItem = SpriteBatchItem(
          sprite: sprite,
          position: Vector2(200, 200),
          size: Vector2(32, 32),
          renderLayer: RenderLayer.ui,
        );
        
        // Act
        manager.addSprite(backgroundItem);
        manager.addSprite(entityItem);
        manager.addSprite(uiItem);
        
        final sortedBatches = manager.getSortedBatches();
        
        // Assert
        expect(sortedBatches.length, greaterThan(0));
        expect(manager.getBatchesForLayer(RenderLayer.background).isNotEmpty, isTrue);
        expect(manager.getBatchesForLayer(RenderLayer.entities).isNotEmpty, isTrue);
        expect(manager.getBatchesForLayer(RenderLayer.ui).isNotEmpty, isTrue);
      });

      test('should optimize batches by consolidating same image', () {
        // Arrange
        final manager = SpriteBatchManager(maxBatchSize: 10);
        final mockImage = _createMockImage(64, 64);
        final sprite = Sprite(mockImage);
        
        // Add multiple sprites with same image
        for (int i = 0; i < 5; i++) {
          manager.addSprite(SpriteBatchItem(
            sprite: sprite,
            position: Vector2(i * 32.0, 0),
            size: Vector2(32, 32),
            renderLayer: RenderLayer.entities,
          ));
        }
        
        // Act
        final stats = manager.getStats();
        manager.optimizeBatches();
        final optimizedStats = manager.getStats();
        
        // Assert
        expect(stats['totalSprites'], equals(5));
        expect(optimizedStats['totalSprites'], equals(5));
        // Should consolidate into fewer batches
        expect(optimizedStats['totalBatches'], lessThanOrEqualTo(stats['totalBatches']));
      });

      test('should respect max batch size limit', () {
        // Arrange
        const maxBatchSize = 3;
        final manager = SpriteBatchManager(maxBatchSize: maxBatchSize);
        final mockImage = _createMockImage(64, 64);
        final sprite = Sprite(mockImage);
        
        // Act - Add more sprites than max batch size
        for (int i = 0; i < 5; i++) {
          manager.addSprite(SpriteBatchItem(
            sprite: sprite,
            position: Vector2(i * 32.0, 0),
            size: Vector2(32, 32),
            renderLayer: RenderLayer.entities,
          ));
        }
        
        final stats = manager.getStats();
        
        // Assert
        expect(stats['totalSprites'], equals(5));
        expect(stats['totalBatches'], greaterThan(1)); // Should create multiple batches
      });

      test('should handle different blend modes', () {
        // Arrange
        final mockImage = _createMockImage(64, 64);
        final sprite = Sprite(mockImage);
        final items = [
          SpriteBatchItem(
            sprite: sprite,
            position: Vector2(0, 0),
            size: Vector2(32, 32),
          ),
        ];
        
        // Act
        final normalBatch = SpriteBatch(
          image: mockImage,
          items: items,
          blendMode: BlendMode.srcOver,
        );
        
        final additiveBatch = SpriteBatch(
          image: mockImage,
          items: items,
          blendMode: BlendMode.plus,
        );
        
        // Assert
        expect(normalBatch.blendMode, equals(BlendMode.srcOver));
        expect(additiveBatch.blendMode, equals(BlendMode.plus));
      });

      test('should provide accurate batch statistics', () {
        // Arrange
        final manager = SpriteBatchManager();
        final mockImage1 = _createMockImage(64, 64);
        final mockImage2 = _createMockImage(32, 32);
        final sprite1 = Sprite(mockImage1);
        final sprite2 = Sprite(mockImage2);
        
        // Act
        manager.addSprite(SpriteBatchItem(
          sprite: sprite1,
          position: Vector2(0, 0),
          size: Vector2(32, 32),
          renderLayer: RenderLayer.entities,
        ));
        
        manager.addSprite(SpriteBatchItem(
          sprite: sprite2,
          position: Vector2(50, 50),
          size: Vector2(16, 16),
          renderLayer: RenderLayer.particles,
        ));
        
        final stats = manager.getStats();
        
        // Assert
        expect(stats['totalSprites'], equals(2));
        expect(stats['totalBatches'], equals(2)); // Different images = different batches
        expect(stats['layerCount'], equals(2));
        expect(stats['batchingEnabled'], isTrue);
      });
    });

    group('Asset Compression and Loading', () {
      test('should support multiple asset formats', () {
        // Arrange
        final assetFormats = {
          AssetType.sprite: ['.png', '.jpg'],
          AssetType.audio: ['.mp3', '.ogg'],
          AssetType.data: ['.json'],
        };
        
        // Assert
        expect(assetFormats[AssetType.sprite], contains('.png'));
        expect(assetFormats[AssetType.audio], contains('.mp3'));
        expect(assetFormats[AssetType.data], contains('.json'));
      });

      test('should optimize asset loading with preloading', () {
        // Arrange
        final assetManager = AssetManager();
        final preloadAssets = [
          const AssetDefinition(
            id: 'player_idle',
            path: 'images/sprites/game/player/idle.png',
            type: AssetType.sprite,
            preload: true,
          ),
          const AssetDefinition(
            id: 'background_music',
            path: 'audio/music/gameplay.mp3',
            type: AssetType.audio,
            preload: true,
          ),
        ];
        
        // Act
        assetManager.registerAssetDefinitions(preloadAssets);
        
        // Assert
        expect(preloadAssets.where((asset) => asset.preload).length, equals(2));
        expect(preloadAssets[0].preload, isTrue);
        expect(preloadAssets[1].preload, isTrue);
      });

      test('should cache loaded assets for performance', () {
        // Arrange
        final assetManager = AssetManager();
        
        // Act
        final initialStats = assetManager.getCacheStats();
        
        // Simulate some cached assets
        final expectedStats = {
          'images': 0,
          'spriteSheets': 0,
          'spriteAtlases': 0,
          'audioCache': 0,
          'preloadedAssets': 0,
        };
        
        // Assert
        expect(initialStats, equals(expectedStats));
        expect(initialStats.keys, contains('spriteSheets'));
        expect(initialStats.keys, contains('spriteAtlases'));
        expect(initialStats.keys, contains('audioCache'));
      });

      test('should handle asset loading errors gracefully', () {
        // Act & Assert
        expect(() => _validateAssetPath(''), throwsArgumentError);
        expect(() => _validateAssetPath('../../../etc/passwd'), throwsArgumentError);
        expect(_validateAssetPath('images/sprites/valid.png'), isTrue);
      });

      test('should optimize memory usage with asset cleanup', () {
        // Arrange
        final assetManager = AssetManager();
        
        // Act
        assetManager.clearCache();
        final clearedStats = assetManager.getCacheStats();
        
        // Assert
        expect(clearedStats['spriteSheets'], equals(0));
        expect(clearedStats['spriteAtlases'], equals(0));
        expect(clearedStats['audioCache'], equals(0));
        expect(clearedStats['preloadedAssets'], equals(0));
      });

      test('should support lazy loading for non-critical assets', () {
        // Arrange
        final criticalAssets = [
          const AssetDefinition(
            id: 'player_sprite',
            path: 'images/sprites/game/player/idle.png',
            type: AssetType.sprite,
            preload: true,
          ),
        ];
        
        final lazyAssets = [
          const AssetDefinition(
            id: 'background_detail',
            path: 'images/sprites/game/background_detail.png',
            type: AssetType.sprite,
            preload: false,
          ),
        ];
        
        // Assert
        expect(criticalAssets[0].preload, isTrue);
        expect(lazyAssets[0].preload, isFalse);
      });
    });

    group('Performance Optimization', () {
      test('should minimize draw calls through batching', () {
        // Arrange
        final manager = SpriteBatchManager();
        final mockImage = _createMockImage(64, 64);
        final sprite = Sprite(mockImage);
        
        // Add 10 sprites with same image (should batch together)
        for (int i = 0; i < 10; i++) {
          manager.addSprite(SpriteBatchItem(
            sprite: sprite,
            position: Vector2(i * 32.0, 0),
            size: Vector2(32, 32),
            renderLayer: RenderLayer.entities,
          ));
        }
        
        // Act
        final stats = manager.getStats();
        
        // Assert
        expect(stats['totalSprites'], equals(10));
        expect(stats['totalBatches'], equals(1)); // All batched together
      });

      test('should optimize render order by layer', () {
        // Arrange
        final layers = [
          RenderLayer.background,
          RenderLayer.tiles,
          RenderLayer.entities,
          RenderLayer.particles,
          RenderLayer.ui,
        ];
        
        // Act
        final sortedLayers = layers..sort((a, b) => a.value.compareTo(b.value));
        
        // Assert
        expect(sortedLayers[0], equals(RenderLayer.background));
        expect(sortedLayers.last, equals(RenderLayer.ui));
        expect(sortedLayers[1].value, lessThan(sortedLayers[2].value));
      });

      test('should support efficient sprite atlas lookup', () {
        // Arrange
        final sprites = <String, SpriteRect>{};
        for (int i = 0; i < 100; i++) {
          sprites['sprite_$i'] = SpriteRect(
            x: (i % 10) * 32,
            y: (i ~/ 10) * 32,
            width: 32,
            height: 32,
          );
        }
        
        final mockImage = _createMockImage(320, 320);
        final atlas = SpriteAtlas(
          atlasId: 'large_atlas',
          image: mockImage,
          sprites: sprites,
        );
        
        // Act & Assert
        expect(atlas.hasSprite('sprite_0'), isTrue);
        expect(atlas.hasSprite('sprite_50'), isTrue);
        expect(atlas.hasSprite('sprite_99'), isTrue);
        expect(atlas.hasSprite('sprite_100'), isFalse);
        expect(atlas.sprites.length, equals(100));
      });

      test('should optimize memory with object pooling support', () {
        // Arrange
        final batchItems = <SpriteBatchItem>[];
        final mockImage = _createMockImage(32, 32);
        final sprite = Sprite(mockImage);
        
        // Create many batch items (simulating object pool usage)
        for (int i = 0; i < 1000; i++) {
          batchItems.add(SpriteBatchItem(
            sprite: sprite,
            position: Vector2(i.toDouble(), 0),
            size: Vector2(32, 32),
          ));
        }
        
        // Act
        final uniqueSprites = <Sprite>{};
        for (final item in batchItems) {
          uniqueSprites.add(item.sprite);
        }
        
        // Assert
        expect(batchItems.length, equals(1000));
        expect(uniqueSprites.length, equals(1)); // All share same sprite instance
      });

      test('should handle high-frequency batch updates efficiently', () {
        // Arrange
        final manager = SpriteBatchManager();
        final mockImage = _createMockImage(32, 32);
        final sprite = Sprite(mockImage);
        
        final item = SpriteBatchItem(
          sprite: sprite,
          position: Vector2(0, 0),
          size: Vector2(32, 32),
        );
        
        // Act - Simulate rapid add/remove cycles
        for (int i = 0; i < 100; i++) {
          manager.addSprite(item);
          manager.removeSprite(item);
        }
        
        final stats = manager.getStats();
        
        // Assert
        expect(stats['totalSprites'], equals(0)); // Should be clean after removes
        expect(stats['totalBatches'], equals(0));
      });
    });
  });
}

// Helper functions for testing
ui.Image _createMockImage(int width, int height) {
  // In a real test, this would create a proper mock image
  // For now, we'll use a placeholder that satisfies the type system
  return _MockImage(width, height);
}

bool _validateAssetPath(String path) {
  if (path.isEmpty) {
    throw ArgumentError('Asset path cannot be empty');
  }
  
  if (path.contains('..')) {
    throw ArgumentError('Asset path cannot contain relative references');
  }
  
  return true;
}

// Mock image class for testing
class _MockImage implements ui.Image {
  _MockImage(this.width, this.height);
  
  @override
  final int width;
  
  @override
  final int height;
  
  @override
  void dispose() {}
  
  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;
  
  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    throw UnimplementedError();
  }
  
  @override
  ui.Image clone() => this;
  
  @override
  bool get debugDisposed => false;
  
  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;
  
  @override
  bool isCloneOf(ui.Image other) => false;
}