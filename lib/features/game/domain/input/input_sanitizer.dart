import 'package:flame/components.dart';

/// Input sanitizer for cleaning and normalizing input values
class InputSanitizer {
  // Sanitization settings
  Vector2 _screenBounds = Vector2(800, 600);
  double _deadZone = 0.05;
  bool _enableSmoothing = true;
  double _smoothingFactor = 0.8;
  
  // Smoothing state
  double _lastMovementInput = 0.0;
  Vector2? _lastAimPosition;
  
  /// Sanitize movement input with deadzone and smoothing
  double sanitizeMovementInput(double input) {
    // Apply deadzone
    if (input.abs() < _deadZone) {
      input = 0.0;
    }
    
    // Apply smoothing if enabled
    if (_enableSmoothing) {
      input = _lastMovementInput * (1.0 - _smoothingFactor) + input * _smoothingFactor;
      _lastMovementInput = input;
    }
    
    // Normalize to -1.0 to 1.0 range
    return input.clamp(-1.0, 1.0);
  }
  
  /// Sanitize aim position to ensure it's within screen bounds
  Vector2 sanitizeAimPosition(Vector2 position) {
    // Clamp to screen bounds
    final clampedX = position.x.clamp(0.0, _screenBounds.x);
    final clampedY = position.y.clamp(0.0, _screenBounds.y);
    
    Vector2 sanitizedPosition = Vector2(clampedX, clampedY);
    
    // Apply smoothing if enabled
    if (_enableSmoothing && _lastAimPosition != null) {
      sanitizedPosition = _lastAimPosition! * (1.0 - _smoothingFactor) + 
                         sanitizedPosition * _smoothingFactor;
    }
    
    _lastAimPosition = sanitizedPosition;
    return sanitizedPosition;
  }
  
  /// Sanitize touch input with additional processing for mobile
  Vector2 sanitizeTouchInput(Vector2 position) {
    // Apply basic position sanitization
    Vector2 sanitized = sanitizeAimPosition(position);
    
    // Additional mobile-specific processing could go here
    // For example: palm rejection, pressure sensitivity, etc.
    
    return sanitized;
  }
  
  /// Sanitize gamepad input with deadzone handling
  double sanitizeGamepadInput(double input, {double? customDeadzone}) {
    final deadzone = customDeadzone ?? _deadZone;
    
    // Apply circular deadzone for analog sticks
    if (input.abs() < deadzone) {
      return 0.0;
    }
    
    // Scale input to account for deadzone
    final sign = input.sign;
    final scaledInput = (input.abs() - deadzone) / (1.0 - deadzone);
    
    return (scaledInput * sign).clamp(-1.0, 1.0);
  }
  
  /// Configure sanitization settings
  void configure({
    Vector2? screenBounds,
    double? deadZone,
    bool? enableSmoothing,
    double? smoothingFactor,
  }) {
    if (screenBounds != null) {
      _screenBounds = screenBounds;
    }
    if (deadZone != null) {
      _deadZone = deadZone.clamp(0.0, 0.5);
    }
    if (enableSmoothing != null) {
      _enableSmoothing = enableSmoothing;
    }
    if (smoothingFactor != null) {
      _smoothingFactor = smoothingFactor.clamp(0.0, 1.0);
    }
  }
  
  /// Get current sanitization settings
  Map<String, dynamic> getSettings() {
    return {
      'screenBounds': {'x': _screenBounds.x, 'y': _screenBounds.y},
      'deadZone': _deadZone,
      'enableSmoothing': _enableSmoothing,
      'smoothingFactor': _smoothingFactor,
    };
  }
  
  /// Load sanitization settings
  void loadSettings(Map<String, dynamic> settings) {
    if (settings.containsKey('screenBounds')) {
      final bounds = settings['screenBounds'];
      _screenBounds = Vector2(bounds['x']?.toDouble() ?? 800, bounds['y']?.toDouble() ?? 600);
    }
    
    configure(
      deadZone: settings['deadZone']?.toDouble(),
      enableSmoothing: settings['enableSmoothing'],
      smoothingFactor: settings['smoothingFactor']?.toDouble(),
    );
  }
  
  /// Reset smoothing state
  void resetSmoothing() {
    _lastMovementInput = 0.0;
    _lastAimPosition = null;
  }
  
  /// Update screen bounds (called when screen size changes)
  void updateScreenBounds(Vector2 newBounds) {
    _screenBounds = newBounds;
  }
}