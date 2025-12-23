import 'package:equatable/equatable.dart';

/// Enum defining different types of assets
enum AssetType {
  sprite,
  audio,
  data,
  font,
  spriteAtlas,
}

/// Definition of an asset with metadata and loading configuration
class AssetDefinition extends Equatable {
  const AssetDefinition({
    required this.id,
    required this.path,
    required this.type,
    this.metadata = const {},
    this.preload = false,
  });

  /// Unique identifier for the asset
  final String id;
  
  /// Path to the asset file
  final String path;
  
  /// Type of the asset
  final AssetType type;
  
  /// Additional metadata for the asset
  final Map<String, dynamic> metadata;
  
  /// Whether this asset should be preloaded
  final bool preload;

  @override
  List<Object?> get props => [id, path, type, metadata, preload];

  /// Create a copy with modified properties
  AssetDefinition copyWith({
    String? id,
    String? path,
    AssetType? type,
    Map<String, dynamic>? metadata,
    bool? preload,
  }) {
    return AssetDefinition(
      id: id ?? this.id,
      path: path ?? this.path,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      preload: preload ?? this.preload,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'type': type.name,
      'metadata': metadata,
      'preload': preload,
    };
  }

  /// Create from JSON
  static AssetDefinition fromJson(Map<String, dynamic> json) {
    return AssetDefinition(
      id: json['id'] as String,
      path: json['path'] as String,
      type: AssetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AssetType.sprite,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      preload: json['preload'] as bool? ?? false,
    );
  }
}

/// Configuration for sprite atlas
class SpriteAtlasConfig extends Equatable {
  const SpriteAtlasConfig({
    required this.atlasId,
    required this.imagePath,
    required this.dataPath,
    this.spriteSize,
    this.margin = 0,
    this.spacing = 0,
  });

  /// Unique identifier for the atlas
  final String atlasId;
  
  /// Path to the atlas image
  final String imagePath;
  
  /// Path to the atlas data file (JSON)
  final String dataPath;
  
  /// Size of individual sprites (if uniform)
  final (int width, int height)? spriteSize;
  
  /// Margin around sprites
  final int margin;
  
  /// Spacing between sprites
  final int spacing;

  @override
  List<Object?> get props => [atlasId, imagePath, dataPath, spriteSize, margin, spacing];
}

/// Data structure for sprite atlas information
class SpriteAtlasData extends Equatable {
  const SpriteAtlasData({
    required this.sprites,
    this.animations = const {},
  });

  /// Map of sprite names to their rectangles in the atlas
  final Map<String, SpriteRect> sprites;
  
  /// Map of animation names to sprite sequences
  final Map<String, List<String>> animations;

  @override
  List<Object?> get props => [sprites, animations];

  /// Convert from JSON
  static SpriteAtlasData fromJson(Map<String, dynamic> json) {
    final spritesJson = json['sprites'] as Map<String, dynamic>? ?? {};
    final sprites = <String, SpriteRect>{};
    
    for (final entry in spritesJson.entries) {
      sprites[entry.key] = SpriteRect.fromJson(entry.value as Map<String, dynamic>);
    }

    final animationsJson = json['animations'] as Map<String, dynamic>? ?? {};
    final animations = <String, List<String>>{};
    
    for (final entry in animationsJson.entries) {
      animations[entry.key] = List<String>.from(entry.value as List);
    }

    return SpriteAtlasData(
      sprites: sprites,
      animations: animations,
    );
  }
}

/// Rectangle definition for a sprite in an atlas
class SpriteRect extends Equatable {
  const SpriteRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  List<Object?> get props => [x, y, width, height];

  /// Convert from JSON
  static SpriteRect fromJson(Map<String, dynamic> json) {
    return SpriteRect(
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}