import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'components/player_component.dart';
import 'components/tile_component.dart';
import 'components/elevator_component.dart';
import 'components/spring_component.dart';
import 'components/target_component.dart';
import 'components/shutter_component.dart';
import 'components/player_beam_component.dart';
import 'components/billboard_component.dart';
import 'package:hard_hat/save/game_save_manager.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';
import 'levels/level1_data.dart';

/// The actual playable Hard Hat game — directly using Flame components.
/// Supports 4 levels with 4 segments each, matching Godot's sandbox.gd.
class HardHatGameActual extends FlameGame
    with
        HasCollisionDetection,
        HasKeyboardHandlerComponents,
        MouseMovementDetector {
  late PlayerComponent player;
  int currentLevelId = 1;

  // Segment system (matching Godot sandbox.gd)
  int currentSegment = 0;
  int ballSegment = 0;

  // Camera (matching Godot sandbox.gd)
  double tripodMinX = -9999.0;
  double tripodMaxX = 9999.0;

  // Game state
  GameplayState gameState = GameplayState.playing;
  bool transitionFlag = true; // Disable pause during transitions

  // Mouse position for ball aiming (matching Godot ball.gd L73-93)
  Vector2 _mousePosition = Vector2.zero();
  Vector2 get mousePosition => _mousePosition;

  // Ball timer HUD
  double ballTimerRemaining = 0.0;
  double ballTimerMax = 10.0;

  // Level completion callback
  void Function(int levelId)? onLevelCompleted;
  void Function()? onOutroTriggered;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    await _loadLevel(currentLevelId);
    camera.viewport.add(_HudComponent());
  }

  // === LEVEL LOADING (matching Godot sandbox.load_level) ===
  Future<void> _loadLevel(int levelId) async {
    world.removeAll(world.children);
    currentLevelId = levelId;
    currentSegment = 0;
    ballSegment = 0;

    // Background
    world.add(_BackgroundComponent(gameSize: size));

    // Build level
    final levelData = _getLevelData(levelId);

    // Add tiles per segment
    for (final seg in levelData.segments) {
      for (final tileData in seg.tiles) {
        world.add(
          TileComponent(
            type: tileData.type,
            gridX: tileData.gridX,
            gridY: tileData.gridY,
            position: Vector2(
              tileData.gridX * TileComponent.tileSize,
              tileData.gridY * TileComponent.tileSize,
            ),
            onDestroyed: (tile) {
              debugPrint('Tile destroyed at (${tile.gridX}, ${tile.gridY})');
            },
            onBreakParticles: (tile, pos) {
              _spawnBreakParticles(tile.tileType, pos);
            },
          ),
        );
      }
    }

    // Add props
    for (final prop in levelData.props) {
      world.add(prop);
    }

    // Add segment triggers
    for (int i = 0; i < levelData.segments.length; i++) {
      final seg = levelData.segments[i];
      world.add(
        _SegmentTrigger(
          segmentId: i,
          position: Vector2(seg.triggerX, 0),
          triggerHeight: size.y,
          onEnter: (segId) => _switchSegment(levelData, segId),
        ),
      );
    }

    // Ground
    _addGround(levelData.groundY, levelData.totalWidth);

    // Spawn player at segment 0
    final seg0 = levelData.segments[0];
    player = PlayerComponent(
      position: seg0.spawnPoint.clone(),
      onRespawn: () => _loadLevel(currentLevelId),
      onXUpdate: (x) => _updateCamera(x),
      onCameraShakeRequest: (dir) => _cameraShake(dir),
    )..onStarParticles = (pos, normal) => _spawnStarParticles(pos, normal);
    world.add(player);

    // Set initial camera bounds
    _setTripodValues(seg0.cameraMinX, seg0.cameraMaxX, forceUpdate: true);
    transitionFlag = false;
  }

  void _addGround(double groundY, double totalWidth) {
    final numTiles = (totalWidth / TileComponent.tileSize).ceil();
    for (int x = 0; x < numTiles; x++) {
      world.add(
        TileComponent(
          type: TileType.ground,
          gridX: x,
          gridY: (groundY / TileComponent.tileSize).floor(),
          position: Vector2(x * TileComponent.tileSize, groundY),
        ),
      );
    }
  }

  // === SEGMENT SYSTEM (matching Godot sandbox.switch_segment) ===
  void _switchSegment(_LevelData levelData, int segmentId) {
    if (segmentId >= levelData.segments.length) return;
    if (segmentId > currentSegment) {
      currentSegment = segmentId;
    }

    // Kill ball if switching segment AND killBallOnSwitch is true (Godot 1.gd L4-9)
    final seg = levelData.segments[segmentId];
    if (seg.killBallOnSwitch && segmentId != ballSegment) {
      player.ballReference?.kill();
      player.ballReference = null;
    }
    ballSegment = segmentId;

    _setTripodValues(seg.cameraMinX, seg.cameraMaxX);
  }

  void _setTripodValues(double minX, double maxX, {bool forceUpdate = false}) {
    tripodMinX = minX;
    tripodMaxX = maxX;
    if (forceUpdate) {
      camera.viewfinder.position = Vector2(minX, 0);
    }
  }

  // === CAMERA (matching Godot sandbox._on_player_x_update) ===
  void _updateCamera(double playerX) {
    double targetX = playerX;
    if (targetX < tripodMinX || targetX > tripodMaxX) {
      targetX = targetX.clamp(tripodMinX, tripodMaxX);
    }
    final camX = (targetX - size.x / 2)
        .clamp(tripodMinX, max(tripodMinX, tripodMaxX - size.x))
        .toDouble();
    camera.viewfinder.position = Vector2(camX, 0);
  }

  void _cameraShake(Vector2 direction) {
    final shakeOffset = direction.normalized() * 3;
    final origPos = camera.viewfinder.position.clone();
    camera.viewfinder.position += shakeOffset;
    Future.delayed(const Duration(milliseconds: 50), () {
      camera.viewfinder.position = origPos;
    });
  }

  void _spawnBreakParticles(TileType type, Vector2 position) {
    world.add(
      _BreakParticleEffect(position: position, color: _getParticleColor(type)),
    );
  }

  // Star/impact particles on every ball bounce (Godot ball.gd L168-173)
  void _spawnStarParticles(Vector2 pos, Vector2 normal) {
    world.add(_StarParticleEffect(position: pos, normal: normal));
  }

  Color _getParticleColor(TileType type) {
    switch (type) {
      case TileType.scaffolding:
        return const Color(0xFFC4A882);
      case TileType.timber:
      case TileType.timberOneHit:
        return const Color(0xFF8B6914);
      case TileType.bricks:
      case TileType.bricksOneHit:
      case TileType.bricksTwoHit:
        return const Color(0xFFB22222);
      default:
        return const Color(0xFF888888);
    }
  }

  // === LEVEL COMPLETION ===
  void Function()? onLevelCompleteSplash;

  void _onElevatorStarted() {
    transitionFlag = true; // Disable pause
    onLevelCompleteSplash
        ?.call(); // Godot level.gd L11-12: show "Level Complete" splash
  }

  void _onElevatorReached(int levelId) {
    switch (levelId) {
      case 1:
        GameSaveManager.setLevel1Completed();
        onLevelCompleted?.call(2);
        break;
      case 2:
        GameSaveManager.setLevel2Completed();
        onLevelCompleted?.call(3);
        break;
      case 3:
        GameSaveManager.setLevel3Completed();
        onLevelCompleted?.call(4);
        break;
      case 4:
        GameSaveManager.setLevel4Completed();
        // Godot 4.gd L37-40: if outro already viewed, quit to menu
        if (GameSaveManager.outroViewed) {
          onLevelCompleted?.call(-1); // Signal to go back to menu
        } else {
          onOutroTriggered?.call();
        }
        break;
    }
  }

  // === UPDATE ===
  @override
  void update(double dt) {
    super.update(dt);
    // Track ball timer for HUD
    ballTimerRemaining = player.ballTimerRemaining;
    ballTimerMax = player.ballTimerMax;

    // Forward mouse position to ball for aim tracking (Godot ball.gd L73-93)
    if (player.ballReference != null && player.ballReference!.tracking) {
      final ballScreenPos = player.ballReference!.absolutePosition;
      final direction = _mousePosition - ballScreenPos;
      if (direction.length2 > 1.0) {
        player.ballReference!.setDirection(direction.clone()..y = direction.y);
      }
    }
  }

  // === MOUSE TRACKING (matching Godot ball.gd cursor tracking) ===
  @override
  void onMouseMove(PointerHoverInfo info) {
    _mousePosition = info.eventPosition.global;
  }

  // === KEY HANDLING ===
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (transitionFlag) return KeyEventResult.handled;
      // 3-state pause system (matching Godot sandbox.gd L94-125)
      switch (gameState) {
        case GameplayState.playing:
          gameState = GameplayState.paused;
          pauseEngine();
          GameAudioManager.duckForPause();
          break;
        case GameplayState.paused:
          gameState = GameplayState.countdown;
          resumeEngine();
          GameAudioManager.restoreFromPause();
          break;
        case GameplayState.countdown:
          // Re-pause during countdown (Godot sandbox.gd L120-125)
          gameState = GameplayState.paused;
          pauseEngine();
          GameAudioManager.duckForPause();
          break;
      }
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  // ============================================================
  // LEVEL DATA BUILDERS
  // ============================================================

  _LevelData _getLevelData(int levelId) {
    switch (levelId) {
      case 1:
        return _buildLevel1();
      case 2:
        return _buildLevel2();
      case 3:
        return _buildLevel3();
      case 4:
        return _buildLevel4();
      default:
        return _buildLevel1();
    }
  }

  int _gridY(double y) => (y / TileComponent.tileSize).floor();

  /// **Level 1 — The Foundations** (decoded from Godot 1.tscn GridMap)
  _LevelData _buildLevel1() {
    final layout = buildGodotLevel1(size.y);
    final segments = <_SegmentData>[];
    final props = <Component>[];

    // Convert layout tiles into _TileInfo
    final allTiles = <_TileInfo>[];
    for (final t in layout.tiles) {
      allTiles.add(_TileInfo(type: t.type, gridX: t.gridX, gridY: t.gridY));
    }

    // Create segments with proper spawn/camera data
    for (int i = 0; i < layout.segments.length; i++) {
      final seg = layout.segments[i];
      segments.add(
        _SegmentData(
          tiles: i == 0 ? allTiles : [], // All tiles in segment 0
          spawnPoint: seg.spawnPoint,
          cameraMinX: seg.cameraMinX,
          cameraMaxX: seg.cameraMaxX,
          triggerX: seg.triggerX,
          killBallOnSwitch: seg.killBall,
        ),
      );
    }

    // Add props
    for (final prop in layout.props) {
      if (prop.type == 'elevator') {
        props.add(
          ElevatorComponent(
            position: Vector2(prop.worldX, prop.worldY),
            targetY: prop.worldY - 8 * TileComponent.tileSize,
            onStarted: _onElevatorStarted,
            onReached: () => _onElevatorReached(1),
          ),
        );
      } else if (prop.type.startsWith('billboard_')) {
        final billboardType = prop.type.split('_')[1]; // e.g. 'move', 'jump'
        props.add(
          BillboardComponent(
            type: billboardType,
            position: Vector2(prop.worldX, prop.worldY),
            large: billboardType == 'pogo', // pogo uses large billboard
          ),
        );
      }
    }

    return _LevelData(
      segments: segments,
      props: props,
      groundY: layout.groundY,
      totalWidth: layout.totalWidth,
    );
  }

  /// **Level 2 — Breaking Through** (Introduces bricks + targets + shutters)
  _LevelData _buildLevel2() {
    const ts = TileComponent.tileSize;
    final groundY = size.y - ts;
    final segments = <_SegmentData>[];
    final props = <Component>[];

    // Segment 0: Scaffolding warm-up
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 4; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.scaffolding,
            gridX: 8,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(2 * ts, groundY),
          cameraMinX: 0,
          cameraMaxX: 12 * ts,
          triggerX: 0,
        ),
      );
    }

    // Segment 1: Timber double wall
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 5; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.timber,
            gridX: 16,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
        tiles.add(
          _TileInfo(
            type: TileType.timber,
            gridX: 17,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(12 * ts, groundY),
          cameraMinX: 10 * ts,
          cameraMaxX: 21 * ts,
          triggerX: 10 * ts,
        ),
      );
    }

    // Segment 2: Bricks + target/shutter puzzle
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 4; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 24,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 25,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(20 * ts, groundY),
          cameraMinX: 18 * ts,
          cameraMaxX: 30 * ts,
          triggerX: 18 * ts,
        ),
      );
    }

    // Target + Shutter for segment 2
    final shutter1 = ShutterComponent(
      position: Vector2(27 * ts, groundY - 4 * ts),
      offset: Vector2(0, -6 * ts),
    );
    props.add(
      TargetComponent(
        position: Vector2(23 * ts, groundY - 5 * ts),
        onHit: (target) => shutter1.onTargetHit(),
      ),
    );
    props.add(shutter1);

    // Segment 3: Mixed wall + elevator
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 6; y++) {
        if (y < 2) {
          tiles.add(
            _TileInfo(
              type: TileType.bricks,
              gridX: 35,
              gridY: _gridY(groundY - ts * (y + 1)),
            ),
          );
        } else if (y < 4) {
          tiles.add(
            _TileInfo(
              type: TileType.timber,
              gridX: 35,
              gridY: _gridY(groundY - ts * (y + 1)),
            ),
          );
        } else {
          tiles.add(
            _TileInfo(
              type: TileType.scaffolding,
              gridX: 35,
              gridY: _gridY(groundY - ts * (y + 1)),
            ),
          );
        }
      }
      // Beam bridge
      for (int x = 30; x <= 34; x++) {
        tiles.add(
          _TileInfo(
            type: TileType.beam,
            gridX: x,
            gridY: _gridY(groundY - ts * 5),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(28 * ts, groundY),
          cameraMinX: 26 * ts,
          cameraMaxX: 42 * ts,
          triggerX: 26 * ts,
        ),
      );
    }

    props.add(
      ElevatorComponent(
        position: Vector2(40 * ts, groundY - 20),
        targetY: groundY - 8 * ts,
        onStarted: _onElevatorStarted,
        onReached: () => _onElevatorReached(2),
      ),
    );

    return _LevelData(
      segments: segments,
      props: props,
      groundY: groundY,
      totalWidth: 44 * ts,
    );
  }

  /// **Level 3 — Spring Loaded** (Introduces springs, retracting shutters)
  _LevelData _buildLevel3() {
    const ts = TileComponent.tileSize;
    final groundY = size.y - ts;
    final segments = <_SegmentData>[];
    final props = <Component>[];

    // Segment 0: Spring introduction
    {
      final tiles = <_TileInfo>[];
      // Elevated platform requiring spring
      for (int x = 6; x <= 10; x++) {
        tiles.add(
          _TileInfo(
            type: TileType.beam,
            gridX: x,
            gridY: _gridY(groundY - ts * 5),
          ),
        );
      }
      // Wall past platform
      for (int y = 0; y < 3; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.timber,
            gridX: 11,
            gridY: _gridY(groundY - ts * (y + 6)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(2 * ts, groundY),
          cameraMinX: 0,
          cameraMaxX: 14 * ts,
          triggerX: 0,
        ),
      );
    }
    // Spring to reach platform
    props.add(SpringComponent(position: Vector2(5 * ts, groundY)));

    // Segment 1: Scaffolding + spring combo
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 5; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.scaffolding,
            gridX: 18,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      // High platform
      for (int x = 19; x <= 22; x++) {
        tiles.add(
          _TileInfo(
            type: TileType.beam,
            gridX: x,
            gridY: _gridY(groundY - ts * 6),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(13 * ts, groundY),
          cameraMinX: 12 * ts,
          cameraMaxX: 25 * ts,
          triggerX: 12 * ts,
        ),
      );
    }
    props.add(SpringComponent(position: Vector2(16 * ts, groundY)));

    // Segment 2: Retracting shutter puzzle
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 4; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 28,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      for (int y = 0; y < 4; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 32,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(24 * ts, groundY),
          cameraMinX: 23 * ts,
          cameraMaxX: 36 * ts,
          triggerX: 23 * ts,
        ),
      );
    }

    // Respawning target + retracting shutter
    final retractShutter = RetractingShutterComponent(
      position: Vector2(30 * ts, groundY - 4 * ts),
      offset: Vector2(0, -6 * ts),
      cooldown: 3.0,
    );
    props.add(
      RespawningTargetComponent(
        position: Vector2(27 * ts, groundY - 5 * ts),
        onHit: (target) => retractShutter.onTargetHit(),
        respawnTime: 5.0,
      ),
    );
    props.add(retractShutter);

    // Segment 3: Final gauntlet + elevator
    {
      final tiles = <_TileInfo>[];
      // Mixed wall
      for (int y = 0; y < 5; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 38,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      for (int y = 0; y < 3; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.timber,
            gridX: 39,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      for (int x = 36; x <= 37; x++) {
        tiles.add(
          _TileInfo(
            type: TileType.beam,
            gridX: x,
            gridY: _gridY(groundY - ts * 4),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(34 * ts, groundY),
          cameraMinX: 33 * ts,
          cameraMaxX: 46 * ts,
          triggerX: 33 * ts,
        ),
      );
    }

    props.add(SpringComponent(position: Vector2(35 * ts, groundY)));
    props.add(
      ElevatorComponent(
        position: Vector2(44 * ts, groundY - 20),
        targetY: groundY - 8 * ts,
        onStarted: _onElevatorStarted,
        onReached: () => _onElevatorReached(3),
      ),
    );

    return _LevelData(
      segments: segments,
      props: props,
      groundY: groundY,
      totalWidth: 48 * ts,
    );
  }

  /// **Level 4 — The Final Floor** (Complex puzzle: 3-target counter, player beam)
  _LevelData _buildLevel4() {
    const ts = TileComponent.tileSize;
    final groundY = size.y - ts;
    final segments = <_SegmentData>[];
    final props = <Component>[];

    // Target counter for final shutters (matching Godot 4.gd)
    int targetHitCount = 0;
    ShutterComponent? finalShutter1;
    ShutterComponent? finalShutter2;

    // Segment 0: Warm-up with player beam
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 3; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 8,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
        tiles.add(
          _TileInfo(
            type: TileType.timber,
            gridX: 9,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(2 * ts, groundY),
          cameraMinX: 0,
          cameraMaxX: 13 * ts,
          triggerX: 0,
        ),
      );
    }
    props.add(PlayerBeamComponent(position: Vector2(4 * ts, groundY - ts)));

    // Segment 1: Target + shutter gate
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 5; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 18,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      for (int x = 14; x <= 16; x++) {
        tiles.add(
          _TileInfo(
            type: TileType.beam,
            gridX: x,
            gridY: _gridY(groundY - ts * 4),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(12 * ts, groundY),
          cameraMinX: 11 * ts,
          cameraMaxX: 22 * ts,
          triggerX: 11 * ts,
        ),
      );
    }

    final shutter2 = ShutterComponent(
      position: Vector2(20 * ts, groundY - 5 * ts),
      offset: Vector2(0, -6 * ts),
    );
    props.add(
      TargetComponent(
        position: Vector2(17 * ts, groundY - 6 * ts),
        onHit: (target) => shutter2.onTargetHit(),
      ),
    );
    props.add(shutter2);

    // Segment 2: Triple targets → final shutters
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 4; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 27,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 28,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      for (int x = 23; x <= 26; x++) {
        tiles.add(
          _TileInfo(
            type: TileType.beam,
            gridX: x,
            gridY: _gridY(groundY - ts * 5),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(21 * ts, groundY),
          cameraMinX: 20 * ts,
          cameraMaxX: 34 * ts,
          triggerX: 20 * ts,
        ),
      );
    }

    // 3 targets that together open final shutters (matching Godot 4.gd counter)
    finalShutter1 = ShutterComponent(
      position: Vector2(30 * ts, groundY - 5 * ts),
      offset: Vector2(0, -6 * ts),
    );
    finalShutter2 = ShutterComponent(
      position: Vector2(31 * ts, groundY - 5 * ts),
      offset: Vector2(0, -6 * ts),
    );

    void onTargetHitCounter(TargetComponent target) {
      targetHitCount++;
      if (targetHitCount >= 3) {
        finalShutter1?.onTargetHit();
        finalShutter2?.onTargetHit();
      }
    }

    props.add(
      TargetComponent(
        position: Vector2(24 * ts, groundY - 6 * ts),
        onHit: onTargetHitCounter,
      ),
    );
    props.add(
      TargetComponent(
        position: Vector2(26 * ts, groundY - 7 * ts),
        onHit: onTargetHitCounter,
      ),
    );
    props.add(
      TargetComponent(
        position: Vector2(28 * ts, groundY - 6 * ts),
        onHit: onTargetHitCounter,
      ),
    );
    props.add(finalShutter1);
    props.add(finalShutter2);

    // Segment 3: Final climb + elevator
    {
      final tiles = <_TileInfo>[];
      for (int y = 0; y < 6; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.bricks,
            gridX: 37,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      for (int y = 0; y < 4; y++) {
        tiles.add(
          _TileInfo(
            type: TileType.timber,
            gridX: 38,
            gridY: _gridY(groundY - ts * (y + 1)),
          ),
        );
      }
      segments.add(
        _SegmentData(
          tiles: tiles,
          spawnPoint: Vector2(33 * ts, groundY),
          cameraMinX: 32 * ts,
          cameraMaxX: 44 * ts,
          triggerX: 32 * ts,
        ),
      );
    }

    props.add(SpringComponent(position: Vector2(34 * ts, groundY)));
    props.add(
      ElevatorComponent(
        position: Vector2(42 * ts, groundY - 20),
        targetY: groundY - 8 * ts,
        onStarted: _onElevatorStarted,
        onReached: () => _onElevatorReached(4),
      ),
    );

    return _LevelData(
      segments: segments,
      props: props,
      groundY: groundY,
      totalWidth: 46 * ts,
    );
  }
}

// === DATA CLASSES ===

enum GameplayState { playing, paused, countdown }

class _LevelData {
  final List<_SegmentData> segments;
  final List<Component> props;
  final double groundY;
  final double totalWidth;

  _LevelData({
    required this.segments,
    required this.props,
    required this.groundY,
    required this.totalWidth,
  });
}

class _SegmentData {
  final List<_TileInfo> tiles;
  final Vector2 spawnPoint;
  final double cameraMinX;
  final double cameraMaxX;
  final double triggerX; // X position that triggers this segment
  final bool killBallOnSwitch; // Godot 1.gd: segments 0,1 pass false

  _SegmentData({
    required this.tiles,
    required this.spawnPoint,
    required this.cameraMinX,
    required this.cameraMaxX,
    required this.triggerX,
    this.killBallOnSwitch = true, // Default: kill ball on segment switch
  });
}

class _TileInfo {
  final TileType type;
  final int gridX;
  final int gridY;
  _TileInfo({required this.type, required this.gridX, required this.gridY});
}

/// Invisible trigger area that switches segments when the player crosses it
class _SegmentTrigger extends PositionComponent {
  final int segmentId;
  final double triggerHeight;
  final void Function(int segmentId) onEnter;
  bool _triggered = false;

  _SegmentTrigger({
    required this.segmentId,
    required Vector2 position,
    required this.triggerHeight,
    required this.onEnter,
  }) : super(
         position: position,
         size: Vector2(TileComponent.tileSize, triggerHeight),
       );

  @override
  void update(double dt) {
    super.update(dt);
    // Check if player is within trigger zone
    final game = findParent<HardHatGameActual>();
    if (game != null && !_triggered) {
      final playerX = game.player.position.x;
      if (playerX >= position.x && playerX <= position.x + size.x) {
        _triggered = true;
        onEnter(segmentId);
      }
    }
  }
}

// === PARALLAX BACKGROUND ===

class _BackgroundComponent extends PositionComponent
    with HasGameReference<HardHatGameActual> {
  final Vector2 gameSize;
  ui.Image? _bgImage;
  bool _imageLoaded = false;

  _BackgroundComponent({required this.gameSize})
    : super(position: Vector2.zero(), size: gameSize * 3, priority: -10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _bgImage = await Flame.images.load('sprites/game/background.png');
      _imageLoaded = true;
    } catch (e) {
      debugPrint('Background image failed to load: $e');
    }
  }

  @override
  void render(Canvas canvas) {
    final camX = game.camera.viewfinder.position.x;

    if (_imageLoaded && _bgImage != null) {
      _renderWithImage(canvas, camX);
    } else {
      _renderFallback(canvas, camX);
    }
  }

  void _renderWithImage(Canvas canvas, double camX) {
    final img = _bgImage!;
    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();

    // Sky gradient above the background image
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFB0E0E6)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y * 0.3));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y * 0.3), skyPaint);

    // Draw background image tiled with parallax (0.3x scroll)
    final parallax = camX * 0.3;
    final scale = gameSize.y / imgH; // Scale to fill screen height
    final scaledW = imgW * scale;

    // Determine how many tiles we need to cover visible area
    final startTile = ((parallax / scaledW).floor() - 1);
    final endTile = startTile + (size.x / scaledW).ceil() + 2;

    final src = Rect.fromLTWH(0, 0, imgW, imgH);
    for (int i = startTile; i <= endTile; i++) {
      final x = i * scaledW - parallax;
      final dst = Rect.fromLTWH(x, 0, scaledW, gameSize.y);
      canvas.drawImageRect(img, src, dst, Paint());
    }
  }

  void _renderFallback(Canvas canvas, double camX) {
    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1565C0), Color(0xFF64B5F6), Color(0xFFBBDEFB)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y * 0.7), skyPaint);

    // Simple buildings silhouette
    final bp = Paint()..color = const Color(0x33000000);
    for (int i = 0; i < 20; i++) {
      final x = i * 120.0 - camX * 0.3;
      final h = 60.0 + (i * 37 % 90);
      canvas.drawRect(Rect.fromLTWH(x, size.y * 0.65 - h, 80, h), bp);
    }
  }
}

