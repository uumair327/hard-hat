import 'package:flame/components.dart';

import '../../domain/entities/level.dart';
import '../../domain/entities/tile.dart';

class LevelModel extends Level {
  const LevelModel({
    required super.id,
    required super.name,
    required super.size,
    required super.tiles,
    required super.playerSpawn,
    required super.cameraMin,
    required super.cameraMax,
    required super.elements,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as int,
      name: json['name'] as String,
      size: Vector2(
        (json['size']['x'] as num).toDouble(),
        (json['size']['y'] as num).toDouble(),
      ),
      tiles: (json['tiles'] as List)
          .map((tileJson) => TileModel.fromJson(tileJson))
          .cast<TileData>()
          .toList(),
      playerSpawn: Vector2(
        (json['playerSpawn']['x'] as num).toDouble(),
        (json['playerSpawn']['y'] as num).toDouble(),
      ),
      cameraMin: Vector2(
        (json['cameraMin']['x'] as num).toDouble(),
        (json['cameraMin']['y'] as num).toDouble(),
      ),
      cameraMax: Vector2(
        (json['cameraMax']['x'] as num).toDouble(),
        (json['cameraMax']['y'] as num).toDouble(),
      ),
      elements: (json['elements'] as List? ?? [])
          .map((elementJson) => InteractiveElementModel.fromJson(elementJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': {'x': size.x, 'y': size.y},
      'tiles': tiles.map((tile) => TileModel.fromTileData(tile).toJson()).toList(),
      'playerSpawn': {'x': playerSpawn.x, 'y': playerSpawn.y},
      'cameraMin': {'x': cameraMin.x, 'y': cameraMin.y},
      'cameraMax': {'x': cameraMax.x, 'y': cameraMax.y},
      'elements': elements.map((element) => InteractiveElementModel.fromEntity(element).toJson()).toList(),
    };
  }

  factory LevelModel.fromEntity(Level level) {
    return LevelModel(
      id: level.id,
      name: level.name,
      size: level.size,
      tiles: level.tiles,
      playerSpawn: level.playerSpawn,
      cameraMin: level.cameraMin,
      cameraMax: level.cameraMax,
      elements: level.elements,
    );
  }
}

class TileModel extends TileData {
  const TileModel({
    required super.position,
    required super.type,
    required super.durability,
    required super.maxDurability,
    required super.isDestructible,
  });

  factory TileModel.fromJson(Map<String, dynamic> json) {
    return TileModel(
      position: Vector2(
        (json['position']['x'] as num).toDouble(),
        (json['position']['y'] as num).toDouble(),
      ),
      type: TileType.values.byName(json['type'] as String),
      durability: json['durability'] as int,
      maxDurability: json['maxDurability'] as int,
      isDestructible: json['isDestructible'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': {'x': position.x, 'y': position.y},
      'type': type.name,
      'durability': durability,
      'maxDurability': maxDurability,
      'isDestructible': isDestructible,
    };
  }

  factory TileModel.fromTileData(TileData tile) {
    return TileModel(
      position: tile.position,
      type: tile.type,
      durability: tile.durability,
      maxDurability: tile.maxDurability,
      isDestructible: tile.isDestructible,
    );
  }
}

class InteractiveElementModel extends InteractiveElement {
  const InteractiveElementModel({
    required super.type,
    required super.position,
    required super.properties,
  });

  factory InteractiveElementModel.fromJson(Map<String, dynamic> json) {
    return InteractiveElementModel(
      type: json['type'] as String,
      position: Vector2(
        (json['position']['x'] as num).toDouble(),
        (json['position']['y'] as num).toDouble(),
      ),
      properties: json['properties'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'position': {'x': position.x, 'y': position.y},
      'properties': properties,
    };
  }

  factory InteractiveElementModel.fromEntity(InteractiveElement element) {
    return InteractiveElementModel(
      type: element.type,
      position: element.position,
      properties: element.properties,
    );
  }
}