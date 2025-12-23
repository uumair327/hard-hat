import 'package:flame/components.dart';
import 'package:json_annotation/json_annotation.dart';

class Vector2Converter implements JsonConverter<Vector2, Map<String, dynamic>> {
  const Vector2Converter();

  @override
  Vector2 fromJson(Map<String, dynamic> json) {
    return Vector2(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Vector2 vector) {
    return {
      'x': vector.x,
      'y': vector.y,
    };
  }
}

class Vector2ListConverter implements JsonConverter<List<Vector2>, List<dynamic>> {
  const Vector2ListConverter();

  @override
  List<Vector2> fromJson(List<dynamic> json) {
    return json.map((item) => const Vector2Converter().fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  List<dynamic> toJson(List<Vector2> vectors) {
    return vectors.map((vector) => const Vector2Converter().toJson(vector)).toList();
  }
}