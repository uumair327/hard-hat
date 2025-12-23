class GameConstants {
  // Physics Constants
  static const double gravity = 980.0; // pixels per second squared
  static const double playerSpeed = 200.0; // pixels per second
  static const double jumpForce = 400.0; // pixels per second
  static const double ballSpeed = 300.0; // pixels per second
  static const double friction = 0.8;

  // Game Settings
  static const double targetFps = 60.0;
  static const int maxBalls = 3;
  static const double cameraFollowSpeed = 5.0;
  static const double screenShakeIntensity = 10.0;

  // Tile Properties
  static const double tileSize = 32.0;
  static const int scaffoldingDurability = 1;
  static const int timberDurability = 2;
  static const int brickDurability = 3;

  // Audio Settings
  static const double defaultSfxVolume = 1.0;
  static const double defaultMusicVolume = 0.7;

  // UI Constants
  static const double buttonHeight = 60.0;
  static const double menuSpacing = 20.0;
}