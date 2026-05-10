import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:hard_hat/game/hard_hat_game.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';
import 'shutter_component.dart';
import 'tile_component.dart';

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

  // Aim Assist
  double _aimAssistLength = 1280.0;

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
  void Function(Vector2 position, Vector2 normal)?
  onStarParticles; // Godot ball.gd L168

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
    } else {
      // Calculate aim assist raycast length
      final ray = Ray2(origin: position, direction: directionVector);
      final result = game.collisionDetection.raycast(ray, maxDistance: 1280.0);
      if (result != null && result.distance != null) {
        _aimAssistLength = result.distance!;
      } else {
        _aimAssistLength = 1280.0;
      }
    }

    _handleBounds();
  }

  void _handleBounds() {
    // In Godot, the ball bounces off tiles (via move_and_collide), not screen edges.
    // We only kill the ball if it falls way out of the playable area (safety net).
    final gameSize = game.size;
    final camPos = game.camera.viewfinder.position;

    // Kill ball if it goes far outside the visible area (e.g. fell through gap)
    if (position.y > camPos.y + gameSize.y + 200 ||
        position.y < camPos.y - 400 ||
        position.x < camPos.x - 400 ||
        position.x > camPos.x + gameSize.x + 400) {
      kill();
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
      _handleSolidCollision(
        other,
        intersectionPoints,
        isDestructible: other.isDestructible,
        onDamage: () => other.takeDamage(1),
        isBeam: other.tileType == TileType.beam ||
            other.tileType == TileType.ground,
      );
    } else if (other is ShutterComponent) {
      _handleSolidCollision(
        other,
        intersectionPoints,
        isBeam: other.isSliding, // Acts as beam while sliding
      );
    } else if (other is RetractingShutterComponent) {
      _handleSolidCollision(
        other,
        intersectionPoints,
        isBeam: other.isSliding, // Acts as beam while sliding
      );
    }
  }

  void _handleSolidCollision(
    PositionComponent solid,
    Set<Vector2> points, {
    bool isDestructible = false,
    void Function()? onDamage,
    bool isBeam = false,
  }) {
    if (_dead) return;

    // Godot ball.gd L55-59: If hits beam while tracking, force quit aiming
    // and push ball out using collision depth * normal * 100
    if (isBeam && tracking) {
      onForceQuitAiming?.call();
      // Resolve overlap aggressively (Godot uses depth * normal * 100)
      final solidCenter = solid.position + solid.size / 2;
      final diff = position - solidCenter;
      final overlapX = (size.x / 2 + solid.size.x / 2) - diff.x.abs();
      final overlapY = (size.y / 2 + solid.size.y / 2) - diff.y.abs();
      if (overlapX < overlapY) {
        position.x += (diff.x > 0 ? 1 : -1) * (overlapX + 2.0);
      } else {
        position.y += (diff.y > 0 ? 1 : -1) * (overlapY + 2.0);
      }
    }

    if (tracking) return; // Ignore other collisions while tracking

    // Calculate collision normal
    final solidCenter = solid.position + solid.size / 2;
    final ballCenter = position;
    final diff = ballCenter - solidCenter;

    // Determine collision normal and resolve exact overlap
    Vector2 normal;
    final overlapX = (size.x / 2 + solid.size.x / 2) - diff.x.abs();
    final overlapY = (size.y / 2 + solid.size.y / 2) - diff.y.abs();

    if (overlapX < overlapY) {
      normal = Vector2(diff.x > 0 ? 1 : -1, 0);
      position.x += normal.x * overlapX; // Exact horizontal resolution
    } else {
      normal = Vector2(0, diff.y > 0 ? 1 : -1);
      position.y += normal.y * overlapY; // Exact vertical resolution
    }

    // Bounce: velocity = velocity.bounce(normal) equivalent
    velocity = velocity - normal * (2 * velocity.dot(normal));

    _updateSquish();

    if (!_dead) {
      // Camera shake
      onCameraShakeRequest?.call(velocity);

      // Audio
      GameAudioManager.playHit();

      // Handle tile damage
      if (isDestructible) {
        onDamage?.call();
      }
      // Star/impact particles (Godot ball.gd L66)
      if (points.isNotEmpty) {
        onStarParticles?.call(points.first, normal);
      }
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

    // Ball body — Godot: red Color(1, 0.14, 0.14)
    final ballPaint = Paint()
      ..color = tracking
          ? const Color(0xFFFF2424) // Red when tracking (matches Godot)
          : const Color(0xFFCC1E1E); // Darker red when flying

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
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 2.0;

      final lineEnd = Offset(
        center.dx + directionVector.x * _aimAssistLength,
        center.dy + directionVector.y * _aimAssistLength,
      );
      
      // Draw dashed line for better parity with Godot's look (if needed) or solid line
      canvas.drawLine(center, lineEnd, linePaint);

      // Arrow head at collision point
      final arrowPaint = Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 2.0;
      final angle = atan2(directionVector.y, directionVector.x);
      const arrowLen = 10.0;
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
