import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:hard_hat/audio/game_audio_manager.dart';

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

  // Cached textures
  static final Map<TileType, ui.Image?> _textureCache = {};
  static bool _texturesLoaded = false;

  /// Pre-load all tile textures (call once at game start)
  static Future<void> loadTextures() async {
    if (_texturesLoaded) return;
    final mapping = {
      TileType.scaffolding: 'sprites/tiles/scaffolding.png',
      TileType.timber: 'sprites/tiles/timber.png',
      TileType.timberOneHit: 'sprites/tiles/timber_one_hit.png',
      TileType.bricks: 'sprites/tiles/bricks.png',
      TileType.bricksOneHit: 'sprites/tiles/bricks_one_hit.png',
      TileType.bricksTwoHit: 'sprites/tiles/bricks_two_hits.png',
      TileType.beam: 'sprites/tiles/beam.png',
      TileType.spike: 'sprites/tiles/spikes.png',
      TileType.ground: 'sprites/tiles/girder.png',
    };
    for (final entry in mapping.entries) {
      try {
        _textureCache[entry.key] = await Flame.images.load(entry.value);
      } catch (e) {
        debugPrint('TileComponent: Failed to load ${entry.value}: $e');
        _textureCache[entry.key] = null;
      }
    }
    _texturesLoaded = true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    // Ensure textures are loaded
    if (!_texturesLoaded) await loadTextures();
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

  // === RENDERING (matching Godot mesh library visual style) ===
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Try texture rendering first
    final texture = _textureCache[_tileType];
    if (texture != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        texture.width.toDouble(),
        texture.height.toDouble(),
      );
      // Use nearest-neighbor for pixel-perfect scaling (Godot uses pixel art)
      final paint = Paint()..filterQuality = FilterQuality.none;
      // Flash white on damage
      if (_isFlashing) {
        paint.colorFilter = const ColorFilter.mode(
          Color(0xBBFFFFFF),
          BlendMode.srcATop,
        );
      }
      canvas.drawImageRect(texture, src, rect, paint);
    } else {
      // Fallback to solid color blocks matching Godot mesh materials
      final paint = Paint()..color = _getColor();
      if (_isFlashing) {
        paint.color = Color.lerp(paint.color, const Color(0xFFFFFFFF), 0.7)!;
      }
      canvas.drawRect(rect, paint);
      _drawDetails(canvas, rect);
    }
    // No outline — Godot tiles render as seamless blocks
  }

  /// Fallback colors extracted from actual Godot mesh library textures
  Color _getColor() {
    switch (_tileType) {
      case TileType.scaffolding:
        // Godot scaffolding.png: steel gray-purple
        return const Color(0xFF8387A3);
      case TileType.timber:
        // Godot timber.png: warm brown
        return const Color(0xFFCD9C62);
      case TileType.timberOneHit:
        // Godot timber_one_hit.png: cracked brown
        return const Color(0xFF9C7040);
      case TileType.bricks:
        // Godot bricks.png: red-brown construction brick
        return const Color(0xFFAB6553);
      case TileType.bricksOneHit:
        // Godot bricks_one_hit.png: damaged red-brown
        return const Color(0xFF8B5040);
      case TileType.bricksTwoHit:
        // Godot bricks_two_hits.png: heavily damaged
        return const Color(0xFF613630);
      case TileType.beam:
        // Godot girder.png: dark navy steel
        return const Color(0xFF2A3055);
      case TileType.spike:
        // Godot spikes_mesh_library: metallic silver-gray
        return const Color(0xFFC0C0C0);
      case TileType.ground:
        // Godot girder.png: same dark navy as beam
        return const Color(0xFF2A3055);
    }
  }

  void _drawDetails(Canvas canvas, Rect rect) {
    // Simplified fallback details for when textures aren't available
    final detailPaint = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.0;

    switch (_tileType) {
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
        break;
      case TileType.spike:
        // Godot spikes: metallic silver triangular spikes
        final spikePaint = Paint()..color = const Color(0xFF909090);
        final basePaint = Paint()..color = const Color(0xFF606060);
        // Base bar
        canvas.drawRect(
          Rect.fromLTWH(0, rect.height * 0.8, rect.width, rect.height * 0.2),
          basePaint,
        );
        // Triangular spikes
        final path = Path();
        for (int i = 0; i < 4; i++) {
          final x = (i + 0.5) * rect.width / 4;
          path.moveTo(x - rect.width / 8, rect.height * 0.8);
          path.lineTo(x, 0);
          path.lineTo(x + rect.width / 8, rect.height * 0.8);
          path.close();
        }
        canvas.drawPath(path, spikePaint);
        break;
      case TileType.beam:
      case TileType.ground:
        // Godot girder: dark navy with subtle cross-bracing detail
        final bracePaint = Paint()
          ..color = const Color(0x22FFFFFF)
          ..strokeWidth = 1.0;
        canvas.drawLine(
          Offset(0, 0),
          Offset(rect.width, rect.height),
          bracePaint,
        );
        canvas.drawLine(
          Offset(rect.width, 0),
          Offset(0, rect.height),
          bracePaint,
        );
        break;
      default:
        break;
    }
  }
}
