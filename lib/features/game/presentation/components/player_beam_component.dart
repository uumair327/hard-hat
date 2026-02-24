import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'player_component.dart';

/// PlayerBeam component — replicates Godot player_beam.gd
/// A moving platform that follows the player when they're on the ground.
class PlayerBeamComponent extends PositionComponent with CollisionCallbacks {
  PlayerComponent? _player;
  static const double beamSpeed = 80.0; // velocity.x = 2.0 scaled

  PlayerBeamComponent({required Vector2 position})
    : super(position: position, size: Vector2(80, 16));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      _player = other;
      // AudioManager.playSound(SFX_DING, position)
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is PlayerComponent) {
      _player = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move beam when player is standing on it and on the ground (not aiming)
    if (_player != null &&
        _player!.state != PlayerState.aim &&
        _player!.velocity.y >= 0) {
      // On floor proxy
      position.x += beamSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Metal beam
    final beamPaint = Paint()..color = const Color(0xFF708090);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(2),
      ),
      beamPaint,
    );

    // Rivets
    final rivetPaint = Paint()..color = const Color(0xFF555555);
    for (int i = 0; i < 4; i++) {
      final x = 10.0 + i * (size.x - 20) / 3;
      canvas.drawCircle(Offset(x, size.y / 2), 3, rivetPaint);
    }

    // I-beam flanges
    final flangePaint = Paint()
      ..color = const Color(0xFF606060)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, 2), Offset(size.x, 2), flangePaint);
    canvas.drawLine(
      Offset(0, size.y - 2),
      Offset(size.x, size.y - 2),
      flangePaint,
    );
  }
}
