import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'tile_component.dart';
import '../game/hard_hat_game_actual.dart';
import '../services/game_audio_manager.dart';

/// Ball component — replicates Godot ball.gd
/// A wrecking ball that bounces off surfaces and destroys tiles.
class BallComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<HardHatGameActual> {
  // === PHYSICS CONSTANTS (from Godot ball.gd) ===
  static const double ballSpeed = 640.0; // speed = 16.0 scaled to pixels
  static const double ballRadius = 10.0;

  // === STATE ===
  bool tracking = false;
  bool _dead = false;
  Vector2 directionVector = Vector2(1, 0);
  Vector2 velocity = Vector2.zero();

  // Visual
  double _squishAngle = 0.0;
  Vector2 _squishScale = Vector2(1, 1);

  // Kill animation
  double _killTimer = 0.0;
  bool _killing = false;

  // Trail particles for flying state
  final List<_BallTrail> _trail = [];
  double _trailTimer = 0.0;
  static const double _trailInterval = 0.03;

  // Idle glow pulse
  double _glowPhase = 0.0;

  // Callbacks
  void Function(Vector2 direction)? onCameraShakeRequest;
  void Function()? onForceQuitAiming;

  BallComponent({
    required Vector2 position,
    this.onCameraShakeRequest,
    this.onForceQuitAiming,
  }) : super(
         position: position,
         size: Vector2(ballRadius * 2, ballRadius * 2),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: ballRadius));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_killing) {
      _killTimer += dt;
      final scaleValue = max(0.01, 1.0 - (_killTimer / 0.5));
      scale = Vector2.all(scaleValue);
      if (_killTimer >= 0.5) {
        removeFromParent();
      }
      return;
    }

    if (_dead) return;

    // Update glow pulse
    _glowPhase += dt * 4.0;

    // Trail particles when flying
    if (!tracking && velocity.length2 > 100) {
      _trailTimer -= dt;
      if (_trailTimer <= 0) {
        _trailTimer = _trailInterval;
        _trail.add(
          _BallTrail(
            pos: position.clone(),
            life: 0.3,
            size: 3.0 + Random().nextDouble() * 3,
          ),
        );
      }
    }
    // Update trail
    for (int i = _trail.length - 1; i >= 0; i--) {
      _trail[i].life -= dt;
      if (_trail[i].life <= 0) {
        _trail.removeAt(i);
      }
    }

    // Move ball
    if (!tracking) {
      position += velocity * dt;
    }

    _handleBounds();
  }

  void _handleBounds() {
    final gameSize = game.size;

    // Bounce off screen edges
    if (position.x - ballRadius < 0) {
      position.x = ballRadius;
      velocity.x = velocity.x.abs();
      _onBounce(Vector2(1, 0));
    }
    if (position.x + ballRadius > gameSize.x) {
      position.x = gameSize.x - ballRadius;
      velocity.x = -velocity.x.abs();
      _onBounce(Vector2(-1, 0));
    }
    if (position.y - ballRadius < 0) {
      position.y = ballRadius;
      velocity.y = velocity.y.abs();
      _onBounce(Vector2(0, 1));
    }
    if (position.y + ballRadius > gameSize.y - 64) {
      position.y = gameSize.y - 64 - ballRadius;
      velocity.y = -velocity.y.abs();
      _onBounce(Vector2(0, -1));
    }
  }

  // === COLLISION HANDLING ===
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is TileComponent) {
      _handleTileCollision(other, intersectionPoints);
    }
  }

  void _handleTileCollision(TileComponent tile, Set<Vector2> points) {
    if (_dead || tracking) return;

    // Calculate collision normal
    final tileCenter = tile.position + tile.size / 2;
    final ballCenter = position;
    final diff = ballCenter - tileCenter;

    // Determine collision normal
    Vector2 normal;
    final absX = diff.x.abs();
    final absY = diff.y.abs();

    if (absX > absY) {
      normal = Vector2(diff.x > 0 ? 1 : -1, 0);
    } else {
      normal = Vector2(0, diff.y > 0 ? 1 : -1);
    }

    // Bounce: velocity = velocity.bounce(normal) equivalent
    velocity = velocity - normal * (2 * velocity.dot(normal));

    // Push ball out of tile
    position += normal * 2;

    _updateSquish();

    if (!_dead) {
      // Camera shake
      onCameraShakeRequest?.call(velocity);

      // Audio
      GameAudioManager.playHit();

      // Handle tile damage
      if (tile.isDestructible) {
        tile.takeDamage(1);
      }

      // Force quit aiming if ball hits beam while tracking
      if (tile.tileType == TileType.beam && tracking) {
        onForceQuitAiming?.call();
      }
    }
  }

  void _onBounce(Vector2 normal) {
    _updateSquish();
    if (!_dead) {
      onCameraShakeRequest?.call(velocity);
    }
  }

  // === BALL ACTIONS (from Godot ball.gd) ===

  void startTracking() {
    tracking = true;
    velocity = Vector2.zero();
    _squishScale = Vector2(1, 1);
    _squishAngle = 0;
  }

  void shoot() {
    GameAudioManager.playStrike();
    velocity = directionVector.normalized() * ballSpeed;
    tracking = false;
    _updateSquish();
  }

  void setDirection(Vector2 dir) {
    directionVector = dir.normalized();
  }

  void kill() {
    if (!_dead) {
      GameAudioManager.playFizzle();
      _dead = true;
      _killing = true;
      _killTimer = 0.0;
    }
  }

  void _updateSquish() {
    if (velocity.length2 > 0) {
      final vel2d = Vector2(velocity.x, velocity.y).normalized();
      _squishAngle = -atan2(vel2d.x, vel2d.y); // angle to up
      _squishScale = Vector2(0.9, 1.1);
    }
  }

  // === RENDERING ===
  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // === TRAIL PARTICLES (active state) ===
    for (final t in _trail) {
      final alpha = (t.life / 0.3).clamp(0.0, 1.0);
      final tp = Paint()..color = Color.fromRGBO(255, 140, 0, alpha * 0.5);
      final relPos = t.pos - position;
      canvas.drawCircle(
        Offset(center.dx + relPos.x, center.dy + relPos.y),
        t.size * alpha,
        tp,
      );
    }

    // === IDLE GLOW (when tracking/aiming) ===
    if (tracking) {
      final glowAlpha = (0.3 + 0.2 * sin(_glowPhase)).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = Color.fromRGBO(255, 107, 53, glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, ballRadius + 4, glowPaint);
    }

    // === SPEED GLOW (when flying fast) ===
    if (!tracking && velocity.length2 > 10000) {
      final speedGlow = Paint()
        ..color = const Color(0x33FF4400)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(center, ballRadius + 2, speedGlow);
    }

    // Ball body
    final ballPaint = Paint()
      ..color = tracking
          ? const Color(0xFFFF6B35) // Orange when tracking
          : const Color(0xFFCD853F); // Brown when flying

    // Apply squish
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_squishAngle);
    canvas.scale(_squishScale.x, _squishScale.y);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawCircle(center, ballRadius, ballPaint);

    // Iron band
    final bandPaint = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, ballRadius - 1, bandPaint);

    // Highlight
    final highlightPaint = Paint()..color = const Color(0x44FFFFFF);
    canvas.drawCircle(
      Offset(center.dx - 2, center.dy - 2),
      ballRadius * 0.4,
      highlightPaint,
    );

    canvas.restore();

    // Aim assist line when tracking
    if (tracking) {
      final linePaint = Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = 2.0;

      final lineEnd = Offset(
        center.dx + directionVector.x * 100,
        center.dy + directionVector.y * 100,
      );
      canvas.drawLine(center, lineEnd, linePaint);

      // Arrow head
      final arrowPaint = Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 2.0;
      final angle = atan2(directionVector.y, directionVector.x);
      final arrowLen = 10.0;
      canvas.drawLine(
        lineEnd,
        Offset(
          lineEnd.dx - arrowLen * cos(angle - 0.4),
          lineEnd.dy - arrowLen * sin(angle - 0.4),
        ),
        arrowPaint,
      );
      canvas.drawLine(
        lineEnd,
        Offset(
          lineEnd.dx - arrowLen * cos(angle + 0.4),
          lineEnd.dy - arrowLen * sin(angle + 0.4),
        ),
        arrowPaint,
      );
    }
  }
}

/// Trail particle data for ball flying state
class _BallTrail {
  final Vector2 pos;
  double life;
  final double size;
  _BallTrail({required this.pos, required this.life, required this.size});
}
