import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'player_component.dart';
import '../services/game_audio_manager.dart';

/// Spring component — replicates Godot spring.gd
/// Bounce platform that multiplies the player's jump by SPRING_FACTOR.
class SpringComponent extends PositionComponent with CollisionCallbacks {
  // Visual state
  double _squishAmount = 0.0;
  bool _isSquishing = false;
  double _squishTimer = 0.0;
  static const double squishDuration = 0.1;

  SpringComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(40, 24),
        anchor: Anchor.bottomCenter,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(36, 16), position: Vector2(2, 4)));
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      other.setOnSpring(true);
      GameAudioManager.playBoing();
      _startSquish();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is PlayerComponent) {
      other.setOnSpring(false);
      _endSquish();
    }
  }

  void _startSquish() {
    _isSquishing = true;
    _squishTimer = 0.0;
  }

  void _endSquish() {
    _isSquishing = false;
    _squishTimer = 0.0;
    _squishAmount = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isSquishing) {
      _squishTimer += dt;
      final progress = (_squishTimer / squishDuration).clamp(0.0, 1.0);
      _squishAmount =
          0.2 * (1.0 - (progress * 2 - 1).abs()); // Squish then expand
    } else if (_squishAmount > 0) {
      _squishAmount *= 0.85; // Smooth return
      if (_squishAmount < 0.01) _squishAmount = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    final scaleY = 1.0 - _squishAmount;
    final scaleX = 1.0 + _squishAmount * 0.5;

    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-size.x / 2, -size.y);

    // Base plate
    final basePaint = Paint()..color = const Color(0xFF8B4513);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, size.y - 6, size.x - 8, 6),
        const Radius.circular(2),
      ),
      basePaint,
    );

    // Spring coils
    final coilPaint = Paint()
      ..color = const Color(0xFFCD853F)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final y = size.y - 8 - (i * 5);
      final inset = 8.0 + i * 2;
      canvas.drawLine(Offset(inset, y), Offset(size.x - inset, y), coilPaint);
    }

    // Top platform
    final topPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 0, size.x - 4, 8),
        const Radius.circular(3),
      ),
      topPaint,
    );

    // Arrow
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.x / 2, -4),
      Offset(size.x / 2, -14),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.x / 2, -14),
      Offset(size.x / 2 - 4, -10),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.x / 2, -14),
      Offset(size.x / 2 + 4, -10),
      arrowPaint,
    );

    canvas.restore();
  }
}
