import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/core/services/sprite_batch.dart';
import 'package:flame/components.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Mock sprite for testing
Sprite createMockSprite() {
  // Create a simple 1x1 image for testing
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(1, 1);
  return Sprite(image);
}

void main() {
  group('SpriteBatch Tests', () {
    test('should create sprite batch item with correct properties', () {
      // Arrange
      final sprite = createMockSprite();
      final position = Vector2(10, 20);
      final size = Vector2(32, 32);

      // Act
      final item = SpriteBatchItem(
        sprite: sprite,
        position: position,
        size: size,
        rotation: 0.5,
        scale: 2.0,
        renderLayer: RenderLayer.entities,
      );

      // Assert
      expect(item.position, equals(position));
      expect(item.size, equals(size));
      expect(item.rotation, equals(0.5));
      expect(item.scale, equals(2.0));
      expect(item.renderLayer, equals(RenderLayer.entities));
    });

    test('should create copy with modified properties', () {
      // Arrange
      final sprite = createMockSprite();
      final original = SpriteBatchItem(
        sprite: sprite,
        position: Vector2(10, 20),
        size: Vector2(32, 32),
        renderLayer: RenderLayer.entities,
      );

      // Act
      final copy = original.copyWith(
        position: Vector2(50, 60),
        renderLayer: RenderLayer.particles,
      );

      // Assert
      expect(copy.position, equals(Vector2(50, 60)));
      expect(copy.size, equals(original.size));
      expect(copy.renderLayer, equals(RenderLayer.particles));
    });
  });

  group('SpriteBatchManager Tests', () {
    late SpriteBatchManager batchManager;

    setUp(() {
      batchManager = SpriteBatchManager(
        maxBatchSize: 10,
        enableBatching: true,
      );
    });

    test('should initialize with correct settings', () {
      // Assert
      expect(batchManager.maxBatchSize, equals(10));
      expect(batchManager.enableBatching, isTrue);
    });

    test('should provide statistics', () {
      // Act
      final stats = batchManager.getStats();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalBatches'), isTrue);
      expect(stats.containsKey('totalSprites'), isTrue);
      expect(stats.containsKey('batchingEnabled'), isTrue);
      expect(stats['batchingEnabled'], isTrue);
    });

    test('should clear all batches', () {
      // Act
      batchManager.clear();
      final stats = batchManager.getStats();

      // Assert
      expect(stats['totalBatches'], equals(0));
      expect(stats['totalSprites'], equals(0));
    });

    test('should get sorted batches by layer', () {
      // Act
      final batches = batchManager.getSortedBatches();

      // Assert
      expect(batches, isA<List<SpriteBatch>>());
      expect(batches, isEmpty); // No sprites added yet
    });

    test('should get batches for specific layer', () {
      // Act
      final layerBatches = batchManager.getBatchesForLayer(RenderLayer.entities);

      // Assert
      expect(layerBatches, isA<List<SpriteBatch>>());
      expect(layerBatches, isEmpty); // No sprites added yet
    });
  });

  group('RenderLayer Tests', () {
    test('should have correct layer values', () {
      // Assert
      expect(RenderLayer.background.value, equals(0));
      expect(RenderLayer.tiles.value, equals(100));
      expect(RenderLayer.entities.value, equals(300));
      expect(RenderLayer.ui.value, equals(1000));
    });

    test('should maintain correct ordering', () {
      // Arrange
      final layers = [
        RenderLayer.ui,
        RenderLayer.background,
        RenderLayer.entities,
        RenderLayer.tiles,
      ];

      // Act
      layers.sort((a, b) => a.value.compareTo(b.value));

      // Assert
      expect(layers[0], equals(RenderLayer.background));
      expect(layers[1], equals(RenderLayer.tiles));
      expect(layers[2], equals(RenderLayer.entities));
      expect(layers[3], equals(RenderLayer.ui));
    });
  });
}