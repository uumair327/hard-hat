/// Segregated interfaces for pause functionality
/// Follows ISP - clients depend only on what they need

/// Manages pause state
abstract class IPauseStateManager {
  void pauseGame();
  void resumeGame();
  bool get isPaused;
}

/// Manages pause UI visibility
abstract class IPauseUIManager {
  void showPauseMenu();
  void hidePauseMenu();
  void togglePauseMenu();
  bool get isShown;
}

/// Handles pause menu actions
abstract class IPauseActionHandler {
  void setRestartCallback(void Function() callback);
  void setQuitCallback(void Function() callback);
}

/// Detects focus changes for auto-pause
abstract class IFocusChangeListener {
  void onFocusLost();
  void onFocusGained();
}

/// Coordinates pause functionality
abstract class IPauseCoordinator {
  void initialize();
  void dispose();
}