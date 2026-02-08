import 'package:flutter/material.dart';
import 'transition_system.dart';

/// Implementation of the transition system
/// Manages screen transitions with pop-in/pop-out animations
class TransitionSystemImpl implements ITransitionSystem {
  final TickerProvider vsync;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isTransitioning = false;
  
  /// Callback to notify when transition state changes
  final VoidCallback? onTransitionStateChanged;
  
  TransitionSystemImpl({
    required this.vsync,
    this.onTransitionStateChanged,
  }) {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.addListener(_notifyStateChange);
  }
  
  void _notifyStateChange() {
    onTransitionStateChanged?.call();
  }
  
  @override
  bool get isTransitioning => _isTransitioning;
  
  /// Get the current animation value (0.0 to 1.0)
  double get animationValue => _animation.value;
  
  /// Get the animation for listening
  Animation<double> get animation => _animation;
  
  @override
  Future<void> popIn() async {
    _isTransitioning = true;
    await _controller.forward(from: 0.0);
  }
  
  @override
  Future<void> popOut() async {
    await _controller.reverse(from: 1.0);
    _isTransitioning = false;
  }
  
  @override
  Future<void> wait({Duration duration = const Duration(milliseconds: 500)}) async {
    await Future.delayed(duration);
  }
  
  @override
  void dispose() {
    _controller.removeListener(_notifyStateChange);
    _controller.dispose();
  }
}
