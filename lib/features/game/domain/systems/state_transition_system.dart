import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../systems/game_system.dart';
import '../systems/game_state_manager.dart';
import '../interfaces/game_system_interfaces.dart';

/// System that handles state transition animations and effects
class StateTransitionSystem extends GameSystem implements IStateTransitionSystem {
  /// Game state manager for monitoring state changes
  GameStateManager? _gameStateManager;
  
  /// Current transition effect
  TransitionEffect? _currentTransition;
  
  /// Transition overlay component
  TransitionOverlay? _transitionOverlay;
  
  @override
  int get priority => 200; // High priority - render on top
  
  @override
  Future<void> initialize() async {
    // Create transition overlay
    _transitionOverlay = TransitionOverlay();
    add(_transitionOverlay!);
  }
  
  /// Set the game state manager for monitoring state changes
  void setGameStateManager(GameStateManager gameStateManager) {
    _gameStateManager = gameStateManager;
    
    // Register for state change callbacks
    _gameStateManager?.addStateChangeCallback(_onGameStateChanged);
  }
  
  /// Handle game state changes and trigger appropriate transitions
  void _onGameStateChanged(GameState newState, GameState? previousState) {
    if (previousState == null) return;
    
    final transitionType = _getTransitionType(previousState, newState);
    if (transitionType != null) {
      _startTransition(transitionType, newState, previousState);
    }
  }
  
  /// Determine the type of transition based on state change
  StateTransitionType? _getTransitionType(GameState from, GameState to) {
    // Define transition mappings
    final transitionMap = <String, StateTransitionType>{
      '${GameState.menu}_${GameState.playing}': StateTransitionType.fadeIn,
      '${GameState.playing}_${GameState.menu}': StateTransitionType.fadeOut,
      '${GameState.playing}_${GameState.paused}': StateTransitionType.blur,
      '${GameState.paused}_${GameState.playing}': StateTransitionType.unblur,
      '${GameState.playing}_${GameState.levelComplete}': StateTransitionType.zoomOut,
      '${GameState.levelComplete}_${GameState.playing}': StateTransitionType.zoomIn,
      '${GameState.playing}_${GameState.gameOver}': StateTransitionType.shake,
      '${GameState.gameOver}_${GameState.playing}': StateTransitionType.fadeIn,
      '${GameState.loading}_${GameState.playing}': StateTransitionType.slideIn,
      '${GameState.playing}_${GameState.loading}': StateTransitionType.slideOut,
    };
    
    return transitionMap['${from}_$to'];
  }
  
  /// Start a transition effect
  void _startTransition(StateTransitionType type, GameState newState, GameState previousState) {
    // Stop current transition if running
    _currentTransition?.stop();
    
    // Create new transition effect
    _currentTransition = TransitionEffect(
      type: type,
      duration: _getTransitionDuration(type),
      onComplete: () => _onTransitionComplete(newState, previousState),
    );
    
    // Apply transition to overlay
    _transitionOverlay?.startTransition(_currentTransition!);
  }
  
  /// Get transition duration based on type
  Duration _getTransitionDuration(StateTransitionType type) {
    switch (type) {
      case StateTransitionType.fadeIn:
      case StateTransitionType.fadeOut:
        return const Duration(milliseconds: 500);
      case StateTransitionType.blur:
      case StateTransitionType.unblur:
        return const Duration(milliseconds: 300);
      case StateTransitionType.zoomIn:
      case StateTransitionType.zoomOut:
        return const Duration(milliseconds: 800);
      case StateTransitionType.shake:
        return const Duration(milliseconds: 600);
      case StateTransitionType.slideIn:
      case StateTransitionType.slideOut:
        return const Duration(milliseconds: 400);
    }
  }
  
  /// Handle transition completion
  void _onTransitionComplete(GameState newState, GameState previousState) {
    _currentTransition = null;
    
    // Perform any post-transition cleanup
    switch (newState) {
      case GameState.playing:
        // Ensure game systems are active
        break;
      case GameState.paused:
        // Ensure game systems are paused
        break;
      case GameState.menu:
        // Clean up game state if needed
        break;
      default:
        break;
    }
  }
  
  @override
  void updateSystem(double dt) {
    _currentTransition?.update(dt);
  }
  
  /// Check if a transition is currently active
  bool get isTransitioning => _currentTransition != null && _currentTransition!.isActive;
  
  /// Get current transition progress (0.0 to 1.0)
  double get transitionProgress => _currentTransition?.progress ?? 0.0;
  
  @override
  void processStateTransitions(double dt) {
    updateSystem(dt);
  }

  @override
  void queueStateTransition(dynamic entity, dynamic newState) {
    // This is a simplified implementation for the interface
    // The actual state transitions are handled internally
  }

  @override
  void dispose() {
    _gameStateManager?.removeStateChangeCallback(_onGameStateChanged);
    _currentTransition?.stop();
    _currentTransition = null;
    super.dispose();
  }
}

