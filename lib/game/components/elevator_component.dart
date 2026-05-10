import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide Image;
import 'player_component.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';

/// Elevator component — replicates Godot elevator.gd
/// Rides the player up to the top when they step on it.
class ElevatorComponent extends PositionComponent with CollisionCallbacks {
  // From Godot elevator.gd
  final double targetY;
  final double elevatorSpeed;
  static const double startupAdjustment = 1.25 * 40; // scaled
  static const double startupDuration = 1.0;
  static const double startupDelay = 0.5;

  // State
  bool _activated = false;
  bool _startupDone = false;
  double _timer = 0.0;
  double _startY = 0.0;
  double _adjustedY = 0.0;
  PlayerComponent? _player;

  // Sprite
  Image? _sprite;

  // Callbacks
  void Function()? onStarted;
  void Function()? onReached;

  ElevatorComponent({
    required Vector2 position,
    required this.targetY,
    this.elevatorSpeed = 160.0, // speed=4.0 scaled
    this.onStarted,
    this.onReached,
  }) : super(
         position: position,
         size: Vector2(60, 20),
         anchor: Anchor.topCenter,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    try {
      _sprite = await Flame.images.load('sprites/tiles/elevator.png');
    } catch (_) {}
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent && !_activated) {
      _activate(other);
    }
  }

  void _activate(PlayerComponent player) {
    _activated = true;
    _player = player;
    _startY = position.y;
    _adjustedY = _startY - startupAdjustment;
    _timer = 0.0;
    player.enterElevator();
    onStarted?.call();
    GameAudioManager.playElevator();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_activated) return;

    _timer += dt;

    if (_timer < startupDelay) {
      // Waiting before startup
      return;
    }

    if (!_startupDone) {
      // Startup phase — small jolt upward
      final startupProgress = ((_timer - startupDelay) / startupDuration).clamp(
        0.0,
        1.0,
      );
      // Spring ease
      final easedProgress =
          1.0 - (1.0 - startupProgress) * (1.0 - startupProgress);
      position.y = _startY + (_adjustedY - _startY) * easedProgress;

      if (startupProgress >= 1.0) {
        _startupDone = true;
        GameAudioManager.playElevatorLoop();
      }
    } else {
      // Main ascent
      position.y -= elevatorSpeed * dt;

      if (position.y <= targetY) {
        position.y = targetY;
        onReached?.call();
        _activated = false;
        GameAudioManager.stopElevatorLoop();
      }
    }

    // Move player with elevator
    if (_player != null) {
      _player!.position.y = position.y;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      // Render the actual sprite, scaled to fit component size
      final src = Rect.fromLTWH(
        0, 0,
        _sprite!.width.toDouble(), _sprite!.height.toDouble(),
      );
      final dst = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_sprite!, src, dst, Paint());
    } else {
      // Fallback: programmatic drawing
      final platformPaint = Paint()..color = const Color(0xFF8B7355);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(4),
        ),
        platformPaint,
      );
    }

    // Metal rails
    final railPaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 3.0;
    canvas.drawLine(Offset(4, size.y), Offset(4, size.y + 200), railPaint);
    canvas.drawLine(
      Offset(size.x - 4, size.y),
      Offset(size.x - 4, size.y + 200),
      railPaint,
    );

    // Arrow indicator
    if (!_activated) {
      final arrowPaint = Paint()
        ..color = const Color(0xFF00FF00)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(size.x / 2, -10),
        Offset(size.x / 2, -25),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(size.x / 2, -25),
        Offset(size.x / 2 - 6, -18),
        arrowPaint,
      );
      canvas.drawLine(
        Offset(size.x / 2, -25),
        Offset(size.x / 2 + 6, -18),
        arrowPaint,
      );
    }
  }
}
