import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'ball_component.dart';
import 'tile_component.dart';
import '../game/hard_hat_game_actual.dart';
import '../services/game_audio_manager.dart';

/// Player states matching Godot's PlayerState enum exactly
enum PlayerState {
  idle,
  run,
  jump,
  fall,
  coyoteTime,
  jumpQueued,
  aim,
  strike,
  death,
  elevator,
}

/// Player component — a direct Flame PositionComponent replicating Godot player.gd
class PlayerComponent extends PositionComponent
    with
        CollisionCallbacks,
        KeyboardHandler,
        HasGameReference<HardHatGameActual> {
  // === PHYSICS CONSTANTS (from Godot player.gd) ===
  static const double speed = 200.0; // SPEED = 5.0 scaled to pixels
  static const double jumpSpeed = 180.0; // JUMP_SPEED = 4.5 scaled
  static const double springFactor = 3.0; // SPRING_FACTOR
  static const double strikeBoost = 80.0; // STRIKE_BOOST = 2.0 scaled
  static const double gravityForce = 400.0; // GRAVITY = 1.0 scaled

  // === STATE ===
  PlayerState _state = PlayerState.idle;
  PlayerState get state => _state;
  double _inputDirection = 0.0;
  double _playerDirection = 1.0; // 1.0 = right, -1.0 = left
  bool _canStrike = true;
  bool _strikeQueued = false;
  bool _isOnSpring = false;
  double _yWhenAiming = 0.0; // ignore: unused_field - will be used for aim lock
  bool _isOnFloor = false;

  // Step sound loop
  double _stepTimer = 0.0;
  static const double _stepInterval = 0.28; // Time between footstep sounds
  bool _stepSoundActive = false;

  // Flip animation
  double _flipProgress =
      0.0; // 0.0 = facing right, 1.0 = facing left tween done
  double _targetFlip = 0.0;
  static const double _flipSpeed = 10.0;

  // Public accessors for HUD
  double get ballTimerRemaining => _ballTimer;
  double get ballTimerMax => ballTimerDuration;

  // Velocity
  Vector2 velocity = Vector2.zero();

  // Keyboard state
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Ball reference
  BallComponent? ballReference;

  // Timers
  double _coyoteTimer = 0.0;
  double _jumpQueueTimer = 0.0;
  double _ballTimer = 0.0;
  double _strikeCooldownTimer = 0.0;
  double _strikeQueueTimer = 0.0;
  double _deathTimer = 0.0;

  // Timer durations (from Godot)
  static const double coyoteTimeDuration = 0.1;
  static const double jumpQueueDuration = 0.15;
  static const double ballTimerDuration = 10.0;
  static const double strikeCooldownDuration = 0.3;
  static const double strikeQueueDuration = 0.5;
  static const double deathTimerDuration = 1.5;

  // Respawn callback
  void Function()? onRespawn;
  void Function(double x)? onXUpdate;
  void Function(Vector2 direction)? onCameraShakeRequest;

  // Colors per state for placeholder rendering
  static final Map<PlayerState, Color> _stateColors = {
    PlayerState.idle: const Color(0xFF4A90D9),
    PlayerState.run: const Color(0xFF50C878),
    PlayerState.jump: const Color(0xFFFFD700),
    PlayerState.fall: const Color(0xFFFF8C00),
    PlayerState.coyoteTime: const Color(0xFF00CED1),
    PlayerState.jumpQueued: const Color(0xFFFF69B4),
    PlayerState.aim: const Color(0xFFFF4444),
    PlayerState.strike: const Color(0xFF9B59B6),
    PlayerState.death: const Color(0xFF333333),
    PlayerState.elevator: const Color(0xFF888888),
  };

  PlayerComponent({
    required Vector2 position,
    this.onRespawn,
    this.onXUpdate,
    this.onCameraShakeRequest,
  }) : super(
         position: position,
         size: Vector2(32, 48), // Player is 32x48 pixels
         anchor: Anchor.bottomCenter,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(28, 44), position: Vector2(2, 2)));
  }

  // === STATE MACHINE (matching Godot _set_player_state) ===
  void _setPlayerState(PlayerState newState) {
    // Exit current state — skip transition if in death state
    if (_state == PlayerState.death) return;

    switch (_state) {
      case PlayerState.run:
        // Stop step sounds
        _stepSoundActive = false;
        _stepTimer = 0.0;
        break;
      case PlayerState.coyoteTime:
        _coyoteTimer = 0.0;
        break;
      case PlayerState.jumpQueued:
        _jumpQueueTimer = 0.0;
        break;
      case PlayerState.aim:
        // Re-enable floor collision
        break;
      case PlayerState.idle:
      case PlayerState.jump:
      case PlayerState.fall:
      case PlayerState.strike:
      case PlayerState.elevator:
      case PlayerState.death:
        break;
    }

    // Enter new state
    switch (newState) {
      case PlayerState.idle:
        break;
      case PlayerState.run:
        _stepSoundActive = true;
        _stepTimer = 0.0; // Play first step immediately
        break;
      case PlayerState.jump:
        if (_isOnSpring) {
          GameAudioManager.playBoing();
          velocity.y = -(jumpSpeed * springFactor);
        } else {
          velocity.y = -jumpSpeed;
        }
        break;
      case PlayerState.fall:
        break;
      case PlayerState.coyoteTime:
        _coyoteTimer = coyoteTimeDuration;
        break;
      case PlayerState.jumpQueued:
        _jumpQueueTimer = jumpQueueDuration;
        break;
      case PlayerState.aim:
        _ballTimer = ballTimerDuration;
        velocity = Vector2.zero();
        _yWhenAiming = position.y;
        break;
      case PlayerState.strike:
        _strikeCooldownTimer = strikeCooldownDuration;
        _canStrike = false;
        velocity.y = -strikeBoost;
        GameAudioManager.playStrike();
        break;
      case PlayerState.death:
        GameAudioManager.playDeath();
        _killBall();
        _deathTimer = deathTimerDuration;
        velocity = Vector2(0.0, -300.0); // Fly up then fall
        break;
      case PlayerState.elevator:
        _killBall();
        velocity = Vector2.zero();
        break;
    }

    _state = newState;
  }

  // === KEYBOARD HANDLING ===
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    return false;
  }

  bool _isKeyPressed(LogicalKeyboardKey key) => _pressedKeys.contains(key);

  bool get _moveLeftPressed =>
      _isKeyPressed(LogicalKeyboardKey.arrowLeft) ||
      _isKeyPressed(LogicalKeyboardKey.keyA);

  bool get _moveRightPressed =>
      _isKeyPressed(LogicalKeyboardKey.arrowRight) ||
      _isKeyPressed(LogicalKeyboardKey.keyD);

  bool get _jumpJustPressed =>
      _isKeyPressed(LogicalKeyboardKey.space) ||
      _isKeyPressed(LogicalKeyboardKey.arrowUp) ||
      _isKeyPressed(LogicalKeyboardKey.keyW);

  bool get _strikePressed =>
      _isKeyPressed(LogicalKeyboardKey.keyE) ||
      _isKeyPressed(LogicalKeyboardKey.keyZ);

  // === UPDATE LOOP (matching Godot _physics_process) ===
  @override
  void update(double dt) {
    super.update(dt);

    // Smooth flip animation (matching Godot player tween 0→π)
    _targetFlip = _playerDirection < 0 ? 1.0 : 0.0;
    if ((_flipProgress - _targetFlip).abs() > 0.01) {
      _flipProgress += (_targetFlip - _flipProgress) * _flipSpeed * dt;
    } else {
      _flipProgress = _targetFlip;
    }

    // Input direction
    _inputDirection = 0.0;
    if (_moveLeftPressed) _inputDirection -= 1.0;
    if (_moveRightPressed) _inputDirection += 1.0;

    // Update player direction for sprite flip
    if (_state != PlayerState.aim) {
      if (_inputDirection > 0.0) {
        _playerDirection = 1.0;
      } else if (_inputDirection < 0.0) {
        _playerDirection = -1.0;
      }
    }

    // Strike input handling
    if (_strikeQueued && _strikePressed) {
      _checkStrikeCondition();
    } else {
      _strikeQueued = false;
      _strikeQueueTimer = 0.0;
    }

    // Update timers
    _updateTimers(dt);

    // State-specific physics
    switch (_state) {
      case PlayerState.idle:
        _idlePhysicsProcess(dt);
        break;
      case PlayerState.run:
        _runPhysicsProcess(dt);
        break;
      case PlayerState.jump:
        _jumpPhysicsProcess(dt);
        break;
      case PlayerState.fall:
        _fallPhysicsProcess(dt);
        break;
      case PlayerState.coyoteTime:
        _coyoteTimePhysicsProcess(dt);
        break;
      case PlayerState.jumpQueued:
        _jumpQueuedPhysicsProcess(dt);
        break;
      case PlayerState.aim:
        _aimPhysicsProcess(dt);
        break;
      case PlayerState.strike:
        _strikePhysicsProcess(dt);
        break;
      case PlayerState.death:
        _deathPhysicsProcess(dt);
        break;
      case PlayerState.elevator:
        _elevatorPhysicsProcess(dt);
        break;
    }

    // Apply velocity (move_and_slide equivalent)
    position += velocity * dt;

    // Simple floor collision (will be replaced by real tilemap collision)
    _handleFloorCollision();

    // Step sound loop (matching Godot step audio loop)
    if (_stepSoundActive && _state == PlayerState.run) {
      _stepTimer -= dt;
      if (_stepTimer <= 0) {
        _stepTimer = _stepInterval;
        GameAudioManager.playSound('loop/loop_step.mp3');
      }
    }

    // Emit X update for camera
    onXUpdate?.call(position.x);
  }

  // === TIMER UPDATES ===
  void _updateTimers(double dt) {
    if (_coyoteTimer > 0) _coyoteTimer -= dt;
    if (_jumpQueueTimer > 0) _jumpQueueTimer -= dt;
    if (_strikeCooldownTimer > 0) {
      _strikeCooldownTimer -= dt;
      if (_strikeCooldownTimer <= 0) _canStrike = true;
    }
    if (_strikeQueueTimer > 0) {
      _strikeQueueTimer -= dt;
      if (_strikeQueueTimer <= 0 && _state == PlayerState.fall) {
        // Strike queue timed out
      }
    }
    if (_ballTimer > 0 && ballReference != null) {
      _ballTimer -= dt;
      if (_ballTimer <= 0) {
        _onBallTimerTimeout();
      }
    }
    if (_deathTimer > 0) {
      _deathTimer -= dt;
      if (_deathTimer <= 0) {
        onRespawn?.call();
      }
    }
  }

  // === STATE PHYSICS (matching Godot exactly) ===

  void _idlePhysicsProcess(double dt) {
    if (_inputDirection != 0.0) {
      _setPlayerState(PlayerState.run);
    }
    _handleJump();
    _handleCoyoteTime();
    _handleStrike();
  }

  void _runPhysicsProcess(double dt) {
    if (_inputDirection == 0.0) {
      _setPlayerState(PlayerState.idle);
    }
    _handleXMovement();
    _handleJump();
    _handleCoyoteTime();
    _handleStrike();
  }

  void _jumpPhysicsProcess(double dt) {
    _handleGravity(dt);
    _handleXMovement();

    // Variable height jump — release jump key to stop ascending
    if (!_jumpJustPressed && velocity.y < 0) {
      velocity.y = 0.0;
    }

    if (velocity.y >= 0.0) {
      _setPlayerState(PlayerState.fall);
    }
    _handleStrike();
  }

  void _fallPhysicsProcess(double dt) {
    _handleGravity(dt);
    _handleXMovement();
    _handleLand();

    if (_jumpJustPressed) {
      _setPlayerState(PlayerState.jumpQueued);
    }
    _handleStrike();
  }

  void _coyoteTimePhysicsProcess(double dt) {
    _handleGravity(dt);
    _handleXMovement();
    _handleJump();
    _handleLand();
    _handleStrike();
  }

  void _jumpQueuedPhysicsProcess(double dt) {
    _handleGravity(dt);
    _handleXMovement();
    _handleLand();

    if (_jumpJustPressed) {
      if (_isOnFloor) {
        _setPlayerState(PlayerState.jump);
      }
    } else {
      _setPlayerState(PlayerState.fall);
    }
    _handleStrike();
  }

  void _aimPhysicsProcess(double dt) {
    // Lock position during aim
    // Ball tracking is handled by BallComponent
  }

  void _strikePhysicsProcess(double dt) {
    if (_isOnFloor) {
      if (_inputDirection != 0.0) {
        _setPlayerState(PlayerState.run);
      } else {
        _setPlayerState(PlayerState.idle);
      }
    } else {
      _setPlayerState(PlayerState.fall);
    }
  }

  void _deathPhysicsProcess(double dt) {
    velocity.x = 0.0;
    _handleGravity(dt);
  }

  void _elevatorPhysicsProcess(double dt) {
    velocity = Vector2.zero();
  }

  // === HELPER METHODS (matching Godot helpers) ===

  void _handleGravity(double dt) {
    velocity.y += gravityForce * dt;
  }

  void _handleXMovement() {
    velocity.x = _inputDirection * speed;
  }

  void _handleJump() {
    if (_jumpJustPressed) {
      _setPlayerState(PlayerState.jump);
    }
  }

  void _handleLand() {
    if (_isOnFloor) {
      GameAudioManager.playLand();
      if (_inputDirection != 0.0) {
        _setPlayerState(PlayerState.run);
      } else {
        _setPlayerState(PlayerState.idle);
      }
    }
  }

  void _handleCoyoteTime() {
    if (!_isOnFloor) {
      _setPlayerState(PlayerState.coyoteTime);
    }
  }

  void _handleStrike() {
    if (_strikePressed && _canStrike) {
      if (ballReference != null) {
        _strikeQueued = true;
        _strikeQueueTimer = strikeQueueDuration;
        _checkStrikeCondition();
      } else {
        _spawnBall();
        _setPlayerState(PlayerState.aim);
      }
    }
  }

  void _checkStrikeCondition() {
    if (ballReference != null) {
      final ballPos = ballReference!.position;
      final playerCenter = position + Vector2(0, -24);
      final distSq = playerCenter.distanceToSquared(ballPos);

      if (distSq <= 6.0 * 40.0 * 40.0) {
        // scaled from Godot's 6.0
        _strikeQueued = false;
        _strikeQueueTimer = 0.0;
        _setPlayerState(PlayerState.aim);
        ballReference!.startTracking();
        _orientWithRespectToBall(); // Godot player.gd L372
      }
    }
  }

  void _spawnBall() {
    final ballOffset = Vector2(32.0 * _playerDirection, -32.0);
    final ballPos = position + ballOffset;

    ballReference = BallComponent(
      position: ballPos,
      onCameraShakeRequest: (dir) {
        onCameraShakeRequest?.call(dir);
      },
      onForceQuitAiming: () {
        if (_state == PlayerState.aim) {
          _shootBall();
        }
      },
    );

    game.add(ballReference!);
    _ballTimer = ballTimerDuration;
    ballReference!.startTracking();
  }

  void _shootBall() {
    _setPlayerState(PlayerState.strike);
    if (ballReference != null) {
      ballReference!.shoot();
      ballReference!.tracking = false;
      _orientWithRespectToBallDirection(); // Godot player.gd L386
      _ballTimer = ballTimerDuration;
    }
  }

  /// Face toward ball position (Godot player.gd _orient_with_respect_to_ball L391-397)
  void _orientWithRespectToBall() {
    if (ballReference == null) return;
    final relativeBallX = ballReference!.position.x - position.x;
    if (relativeBallX < -40.0 && _playerDirection == 1.0) {
      _playerDirection = -1.0;
    } else if (relativeBallX > 40.0 && _playerDirection == -1.0) {
      _playerDirection = 1.0;
    }
  }

  /// Face ball shoot direction (Godot player.gd _orient_with_respect_to_ball_direction L400-406)
  void _orientWithRespectToBallDirection() {
    if (ballReference == null) return;
    final ballDirX = ballReference!.directionVector.x;
    if (ballDirX < -0.16 && _playerDirection == 1.0) {
      _playerDirection = -1.0;
    } else if (ballDirX > 0.16 && _playerDirection == -1.0) {
      _playerDirection = 1.0;
    }
  }

  void _killBall() {
    if (ballReference != null) {
      ballReference!.kill();
      ballReference = null;
    }
  }

  void _onBallTimerTimeout() {
    _killBall();
    if (_state == PlayerState.aim) {
      if (_isOnFloor) {
        if (_inputDirection != 0.0) {
          _setPlayerState(PlayerState.run);
        } else {
          _setPlayerState(PlayerState.idle);
        }
      } else {
        _setPlayerState(PlayerState.fall);
      }
    }
  }

  // === SIMPLE FLOOR COLLISION (placeholder until tilemap) ===
  void _handleFloorCollision() {
    final gameHeight = game.size.y;
    final floorY = gameHeight - 64; // 64px from bottom as ground

    if (position.y >= floorY) {
      position.y = floorY;
      if (velocity.y > 0) velocity.y = 0;
      _isOnFloor = true;
    } else {
      _isOnFloor = false;
    }

    // Keep player in bounds horizontally
    if (position.x < 16) {
      position.x = 16;
      velocity.x = 0;
    }
  }

  // === Collision callbacks for tile collisions ===
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
    if (points.isEmpty) return;

    // Calculate collision normal
    final tileCenter = tile.position + tile.size / 2;
    final playerCenter = position + Vector2(size.x / 2, -size.y / 2);
    final diff = playerCenter - tileCenter;

    // Determine collision side
    final overlapX = (size.x / 2 + tile.size.x / 2) - diff.x.abs();
    final overlapY = (size.y / 2 + tile.size.y / 2) - diff.y.abs();

    if (overlapX < overlapY) {
      // Horizontal collision
      if (diff.x > 0) {
        position.x += overlapX;
      } else {
        position.x -= overlapX;
      }
      velocity.x = 0;
    } else {
      // Vertical collision
      if (diff.y > 0) {
        // Player is below tile (hitting head)
        position.y += overlapY;
        velocity.y = 0;
      } else {
        // Player is above tile (landing)
        position.y -= overlapY;
        if (velocity.y > 0) velocity.y = 0;
        _isOnFloor = true;
      }
    }

    // Check for spike collision
    if (tile.tileType == TileType.spike) {
      _setPlayerState(PlayerState.death);
    }
  }

  // === Public methods ===
  void setOnSpring(bool value) {
    _isOnSpring = value;
  }

  void enterElevator() {
    _setPlayerState(PlayerState.elevator);
  }

  // === RENDERING ===
  @override
  void render(Canvas canvas) {
    canvas.save();

    // Apply horizontal flip via scale (matching Godot tween rotation.y)
    final scaleX = 1.0 - 2.0 * _flipProgress; // 1.0→-1.0
    canvas.translate(size.x / 2, 0);
    canvas.scale(scaleX, 1.0);
    canvas.translate(-size.x / 2, 0);

    final color = _stateColors[_state] ?? const Color(0xFF4A90D9);

    // === BODY ===
    final bodyPaint = Paint()..color = color;
    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 14, size.x - 12, size.y - 24),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Legs (animated when running)
    final legPaint = Paint()..color = color.withValues(alpha: 0.85);
    final legOffset = _state == PlayerState.run
        ? math.sin(DateTime.now().millisecondsSinceEpoch * 0.015) * 4
        : 0.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.y - 14 + legOffset, 6, 14 - legOffset.abs()),
        const Radius.circular(2),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.x - 14,
          size.y - 14 - legOffset,
          6,
          14 - legOffset.abs(),
        ),
        const Radius.circular(2),
      ),
      legPaint,
    );

    // Arms
    final armPaint = Paint()..color = color.withValues(alpha: 0.9);
    if (_state == PlayerState.aim || _state == PlayerState.strike) {
      // Arms extended for strike
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x - 4, 18, 10, 5),
          const Radius.circular(2),
        ),
        armPaint,
      );
    } else {
      // Arms down
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 18, 5, 12),
          const Radius.circular(2),
        ),
        armPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x - 7, 18, 5, 12),
          const Radius.circular(2),
        ),
        armPaint,
      );
    }

    // === HEAD ===
    final headPaint = Paint()..color = const Color(0xFFFFDBAC); // Skin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 4, size.x - 12, 14),
        const Radius.circular(4),
      ),
      headPaint,
    );

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(size.x * 0.55, 10), 3.5, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.75, 10), 3.5, eyePaint);
    final pupilPaint = Paint()..color = const Color(0xFF222222);
    canvas.drawCircle(Offset(size.x * 0.57, 10), 1.8, pupilPaint);
    canvas.drawCircle(Offset(size.x * 0.77, 10), 1.8, pupilPaint);

    // === HARD HAT ===
    final hatPaint = Paint()..color = const Color(0xFFFFD700);
    // Brim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 2, size.x - 2, 6),
        const Radius.circular(3),
      ),
      hatPaint,
    );
    // Dome
    final domePaint = Paint()..color = const Color(0xFFFFC800);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, -2, size.x - 10, 8),
        const Radius.circular(4),
      ),
      domePaint,
    );
    // Hat stripe
    final stripePaint = Paint()..color = const Color(0xFFFF8C00);
    canvas.drawRect(Rect.fromLTWH(5, 3, size.x - 10, 2), stripePaint);

    // === OUTLINE ===
    final outlinePaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 14, size.x - 12, size.y - 24),
        const Radius.circular(4),
      ),
      outlinePaint,
    );

    // Death state overlay
    if (_state == PlayerState.death) {
      final xPaint = Paint()
        ..color = const Color(0xFFFF0000)
        ..strokeWidth = 3;
      // X eyes
      canvas.drawLine(
        Offset(size.x * 0.5, 7),
        Offset(size.x * 0.6, 13),
        xPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.6, 7),
        Offset(size.x * 0.5, 13),
        xPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.7, 7),
        Offset(size.x * 0.8, 13),
        xPaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.8, 7),
        Offset(size.x * 0.7, 13),
        xPaint,
      );
    }

    canvas.restore();
  }
}
