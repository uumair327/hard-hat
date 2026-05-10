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

  // --- FLOOR: Godot y=-7, continuous girder row x=-12 to x=83 ---
  for (int x = -12; x <= 83; x++) t(TileType.beam, x, -7);

  // --- CEILING: Godot y=6, continuous girder row x=-12 to x=83 ---
  for (int x = -12; x <= 83; x++) t(TileType.beam, x, 6);

  // --- VERTICAL WALLS (girder columns) ---
  // Left wall at x=-12, from y=-6 to y=5
  for (int y = -6; y <= 5; y++) t(TileType.beam, -12, y);
  // Right wall at x=83, from y=-6 to y=5
  for (int y = -6; y <= 5; y++) t(TileType.beam, 83, y);
  // Wall at x=11 (partial), from y=-6 to y=5 (every level)
  for (int y = -6; y <= 5; y++) t(TileType.beam, 11, y);
  // Wall at x=25, from y=-2 to y=5
  for (int y = -2; y <= 5; y++) t(TileType.beam, 25, y);
  // Wall at x=30, from y=-2 to y=5
  for (int y = -2; y <= 5; y++) t(TileType.beam, 30, y);
  // Wall at x=35, from y=-6 to y=5
  for (int y = -6; y <= 5; y++) t(TileType.beam, 35, y);
  // Wall at x=59, from y=-6 to y=5
  for (int y = -6; y <= 5; y++) t(TileType.beam, 59, y);

  // --- INTERNAL PLATFORMS (girder rows) ---
  // Platform at y=2, x=-11 to x=-2
  for (int x = -11; x <= -2; x++) t(TileType.beam, x, 2);
  // Platform at y=2, x=2 to x=4
  for (int x = 2; x <= 4; x++) t(TileType.beam, x, 2);
  // Platform at y=2, x=9 to x=10
  for (int x = 9; x <= 10; x++) t(TileType.beam, x, 2);
  // Long platform at y=2, x=12 to x=24
  for (int x = 12; x <= 24; x++) t(TileType.beam, x, 2);
  // Long platform at y=2, x=39 to x=74
  for (int x = 39; x <= 74; x++) t(TileType.beam, x, 2);

  // Platform at y=-2, x=30 to x=55
  for (int x = 30; x <= 55; x++) t(TileType.beam, x, -2);
  // Platform at y=-2, x=66 to x=82
  for (int x = 66; x <= 82; x++) t(TileType.beam, x, -2);

  // Small platforms
  t(TileType.beam, -2, 5);
  t(TileType.beam, -1, 4);
  t(TileType.beam, 26, 0);
  t(TileType.beam, 27, 0);
  t(TileType.beam, 28, 0);
  t(TileType.beam, 29, 0);
  t(TileType.beam, 60, 0);
  t(TileType.beam, 61, 0);
  t(TileType.beam, 77, 4);
  t(TileType.beam, 78, 4);

  // --- SCAFFOLDING (breakable, 1 hit) ---
  // Vertical ladders at specific X positions
  for (int y = 3; y <= 5; y++) {
    t(TileType.scaffolding, -10, y);
    t(TileType.scaffolding, -8, y);
    t(TileType.scaffolding, -6, y);
    t(TileType.scaffolding, -4, y);
  }
  // Scaffolding columns
  for (int y = -6; y <= -2; y++) t(TileType.scaffolding, 20, y);
  for (int y = -6; y <= -3; y++) t(TileType.scaffolding, 30, y);
  for (int y = -6; y <= -3; y++) t(TileType.scaffolding, 50, y);
  // Long row at y=-4, x=-11 to x=10
  for (int x = -11; x <= 10; x++) t(TileType.scaffolding, x, -4);
  // Scaffolding at top right area
  for (int y = 0; y <= 5; y += 2) {
    t(TileType.scaffolding, 73, y);
    t(TileType.scaffolding, 81, y);
  }
  for (int y = 0; y <= 4; y += 2) {
    t(TileType.scaffolding, 80, y);
    t(TileType.scaffolding, 82, y);
  }
  t(TileType.scaffolding, 67, 0);
  t(TileType.scaffolding, 67, 1);
  t(TileType.scaffolding, 67, -1);

  // --- Bottom scaffolding staircase pattern ---
  // y=-8: groups of 4 scaffolding blocks
  final scafY8 = [
    -12,
    -11,
    -10,
    -9,
    -4,
    -3,
    -2,
    -1,
    4,
    5,
    6,
    7,
    12,
    13,
    14,
    15,
    20,
    21,
    22,
    23,
    28,
    29,
    30,
    31,
    36,
    37,
    38,
    39,
    44,
    45,
    46,
    47,
    52,
    53,
    54,
    55,
    60,
    61,
    62,
    63,
    68,
    69,
    70,
    71,
  ];
  for (final x in scafY8) t(TileType.scaffolding, x, -8);

  // y=-9: alternating groups of 4 (offset by 4 from y=-8)
  final scafY9 = [
    -8,
    -7,
    -6,
    -5,
    0,
    1,
    2,
    3,
    8,
    9,
    10,
    11,
    16,
    17,
    18,
    19,
    24,
    25,
    26,
    27,
    32,
    33,
    34,
    35,
    40,
    41,
    42,
    43,
    48,
    49,
    50,
    51,
    56,
    57,
    58,
    59,
    64,
    65,
    66,
    67,
    72,
    73,
    74,
    75,
  ];
  for (final x in scafY9) t(TileType.scaffolding, x, -9);

  // --- TIMBER (breakable, 2 hits) ---
  // Upper timber platform at y=4, x=12 to x=24 (with gaps at 25)
  for (int x = 12; x <= 24; x++) t(TileType.timber, x, 4);
  // Timber at y=4, x=26-29, 31-34
  for (int x = 26; x <= 29; x++) t(TileType.timber, x, 4);
  for (int x = 31; x <= 34; x++) t(TileType.timber, x, 4);
  // Timber at y=2, x=26-29, 31-34
  for (int x = 26; x <= 29; x++) t(TileType.timber, x, 2);
  for (int x = 31; x <= 34; x++) t(TileType.timber, x, 2);
  // Timber at y=0, x=31-34
  for (int x = 31; x <= 34; x++) t(TileType.timber, x, 0);
  // Single timber columns
  for (int y = -1; y <= 1; y++) t(TileType.timber, 45, y);
  // Timber columns at right side
  for (int y = -6; y <= -3; y++) {
    t(TileType.timber, 67, y);
    t(TileType.timber, 73, y);
  }
  // Timber at y=-5, -6: x=-8,-3,2,7
  for (int y = -6; y <= -5; y++) {
    t(TileType.timber, -8, y);
    t(TileType.timber, -3, y);
    t(TileType.timber, 2, y);
    t(TileType.timber, 7, y);
  }
  // Large timber floor at y=-10, x=-12 to x=11
  for (int x = -12; x <= 11; x++) t(TileType.timber, x, -10);
  // Large timber floor at y=-10, x=36 to x=59
  for (int x = 36; x <= 59; x++) t(TileType.timber, x, -10);
  // Large timber floor at y=-11, x=12 to x=35
  for (int x = 12; x <= 35; x++) t(TileType.timber, x, -11);
  // Timber floor at y=-11, x=60 to x=75
  for (int x = 60; x <= 75; x++) t(TileType.timber, x, -11);

  // --- BRICKS (breakable, 3 hits) ---
  for (int y = 3; y <= 5; y++) {
    t(TileType.bricks, 9, y);
    t(TileType.bricks, 10, y);
  }
  for (int y = 3; y <= 5; y++) t(TileType.bricks, 50, y);
  for (int y = -1; y <= 5; y++) t(TileType.bricks, 79, y);
  t(TileType.bricks, 60, 1);
  t(TileType.bricks, 61, 1);

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
