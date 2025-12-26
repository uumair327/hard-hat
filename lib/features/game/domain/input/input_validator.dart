/// Input validator for ensuring input values are within acceptable ranges
class InputValidator {
  // Validation settings
  double _maxMovementSpeed = 1.0;
  double _minMovementThreshold = 0.01;
  bool _allowRapidInputs = true;
  double _maxInputRate = 60.0; // inputs per second
  
  // Rate limiting
  final Map<String, double> _lastInputTimes = {};
  
  /// Validate movement input
  double validateMovementInput(double input) {
    // Clamp to valid range
    final clampedInput = input.clamp(-_maxMovementSpeed, _maxMovementSpeed);
    
    // Apply minimum threshold
    if (clampedInput.abs() < _minMovementThreshold) {
      return 0.0;
    }
    
    // Rate limiting check
    if (!_allowRapidInputs && !_checkInputRate('movement')) {
      return 0.0;
    }
    
    return clampedInput;
  }
  
  /// Validate jump input
  bool validateJumpInput(bool input) {
    if (!input) return false;
    
    // Rate limiting check for jump spam prevention
    if (!_checkInputRate('jump')) {
      return false;
    }
    
    return true;
  }
  
  /// Validate aiming input
  bool validateAimingInput(bool input) {
    if (!input) return false;
    
    // Rate limiting check
    if (!_checkInputRate('aiming')) {
      return false;
    }
    
    return true;
  }
  
  /// Validate launch input
  bool validateLaunchInput(bool input) {
    if (!input) return false;
    
    // Rate limiting check for launch spam prevention
    if (!_checkInputRate('launch')) {
      return false;
    }
    
    return true;
  }
  
  /// Check input rate limiting
  bool _checkInputRate(String inputType) {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final lastTime = _lastInputTimes[inputType] ?? 0.0;
    
    final timeDelta = currentTime - lastTime;
    final minInterval = 1.0 / _maxInputRate;
    
    if (timeDelta >= minInterval) {
      _lastInputTimes[inputType] = currentTime;
      return true;
    }
    
    return false;
  }
  
  /// Configure validation settings
  void configure({
    double? maxMovementSpeed,
    double? minMovementThreshold,
    bool? allowRapidInputs,
    double? maxInputRate,
  }) {
    if (maxMovementSpeed != null) {
      _maxMovementSpeed = maxMovementSpeed.clamp(0.1, 10.0);
    }
    if (minMovementThreshold != null) {
      _minMovementThreshold = minMovementThreshold.clamp(0.0, 0.5);
    }
    if (allowRapidInputs != null) {
      _allowRapidInputs = allowRapidInputs;
    }
    if (maxInputRate != null) {
      _maxInputRate = maxInputRate.clamp(1.0, 120.0);
    }
  }
  
  /// Get current validation settings
  Map<String, dynamic> getSettings() {
    return {
      'maxMovementSpeed': _maxMovementSpeed,
      'minMovementThreshold': _minMovementThreshold,
      'allowRapidInputs': _allowRapidInputs,
      'maxInputRate': _maxInputRate,
    };
  }
  
  /// Load validation settings
  void loadSettings(Map<String, dynamic> settings) {
    configure(
      maxMovementSpeed: settings['maxMovementSpeed']?.toDouble(),
      minMovementThreshold: settings['minMovementThreshold']?.toDouble(),
      allowRapidInputs: settings['allowRapidInputs'],
      maxInputRate: settings['maxInputRate']?.toDouble(),
    );
  }
  
  /// Reset rate limiting timers
  void resetRateLimiting() {
    _lastInputTimes.clear();
  }
}