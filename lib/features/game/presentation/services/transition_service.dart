import 'package:flutter/material.dart';
import 'package:hard_hat/core/services/services.dart';
import 'package:hard_hat/features/game/presentation/overlays/overlays.dart';

/// Service for managing screen transitions in the game
/// Provides a high-level API for showing transition animations
class TransitionService {
  /// Transition system implementation
  TransitionSystemImpl? _transitionSystem;
  
  /// Current overlay entry
  OverlayEntry? _overlayEntry;
  
  /// Whether a transition is currently active
  bool _isActive = false;
  
  /// Build context for overlays
  BuildContext? _overlayContext;
  
  /// Ticker provider for animations
  final TickerProvider? vsync;
  
  /// Transition color
  final Color transitionColor;
  
  TransitionService({
    this.vsync,
    this.transitionColor = Colors.black,
  });
  
  /// Set the overlay context for showing transitions
  void setOverlayContext(BuildContext context) {
    _overlayContext = context;
  }
  
  /// Initialize the transition system
  void initialize({TickerProvider? tickerProvider}) {
    if (_transitionSystem == null) {
      final provider = tickerProvider ?? vsync;
      if (provider == null) {
        throw StateError('TickerProvider must be provided either in constructor or initialize()');
      }
      _transitionSystem = TransitionSystemImpl(
        vsync: provider,
        onTransitionStateChanged: _onTransitionStateChanged,
      );
    }
  }
  
  /// Callback when transition state changes
  void _onTransitionStateChanged() {
    // Can be used for additional logic when transition state changes
  }
  
  /// Show the transition overlay
  void _showOverlay() {
    if (_isActive || _overlayContext == null || _transitionSystem == null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => TransitionOverlay(
        animation: _transitionSystem!.animation,
        color: transitionColor,
      ),
    );
    
    Overlay.of(_overlayContext!).insert(_overlayEntry!);
    _isActive = true;
  }
  
  /// Hide the transition overlay
  void _hideOverlay() {
    if (!_isActive || _overlayEntry == null) return;
    
    _overlayEntry!.remove();
    _overlayEntry = null;
    _isActive = false;
  }
  
  /// Perform a pop-in animation (wipe from edges to center)
  Future<void> popIn() async {
    if (_transitionSystem == null) {
      throw StateError('TransitionService must be initialized before use. Call initialize() first.');
    }
    
    _showOverlay();
    await _transitionSystem!.popIn();
  }
  
  /// Perform a pop-out animation (wipe from center to edges)
  Future<void> popOut() async {
    if (_transitionSystem == null) return;
    
    await _transitionSystem!.popOut();
    _hideOverlay();
  }
  
  /// Wait for a specified duration during transition
  Future<void> wait({Duration duration = const Duration(milliseconds: 500)}) async {
    if (_transitionSystem == null) return;
    await _transitionSystem!.wait(duration: duration);
  }
  
  /// Perform a complete transition sequence: popIn -> wait -> popOut
  /// Useful for loading screens or level transitions
  Future<void> performTransition({
    Duration waitDuration = const Duration(milliseconds: 500),
    Future<void> Function()? onTransition,
  }) async {
    await popIn();
    
    if (onTransition != null) {
      await onTransition();
    }
    
    await wait(duration: waitDuration);
    await popOut();
  }
  
  /// Check if a transition is currently in progress
  bool get isTransitioning => _transitionSystem?.isTransitioning ?? false;
  
  /// Check if the overlay is currently active
  bool get isActive => _isActive;
  
  /// Dispose of resources
  void dispose() {
    _hideOverlay();
    _transitionSystem?.dispose();
    _transitionSystem = null;
  }
}
