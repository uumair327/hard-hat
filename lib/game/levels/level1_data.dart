import 'package:flame/components.dart';
import 'package:hard_hat/game/components/tile_component.dart';

/// Level data decoded from Godot GridMap files.
/// Coordinates are in Godot grid units (cell_size = 1x1).
/// Godot Y-up → Flutter Y-down conversion: flutter_y = -godot_y
///
/// In Godot Level 1:
///   Floor (bottom girder row): godot_y = -7  → grid_y = 7
///   Ceiling (top girder row):  godot_y = 6   → grid_y = -6
///   Player spawn seg0:         godot (-9, -1) → grid (−9, 1)
///   Level X range:             -12 to 83
///   Level Y range:             -11 to 9 (Godot) → -9 to 11 (grid)

/// Raw tile: (TileType, godot_x, godot_y)
class GodotTile {
  final TileType type;
  final int gx; // Godot X
  final int gy; // Godot Y (Y-up)
  const GodotTile(this.type, this.gx, this.gy);
}

/// Segment info from Godot scene files
class GodotSegment {
  final double originX; // Segment origin X in Godot world
  final double spawnX; // Spawn X (local to segment)
  final double spawnY; // Spawn Y (local)
  final bool killBall;
  const GodotSegment({
    required this.originX,
    required this.spawnX,
    required this.spawnY,
    this.killBall = false,
  });

  /// Absolute spawn position in Godot coords
  double get absSpawnX => originX + spawnX;
  double get absSpawnY => spawnY; // Y is global in segments
}

/// Convert Godot level data into world-space tile positions.
/// [groundScreenY] is the Y position of the ground in Flutter screen coords.
/// Returns (tiles, segments with world positions, groundY, totalWidth).
class LevelLayout {
  final List<TileInfo> tiles;
  final List<SegmentInfo> segments;
  final double groundY;
  final double totalWidth;
  final List<PropInfo> props;

  LevelLayout({
    required this.tiles,
    required this.segments,
    required this.groundY,
    required this.totalWidth,
    this.props = const [],
  });
}

class TileInfo {
  final TileType type;
  final int gridX;
  final int gridY;
  final double worldX;
  final double worldY;
  TileInfo(this.type, this.gridX, this.gridY, this.worldX, this.worldY);
}

class SegmentInfo {
  final Vector2 spawnPoint;
  final double cameraMinX;
  final double cameraMaxX;
  final double triggerX;
  final bool killBall;
  SegmentInfo({
    required this.spawnPoint,
    required this.cameraMinX,
    required this.cameraMaxX,
    required this.triggerX,
    this.killBall = false,
  });
}

class PropInfo {
  final String type; // 'elevator', 'spring', etc.
  final double worldX;
  final double worldY;
  PropInfo(this.type, this.worldX, this.worldY);
}