// === BREAK PARTICLES ===

class _BreakParticleEffect extends PositionComponent {
  final Color color;
  double _timer = 0.0;
  static const double duration = 0.6;
  final List<_Particle> _particles = [];

  _BreakParticleEffect({required Vector2 position, required this.color})
    : super(position: position, size: Vector2.zero()) {
    final rng = Random();
    for (int i = 0; i < 10; i++) {
      final angle = rng.nextDouble() * 3.14159 * 2;
      final speed = 60.0 + rng.nextDouble() * 80.0;
      _particles.add(
        _Particle(
          velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 60),
          size: 2.0 + rng.nextDouble() * 4.0,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
      return;
    }
    for (final p in _particles) {
      p.position += p.velocity * dt;
      p.velocity.y += 300 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = 1.0 - (_timer / duration);
    final paint = Paint()..color = color.withValues(alpha: opacity);
    for (final p in _particles) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(p.position.x, p.position.y),
          width: p.size,
          height: p.size,
        ),
        paint,
      );
    }
  }
}

class _Particle {
  Vector2 position = Vector2.zero();
  final Vector2 velocity;
  final double size;
  _Particle({required this.velocity, required this.size});
}

// === STAR/IMPACT PARTICLES (Godot ball.gd spawn_star_particles) ===

