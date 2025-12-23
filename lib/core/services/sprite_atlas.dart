import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:equatable/equatable.dart';
import 'asset_definition.dart';
import 'asset_exceptions.dart';

/// Manages sprite atlases for optimized rendering
class SpriteAtlas extends Equatable {
  const SpriteAtlas({
    required this.atlasId,
    required this.image,
    required this.sprites,
    this.animations = const {},
  });

  /// Unique identifier for this atlas
  final String atlasId;
  
  /// The loaded atlas image
  final ui.Image image;
  
  /// Map of sprite names to their rectangles
  final Map<String, SpriteRect> sprites;
  
  /// Map of animation names to sprite sequences
  final Map<String, List<String>> animations;

  @override
  List<Object?> get props => [atlasId, image, sprites, animations];

  /// Get a sprite by name from this atlas
  Sprite getSprite(String spriteId) {
    final spriteRect = sprites[spriteId];
    if (spriteRect == null) {
      throw SpriteAtlasException(atlasId, 'Sprite "$spriteId" not found in atlas');
    }

    return Sprite(
      image,
      srcPosition: Vector2(spriteRect.x.toDouble(), spriteRect.y.toDouble()),
      srcSize: Vector2(spriteRect.width.toDouble(), spriteRect.height.toDouble()),
    );
  }

  /// Get an animation sequence by name
  List<Sprite> getAnimation(String animationId) {
    final spriteNames = animations[animationId];
    if (spriteNames == null) {
      throw SpriteAtlasException(atlasId, 'Animation "$animationId" not found in atlas');
    }

    return spriteNames.map((spriteName) => getSprite(spriteName)).toList();
  }

  /// Get all sprite names in this atlas
  List<String> get spriteNames => sprites.keys.toList();

  /// Get all animation names in this atlas
  List<String> get animationNames => animations.keys.toList();

  /// Check if a sprite exists in this atlas
  bool hasSprite(String spriteId) => sprites.containsKey(spriteId);

  /// Check if an animation exists in this atlas
  bool hasAnimation(String animationId) => animations.containsKey(animationId);
}

/// Factory for creating sprite atlases
class SpriteAtlasFactory {
  /// Create a sprite atlas from configuration and loaded data
  static SpriteAtlas createAtlas({
    required String atlasId,
    required ui.Image image,
    required SpriteAtlasData atlasData,
  }) {
    return SpriteAtlas(
      atlasId: atlasId,
      image: image,
      sprites: atlasData.sprites,
      animations: atlasData.animations,
    );
  }

  /// Create a uniform grid atlas (all sprites same size)
  static SpriteAtlas createGridAtlas({
    required String atlasId,
    required ui.Image image,
    required int spriteWidth,
    required int spriteHeight,
    required List<String> spriteNames,
    int margin = 0,
    int spacing = 0,
  }) {
    final sprites = <String, SpriteRect>{};
    
    final cols = (image.width + spacing) ~/ (spriteWidth + spacing);
    
    for (int i = 0; i < spriteNames.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = margin + col * (spriteWidth + spacing);
      final y = margin + row * (spriteHeight + spacing);
      
      sprites[spriteNames[i]] = SpriteRect(
        x: x,
        y: y,
        width: spriteWidth,
        height: spriteHeight,
      );
    }

    return SpriteAtlas(
      atlasId: atlasId,
      image: image,
      sprites: sprites,
    );
  }
}