import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Render layers for z-ordering
enum RenderLayer {
  background(0),
  tiles(100),
  interactive(200),
  entities(300),
  projectiles(400),
  particles(500),
  ui(1000);

  const RenderLayer(this.value);
  final int value;
}

/// Batch item representing a sprite to be rendered
class SpriteBatchItem extends Equatable {
  const SpriteBatchItem({
    required this.sprite,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.paint,
    this.anchor = Anchor.topLeft,
    this.renderLayer = RenderLayer.entities,
  });

  final Sprite sprite;
  final Vector2 position;
  final Vector2 size;
  final double rotation;
  final double scale;
  final Paint? paint;
  final Anchor anchor;
  final RenderLayer renderLayer;

  @override
  List<Object?> get props => [
    sprite,
    position,
    size,
    rotation,
    scale,
    paint,
    anchor,
    renderLayer,
  ];

  /// Create a copy with modified properties
  SpriteBatchItem copyWith({
    Sprite? sprite,
    Vector2? position,
    Vector2? size,
    double? rotation,
    double? scale,
    Paint? paint,
    Anchor? anchor,
    RenderLayer? renderLayer,
  }) {
    return SpriteBatchItem(
      sprite: sprite ?? this.sprite,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      paint: paint ?? this.paint,
      anchor: anchor ?? this.anchor,
      renderLayer: renderLayer ?? this.renderLayer,
    );
  }
}

/// Batch group for sprites sharing the same texture/atlas
class SpriteBatch extends Equatable {
  const SpriteBatch({
    required this.image,
    required this.items,
    this.blendMode = BlendMode.srcOver,
  });

  final ui.Image image;
  final List<SpriteBatchItem> items;
  final BlendMode blendMode;

  @override
  List<Object?> get props => [image, items, blendMode];

  /// Check if this batch can accept a new sprite item
  bool canBatch(SpriteBatchItem item) {
    return item.sprite.image == image;
  }

  /// Add an item to this batch
  SpriteBatch addItem(SpriteBatchItem item) {
    if (!canBatch(item)) {
      throw ArgumentError('Cannot batch sprite with different image');
    }
    
    return SpriteBatch(
      image: image,
      items: [...items, item],
      blendMode: blendMode,
    );
  }

  /// Remove an item from this batch
  SpriteBatch removeItem(SpriteBatchItem item) {
    final newItems = items.where((i) => i != item).toList();
    return SpriteBatch(
      image: image,
      items: newItems,
      blendMode: blendMode,
    );
  }
}

/// Manages sprite batching for optimized rendering
class SpriteBatchManager {
  SpriteBatchManager({
    this.maxBatchSize = 1000,
    this.enableBatching = true,
  });

  final int maxBatchSize;
  final bool enableBatching;
  
  final Map<RenderLayer, List<SpriteBatch>> _layerBatches = {};
  final Map<ui.Image, SpriteBatch> _activeBatches = {};

  /// Add a sprite item to be batched
  void addSprite(SpriteBatchItem item) {
    if (!enableBatching) {
      // If batching is disabled, create individual batches
      _addIndividualSprite(item);
      return;
    }

    final image = item.sprite.image;
    
    // Try to add to existing batch
    if (_activeBatches.containsKey(image)) {
      final existingBatch = _activeBatches[image]!;
      if (existingBatch.items.length < maxBatchSize) {
        _activeBatches[image] = existingBatch.addItem(item);
        return;
      }
    }

    // Create new batch
    final newBatch = SpriteBatch(
      image: image,
      items: [item],
    );
    
    _activeBatches[image] = newBatch;
    
    // Add to layer
    final layer = item.renderLayer;
    _layerBatches.putIfAbsent(layer, () => []);
    _layerBatches[layer]!.add(newBatch);
  }

  /// Add sprite without batching (for special cases)
  void _addIndividualSprite(SpriteBatchItem item) {
    final batch = SpriteBatch(
      image: item.sprite.image,
      items: [item],
    );
    
    final layer = item.renderLayer;
    _layerBatches.putIfAbsent(layer, () => []);
    _layerBatches[layer]!.add(batch);
  }

  /// Remove a sprite item from batches
  void removeSprite(SpriteBatchItem item) {
    final image = item.sprite.image;
    final batch = _activeBatches[image];
    
    if (batch != null) {
      final updatedBatch = batch.removeItem(item);
      
      if (updatedBatch.items.isEmpty) {
        _activeBatches.remove(image);
        // Remove from layer batches
        for (final layerBatches in _layerBatches.values) {
          layerBatches.removeWhere((b) => b == batch);
        }
      } else {
        _activeBatches[image] = updatedBatch;
      }
    }
  }

  /// Get all batches sorted by render layer
  List<SpriteBatch> getSortedBatches() {
    final allBatches = <SpriteBatch>[];
    
    // Sort layers by their values (lower values render first)
    final sortedLayers = _layerBatches.keys.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    for (final layer in sortedLayers) {
      final layerBatches = _layerBatches[layer] ?? [];
      allBatches.addAll(layerBatches);
    }
    
    return allBatches;
  }