class _StarParticleEffect extends PositionComponent {
  final Vector2 normal;
  double _timer = 0.0;
  static const double duration = 0.4;
  final List<_StarParticle> _stars = [];
  static final _rng = Random();

  _StarParticleEffect({required Vector2 position, required this.normal})
    : super(position: position, size: Vector2.zero()) {
    // Spawn 5-8 star particles in the direction of the normal
    final count = 5 + _rng.nextInt(4);
    for (int i = 0; i < count; i++) {
      final spread = (_rng.nextDouble() - 0.5) * 2.0; // -1 to 1
      final speed = 60 + _rng.nextDouble() * 120;
      // Perpendicular direction for spread
      final perpX = -normal.y;
      final perpY = normal.x;
      final vx = (normal.x + perpX * spread * 0.6) * speed;
      final vy = (normal.y + perpY * spread * 0.6) * speed;
      _stars.add(
        _StarParticle(
          velocity: Vector2(vx, vy),
          size: 2.0 + _rng.nextDouble() * 2.0,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
      return;
    }
    for (final s in _stars) {
      s.position += s.velocity * dt;
      s.velocity.y += 200 * dt; // Slight gravity
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_timer / duration).clamp(0.0, 1.0);
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final s in _stars) {
      final paint = Paint()..color = Color.fromRGBO(255, 255, 100, alpha * 0.9);
      // Draw small star shape (4-pointed)
      final cx = s.position.x;
      final cy = s.position.y;
      final r = s.size * (1.0 - progress * 0.5);
      final path = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r * 0.3, cy - r * 0.3)
        ..lineTo(cx + r, cy)
        ..lineTo(cx + r * 0.3, cy + r * 0.3)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r * 0.3, cy + r * 0.3)
        ..lineTo(cx - r, cy)
        ..lineTo(cx - r * 0.3, cy - r * 0.3)
        ..close();
      canvas.drawPath(path, paint);
    }
  }
}

