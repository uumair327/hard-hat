import 'package:flame/extensions.dart';

/// Represents a complete level with all its data
class LevelData {
  final int id;
  final String name;
  final String? description;
  final List<SegmentData> segments;
  final List<TileData> tiles;
  final List<PropData> props;
  final Vector2 size;
  final Vector2 playerSpawn;
  final Vector2 cameraMin;
  final Vector2 cameraMax;

  const LevelData({
    required this.id,
    required this.name,
    this.description,
    required this.segments,
    required this.tiles,
    required this.props,
    required this.size,
    required this.playerSpawn,
    required this.cameraMin,
    required this.cameraMax,
  });

  /// Creates a LevelData instance from JSON
  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => SegmentData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tiles: (json['tiles'] as List<dynamic>?)
              ?.map((e) => TileData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      props: (json['elements'] as List<dynamic>?)
              ?.map((e) => PropData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      size: _parseVector2(json['size']),
      playerSpawn: _parseVector2(json['playerSpawn']),
      cameraMin: _parseVector2(json['cameraMin']),
      cameraMax: _parseVector2(json['cameraMax']),
    );
  }

  /// Helper to parse Vector2 from JSON
  static Vector2 _parseVector2(dynamic json) {
    if (json == null) return Vector2.zero();
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

/// Represents a segment within a level with spawn point and camera bounds
class SegmentData {
  final int id;
  final Vector2 spawnPoint;
  final Vector2 cameraMin;
  final Vector2 cameraMax;
  final List<TriggerData> triggers;

  const SegmentData({
    required this.id,
    required this.spawnPoint,
    required this.cameraMin,
    required this.cameraMax,
    required this.triggers,
  });

  /// Creates a SegmentData instance from JSON
  factory SegmentData.fromJson(Map<String, dynamic> json) {
    final bounds = json['bounds'] as Map<String, dynamic>?;
    final minBounds = bounds?['min'] as Map<String, dynamic>?;
    final maxBounds = bounds?['max'] as Map<String, dynamic>?;

    return SegmentData(
      id: json['id'] as int,
      spawnPoint: _parseVector2(json['spawnPoint']),
      cameraMin: _parseVector2(minBounds),
      cameraMax: _parseVector2(maxBounds),
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => TriggerData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Helper to parse Vector2 from JSON
  static Vector2 _parseVector2(dynamic json) {
    if (json == null) return Vector2.zero();
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

/// Represents a tile in the level
class TileData {
  final Vector2 position;
  final String type;
  final int durability;
  final int maxDurability;
  final bool isDestructible;

  const TileData({
    required this.position,
    required this.type,
    required this.durability,
    required this.maxDurability,
    required this.isDestructible,
  });

  /// Creates a TileData instance from JSON
  factory TileData.fromJson(Map<String, dynamic> json) {
    return TileData(
      position: _parseVector2(json['position']),
      type: json['type'] as String,
      durability: json['durability'] as int,
      maxDurability: json['maxDurability'] as int,
      isDestructible: json['isDestructible'] as bool,
    );
  }

  /// Helper to parse Vector2 from JSON
  static Vector2 _parseVector2(dynamic json) {
    if (json == null) return Vector2.zero();
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

/// Represents an interactive prop/element in the level
class PropData {
  final String type;
  final Vector2 position;
  final Map<String, dynamic> properties;

  const PropData({
    required this.type,
    required this.position,
    required this.properties,
  });

  /// Creates a PropData instance from JSON
  factory PropData.fromJson(Map<String, dynamic> json) {
    return PropData(
      type: json['type'] as String,
      position: _parseVector2(json['position']),
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Helper to parse Vector2 from JSON
  static Vector2 _parseVector2(dynamic json) {
    if (json == null) return Vector2.zero();
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }
}

/// Represents a trigger for segment transitions
class TriggerData {
  final String type;
  final Rect bounds;
  final int? targetSegment;
  final bool killBall;

  const TriggerData({
    required this.type,
    required this.bounds,
    this.targetSegment,
    this.killBall = true,
  });

  /// Creates a TriggerData instance from JSON
  factory TriggerData.fromJson(Map<String, dynamic> json) {
    final boundsJson = json['bounds'] as Map<String, dynamic>?;
    final bounds = boundsJson != null
        ? Rect.fromLTWH(
            (boundsJson['x'] as num).toDouble(),
            (boundsJson['y'] as num).toDouble(),
            (boundsJson['width'] as num).toDouble(),
            (boundsJson['height'] as num).toDouble(),
          )
        : Rect.zero;

    return TriggerData(
      type: json['type'] as String,
      bounds: bounds,
      targetSegment: json['targetSegment'] as int?,
      killBall: json['killBall'] as bool? ?? true,
    );
  }
}
