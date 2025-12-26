import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Accessibility settings for input handling
class AccessibilitySettings {
  /// Enable sticky keys (keys stay pressed until pressed again)
  bool stickyKeys = false;
  
  /// Enable slow keys (delay before key press is registered)
  bool slowKeys = false;
  double slowKeyDelay = 0.5; // seconds
  
  /// Enable bounce keys (ignore rapid key presses)
  bool bounceKeys = false;
  double bounceKeyDelay = 0.1; // seconds
  
  /// Enable mouse keys (use keyboard to control mouse)
  bool mouseKeys = false;
  
  /// Enable high contrast mode for visual feedback
  bool highContrast = false;
  
  /// Enable sound feedback for input
  bool soundFeedback = false;
  
  /// Enable haptic feedback for touch input
  bool hapticFeedback = true;
  
  /// Touch target size multiplier
  double touchTargetMultiplier = 1.0;
  
  /// Input hold time for long press detection
  double longPressTime = 0.5; // seconds
  
  /// Enable one-handed mode for mobile
  bool oneHandedMode = false;
  
  /// Voice control enabled
  bool voiceControl = false;
  
  /// Switch control enabled (for external switches)
  bool switchControl = false;
  
  AccessibilitySettings({
    this.stickyKeys = false,
    this.slowKeys = false,
    this.slowKeyDelay = 0.5,
    this.bounceKeys = false,
    this.bounceKeyDelay = 0.1,
    this.mouseKeys = false,
    this.highContrast = false,
    this.soundFeedback = false,
    this.hapticFeedback = true,
    this.touchTargetMultiplier = 1.0,
    this.longPressTime = 0.5,
    this.oneHandedMode = false,
    this.voiceControl = false,
    this.switchControl = false,
  });
  
  /// Create from map
  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      stickyKeys: map['stickyKeys'] ?? false,
      slowKeys: map['slowKeys'] ?? false,
      slowKeyDelay: map['slowKeyDelay']?.toDouble() ?? 0.5,
      bounceKeys: map['bounceKeys'] ?? false,
      bounceKeyDelay: map['bounceKeyDelay']?.toDouble() ?? 0.1,
      mouseKeys: map['mouseKeys'] ?? false,
      highContrast: map['highContrast'] ?? false,
      soundFeedback: map['soundFeedback'] ?? false,
      hapticFeedback: map['hapticFeedback'] ?? true,
      touchTargetMultiplier: map['touchTargetMultiplier']?.toDouble() ?? 1.0,
      longPressTime: map['longPressTime']?.toDouble() ?? 0.5,
      oneHandedMode: map['oneHandedMode'] ?? false,
      voiceControl: map['voiceControl'] ?? false,
      switchControl: map['switchControl'] ?? false,
    );
  }
  
  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'stickyKeys': stickyKeys,
      'slowKeys': slowKeys,
      'slowKeyDelay': slowKeyDelay,
      'bounceKeys': bounceKeys,
      'bounceKeyDelay': bounceKeyDelay,
      'mouseKeys': mouseKeys,
      'highContrast': highContrast,
      'soundFeedback': soundFeedback,
      'hapticFeedback': hapticFeedback,
      'touchTargetMultiplier': touchTargetMultiplier,
      'longPressTime': longPressTime,
      'oneHandedMode': oneHandedMode,
      'voiceControl': voiceControl,
      'switchControl': switchControl,
    };
  }
}

/// Accessibility input handler for enhanced input accessibility
class AccessibilityInputHandler {
  AccessibilitySettings _settings = AccessibilitySettings();
  bool _enabled = false;
  
  // Sticky keys state
  final Set<LogicalKeyboardKey> _stickyKeysPressed = {};
  
  // Slow keys state
  final Map<LogicalKeyboardKey, double> _slowKeyTimers = {};
  
  // Bounce keys state
  final Map<LogicalKeyboardKey, double> _bounceKeyTimers = {};
  
  // Touch state for accessibility
  final Map<int, TouchAccessibilityState> _touchStates = {};
  
  /// Initialize accessibility handler
  Future<void> initialize() async {
    // Initialize accessibility features
  }
  
