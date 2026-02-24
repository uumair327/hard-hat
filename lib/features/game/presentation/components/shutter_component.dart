import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// Shutter component — replicates Godot shutter.gd
/// A blocking wall that slides away when its connected target is hit.
class ShutterComponent extends PositionComponent {
  final Vector2 offset; // Direction & distance to slide
  final double duration;

  // State
  bool _activated = false;
  double _slideProgress = 0.0;
  Vector2 _startPosition = Vector2.zero();

  ShutterComponent({
    required Vector2 position,
    required this.offset,
    this.duration = 1.0,
  }) : super(
         position: position,
         size: Vector2(40, 120), // Shutter is tall and thin
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startPosition = position.clone();
  }

  /// Called when the connected target is hit
  void onTargetHit() {
    if (_activated) return;
    _activated = true;
    _slideProgress = 0.0;
    // AudioManager.playSound(SFX_DING, position)
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_activated && _slideProgress < 1.0) {
      _slideProgress = (_slideProgress + dt / duration).clamp(0.0, 1.0);

      // Linear interpolation from start to start+offset
      position.x = _startPosition.x + offset.x * _slideProgress;
      position.y = _startPosition.y + offset.y * _slideProgress;

      if (_slideProgress >= 1.0) {
        // Finished sliding — remove collision
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Shutter body (metal plate)
    final shutterPaint = Paint()..color = const Color(0xFF4A4A4A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), shutterPaint);

    // Horizontal lines (metal ridges)
    final ridgePaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 2.0;
    for (int i = 1; i < 6; i++) {
      final y = i * size.y / 6;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), ridgePaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), borderPaint);

    // Warning stripe
    final stripePaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 6), stripePaint);
    canvas.drawRect(Rect.fromLTWH(0, size.y - 6, size.x, 6), stripePaint);
  }
}

/// Retracting Shutter — replicates Godot retracting_shutter.gd
/// Slides away when target is hit, then slides back after cooldown.
class RetractingShutterComponent extends PositionComponent {
  final Vector2 offset;
  final double duration;
  final double cooldown;

  // State
  bool _opening = false;
  bool _retracting = false;
  double _slideProgress = 0.0;
  double _cooldownTimer = 0.0;
  Vector2 _startPosition = Vector2.zero();

  RetractingShutterComponent({
    required Vector2 position,
    required this.offset,
    this.duration = 1.0,
    this.cooldown = 2.0,
  }) : super(position: position, size: Vector2(40, 120));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startPosition = position.clone();
  }

  /// Called when the connected target is hit
  void onTargetHit() {
    if (_opening || _retracting) return;
    _opening = true;
    _slideProgress = 0.0;
    // AudioManager.playSound(SFX_DING, position)
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_opening) {
      _slideProgress = (_slideProgress + dt / duration).clamp(0.0, 1.0);
      position.x = _startPosition.x + offset.x * _slideProgress;
      position.y = _startPosition.y + offset.y * _slideProgress;

      if (_slideProgress >= 1.0) {
        _opening = false;
        _cooldownTimer = cooldown + duration;
      }
    } else if (_cooldownTimer > 0) {
      _cooldownTimer -= dt;
      if (_cooldownTimer <= 0) {
        _retracting = true;
        _slideProgress = 1.0;
      }
    } else if (_retracting) {
      _slideProgress = (_slideProgress - dt / duration).clamp(0.0, 1.0);
      position.x = _startPosition.x + offset.x * _slideProgress;
      position.y = _startPosition.y + offset.y * _slideProgress;

      if (_slideProgress <= 0) {
        _retracting = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Same as Shutter but with different color
    final shutterPaint = Paint()..color = const Color(0xFF5A3A2A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), shutterPaint);

    final ridgePaint = Paint()
      ..color = const Color(0xFF4A2A1A)
      ..strokeWidth = 2.0;
    for (int i = 1; i < 6; i++) {
      final y = i * size.y / 6;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), ridgePaint);
    }

    final borderPaint = Paint()
      ..color = const Color(0xFF3A1A0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), borderPaint);

    // Retractable indicator (orange stripes)
    final indicatorPaint = Paint()..color = const Color(0xFFFF8C00);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 6), indicatorPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.y - 6, size.x, 6), indicatorPaint);
  }
}
