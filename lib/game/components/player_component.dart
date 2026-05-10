import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'ball_component.dart';
import 'shutter_component.dart';
import 'tile_component.dart';
import 'package:hard_hat/game/hard_hat_game.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';

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

  // Hitbox reference for death disable (Godot player.gd L86)
  RectangleHitbox? _hitbox;

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

  // Key state tracking for just_pressed / just_released (matching Godot)
  final Set<LogicalKeyboardKey> _prevPressedKeys = {};
  bool _strikeJustPressed = false;
  bool _strikeJustReleased = false;
  bool _jumpJustPressedFlag = false;
  bool _jumpJustReleasedFlag = false;

  // Respawn callback
  void Function()? onRespawn;
  void Function(double x)? onXUpdate;
  void Function(Vector2 direction)? onCameraShakeRequest;
  void Function(Vector2 position, Vector2 normal)? onStarParticles;

  // === SPRITE ANIMATION ===
  // Sprite sheets loaded from assets/images/sprites/game/player/
  final Map<String, _SpriteSheetData> _spriteSheets = {};
  String _currentAnim = 'idle';
  int _currentFrame = 0;
  double _animTimer = 0.0;
  bool _spritesLoaded = false;

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
    _hitbox = RectangleHitbox(size: Vector2(28, 44), position: Vector2(2, 2));
    add(_hitbox!);
    await _loadSprites();
  }

  Future<void> _loadSprites() async {
    try {
      // idle: 1500x1500, 3 cols x 3 rows (8 frames used), 12fps, loop
      _spriteSheets['idle'] = await _SpriteSheetData.load(
        'sprites/game/player/idle.png',
        3,
        3,
        8,
        12.0,
        true,
      );
      // run: 1500x2000, 3 cols x 4 rows (12 frames), 15fps, loop
      _spriteSheets['run'] = await _SpriteSheetData.load(
        'sprites/game/player/run.png',
        3,
        4,
        12,
        15.0,
        true,
      );
      // jump: 1000x1000, 2 cols x 2 rows (4 frames), 6fps, no loop
      _spriteSheets['jump'] = await _SpriteSheetData.load(
        'sprites/game/player/jump.png',
        2,
        2,
        4,
        6.0,
        false,
      );
      // peak: 1500x1000, 3 cols x 2 rows (6 frames), 12fps, loop
      _spriteSheets['peak'] = await _SpriteSheetData.load(
        'sprites/game/player/peak.png',
        3,
        2,
        6,
        12.0,
        true,
      );
      // fall: 1000x500, 2 cols x 1 row (2 frames), 3fps, loop
      _spriteSheets['fall'] = await _SpriteSheetData.load(
        'sprites/game/player/fall.png',
        2,
        1,
        2,
        3.0,
        true,
      );
      // aim: 1500x500, 3 cols x 1 row (3 frames), 24fps, no loop
      _spriteSheets['aim'] = await _SpriteSheetData.load(
        'sprites/game/player/aim.png',
        3,
        1,
        3,
        24.0,
        false,
      );
      // strike: 1050x1000, 2 cols x 2 rows (4 frames), 12fps, no loop
      _spriteSheets['strike'] = await _SpriteSheetData.load(
        'sprites/game/player/strike.png',
        2,
        2,
        4,
        12.0,
        false,
      );
      // death: single full image (1 frame), no anim
      _spriteSheets['death'] = await _SpriteSheetData.load(
        'sprites/game/player/death.png',
        1,
        1,
        1,
        0.0,
        false,
      );
      _spritesLoaded = true;
    } catch (e) {
      debugPrint('PlayerComponent: Error loading sprites: $e');
      _spritesLoaded = false;
    }
  }

  void _setAnimation(String animName) {
    if (_currentAnim != animName) {
      _currentAnim = animName;
      _currentFrame = 0;
      _animTimer = 0.0;
    }
  }

  // === STATE MACHINE (matching Godot _set_player_state) ===
  void _setPlayerState(PlayerState newState) {
    // Exit current state — skip transition if in death state
    if (_state == PlayerState.death) return;

    switch (_state) {
      case PlayerState.run:
        // Stop step sounds
        GameAudioManager.stopStepLoop();
        _stepSoundActive = false;
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
        GameAudioManager.playStepLoop();
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
        _hitbox?.collisionType = CollisionType.inactive; // Godot L86
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
    // Compute just pressed / just released before updating current keys
    final strikeKeys = {LogicalKeyboardKey.keyE, LogicalKeyboardKey.keyZ};
    final jumpKeys = {
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyW,
    };

    final wasStrike = _prevPressedKeys.any((k) => strikeKeys.contains(k));
    final isStrike = keysPressed.any((k) => strikeKeys.contains(k));
    if (isStrike && !wasStrike) _strikeJustPressed = true;
    if (!isStrike && wasStrike) _strikeJustReleased = true;

    final wasJump = _prevPressedKeys.any((k) => jumpKeys.contains(k));
    final isJump = keysPressed.any((k) => jumpKeys.contains(k));
    if (isJump && !wasJump) _jumpJustPressedFlag = true;
    if (!isJump && wasJump) _jumpJustReleasedFlag = true;

    _prevPressedKeys.clear();
    _prevPressedKeys.addAll(keysPressed);
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

  bool get _jumpHeld =>
      _isKeyPressed(LogicalKeyboardKey.space) ||
      _isKeyPressed(LogicalKeyboardKey.arrowUp) ||
      _isKeyPressed(LogicalKeyboardKey.keyW);

  bool get _strikeHeld =>
      _isKeyPressed(LogicalKeyboardKey.keyE) ||
      _isKeyPressed(LogicalKeyboardKey.keyZ);

  // === UPDATE LOOP (matching Godot _physics_process) ===
  @override
  void update(double dt) {
    super.update(dt);

    // Advance sprite animation
    if (_spritesLoaded) {
      final sheet = _spriteSheets[_currentAnim];
      if (sheet != null && sheet.fps > 0 && sheet.frameCount > 1) {
        _animTimer += dt;
        final frameDuration = 1.0 / sheet.fps;
        if (_animTimer >= frameDuration) {
          _animTimer -= frameDuration;
          _currentFrame++;
          if (_currentFrame >= sheet.frameCount) {
            _currentFrame = sheet.loop ? 0 : sheet.frameCount - 1;
          }
        }
      }
    }

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

    // Strike input handling (matching Godot player.gd L135-139)
    if (_strikeQueued && _strikeHeld) {
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

    // Step sound loop is handled via playStepLoop/stopStepLoop on state change.

    // Emit X update for camera
    onXUpdate?.call(position.x);

    // Clear just-pressed/released flags at end of frame
    _strikeJustPressed = false;
    _strikeJustReleased = false;
    _jumpJustPressedFlag = false;
    _jumpJustReleasedFlag = false;
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

    // Variable height jump — release jump key to stop ascending (Godot L199-200)
    if (_jumpJustReleasedFlag) {
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

    // Godot L213-214: just_pressed jump → queue
    if (_jumpJustPressedFlag) {
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

    // Godot L232-236
    if (_jumpHeld) {
      if (_isOnFloor) {
        _setPlayerState(PlayerState.jump);
      }
    } else {
      _setPlayerState(PlayerState.fall);
    }
    _handleStrike();
  }

  // Godot _aim_physics_process (L241-259)
  void _aimPhysicsProcess(double dt) {
    // Lock velocity during aim (Godot L71: velocity = Vector3.ZERO)
    velocity = Vector2.zero();

    // Update ball direction toward mouse (matching Godot ball.gd L73-93)
    if (ballReference != null && ballReference!.tracking) {
      // Convert mouse screen position to world position
      // mousePosition is in screen coords, ball position is in world coords
      final camPos = game.camera.viewfinder.position;
      final mouseWorld = game.mousePosition + camPos;
      final ballPos = ballReference!.position;
      final dir = mouseWorld - ballPos;
      if (dir.length2 > 1.0) {
        ballReference!.setDirection(dir.normalized());
      }
    }

    // Release ball when strike key is released (Godot L258)
    if (_strikeJustReleased && ballReference != null) {
      _shootBall();
    }
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

  // Godot L290-292: just_pressed jump
  void _handleJump() {
    if (_jumpJustPressedFlag) {
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

  // Godot _handle_strike (L310-351) — uses just_pressed
  void _handleStrike() {
    if (_strikeJustPressed && _canStrike) {
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
    )..onStarParticles = onStarParticles;

    game.world.add(ballReference!);
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
      _handleSolidCollision(other, intersectionPoints);
    } else if (other is ShutterComponent) {
      _handleSolidCollision(other, intersectionPoints);
    } else if (other is RetractingShutterComponent) {
      _handleSolidCollision(other, intersectionPoints);
    }
  }

  void _handleSolidCollision(PositionComponent solid, Set<Vector2> points) {
    if (points.isEmpty) return;

    // Calculate collision normal
    final solidCenter = solid.position + solid.size / 2;
    final playerCenter = position + Vector2(size.x / 2, -size.y / 2);
    final diff = playerCenter - solidCenter;

    // Determine collision side
    final overlapX = (size.x / 2 + solid.size.x / 2) - diff.x.abs();
    final overlapY = (size.y / 2 + solid.size.y / 2) - diff.y.abs();

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
    if (solid is TileComponent && solid.tileType == TileType.spike) {
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

    if (_spritesLoaded) {
      _renderSprite(canvas);
    } else {
      _renderFallback(canvas);
    }

    canvas.restore();
  }

  void _renderSprite(Canvas canvas) {
    // Map player state to animation name
    final animName = _getAnimForState(_state);
    _setAnimation(animName);

    final sheet = _spriteSheets[_currentAnim];
    if (sheet == null) {
      _renderFallback(canvas);
      return;
    }

    final frame = sheet.getFrame(_currentFrame);
    if (frame == null) {
      _renderFallback(canvas);
      return;
    }

    // Draw the sprite frame scaled to fit the component
    // Sprites are large (500x500) so we scale down to component size
    // Use a slightly larger render area to show the bat/sign tool
    final renderWidth = size.x * 2.2; // Extra width for bat
    final renderHeight = size.y * 1.6; // Extra height for hat
    final offsetX = -(renderWidth - size.x) / 2;
    final offsetY = -(renderHeight - size.y) * 0.55;

    final dst = Rect.fromLTWH(offsetX, offsetY, renderWidth, renderHeight);
    canvas.drawImageRect(sheet.image, frame, dst, Paint());
  }

  String _getAnimForState(PlayerState state) {
    switch (state) {
      case PlayerState.idle:
      case PlayerState.elevator:
        return 'idle';
      case PlayerState.run:
        return 'run';
      case PlayerState.jump:
      case PlayerState.jumpQueued:
        return 'jump';
      case PlayerState.fall:
        return 'fall';
      case PlayerState.coyoteTime:
        return 'peak';
      case PlayerState.aim:
        return 'aim';
      case PlayerState.strike:
        return 'strike';
      case PlayerState.death:
        return 'death';
    }
  }

  void _renderFallback(Canvas canvas) {
    // Simple colored rectangle fallback if sprites fail to load
    final bodyPaint = Paint()..color = const Color(0xFF4A90D9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
        const Radius.circular(4),
      ),
      bodyPaint,
    );
    // Hard hat
    final hatPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 0, size.x - 2, 8),
        const Radius.circular(3),
      ),
      hatPaint,
    );
  }
}

/// Helper class for sprite sheet data matching Godot's SpriteFrames
class _SpriteSheetData {
  final ui.Image image;
  final int columns;
  final int rows;
  final int frameCount;
  final double fps;
  final bool loop;
  final double frameWidth;
  final double frameHeight;

  _SpriteSheetData({
    required this.image,
    required this.columns,
    required this.rows,
    required this.frameCount,
    required this.fps,
    required this.loop,
    required this.frameWidth,
    required this.frameHeight,
  });

  static Future<_SpriteSheetData> load(
    String path,
    int cols,
    int rows,
    int frameCount,
    double fps,
    bool loop,
  ) async {
    final image = await Flame.images.load(path);
    final fw = image.width / cols;
    final fh = image.height / rows;
    return _SpriteSheetData(
      image: image,
      columns: cols,
      rows: rows,
      frameCount: frameCount,
      fps: fps,
      loop: loop,
      frameWidth: fw,
      frameHeight: fh,
    );
  }

  /// Get the source rectangle for a given frame index
  Rect? getFrame(int frameIndex) {
    if (frameIndex < 0 || frameIndex >= frameCount) return null;
    final col = frameIndex % columns;
    final row = frameIndex ~/ columns;
    return Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
  }
}
