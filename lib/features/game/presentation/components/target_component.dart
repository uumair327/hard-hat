import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'ball_component.dart';

/// Target component — replicates Godot target.gd
/// A spinning target that the ball can hit. Emits 'hit' signal.
class TargetComponent extends PositionComponent with CollisionCallbacks {
  // State
  bool _isHit = false;
  double _spinAngle = 0.0;
  static const double spinSpeed = 3.0; // radians per second

  // Callbacks
  void Function(TargetComponent target)? onHit;

  TargetComponent({required Vector2 position, this.onHit})
    : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 14));
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BallComponent && !_isHit) {
      _onBallHit();
    }
  }

  void _onBallHit() {
    // AudioManager.playSound(SFX_BREAK, position)
    _isHit = true;
    onHit?.call(this);
  }

  /// Reset the target (used by RespawningTarget subclass behavior)
  void reset() {
    _isHit = false;
  }

  bool get isHit => _isHit;

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isHit) {
      _spinAngle += spinSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isHit) return; // Invisible when hit

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_spinAngle);
    canvas.translate(-size.x / 2, -size.y / 2);

    // Target ring (outer)
    final outerPaint = Paint()..color = const Color(0xFFFF4444);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, outerPaint);

    // White ring
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 10, whitePaint);

    // Inner red
    final innerPaint = Paint()..color = const Color(0xFFFF4444);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, innerPaint);

    // Bullseye
    final centerPaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3, centerPaint);

    canvas.restore();
  }
}

/// Respawning Target — extends Target behavior with a respawn timer
/// Replicates Godot respawning_target.gd
class RespawningTargetComponent extends TargetComponent {
  final double respawnTime;
  double _respawnTimer = 0.0;
  bool _waitingRespawn = false;

  RespawningTargetComponent({
    required super.position,
    super.onHit,
    this.respawnTime = 4.0,
  });

  @override
  void _onBallHit() {
    super._onBallHit();
    _waitingRespawn = true;
    _respawnTimer = respawnTime;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_waitingRespawn) {
      _respawnTimer -= dt;
      if (_respawnTimer <= 0) {
        _waitingRespawn = false;
        reset();
      }
    }
  }
}
