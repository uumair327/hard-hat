import 'package:equatable/equatable.dart';
import 'package:flame/components.dart';
import 'tile.dart';

class Level extends Equatable {
  final int id;
  final String name;
  final String description;
  final Vector2 size;
  final List<TileData> tiles;
  final Vector2 playerSpawn;
  final Vector2 cameraMin;
  final Vector2 cameraMax;
  final List<InteractiveElement> elements;
  final Map<String, dynamic> data;

  const Level({
    required this.id,
    required this.name,
    required this.description,
    required this.size,
    required this.tiles,
    required this.playerSpawn,
    required this.cameraMin,
    required this.cameraMax,
    required this.elements,
    this.data = const {},
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      size: Vector2(
        (json['size']['x'] as num).toDouble(),
        (json['size']['y'] as num).toDouble(),
      ),
      tiles: (json['tiles'] as List? ?? [])
          .map((tileJson) => TileData(
                position: Vector2(
                  (tileJson['position']['x'] as num).toDouble(),
                  (tileJson['position']['y'] as num).toDouble(),
                ),
                type: TileType.values.byName(tileJson['type'] as String),
                durability: tileJson['durability'] as int,
                maxDurability: tileJson['maxDurability'] as int,
                isDestructible: tileJson['isDestructible'] as bool,
              ))
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
          .map((elementJson) => InteractiveElement(
                type: elementJson['type'] as String,
                position: Vector2(
                  (elementJson['position']['x'] as num).toDouble(),
                  (elementJson['position']['y'] as num).toDouble(),
                ),
                properties: elementJson['properties'] as Map<String, dynamic>? ?? {},
              ))
          .toList(),
      data: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'size': {'x': size.x, 'y': size.y},
      'tiles': tiles.map((tile) => {
        'position': {'x': tile.position.x, 'y': tile.position.y},
        'type': tile.type.name,
        'durability': tile.durability,
        'maxDurability': tile.maxDurability,
        'isDestructible': tile.isDestructible,
      }).toList(),
      'playerSpawn': {'x': playerSpawn.x, 'y': playerSpawn.y},
      'cameraMin': {'x': cameraMin.x, 'y': cameraMin.y},
      'cameraMax': {'x': cameraMax.x, 'y': cameraMax.y},
      'elements': elements.map((element) => {
        'type': element.type,
        'position': {'x': element.position.x, 'y': element.position.y},
        'properties': element.properties,
      }).toList(),
      ...data,
    };
  }

  @override
  List<Object?> get props => [
    id, 
    name, 
    description, 
    size, 
    tiles, 
    playerSpawn, 
    cameraMin, 
    cameraMax, 
    elements, 
    data
  ];
}

/// Represents an interactive element in the level
class InteractiveElement extends Equatable {
  final String type;
  final Vector2 position;
  final Map<String, dynamic> properties;

  const InteractiveElement({
    required this.type,
    required this.position,
    required this.properties,
  });

  @override
  List<Object?> get props => [type, position, properties];
}