class _StarParticle {
  Vector2 position = Vector2.zero();
  final Vector2 velocity;
  final double size;
  _StarParticle({required this.velocity, required this.size});
}

// === HUD ===

class _HudComponent extends PositionComponent
    with HasGameReference<HardHatGameActual> {
  @override
  void render(Canvas canvas) {
    // Controls hint
    final textPainter = TextPainter(
      text: const TextSpan(
        text:
            'WASD/Arrows: Move  |  Space: Jump  |  E/Z: Strike  |  ESC: Pause',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((game.size.x - textPainter.width) / 2, 8));

    // Level + State info
    final levelPainter = TextPainter(
      text: TextSpan(
        text:
            'Level ${game.currentLevelId}  |  Segment ${game.currentSegment + 1}/4  |  ${game.player.state.name}',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    levelPainter.layout();
    levelPainter.paint(
      canvas,
      Offset((game.size.x - levelPainter.width) / 2, 26),
    );

    // Ball timer bar
    if (game.player.ballReference != null) {
      _drawBallTimerBar(canvas);
    }
  }

  void _drawBallTimerBar(Canvas canvas) {
    const barWidth = 100.0;
    const barHeight = 8.0;
    final barX = game.size.x / 2 - barWidth / 2;
    const barY = 42.0;

    // Background
    final bgPaint = Paint()..color = const Color(0x66000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Fill (green to red gradient based on remaining time)
    final progress = (game.ballTimerRemaining / game.ballTimerMax).clamp(
      0.0,
      1.0,
    );
    final fillColor = Color.lerp(
      const Color(0xFFFF4444),
      const Color(0xFF44FF44),
      progress,
    )!;
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * progress, barHeight),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Label
    final label = TextPainter(
      text: const TextSpan(
        text: '⚾ BALL',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    label.layout();
    label.paint(canvas, Offset(barX - label.width - 6, barY - 1));
  }
}
