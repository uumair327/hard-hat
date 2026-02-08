/// Interface for the transition system
/// Provides screen transitions with pop-in/pop-out animations
abstract class ITransitionSystem {
  /// Perform pop-in animation (wipe from edges to center)
  /// Blocks the screen view during transition
  Future<void> popIn();
  
  /// Perform pop-out animation (wipe from center to edges)
  /// Reveals the screen after transition
  Future<void> popOut();
  
  /// Wait for a specified duration during transition
  /// Useful for holding the transition screen while loading
  Future<void> wait({Duration duration = const Duration(milliseconds: 500)});
  
  /// Check if a transition is currently in progress
  bool get isTransitioning;
  
  /// Dispose of resources
  void dispose();
}
