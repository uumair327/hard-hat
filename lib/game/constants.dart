/// Game physics constants matching Godot's values.
/// See GODOT_FLUTTER_PARITY.md §5 for full reference.

/// Player physics constants (from Godot player.gd)
class PlayerConstants {
  static const double speed = 200.0;         // SPEED = 5.0 scaled
  static const double jumpSpeed = 180.0;     // JUMP_SPEED = 4.5 scaled
  static const double springFactor = 3.0;    // SPRING_FACTOR
  static const double strikeBoost = 80.0;    // STRIKE_BOOST = 2.0 scaled
  static const double gravityForce = 400.0;  // GRAVITY = 1.0 scaled

  // Timer durations
  static const double coyoteTimeDuration = 0.1;
  static const double jumpQueueDuration = 0.15;
  static const double ballTimerDuration = 10.0;
  static const double strikeCooldownDuration = 0.3;
  static const double strikeQueueDuration = 0.5;
  static const double deathTimerDuration = 1.5;
  static const double stepInterval = 0.28;
}

/// Ball physics constants (from Godot ball.gd)
class BallConstants {
  static const double ballSpeed = 640.0;  // speed = 16.0 scaled
  static const double ballRadius = 10.0;
}

/// Camera constants
class CameraConstants {
  static const double backgroundRotationSpeed = 0.005;
  static const double cameraShakeDistance = 3.0;
  static const int cameraShakeDurationMs = 50;
}

/// Transition timing
class TransitionConstants {
  static const double popInDuration = 0.5;
  static const double popOutDuration = 0.5;
  static const double waitDuration = 0.5;
  static const double pauseMenuSlide = 0.2;
  static const double unpauseCountdownStep = 0.75; // 3 × 0.75s = 2.25s total
}
