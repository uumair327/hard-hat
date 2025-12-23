/// Abstract service for managing pause menu functionality
/// This interface belongs in the domain layer and is implemented in presentation
abstract class PauseMenuService {
  /// Show the pause menu
  void showPauseMenu();
  
  /// Hide the pause menu
  void hidePauseMenu();
  
  /// Check if pause menu is currently shown
  bool get isShown;
  
  /// Set callback for restart action
  void setOnRestart(void Function() callback);
  
  /// Set callback for quit action
  void setOnQuit(void Function() callback);
  
  /// Set callback for resume action
  void setOnResume(void Function() callback);
}