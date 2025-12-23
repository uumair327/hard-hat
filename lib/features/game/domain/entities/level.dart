import 'package:equatable/equatable.dart';

class Level extends Equatable {
  final int id;
  final String name;
  final String description;
  final Map<String, dynamic> data;

  const Level({
    required this.id,
    required this.name,
    required this.description,
    required this.data,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      data: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      ...data,
    };
  }

  @override
  List<Object?> get props => [id, name, description, data];
}