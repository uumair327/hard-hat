import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../services/game_audio_manager.dart';

/// Tile types matching Godot's GridMap cell items
enum TileType {
  scaffolding, // 0: 1 hit to destroy
  timber, // 1: 2 hits total  (becomes timberOneHit)
  timberOneHit, // 2: 1 hit remaining
  bricks, // 3: 3 hits total  (becomes bricksOneHit)
  bricksOneHit, // 4: 2 hits remaining (becomes bricksTwoHit)
  bricksTwoHit, // 5: 1 hit remaining
  beam, // 6: Indestructible girder
  spike, // Spikes (kills player on contact)
  ground, // Ground platform
}

/// Tile component — a single destructible/indestructible block in the level
class TileComponent extends PositionComponent with CollisionCallbacks {
  TileType _tileType;
  TileType get tileType => _tileType;

  // Grid position (for level data reference)
  final int gridX;
  final int gridY;

  // Destruction callback
  void Function(TileComponent tile)? onDestroyed;

  // Particle callback
  void Function(TileComponent tile, Vector2 position)? onBreakParticles;

  static const double tileSize = 40.0;

  // Visual state
  double _damageFlashTimer = 0.0;
  bool _isFlashing = false;

  TileComponent({
    required TileType type,
    required this.gridX,
    required this.gridY,
    required Vector2 position,
    this.onDestroyed,
    this.onBreakParticles,
  }) : _tileType = type,
       super(position: position, size: Vector2(tileSize, tileSize));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isFlashing) {
      _damageFlashTimer -= dt;
      if (_damageFlashTimer <= 0) {
        _isFlashing = false;
      }
    }
  }

  /// Whether this tile can be destroyed by the ball
  bool get isDestructible {
    return _tileType != TileType.beam &&
        _tileType != TileType.spike &&
        _tileType != TileType.ground;
  }

  /// Apply 1 hit of damage — matches Godot handle_brick_hit exactly
  void takeDamage(int damage) {
    if (!isDestructible) return;

    // Flash effect
    _isFlashing = true;
    _damageFlashTimer = 0.1;

    switch (_tileType) {
      case TileType.scaffolding: // 0 → destroy
        _destroy();
        break;

      case TileType.timber: // 1 → 2 (timber one hit)
        _tileType = TileType.timberOneHit;
        onBreakParticles?.call(this, position + size / 2);
        break;

      case TileType.timberOneHit: // 2 → destroy
        _destroy();
        break;

      case TileType.bricks: // 3 → 4 (bricks one hit)
        _tileType = TileType.bricksOneHit;
        onBreakParticles?.call(this, position + size / 2);
        break;

      case TileType.bricksOneHit: // 4 → 5 (bricks two hits)
        _tileType = TileType.bricksTwoHit;
        onBreakParticles?.call(this, position + size / 2);
        break;

      case TileType.bricksTwoHit: // 5 → destroy
        _destroy();
        break;

      case TileType.beam: // 6 → indestructible
        break;

      case TileType.spike:
      case TileType.ground:
        break;
    }
  }

  void _destroy() {
    GameAudioManager.playBreak();
    onBreakParticles?.call(this, position + size / 2);
    onDestroyed?.call(this);
    removeFromParent();
  }

  // === RENDERING ===
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..color = _getColor();

    // Flash white on damage
    if (_isFlashing) {
      paint.color = Color.lerp(paint.color, const Color(0xFFFFFFFF), 0.7)!;
    }

    canvas.drawRect(rect, paint);

    // Draw tile details
    _drawDetails(canvas, rect);

    // Draw outline
    final outlinePaint = Paint()
      ..color = const Color(0x44000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, outlinePaint);
  }

  Color _getColor() {
    switch (_tileType) {
      case TileType.scaffolding:
        return const Color(0xFFC4A882); // Light wood
      case TileType.timber:
        return const Color(0xFF8B6914); // Dark wood
      case TileType.timberOneHit:
        return const Color(0xFF6B4914); // Damaged wood
      case TileType.bricks:
        return const Color(0xFFB22222); // Red bricks
      case TileType.bricksOneHit:
        return const Color(0xFF8B1A1A); // Cracked bricks
      case TileType.bricksTwoHit:
        return const Color(0xFF5C1010); // Very damaged bricks
      case TileType.beam:
        return const Color(0xFF708090); // Steel gray
      case TileType.spike:
        return const Color(0xFFFF0000); // Red
      case TileType.ground:
        return const Color(0xFF556B2F); // Dark olive green
    }
  }

  void _drawDetails(Canvas canvas, Rect rect) {
    final detailPaint = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.0;

    switch (_tileType) {
      case TileType.scaffolding:
        // Cross-hatch pattern
        canvas.drawLine(
          Offset(0, rect.height / 2),
          Offset(rect.width, rect.height / 2),
          detailPaint,
        );
        canvas.drawLine(
          Offset(rect.width / 2, 0),
          Offset(rect.width / 2, rect.height),
          detailPaint,
        );
        // Diagonal
        canvas.drawLine(
          const Offset(0, 0),
          Offset(rect.width, rect.height),
          detailPaint..strokeWidth = 0.5,
        );
        break;

      case TileType.timber:
      case TileType.timberOneHit:
        // Wood grain
        for (int i = 1; i <= 3; i++) {
          canvas.drawLine(
            Offset(0, i * rect.height / 4),
            Offset(rect.width, i * rect.height / 4),
            detailPaint,
          );
        }
        // Cracks for damaged
        if (_tileType == TileType.timberOneHit) {
          final crackPaint = Paint()
            ..color = const Color(0x66000000)
            ..strokeWidth = 1.5;
          canvas.drawLine(
            Offset(rect.width * 0.3, 0),
            Offset(rect.width * 0.6, rect.height),
            crackPaint,
          );
        }
        break;

      case TileType.bricks:
      case TileType.bricksOneHit:
      case TileType.bricksTwoHit:
        // Brick mortar lines
        canvas.drawLine(
          Offset(0, rect.height / 2),
          Offset(rect.width, rect.height / 2),
          detailPaint,
        );
        canvas.drawLine(
          Offset(rect.width / 2, 0),
          Offset(rect.width / 2, rect.height / 2),
          detailPaint,
        );
        canvas.drawLine(
          Offset(rect.width / 4, rect.height / 2),
          Offset(rect.width / 4, rect.height),
          detailPaint,
        );
        canvas.drawLine(
          Offset(rect.width * 3 / 4, rect.height / 2),
          Offset(rect.width * 3 / 4, rect.height),
          detailPaint,
        );
        // Cracks for damaged
        if (_tileType == TileType.bricksOneHit ||
            _tileType == TileType.bricksTwoHit) {
          final crackPaint = Paint()
            ..color = const Color(0x66000000)
            ..strokeWidth = 1.5;
          canvas.drawLine(
            Offset(rect.width * 0.2, rect.height * 0.1),
            Offset(rect.width * 0.7, rect.height * 0.9),
            crackPaint,
          );
        }
        if (_tileType == TileType.bricksTwoHit) {
          final crackPaint = Paint()
            ..color = const Color(0x88000000)
            ..strokeWidth = 2.0;
          canvas.drawLine(
            Offset(rect.width * 0.8, rect.height * 0.1),
            Offset(rect.width * 0.3, rect.height * 0.8),
            crackPaint,
          );
        }
        break;

      case TileType.beam:
        // Steel I-beam pattern
        final beamPaint = Paint()
          ..color = const Color(0x22000000)
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(0, rect.height * 0.2),
          Offset(rect.width, rect.height * 0.2),
          beamPaint,
        );
        canvas.drawLine(
          Offset(0, rect.height * 0.8),
          Offset(rect.width, rect.height * 0.8),
          beamPaint,
        );
        canvas.drawLine(
          Offset(rect.width / 2, rect.height * 0.2),
          Offset(rect.width / 2, rect.height * 0.8),
          beamPaint,
        );
        break;

      case TileType.spike:
        // Triangle spikes
        final spikePaint = Paint()..color = const Color(0xFFCC0000);
        final path = Path();
        for (int i = 0; i < 3; i++) {
          final x = (i + 0.5) * rect.width / 3;
          path.moveTo(x - rect.width / 6, rect.height);
          path.lineTo(x, 0);
          path.lineTo(x + rect.width / 6, rect.height);
          path.close();
        }
        canvas.drawPath(path, spikePaint);
        break;

      case TileType.ground:
        // Grass on top
        final grassPaint = Paint()..color = const Color(0xFF228B22);
        canvas.drawRect(Rect.fromLTWH(0, 0, rect.width, 4), grassPaint);
        // Some dirt texture dots
        final dotPaint = Paint()..color = const Color(0x22000000);
        canvas.drawCircle(
          Offset(rect.width * 0.3, rect.height * 0.6),
          2,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(rect.width * 0.7, rect.height * 0.4),
          1.5,
          dotPaint,
        );
        canvas.drawCircle(
          Offset(rect.width * 0.5, rect.height * 0.8),
          1,
          dotPaint,
        );
        break;
    }
  }
}