  /// Get batches for a specific layer
  List<SpriteBatch> getBatchesForLayer(RenderLayer layer) {
    return _layerBatches[layer] ?? [];
  }

  /// Render all batches to canvas
  void renderBatches(Canvas canvas) {
    final batches = getSortedBatches();
    
    for (final batch in batches) {
      _renderBatch(canvas, batch);
    }
  }

  /// Render a specific batch
  void _renderBatch(Canvas canvas, SpriteBatch batch) {
    if (batch.items.isEmpty) return;

    // Group items by similar properties for further optimization
    final groupedItems = _groupSimilarItems(batch.items);
    
    for (final group in groupedItems) {
      _renderItemGroup(canvas, group);
    }
  }

  /// Group similar items for optimized rendering
  List<List<SpriteBatchItem>> _groupSimilarItems(List<SpriteBatchItem> items) {
    final groups = <List<SpriteBatchItem>>[];
    final Map<String, List<SpriteBatchItem>> groupMap = {};
    
    for (final item in items) {
      // Create a key based on rendering properties
      final key = '${item.paint?.hashCode ?? 'null'}_${item.scale}_${item.anchor}';
      groupMap.putIfAbsent(key, () => []);
      groupMap[key]!.add(item);
    }
    
    groups.addAll(groupMap.values);
    return groups;
  }

  /// Render a group of similar items
  void _renderItemGroup(Canvas canvas, List<SpriteBatchItem> items) {
    for (final item in items) {
      _renderSpriteItem(canvas, item);
    }
  }

  /// Render an individual sprite item
  void _renderSpriteItem(Canvas canvas, SpriteBatchItem item) {
    canvas.save();
    
    // Apply transformations
    final anchorOffset = _getAnchorOffset(item.anchor, item.size);
    canvas.translate(
      item.position.x - anchorOffset.x,
      item.position.y - anchorOffset.y,
    );
    
    if (item.rotation != 0) {
      canvas.translate(item.size.x / 2, item.size.y / 2);
      canvas.rotate(item.rotation);
      canvas.translate(-item.size.x / 2, -item.size.y / 2);
    }
    
    if (item.scale != 1.0) {
      canvas.scale(item.scale);
    }
    
    // Render the sprite
    item.sprite.render(
      canvas,
      size: item.size,
      overridePaint: item.paint,
    );
    
    canvas.restore();
  }

  /// Get anchor offset for positioning
  Vector2 _getAnchorOffset(Anchor anchor, Vector2 size) {
    switch (anchor) {
      case Anchor.topLeft:
        return Vector2.zero();
      case Anchor.topCenter:
        return Vector2(size.x / 2, 0);
      case Anchor.topRight:
        return Vector2(size.x, 0);
      case Anchor.centerLeft:
        return Vector2(0, size.y / 2);
      case Anchor.center:
        return Vector2(size.x / 2, size.y / 2);
      case Anchor.centerRight:
        return Vector2(size.x, size.y / 2);
      case Anchor.bottomLeft:
        return Vector2(0, size.y);
      case Anchor.bottomCenter:
        return Vector2(size.x / 2, size.y);
      case Anchor.bottomRight:
        return Vector2(size.x, size.y);
      default:
        return Vector2.zero();
    }
  }

  /// Clear all batches
  void clear() {
    _layerBatches.clear();
    _activeBatches.clear();
  }

  /// Get statistics about current batches
  Map<String, dynamic> getStats() {
    int totalBatches = 0;
    int totalSprites = 0;
    
    for (final layerBatches in _layerBatches.values) {
      totalBatches += layerBatches.length;
      for (final batch in layerBatches) {
        totalSprites += batch.items.length;
      }
    }
    
    return {
      'totalBatches': totalBatches,
      'totalSprites': totalSprites,
      'layerCount': _layerBatches.length,
      'activeBatches': _activeBatches.length,
      'batchingEnabled': enableBatching,
    };
  }

  /// Optimize batches by consolidating similar ones
  void optimizeBatches() {
    for (final layer in _layerBatches.keys) {
      final layerBatches = _layerBatches[layer]!;
      final optimizedBatches = <SpriteBatch>[];
      final imageGroups = <ui.Image, List<SpriteBatch>>{};
      
      // Group batches by image
      for (final batch in layerBatches) {
        imageGroups.putIfAbsent(batch.image, () => []);
        imageGroups[batch.image]!.add(batch);
      }
      
      // Consolidate batches with same image
      for (final entry in imageGroups.entries) {
        final image = entry.key;
        final batches = entry.value;
        
        if (batches.length == 1) {
          optimizedBatches.add(batches.first);
        } else {
          // Merge multiple batches into one
          final allItems = <SpriteBatchItem>[];
          for (final batch in batches) {
            allItems.addAll(batch.items);
          }
          
          optimizedBatches.add(SpriteBatch(
            image: image,
            items: allItems,
          ));
        }
      }
      
      _layerBatches[layer] = optimizedBatches;
    }
  }
}