import 'package:flame/components.dart';
import 'asset_manager.dart';
import 'sprite_atlas.dart';
import 'asset_exceptions.dart';

/// Integration helper for using sprite atlases with the asset manager
class SpriteAtlasIntegration {
  SpriteAtlasIntegration(this._assetManager);

  final AssetManager _assetManager;

  /// Create a sprite component from an atlas
  Future<SpriteComponent> createSpriteFromAtlas({
    required String atlasId,
    required String spriteId,
    Vector2? size,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
  }) async {
    try {
      final atlas = await _assetManager.loadAsset<SpriteAtlas>(atlasId);
      final sprite = atlas.getSprite(spriteId);
      
      return SpriteComponent(
        sprite: sprite,
        size: size,
        position: position,
        anchor: anchor,
      );
    } catch (e) {
      throw AssetLoadingException(atlasId, 'Failed to create sprite "$spriteId": $e');
    }
  }

  /// Create an animation component from an atlas
  Future<SpriteAnimationComponent> createAnimationFromAtlas({
    required String atlasId,
    required String animationId,
    required double stepTime,
    Vector2? size,
    Vector2? position,
    Anchor anchor = Anchor.topLeft,
    bool loop = true,
  }) async {
    try {
      final atlas = await _assetManager.loadAsset<SpriteAtlas>(atlasId);
      final sprites = atlas.getAnimation(animationId);
      
      final animation = SpriteAnimation.spriteList(
        sprites,
        stepTime: stepTime,
        loop: loop,
      );
      
      return SpriteAnimationComponent(
        animation: animation,
        size: size,
        position: position,
        anchor: anchor,
      );
    } catch (e) {
      throw AssetLoadingException(atlasId, 'Failed to create animation "$animationId": $e');
    }
  }

  /// Get a sprite directly from an atlas (synchronous if atlas is loaded)
  Sprite getSpriteFromAtlas(String atlasId, String spriteId) {
    return _assetManager.getSpriteFromAtlas(atlasId, spriteId);
  }

  /// Get an animation directly from an atlas (synchronous if atlas is loaded)
  List<Sprite> getAnimationFromAtlas(String atlasId, String animationId) {
    return _assetManager.getAnimationFromAtlas(atlasId, animationId);
  }

  /// Create a sprite animation from atlas sprites
  SpriteAnimation createSpriteAnimation({
    required String atlasId,
    required String animationId,
    required double stepTime,
    bool loop = true,
  }) {
    final sprites = getAnimationFromAtlas(atlasId, animationId);
    return SpriteAnimation.spriteList(
      sprites,
      stepTime: stepTime,
      loop: loop,
    );
  }

  /// Create multiple sprites from an atlas at once
  Map<String, Sprite> createMultipleSprites({
    required String atlasId,
    required List<String> spriteIds,
  }) {
    final sprites = <String, Sprite>{};
    
    for (final spriteId in spriteIds) {
      try {
        sprites[spriteId] = getSpriteFromAtlas(atlasId, spriteId);
      } catch (e) {
        // Log error but continue with other sprites
        print('Failed to load sprite "$spriteId" from atlas "$atlasId": $e');
      }
    }
    
    return sprites;
  }

  /// Create multiple animations from an atlas at once
  Map<String, SpriteAnimation> createMultipleAnimations({
    required String atlasId,
    required Map<String, double> animationStepTimes,
    bool loop = true,
  }) {
    final animations = <String, SpriteAnimation>{};
    
    for (final entry in animationStepTimes.entries) {
      final animationId = entry.key;
      final stepTime = entry.value;
      
      try {
        animations[animationId] = createSpriteAnimation(
          atlasId: atlasId,
          animationId: animationId,
          stepTime: stepTime,
          loop: loop,
        );
      } catch (e) {
        // Log error but continue with other animations
        print('Failed to load animation "$animationId" from atlas "$atlasId": $e');
      }
    }
    
    return animations;
  }

  /// Check if an atlas is loaded and available
  bool isAtlasLoaded(String atlasId) {
    try {
      _assetManager.getSpriteFromAtlas(atlasId, ''); // This will throw if atlas not loaded
      return false; // If we get here, the sprite doesn't exist but atlas might
    } catch (e) {
      if (e is SpriteAtlasException && e.message.contains('Atlas not loaded')) {
        return false;
      }
      return true; // Atlas is loaded, just the sprite doesn't exist
    }
  }

  /// Preload specific atlases
  Future<void> preloadAtlases(List<String> atlasIds) async {
    final futures = atlasIds.map((atlasId) async {
      try {
        await _assetManager.loadAsset<SpriteAtlas>(atlasId);
      } catch (e) {
        print('Failed to preload atlas "$atlasId": $e');
      }
    });
    
    await Future.wait(futures);
  }
}