/// Build Level 1 layout from decoded Godot data.
/// The Godot level floor is at godot_y = -7.
/// We map it so the floor is at [screenGroundY].
LevelLayout buildGodotLevel1(double screenHeight) {
  const ts = TileComponent.tileSize; // 40.0

  // Godot floor row is at godot_y = -7 → grid_y = 7
  // We want the floor at the bottom of the visible area
  // World Y = (grid_y + yOffset) * ts
  // For floor: (7 + yOffset) * ts = screenGroundY
  // screenGroundY = screenHeight - ts
  final screenGroundY = screenHeight - ts;
  final yOffset = screenGroundY / ts - 7;

  // X offset: Godot level starts at x=-12, add 13 for some left padding
  const xOffset = 13.0;

  double worldX(double gx) => (gx + xOffset) * ts;
  double worldY(double gy) => (-gy + yOffset) * ts;

  final tiles = <TileInfo>[];

  // === GODOT GRIDMAP TILES (decoded from 1.tscn) ===
  // Helper to add tiles compactly
  void t(TileType type, int gx, int gy) {
    final wx = worldX(gx.toDouble());
    final wy = worldY(gy.toDouble());
    final fgx = (wx / ts).floor();
    final fgy = (wy / ts).floor();
    tiles.add(TileInfo(type, fgx, fgy, wx, wy));
  }

  // Generated Godot Tiles
// === LEVEL 1 TILE DATA (from Godot GridMap) ===
// Godot coord system: Y-up. Tile at godot(x, y)
// Flutter coord system: Y-down. We use: flutter_y = -godot_y
// Godot cell_size = 1x1, scale to tileSize (40px)

// Total tiles: 685

// girder: 370 tiles
  t(TileType.beam, -12, 6);
  t(TileType.beam, -11, 6);
  t(TileType.beam, -10, 6);
  t(TileType.beam, -9, 6);
  t(TileType.beam, -8, 6);
  t(TileType.beam, -7, 6);
  t(TileType.beam, -6, 6);
  t(TileType.beam, -5, 6);
  t(TileType.beam, -4, 6);
  t(TileType.beam, -3, 6);
  t(TileType.beam, -2, 6);
  t(TileType.beam, -1, 6);
  t(TileType.beam, 0, 6);
  t(TileType.beam, 1, 6);
  t(TileType.beam, 2, 6);
  t(TileType.beam, 3, 6);
  t(TileType.beam, 4, 6);
  t(TileType.beam, 5, 6);
  t(TileType.beam, 6, 6);
  t(TileType.beam, 7, 6);
  t(TileType.beam, 8, 6);
  t(TileType.beam, 9, 6);
  t(TileType.beam, 10, 6);
  t(TileType.beam, 11, 6);
  t(TileType.beam, 12, 6);
  t(TileType.beam, 13, 6);
  t(TileType.beam, 14, 6);
  t(TileType.beam, 15, 6);
  t(TileType.beam, 16, 6);
  t(TileType.beam, 17, 6);
  t(TileType.beam, 18, 6);
  t(TileType.beam, 19, 6);
  t(TileType.beam, 20, 6);
  t(TileType.beam, 21, 6);
  t(TileType.beam, 22, 6);
  t(TileType.beam, 23, 6);
  t(TileType.beam, 24, 6);
  t(TileType.beam, 25, 6);
  t(TileType.beam, 26, 6);
  t(TileType.beam, 27, 6);
  t(TileType.beam, 28, 6);
  t(TileType.beam, 29, 6);
  t(TileType.beam, 30, 6);
  t(TileType.beam, 31, 6);
  t(TileType.beam, 32, 6);
  t(TileType.beam, 33, 6);
  t(TileType.beam, 34, 6);
  t(TileType.beam, 35, 6);
  t(TileType.beam, 36, 6);
  t(TileType.beam, 37, 6);
  t(TileType.beam, 38, 6);
  t(TileType.beam, 39, 6);
  t(TileType.beam, 40, 6);
  t(TileType.beam, 41, 6);
  t(TileType.beam, 42, 6);
  t(TileType.beam, 43, 6);
  t(TileType.beam, 44, 6);
  t(TileType.beam, 45, 6);
  t(TileType.beam, 46, 6);
  t(TileType.beam, 47, 6);
  t(TileType.beam, 48, 6);
  t(TileType.beam, 49, 6);
  t(TileType.beam, 50, 6);
  t(TileType.beam, 51, 6);
  t(TileType.beam, 52, 6);
  t(TileType.beam, 53, 6);
  t(TileType.beam, 54, 6);
  t(TileType.beam, 55, 6);
  t(TileType.beam, 56, 6);
  t(TileType.beam, 57, 6);
  t(TileType.beam, 58, 6);
  t(TileType.beam, 59, 6);
  t(TileType.beam, 60, 6);
  t(TileType.beam, 61, 6);
  t(TileType.beam, 62, 6);
  t(TileType.beam, 63, 6);
  t(TileType.beam, 64, 6);
  t(TileType.beam, 65, 6);
  t(TileType.beam, 66, 6);
  t(TileType.beam, 67, 6);
  t(TileType.beam, 68, 6);
  t(TileType.beam, 69, 6);
  t(TileType.beam, 70, 6);
  t(TileType.beam, 71, 6);
  t(TileType.beam, 72, 6);
  t(TileType.beam, 73, 6);
  t(TileType.beam, 74, 6);
  t(TileType.beam, 75, 6);
  t(TileType.beam, 76, 6);
  t(TileType.beam, 77, 6);
  t(TileType.beam, 78, 6);
  t(TileType.beam, 79, 6);
  t(TileType.beam, 80, 6);
  t(TileType.beam, 81, 6);
  t(TileType.beam, 82, 6);
  t(TileType.beam, 83, 6);
  t(TileType.beam, -12, 5);
  t(TileType.beam, -2, 5);
  t(TileType.beam, 11, 5);
  t(TileType.beam, 25, 5);
  t(TileType.beam, 30, 5);
  t(TileType.beam, 35, 5);
  t(TileType.beam, 83, 5);
  t(TileType.beam, -12, 4);
  t(TileType.beam, -2, 4);
  t(TileType.beam, -1, 4);
  t(TileType.beam, 11, 4);
  t(TileType.beam, 25, 4);
  t(TileType.beam, 30, 4);
  t(TileType.beam, 35, 4);
  t(TileType.beam, 77, 4);
  t(TileType.beam, 78, 4);
  t(TileType.beam, 83, 4);
  t(TileType.beam, -12, 3);
  t(TileType.beam, -2, 3);
  t(TileType.beam, 11, 3);
  t(TileType.beam, 25, 3);
  t(TileType.beam, 30, 3);
  t(TileType.beam, 35, 3);
  t(TileType.beam, 83, 3);
  t(TileType.beam, -12, 2);
  t(TileType.beam, -11, 2);
  t(TileType.beam, -10, 2);
  t(TileType.beam, -9, 2);
  t(TileType.beam, -8, 2);
  t(TileType.beam, -7, 2);
  t(TileType.beam, -6, 2);
  t(TileType.beam, -5, 2);
  t(TileType.beam, -4, 2);
  t(TileType.beam, -3, 2);
  t(TileType.beam, -2, 2);
  t(TileType.beam, 2, 2);
  t(TileType.beam, 3, 2);
  t(TileType.beam, 4, 2);
  t(TileType.beam, 9, 2);
  t(TileType.beam, 10, 2);
  t(TileType.beam, 11, 2);
  t(TileType.beam, 12, 2);
  t(TileType.beam, 13, 2);
  t(TileType.beam, 14, 2);
  t(TileType.beam, 15, 2);
  t(TileType.beam, 16, 2);
  t(TileType.beam, 17, 2);
  t(TileType.beam, 18, 2);
  t(TileType.beam, 19, 2);
  t(TileType.beam, 20, 2);
  t(TileType.beam, 21, 2);
  t(TileType.beam, 22, 2);
  t(TileType.beam, 23, 2);
  t(TileType.beam, 24, 2);
  t(TileType.beam, 25, 2);
  t(TileType.beam, 30, 2);
  t(TileType.beam, 35, 2);
  t(TileType.beam, 39, 2);
  t(TileType.beam, 40, 2);
  t(TileType.beam, 41, 2);
  t(TileType.beam, 42, 2);
  t(TileType.beam, 43, 2);
  t(TileType.beam, 44, 2);
  t(TileType.beam, 45, 2);
  t(TileType.beam, 46, 2);
  t(TileType.beam, 47, 2);
  t(TileType.beam, 48, 2);
  t(TileType.beam, 49, 2);
  t(TileType.beam, 50, 2);
  t(TileType.beam, 51, 2);
  t(TileType.beam, 52, 2);
  t(TileType.beam, 53, 2);
  t(TileType.beam, 54, 2);
  t(TileType.beam, 55, 2);
  t(TileType.beam, 56, 2);
  t(TileType.beam, 57, 2);
  t(TileType.beam, 58, 2);
  t(TileType.beam, 59, 2);
  t(TileType.beam, 60, 2);
  t(TileType.beam, 61, 2);
  t(TileType.beam, 62, 2);
  t(TileType.beam, 63, 2);
  t(TileType.beam, 64, 2);
  t(TileType.beam, 65, 2);
  t(TileType.beam, 66, 2);
  t(TileType.beam, 67, 2);
  t(TileType.beam, 68, 2);
  t(TileType.beam, 69, 2);
  t(TileType.beam, 70, 2);
  t(TileType.beam, 71, 2);
  t(TileType.beam, 72, 2);
  t(TileType.beam, 73, 2);
  t(TileType.beam, 74, 2);
  t(TileType.beam, 83, 2);
  t(TileType.beam, -12, 1);
  t(TileType.beam, 25, 1);
  t(TileType.beam, 30, 1);
  t(TileType.beam, 35, 1);
  t(TileType.beam, 59, 1);
  t(TileType.beam, 83, 1);
  t(TileType.beam, -12, 0);
  t(TileType.beam, 25, 0);
  t(TileType.beam, 26, 0);
  t(TileType.beam, 27, 0);
  t(TileType.beam, 28, 0);
  t(TileType.beam, 29, 0);
  t(TileType.beam, 30, 0);
  t(TileType.beam, 35, 0);
  t(TileType.beam, 59, 0);
  t(TileType.beam, 60, 0);
  t(TileType.beam, 61, 0);
  t(TileType.beam, 83, 0);
  t(TileType.beam, -12, -1);
  t(TileType.beam, 30, -1);
  t(TileType.beam, 35, -1);
  t(TileType.beam, 59, -1);
  t(TileType.beam, 83, -1);
  t(TileType.beam, -12, -2);
  t(TileType.beam, 11, -2);
  t(TileType.beam, 30, -2);
  t(TileType.beam, 31, -2);
  t(TileType.beam, 32, -2);
  t(TileType.beam, 33, -2);
  t(TileType.beam, 34, -2);
  t(TileType.beam, 35, -2);
  t(TileType.beam, 36, -2);
  t(TileType.beam, 37, -2);
  t(TileType.beam, 38, -2);
  t(TileType.beam, 39, -2);
  t(TileType.beam, 40, -2);
  t(TileType.beam, 41, -2);
  t(TileType.beam, 42, -2);
  t(TileType.beam, 43, -2);
  t(TileType.beam, 44, -2);
  t(TileType.beam, 45, -2);
  t(TileType.beam, 46, -2);
  t(TileType.beam, 47, -2);
  t(TileType.beam, 48, -2);
  t(TileType.beam, 49, -2);
  t(TileType.beam, 50, -2);
  t(TileType.beam, 51, -2);
  t(TileType.beam, 52, -2);
  t(TileType.beam, 53, -2);
  t(TileType.beam, 54, -2);
  t(TileType.beam, 55, -2);
  t(TileType.beam, 59, -2);
  t(TileType.beam, 66, -2);
  t(TileType.beam, 67, -2);
  t(TileType.beam, 68, -2);
  t(TileType.beam, 69, -2);
  t(TileType.beam, 73, -2);
  t(TileType.beam, 74, -2);
  t(TileType.beam, 75, -2);
  t(TileType.beam, 76, -2);
  t(TileType.beam, 77, -2);
  t(TileType.beam, 78, -2);
  t(TileType.beam, 79, -2);
  t(TileType.beam, 80, -2);
  t(TileType.beam, 81, -2);
  t(TileType.beam, 82, -2);
  t(TileType.beam, 83, -2);
  t(TileType.beam, -12, -3);
  t(TileType.beam, 11, -3);
  t(TileType.beam, 59, -3);
  t(TileType.beam, 83, -3);
  t(TileType.beam, -12, -4);
  t(TileType.beam, 11, -4);
  t(TileType.beam, 59, -4);
  t(TileType.beam, 83, -4);
  t(TileType.beam, -12, -5);
  t(TileType.beam, 11, -5);
  t(TileType.beam, 59, -5);
  t(TileType.beam, 83, -5);
  t(TileType.beam, -12, -6);
  t(TileType.beam, 11, -6);
  t(TileType.beam, 35, -6);
  t(TileType.beam, 59, -6);
  t(TileType.beam, 83, -6);
  t(TileType.beam, -12, -7);
  t(TileType.beam, -11, -7);
  t(TileType.beam, -10, -7);
  t(TileType.beam, -9, -7);
  t(TileType.beam, -8, -7);
  t(TileType.beam, -7, -7);
  t(TileType.beam, -6, -7);
  t(TileType.beam, -5, -7);
  t(TileType.beam, -4, -7);
  t(TileType.beam, -3, -7);
  t(TileType.beam, -2, -7);
  t(TileType.beam, -1, -7);
  t(TileType.beam, 0, -7);
  t(TileType.beam, 1, -7);
  t(TileType.beam, 2, -7);
  t(TileType.beam, 3, -7);
  t(TileType.beam, 4, -7);
  t(TileType.beam, 5, -7);
  t(TileType.beam, 6, -7);
  t(TileType.beam, 7, -7);
  t(TileType.beam, 8, -7);
  t(TileType.beam, 9, -7);
  t(TileType.beam, 10, -7);
  t(TileType.beam, 11, -7);
  t(TileType.beam, 12, -7);
  t(TileType.beam, 13, -7);
  t(TileType.beam, 14, -7);
  t(TileType.beam, 15, -7);
  t(TileType.beam, 16, -7);
  t(TileType.beam, 17, -7);
  t(TileType.beam, 18, -7);
  t(TileType.beam, 19, -7);
  t(TileType.beam, 20, -7);
  t(TileType.beam, 21, -7);
  t(TileType.beam, 22, -7);
  t(TileType.beam, 23, -7);
  t(TileType.beam, 24, -7);
  t(TileType.beam, 25, -7);
  t(TileType.beam, 26, -7);
  t(TileType.beam, 27, -7);
  t(TileType.beam, 28, -7);
  t(TileType.beam, 29, -7);
  t(TileType.beam, 30, -7);
  t(TileType.beam, 31, -7);
  t(TileType.beam, 32, -7);
  t(TileType.beam, 33, -7);
  t(TileType.beam, 34, -7);
  t(TileType.beam, 35, -7);
  t(TileType.beam, 36, -7);
  t(TileType.beam, 37, -7);
  t(TileType.beam, 38, -7);
  t(TileType.beam, 39, -7);
  t(TileType.beam, 40, -7);
  t(TileType.beam, 41, -7);
  t(TileType.beam, 42, -7);
  t(TileType.beam, 43, -7);
  t(TileType.beam, 44, -7);
  t(TileType.beam, 45, -7);
  t(TileType.beam, 46, -7);
  t(TileType.beam, 47, -7);
  t(TileType.beam, 48, -7);
  t(TileType.beam, 49, -7);
  t(TileType.beam, 50, -7);
  t(TileType.beam, 51, -7);
  t(TileType.beam, 52, -7);
  t(TileType.beam, 53, -7);
  t(TileType.beam, 54, -7);
  t(TileType.beam, 55, -7);
  t(TileType.beam, 56, -7);
  t(TileType.beam, 57, -7);
  t(TileType.beam, 58, -7);
  t(TileType.beam, 59, -7);
  t(TileType.beam, 60, -7);
  t(TileType.beam, 61, -7);
  t(TileType.beam, 62, -7);
  t(TileType.beam, 63, -7);
  t(TileType.beam, 64, -7);
  t(TileType.beam, 65, -7);
  t(TileType.beam, 66, -7);
  t(TileType.beam, 67, -7);
  t(TileType.beam, 68, -7);
  t(TileType.beam, 69, -7);
  t(TileType.beam, 70, -7);
  t(TileType.beam, 71, -7);
  t(TileType.beam, 72, -7);
  t(TileType.beam, 73, -7);
  t(TileType.beam, 74, -7);
  t(TileType.beam, 75, -7);
  t(TileType.beam, 76, -7);
  t(TileType.beam, 77, -7);
  t(TileType.beam, 78, -7);
  t(TileType.beam, 79, -7);
  t(TileType.beam, 80, -7);
  t(TileType.beam, 81, -7);
  t(TileType.beam, 82, -7);
  t(TileType.beam, 83, -7);
// scaffolding: 157 tiles
  t(TileType.scaffolding, -10, 5);
  t(TileType.scaffolding, -8, 5);
  t(TileType.scaffolding, -6, 5);
  t(TileType.scaffolding, -4, 5);
  t(TileType.scaffolding, 73, 5);
  t(TileType.scaffolding, 81, 5);
  t(TileType.scaffolding, -10, 4);
  t(TileType.scaffolding, -8, 4);
  t(TileType.scaffolding, -6, 4);
  t(TileType.scaffolding, -4, 4);
  t(TileType.scaffolding, 73, 4);
  t(TileType.scaffolding, 80, 4);
  t(TileType.scaffolding, 82, 4);
  t(TileType.scaffolding, -10, 3);
  t(TileType.scaffolding, -8, 3);
  t(TileType.scaffolding, -6, 3);
  t(TileType.scaffolding, -4, 3);
  t(TileType.scaffolding, 73, 3);
  t(TileType.scaffolding, 81, 3);
  t(TileType.scaffolding, 80, 2);
  t(TileType.scaffolding, 82, 2);
  t(TileType.scaffolding, 20, 1);
  t(TileType.scaffolding, 67, 1);
  t(TileType.scaffolding, 73, 1);
  t(TileType.scaffolding, 81, 1);
  t(TileType.scaffolding, 20, 0);
  t(TileType.scaffolding, 67, 0);
  t(TileType.scaffolding, 73, 0);
  t(TileType.scaffolding, 80, 0);
  t(TileType.scaffolding, 82, 0);
  t(TileType.scaffolding, 20, -1);
  t(TileType.scaffolding, 67, -1);
  t(TileType.scaffolding, 73, -1);
  t(TileType.scaffolding, 81, -1);
  t(TileType.scaffolding, 20, -2);
  t(TileType.scaffolding, 20, -3);
  t(TileType.scaffolding, 30, -3);
  t(TileType.scaffolding, 50, -3);
  t(TileType.scaffolding, -11, -4);
  t(TileType.scaffolding, -10, -4);
  t(TileType.scaffolding, -9, -4);
  t(TileType.scaffolding, -8, -4);
  t(TileType.scaffolding, -7, -4);
  t(TileType.scaffolding, -6, -4);
  t(TileType.scaffolding, -5, -4);
  t(TileType.scaffolding, -4, -4);
  t(TileType.scaffolding, -3, -4);
  t(TileType.scaffolding, -2, -4);
  t(TileType.scaffolding, -1, -4);
  t(TileType.scaffolding, 0, -4);
  t(TileType.scaffolding, 1, -4);
  t(TileType.scaffolding, 2, -4);
  t(TileType.scaffolding, 3, -4);
  t(TileType.scaffolding, 4, -4);
  t(TileType.scaffolding, 5, -4);
  t(TileType.scaffolding, 6, -4);
  t(TileType.scaffolding, 7, -4);
  t(TileType.scaffolding, 8, -4);
  t(TileType.scaffolding, 9, -4);
  t(TileType.scaffolding, 10, -4);
  t(TileType.scaffolding, 20, -4);
  t(TileType.scaffolding, 30, -4);
  t(TileType.scaffolding, 50, -4);
  t(TileType.scaffolding, 20, -5);
  t(TileType.scaffolding, 30, -5);
  t(TileType.scaffolding, 50, -5);
  t(TileType.scaffolding, 20, -6);
  t(TileType.scaffolding, 30, -6);
  t(TileType.scaffolding, 50, -6);
  t(TileType.scaffolding, -12, -8);
  t(TileType.scaffolding, -11, -8);
  t(TileType.scaffolding, -10, -8);
  t(TileType.scaffolding, -9, -8);
  t(TileType.scaffolding, -4, -8);
  t(TileType.scaffolding, -3, -8);
  t(TileType.scaffolding, -2, -8);
  t(TileType.scaffolding, -1, -8);
  t(TileType.scaffolding, 4, -8);
  t(TileType.scaffolding, 5, -8);
  t(TileType.scaffolding, 6, -8);
  t(TileType.scaffolding, 7, -8);
  t(TileType.scaffolding, 12, -8);
  t(TileType.scaffolding, 13, -8);
  t(TileType.scaffolding, 14, -8);
  t(TileType.scaffolding, 15, -8);
  t(TileType.scaffolding, 20, -8);
  t(TileType.scaffolding, 21, -8);
  t(TileType.scaffolding, 22, -8);
  t(TileType.scaffolding, 23, -8);
  t(TileType.scaffolding, 28, -8);
  t(TileType.scaffolding, 29, -8);
  t(TileType.scaffolding, 30, -8);
  t(TileType.scaffolding, 31, -8);
  t(TileType.scaffolding, 36, -8);
  t(TileType.scaffolding, 37, -8);
  t(TileType.scaffolding, 38, -8);
  t(TileType.scaffolding, 39, -8);
  t(TileType.scaffolding, 44, -8);
  t(TileType.scaffolding, 45, -8);
  t(TileType.scaffolding, 46, -8);
  t(TileType.scaffolding, 47, -8);
  t(TileType.scaffolding, 52, -8);
  t(TileType.scaffolding, 53, -8);
  t(TileType.scaffolding, 54, -8);
  t(TileType.scaffolding, 55, -8);
  t(TileType.scaffolding, 60, -8);
  t(TileType.scaffolding, 61, -8);
  t(TileType.scaffolding, 62, -8);
  t(TileType.scaffolding, 63, -8);
  t(TileType.scaffolding, 68, -8);
  t(TileType.scaffolding, 69, -8);
  t(TileType.scaffolding, 70, -8);
  t(TileType.scaffolding, 71, -8);
  t(TileType.scaffolding, -8, -9);
  t(TileType.scaffolding, -7, -9);
  t(TileType.scaffolding, -6, -9);
  t(TileType.scaffolding, -5, -9);
  t(TileType.scaffolding, 0, -9);
  t(TileType.scaffolding, 1, -9);
  t(TileType.scaffolding, 2, -9);
  t(TileType.scaffolding, 3, -9);
  t(TileType.scaffolding, 8, -9);
  t(TileType.scaffolding, 9, -9);
  t(TileType.scaffolding, 10, -9);
  t(TileType.scaffolding, 11, -9);
  t(TileType.scaffolding, 16, -9);
  t(TileType.scaffolding, 17, -9);
  t(TileType.scaffolding, 18, -9);
  t(TileType.scaffolding, 19, -9);
  t(TileType.scaffolding, 24, -9);
  t(TileType.scaffolding, 25, -9);
  t(TileType.scaffolding, 26, -9);
  t(TileType.scaffolding, 27, -9);
  t(TileType.scaffolding, 32, -9);
  t(TileType.scaffolding, 33, -9);
  t(TileType.scaffolding, 34, -9);
  t(TileType.scaffolding, 35, -9);
  t(TileType.scaffolding, 40, -9);
  t(TileType.scaffolding, 41, -9);
  t(TileType.scaffolding, 42, -9);
  t(TileType.scaffolding, 43, -9);
  t(TileType.scaffolding, 48, -9);
  t(TileType.scaffolding, 49, -9);
  t(TileType.scaffolding, 50, -9);
  t(TileType.scaffolding, 51, -9);
  t(TileType.scaffolding, 56, -9);
  t(TileType.scaffolding, 57, -9);
  t(TileType.scaffolding, 58, -9);
  t(TileType.scaffolding, 59, -9);
  t(TileType.scaffolding, 64, -9);
  t(TileType.scaffolding, 65, -9);
  t(TileType.scaffolding, 66, -9);
  t(TileType.scaffolding, 67, -9);
  t(TileType.scaffolding, 72, -9);
  t(TileType.scaffolding, 73, -9);
  t(TileType.scaffolding, 74, -9);
  t(TileType.scaffolding, 75, -9);
// bricks: 18 tiles
  t(TileType.bricks, 9, 5);
  t(TileType.bricks, 10, 5);
  t(TileType.bricks, 50, 5);
  t(TileType.bricks, 79, 5);
  t(TileType.bricks, 9, 4);
  t(TileType.bricks, 10, 4);
  t(TileType.bricks, 50, 4);
  t(TileType.bricks, 79, 4);
  t(TileType.bricks, 9, 3);
  t(TileType.bricks, 10, 3);
  t(TileType.bricks, 50, 3);
  t(TileType.bricks, 79, 3);
  t(TileType.bricks, 79, 2);
  t(TileType.bricks, 60, 1);
  t(TileType.bricks, 61, 1);
  t(TileType.bricks, 79, 1);
  t(TileType.bricks, 79, 0);
  t(TileType.bricks, 79, -1);
// timber: 140 tiles
  t(TileType.timber, 12, 4);
  t(TileType.timber, 13, 4);
  t(TileType.timber, 14, 4);
  t(TileType.timber, 15, 4);
  t(TileType.timber, 16, 4);
  t(TileType.timber, 17, 4);
  t(TileType.timber, 18, 4);
  t(TileType.timber, 19, 4);
  t(TileType.timber, 20, 4);
  t(TileType.timber, 21, 4);
  t(TileType.timber, 22, 4);
  t(TileType.timber, 23, 4);
  t(TileType.timber, 24, 4);
  t(TileType.timber, 26, 4);
  t(TileType.timber, 27, 4);
  t(TileType.timber, 28, 4);
  t(TileType.timber, 29, 4);
  t(TileType.timber, 31, 4);
  t(TileType.timber, 32, 4);
  t(TileType.timber, 33, 4);
  t(TileType.timber, 34, 4);
  t(TileType.timber, 26, 2);
  t(TileType.timber, 27, 2);
  t(TileType.timber, 28, 2);
  t(TileType.timber, 29, 2);
  t(TileType.timber, 31, 2);
  t(TileType.timber, 32, 2);
  t(TileType.timber, 33, 2);
  t(TileType.timber, 34, 2);
  t(TileType.timber, 45, 1);
  t(TileType.timber, 31, 0);
  t(TileType.timber, 32, 0);
  t(TileType.timber, 33, 0);
  t(TileType.timber, 34, 0);
  t(TileType.timber, 45, 0);
  t(TileType.timber, 45, -1);
  t(TileType.timber, 67, -3);
  t(TileType.timber, 73, -3);
  t(TileType.timber, 67, -4);
  t(TileType.timber, 73, -4);
  t(TileType.timber, -8, -5);
  t(TileType.timber, -3, -5);
  t(TileType.timber, 2, -5);
  t(TileType.timber, 7, -5);
  t(TileType.timber, 67, -5);
  t(TileType.timber, 73, -5);
  t(TileType.timber, -8, -6);
  t(TileType.timber, -3, -6);
  t(TileType.timber, 2, -6);
  t(TileType.timber, 7, -6);
  t(TileType.timber, 67, -6);
  t(TileType.timber, 73, -6);
  t(TileType.timber, -12, -10);
  t(TileType.timber, -11, -10);
  t(TileType.timber, -10, -10);
  t(TileType.timber, -9, -10);
  t(TileType.timber, -8, -10);
  t(TileType.timber, -7, -10);
  t(TileType.timber, -6, -10);
  t(TileType.timber, -5, -10);
  t(TileType.timber, -4, -10);
  t(TileType.timber, -3, -10);
  t(TileType.timber, -2, -10);
  t(TileType.timber, -1, -10);
  t(TileType.timber, 0, -10);
  t(TileType.timber, 1, -10);
  t(TileType.timber, 2, -10);
  t(TileType.timber, 3, -10);
  t(TileType.timber, 4, -10);
  t(TileType.timber, 5, -10);
  t(TileType.timber, 6, -10);
  t(TileType.timber, 7, -10);
  t(TileType.timber, 8, -10);
  t(TileType.timber, 9, -10);
  t(TileType.timber, 10, -10);
  t(TileType.timber, 11, -10);
  t(TileType.timber, 36, -10);
  t(TileType.timber, 37, -10);
  t(TileType.timber, 38, -10);
  t(TileType.timber, 39, -10);
  t(TileType.timber, 40, -10);
  t(TileType.timber, 41, -10);
  t(TileType.timber, 42, -10);
  t(TileType.timber, 43, -10);
  t(TileType.timber, 44, -10);
  t(TileType.timber, 45, -10);
  t(TileType.timber, 46, -10);
  t(TileType.timber, 47, -10);
  t(TileType.timber, 48, -10);
  t(TileType.timber, 49, -10);
  t(TileType.timber, 50, -10);
  t(TileType.timber, 51, -10);
  t(TileType.timber, 52, -10);
  t(TileType.timber, 53, -10);
  t(TileType.timber, 54, -10);
  t(TileType.timber, 55, -10);
  t(TileType.timber, 56, -10);
  t(TileType.timber, 57, -10);
  t(TileType.timber, 58, -10);
  t(TileType.timber, 59, -10);
  t(TileType.timber, 12, -11);
  t(TileType.timber, 13, -11);
  t(TileType.timber, 14, -11);
  t(TileType.timber, 15, -11);
  t(TileType.timber, 16, -11);
  t(TileType.timber, 17, -11);
  t(TileType.timber, 18, -11);
  t(TileType.timber, 19, -11);
  t(TileType.timber, 20, -11);
  t(TileType.timber, 21, -11);
  t(TileType.timber, 22, -11);
  t(TileType.timber, 23, -11);
  t(TileType.timber, 24, -11);
  t(TileType.timber, 25, -11);
  t(TileType.timber, 26, -11);
  t(TileType.timber, 27, -11);
  t(TileType.timber, 28, -11);
  t(TileType.timber, 29, -11);
  t(TileType.timber, 30, -11);
  t(TileType.timber, 31, -11);
  t(TileType.timber, 32, -11);
  t(TileType.timber, 33, -11);
  t(TileType.timber, 34, -11);
  t(TileType.timber, 35, -11);
  t(TileType.timber, 60, -11);
  t(TileType.timber, 61, -11);
  t(TileType.timber, 62, -11);
  t(TileType.timber, 63, -11);
  t(TileType.timber, 64, -11);
  t(TileType.timber, 65, -11);
  t(TileType.timber, 66, -11);
  t(TileType.timber, 67, -11);
  t(TileType.timber, 68, -11);
  t(TileType.timber, 69, -11);
  t(TileType.timber, 70, -11);
  t(TileType.timber, 71, -11);
  t(TileType.timber, 72, -11);
  t(TileType.timber, 73, -11);
  t(TileType.timber, 74, -11);
  t(TileType.timber, 75, -11);

  // === SEGMENTS ===
  final segments = <SegmentInfo>[
    // Segment 0: origin=(0,0), spawn=(-9,-1)
    SegmentInfo(
      spawnPoint: Vector2(worldX(-9), worldY(-1)),
      cameraMinX: 0,
      cameraMaxX: worldX(10),
      triggerX: 0,
      killBall: false,
    ),
    // Segment 1: origin=(23.5,0), spawn=(14,-1)
    SegmentInfo(
      spawnPoint: Vector2(worldX(14), worldY(-1)),
      cameraMinX: worldX(12),
      cameraMaxX: worldX(34),
      triggerX: worldX(12),
      killBall: false,
    ),
    // Segment 2: origin=(47.5,0), spawn=(38,3)
    SegmentInfo(
      spawnPoint: Vector2(worldX(38), worldY(3)),
      cameraMinX: worldX(36),
      cameraMaxX: worldX(58),
      triggerX: worldX(36),
      killBall: true,
    ),
    // Segment 3: origin=(71.5,0), spawn=(62,-5)
    SegmentInfo(
      spawnPoint: Vector2(worldX(62), worldY(-5)),
      cameraMinX: worldX(60),
      cameraMaxX: worldX(84),
      triggerX: worldX(60),
      killBall: true,
    ),
  ];

  // === PROPS ===
  final props = <PropInfo>[
    // Elevator at Godot (79.5, 3)
    PropInfo('elevator', worldX(79.5), worldY(3)),
    
    // Tutorial Billboards
    PropInfo('billboard_move', worldX(-5), worldY(0.2)),
    PropInfo('billboard_jump', worldX(3.5), worldY(0.2)),
    PropInfo('billboard_strike', worldX(23), worldY(0.2)),
    PropInfo('billboard_aim', worldX(28), worldY(2.2)),
  ];

  return LevelLayout(
    tiles: tiles,
    segments: segments,
    groundY: worldY(-7),
    totalWidth: worldX(85),
    props: props,
  );
}