  /// Enable or disable accessibility features
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _clearAccessibilityState();
    }
  }
  
  /// Configure accessibility settings
  void configure(AccessibilitySettings settings) {
    _settings = settings;
  }
  
  /// Process keyboard input with accessibility features
  Set<LogicalKeyboardKey> processKeyboardInput(Set<LogicalKeyboardKey> pressedKeys) {
    if (!_enabled) return pressedKeys;
    
    Set<LogicalKeyboardKey> processedKeys = Set.from(pressedKeys);
    
    // Apply sticky keys
    if (_settings.stickyKeys) {
      processedKeys = _applyStickyKeys(processedKeys);
    }
    
    // Apply slow keys
    if (_settings.slowKeys) {
      processedKeys = _applySlowKeys(processedKeys);
    }
    
    // Apply bounce keys
    if (_settings.bounceKeys) {
      processedKeys = _applyBounceKeys(processedKeys);
    }
    
    return processedKeys;
  }
  
  /// Apply sticky keys functionality
  Set<LogicalKeyboardKey> _applyStickyKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final result = Set<LogicalKeyboardKey>.from(_stickyKeysPressed);
    
    for (final key in pressedKeys) {
      if (_stickyKeysPressed.contains(key)) {
        // Key was already sticky, remove it
        _stickyKeysPressed.remove(key);
        result.remove(key);
      } else {
        // New key press, make it sticky
        _stickyKeysPressed.add(key);
        result.add(key);
      }
    }
    
    return result;
  }
  
  /// Apply slow keys functionality
  Set<LogicalKeyboardKey> _applySlowKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final result = <LogicalKeyboardKey>{};
    
    // Update timers for currently pressed keys
    for (final key in pressedKeys) {
      if (!_slowKeyTimers.containsKey(key)) {
        _slowKeyTimers[key] = currentTime;
      }
      
      // Check if key has been held long enough
      if (currentTime - _slowKeyTimers[key]! >= _settings.slowKeyDelay) {
        result.add(key);
      }
    }
    
    // Clean up timers for released keys
    _slowKeyTimers.removeWhere((key, time) => !pressedKeys.contains(key));
    
    return result;
  }
  
  /// Apply bounce keys functionality
  Set<LogicalKeyboardKey> _applyBounceKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final result = <LogicalKeyboardKey>{};
    
    for (final key in pressedKeys) {
      final lastBounceTime = _bounceKeyTimers[key] ?? 0.0;
      
      // Check if enough time has passed since last bounce
      if (currentTime - lastBounceTime >= _settings.bounceKeyDelay) {
        result.add(key);
        _bounceKeyTimers[key] = currentTime;
      }
    }
    
    return result;
  }
  
  /// Process touch input with accessibility features
  Vector2 processTouchInput(Vector2 position) {
    if (!_enabled) return position;
    
    Vector2 processedPosition = position;
    
    // Apply touch target size multiplier
    if (_settings.touchTargetMultiplier != 1.0) {
      processedPosition = _applyTouchTargetMultiplier(processedPosition);
    }
    
    // Apply one-handed mode adjustments
    if (_settings.oneHandedMode) {
      processedPosition = _applyOneHandedMode(processedPosition);
    }
    
    return processedPosition;
  }
  
  /// Apply touch target size multiplier
  Vector2 _applyTouchTargetMultiplier(Vector2 position) {
    // This would typically involve expanding touch targets
    // For now, we'll just return the position as-is
    // In a real implementation, this would modify the effective touch area
    return position;
  }
  
  /// Apply one-handed mode adjustments
  Vector2 _applyOneHandedMode(Vector2 position) {
    // Adjust touch positions for one-handed use
    // This could involve shifting the effective touch area
    // or providing alternative input methods
    return position;
  }
  
  /// Handle long press detection
  bool isLongPress(int touchId, double currentTime) {
    final touchState = _touchStates[touchId];
    if (touchState == null) return false;
    
    return currentTime - touchState.startTime >= _settings.longPressTime;
  }
  
  /// Start tracking a touch
  void startTouchTracking(int touchId, Vector2 position) {
    _touchStates[touchId] = TouchAccessibilityState(
      startTime: DateTime.now().millisecondsSinceEpoch / 1000.0,
      startPosition: position,
    );
  }
  
  /// Stop tracking a touch
  void stopTouchTracking(int touchId) {
    _touchStates.remove(touchId);
  }
  
  /// Provide haptic feedback if enabled
  void provideHapticFeedback() {
    if (_enabled && _settings.hapticFeedback) {
      // Trigger haptic feedback
      // This would integrate with the platform's haptic feedback system
    }
  }
  
  /// Provide sound feedback if enabled
  void provideSoundFeedback(String feedbackType) {
    if (_enabled && _settings.soundFeedback) {
      // Trigger sound feedback
      // This would integrate with the audio system
    }
  }
  
  /// Get current accessibility settings
  AccessibilitySettings getSettings() {
    return _settings;
  }
  
  /// Load settings from map
  void loadSettings(Map<String, dynamic> settings) {
    _settings = AccessibilitySettings.fromMap(settings);
  }
  
  /// Clear accessibility state
  void _clearAccessibilityState() {
    _stickyKeysPressed.clear();
    _slowKeyTimers.clear();
    _bounceKeyTimers.clear();
    _touchStates.clear();
  }
  
  /// Update accessibility timers
  void update(double dt) {
    if (!_enabled) return;
    
    // Update slow key timers
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    
    // Clean up old bounce key timers
    _bounceKeyTimers.removeWhere((key, time) => 
        currentTime - time > _settings.bounceKeyDelay * 2);
    
    // Clean up old touch states
    _touchStates.removeWhere((id, state) => 
        currentTime - state.startTime > 10.0); // 10 second timeout
  }
  
  /// Dispose of accessibility handler
  void dispose() {
    _clearAccessibilityState();
  }
}

/// Touch accessibility state tracking
class TouchAccessibilityState {
  final double startTime;
  final Vector2 startPosition;
  
  TouchAccessibilityState({
    required this.startTime,
    required this.startPosition,
  });
}