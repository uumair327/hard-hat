import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:injectable/injectable.dart';
import 'asset_definition.dart';
import 'asset_exceptions.dart';
import 'sprite_atlas.dart';

/// Enhanced asset manager with caching, lazy loading, and sprite atlas support
@lazySingleton
class AssetManager {
  AssetManager({
    Images? images,
  }) : _images = images ?? Images();

  final Images _images;
  final Map<String, SpriteSheet> _spriteSheets = {};
  final Map<String, String> _audioCache = {};
  final Map<String, SpriteAtlas> _spriteAtlases = {};
  final Map<String, AssetDefinition> _assetDefinitions = {};
  final Map<String, Completer<dynamic>> _loadingAssets = {};
  final Set<String> _preloadedAssets = {};

  /// Register asset definitions for the game
  void registerAssetDefinitions(List<AssetDefinition> definitions) {
    for (final definition in definitions) {
      _assetDefinitions[definition.id] = definition;
    }
  }

  /// Load a generic asset by ID with caching and error handling
  Future<T> loadAsset<T>(String assetId) async {
    // Check if already loading to prevent duplicate requests
    if (_loadingAssets.containsKey(assetId)) {
      return await _loadingAssets[assetId]!.future as T;
    }

    final completer = Completer<T>();
    _loadingAssets[assetId] = completer;

    try {
      final result = await _loadAssetInternal<T>(assetId);
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _loadingAssets.remove(assetId);
    }
  }

  /// Internal asset loading with fallback handling
  Future<T> _loadAssetInternal<T>(String assetId) async {
    try {
      final definition = _assetDefinitions[assetId];
      if (definition == null) {
        throw AssetNotFoundException(assetId);
      }

      switch (definition.type) {
        case AssetType.sprite:
          return await _loadSprite(definition) as T;
        case AssetType.spriteAtlas:
          return await _loadSpriteAtlas(definition) as T;
        case AssetType.audio:
          return _getAudioPath(definition) as T;
        case AssetType.data:
          return await _loadDataAsset(definition) as T;
        default:
          throw AssetLoadingException(assetId, 'Unsupported asset type: ${definition.type}');
      }
    } on AssetNotFoundException {
      // Try fallback asset
      return await _getFallbackAsset<T>(assetId);
    } on AssetCorruptedException {
      // Attempt reload once
      return await _reloadAsset<T>(assetId);
    }
  }

  /// Load a sprite with caching
  Future<Sprite> _loadSprite(AssetDefinition definition) async {
    try {
      final image = await _images.load(definition.path);
      return Sprite(image);
    } catch (e) {
      throw AssetCorruptedException(definition.id, e.toString());
    }
  }

  /// Load a sprite atlas with caching
  Future<SpriteAtlas> _loadSpriteAtlas(AssetDefinition definition) async {
    if (_spriteAtlases.containsKey(definition.id)) {
      return _spriteAtlases[definition.id]!;
    }

    try {
      final imagePath = definition.path;
      final dataPath = definition.metadata['dataPath'] as String?;
      
      if (dataPath == null) {
        throw AssetCorruptedException(definition.id, 'Missing dataPath in metadata');
      }

      // Load image and atlas data concurrently
      final futures = await Future.wait([
        _images.load(imagePath),
        _loadAtlasData(dataPath),
      ]);

      final image = futures[0] as ui.Image;
      final atlasData = futures[1] as SpriteAtlasData;

      final atlas = SpriteAtlasFactory.createAtlas(
        atlasId: definition.id,
        image: image,
        atlasData: atlasData,
      );

      _spriteAtlases[definition.id] = atlas;
      return atlas;
    } catch (e) {
      throw AssetCorruptedException(definition.id, e.toString());
    }
  }