/// Types of transition effects for game state changes
enum StateTransitionType {
  fadeIn,
  fadeOut,
  blur,
  unblur,
  zoomIn,
  zoomOut,
  shake,
  slideIn,
  slideOut,
}

/// Represents a transition effect
class TransitionEffect {
  final StateTransitionType type;
  final Duration duration;
  final VoidCallback? onComplete;
  
  double _progress = 0.0;
  bool _isActive = false;
  
  TransitionEffect({
    required this.type,
    required this.duration,
    this.onComplete,
  });
  
  /// Start the transition
  void start() {
    _isActive = true;
    _progress = 0.0;
  }
  
  /// Update the transition
  void update(double dt) {
    if (!_isActive) return;
    
    _progress += dt / (duration.inMilliseconds / 1000.0);
    
    if (_progress >= 1.0) {
      _progress = 1.0;
      _isActive = false;
      onComplete?.call();
    }
  }
  
  /// Stop the transition
  void stop() {
    _isActive = false;
    _progress = 0.0;
  }
  
  /// Get current progress (0.0 to 1.0)
  double get progress => _progress;
  
  /// Check if transition is active
  bool get isActive => _isActive;
  
  /// Get eased progress for smooth animations
  double get easedProgress {
    switch (type) {
      case StateTransitionType.fadeIn:
      case StateTransitionType.fadeOut:
        return _easeInOut(_progress);
      case StateTransitionType.blur:
      case StateTransitionType.unblur:
        return _easeOut(_progress);
      case StateTransitionType.zoomIn:
      case StateTransitionType.zoomOut:
        return _easeInOut(_progress);
      case StateTransitionType.shake:
        return _progress; // Linear for shake
      case StateTransitionType.slideIn:
      case StateTransitionType.slideOut:
        return _easeOut(_progress);
    }
  }
  
  /// Ease in-out function
  double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }
  
  /// Ease out function
  double _easeOut(double t) {
    return 1 - (1 - t) * (1 - t);
  }
}

/// Overlay component for rendering transition effects
class TransitionOverlay extends Component with HasGameRef {
  TransitionEffect? _currentTransition;
  
  /// Get the game size for rendering
  Vector2 get gameSize => gameRef.size;
  
  /// Start a transition effect
  void startTransition(TransitionEffect transition) {
    _currentTransition = transition;
    _currentTransition?.start();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _currentTransition?.update(dt);
    
    // Remove completed transitions
    if (_currentTransition != null && !_currentTransition!.isActive) {
      _currentTransition = null;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (_currentTransition == null) return;
    
    final transition = _currentTransition!;
    final progress = transition.easedProgress;
    
    // Render transition effect based on type
    switch (transition.type) {
      case StateTransitionType.fadeIn:
        _renderFade(canvas, 1.0 - progress);
        break;
      case StateTransitionType.fadeOut:
        _renderFade(canvas, progress);
        break;
      case StateTransitionType.blur:
        _renderBlur(canvas, progress);
        break;
      case StateTransitionType.unblur:
        _renderBlur(canvas, 1.0 - progress);
        break;
      case StateTransitionType.zoomIn:
        _renderZoom(canvas, 0.5 + (progress * 0.5));
        break;
      case StateTransitionType.zoomOut:
        _renderZoom(canvas, 1.0 + (progress * 0.5));
        break;
      case StateTransitionType.shake:
        _renderShake(canvas, progress);
        break;
      case StateTransitionType.slideIn:
        _renderSlide(canvas, 1.0 - progress);
        break;
      case StateTransitionType.slideOut:
        _renderSlide(canvas, progress);
        break;
    }
  }
  
  /// Render fade effect
  void _renderFade(Canvas canvas, double opacity) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity.clamp(0.0, 1.0));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      paint,
    );
  }
  
  /// Render blur effect (simplified as overlay)
  void _renderBlur(Canvas canvas, double intensity) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(intensity * 0.3);
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      paint,
    );
  }
  
  /// Render zoom effect (visual indicator)
  void _renderZoom(Canvas canvas, double scale) {
    // This would ideally affect the camera, but for now we'll show a visual indicator
    if (scale != 1.0) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.1);
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
        paint,
      );
    }
  }
  
  /// Render shake effect (visual indicator)
  void _renderShake(Canvas canvas, double intensity) {
    // Visual shake indicator
    final paint = Paint()
      ..color = Colors.red.withOpacity(intensity * 0.2);
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      paint,
    );
  }
  
  /// Render slide effect
  void _renderSlide(Canvas canvas, double offset) {
    final paint = Paint()
      ..color = Colors.black;
    
    final slideWidth = gameSize.x * offset;
    canvas.drawRect(
      Rect.fromLTWH(gameSize.x - slideWidth, 0, slideWidth, gameSize.y),
      paint,
    );
  }
}