  /// Load atlas data from JSON file
  Future<SpriteAtlasData> _loadAtlasData(String dataPath) async {
    try {
      final jsonString = await rootBundle.loadString(dataPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return SpriteAtlasData.fromJson(jsonData);
    } catch (e) {
      throw AssetLoadingException(dataPath, 'Failed to load atlas data: $e');
    }
  }

  /// Load data asset (JSON, etc.)
  Future<Map<String, dynamic>> _loadDataAsset(AssetDefinition definition) async {
    try {
      final jsonString = await rootBundle.loadString(definition.path);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw AssetCorruptedException(definition.id, e.toString());
    }
  }

  /// Get audio path with caching
  String _getAudioPath(AssetDefinition definition) {
    if (_audioCache.containsKey(definition.id)) {
      return _audioCache[definition.id]!;
    }
    
    _audioCache[definition.id] = definition.path;
    return definition.path;
  }

  /// Get fallback asset when primary loading fails
  Future<T> _getFallbackAsset<T>(String assetId) async {
    // For sprites, return a simple colored rectangle
    if (T == Sprite) {
      // Create a simple fallback sprite (this would need a fallback image)
      throw AssetNotFoundException(assetId);
    }
    
    // For other types, throw the original exception
    throw AssetNotFoundException(assetId);
  }

  /// Attempt to reload a corrupted asset
  Future<T> _reloadAsset<T>(String assetId) async {
    // Clear from caches and try loading again
    _images.clearCache();
    _spriteAtlases.remove(assetId);
    _audioCache.remove(assetId);
    
    return await _loadAssetInternal<T>(assetId);
  }

  // Legacy methods for backward compatibility
  
  /// Sprite loading with caching (legacy method)
  Future<Sprite> loadSprite(String path) async {
    final image = await _images.load(path);
    return Sprite(image);
  }

  /// Sprite sheet loading with caching (legacy method)
  Future<SpriteSheet> loadSpriteSheet(String imagePath, Vector2 spriteSize) async {
    if (_spriteSheets.containsKey(imagePath)) {
      return _spriteSheets[imagePath]!;
    }

    final image = await _images.load(imagePath);
    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: spriteSize,
    );
    
    _spriteSheets[imagePath] = spriteSheet;
    return spriteSheet;
  }

  /// Audio path caching (legacy method)
  String getAudioPath(String audioId) {
    return _audioCache[audioId] ?? 'audio/$audioId.mp3';
  }

  // New enhanced methods

  /// Get a sprite from an atlas
  Sprite getSpriteFromAtlas(String atlasId, String spriteId) {
    final atlas = _spriteAtlases[atlasId];
    if (atlas == null) {
      throw SpriteAtlasException(atlasId, 'Atlas not loaded');
    }
    return atlas.getSprite(spriteId);
  }

  /// Get an animation from an atlas
  List<Sprite> getAnimationFromAtlas(String atlasId, String animationId) {
    final atlas = _spriteAtlases[atlasId];
    if (atlas == null) {
      throw SpriteAtlasException(atlasId, 'Atlas not loaded');
    }
    return atlas.getAnimation(animationId);
  }

  /// Preload assets marked for preloading
  Future<void> preloadAssets() async {
    final preloadAssets = _assetDefinitions.values
        .where((def) => def.preload)
        .toList();

    // Load assets in parallel with error handling
    final futures = preloadAssets.map((definition) async {
      try {
        switch (definition.type) {
          case AssetType.sprite:
            await loadAsset<Sprite>(definition.id);
            break;
          case AssetType.spriteAtlas:
            await loadAsset<SpriteAtlas>(definition.id);
            break;
          case AssetType.audio:
            loadAsset<String>(definition.id); // Audio paths are synchronous
            break;
          case AssetType.data:
            await loadAsset<Map<String, dynamic>>(definition.id);
            break;
          default:
            break;
        }
        _preloadedAssets.add(definition.id);
      } catch (e) {
        // Log error but don't fail the entire preload process
        print('Failed to preload asset ${definition.id}: $e');
      }
    });

    await Future.wait(futures);
  }

  /// Preload assets in background (non-blocking)
  void preloadAssetsInBackground() {
    preloadAssets().catchError((e) {
      print('Background preload failed: $e');
    });
  }

  /// Check if an asset is preloaded
  bool isPreloaded(String assetId) => _preloadedAssets.contains(assetId);

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'images': 0, // Images cache is internal to Flame
      'spriteSheets': _spriteSheets.length,
      'spriteAtlases': _spriteAtlases.length,
      'audioCache': _audioCache.length,
      'preloadedAssets': _preloadedAssets.length,
    };
  }

  /// Clear all caches
  void clearCache() {
    _images.clearCache();
    _spriteSheets.clear();
    _spriteAtlases.clear();
    _audioCache.clear();
    _preloadedAssets.clear();
    _loadingAssets.clear();
  }

  /// Clear specific asset from cache
  void clearAssetFromCache(String assetId) {
    final definition = _assetDefinitions[assetId];
    if (definition != null) {
      switch (definition.type) {
        case AssetType.sprite:
          // Images cache is managed internally by Flame
          break;
        case AssetType.spriteAtlas:
          _spriteAtlases.remove(assetId);
          break;
        case AssetType.audio:
          _audioCache.remove(assetId);
          break;
        default:
          break;
      }
    }
    _preloadedAssets.remove(assetId);
  }
}