import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Service for detecting focus loss and triggering auto-pause
@lazySingleton
class FocusDetector {
  static FocusDetector? _instance;
  static FocusDetector get instance => _instance ??= FocusDetector._();
  
  FocusDetector._();

  /// Callbacks for focus events
  final List<VoidCallback> _focusLostCallbacks = [];
  final List<VoidCallback> _focusGainedCallbacks = [];
  
  /// Timer for delayed auto-pause
  Timer? _autoPauseTimer;
  
  /// Duration to wait before auto-pausing
  final Duration autoPauseDelay = const Duration(milliseconds: 500);
  
  /// Whether focus detection is currently active
  bool _isActive = false;
  
  /// Current focus state
  bool _hasFocus = true;

  /// Initialize focus detection
  void initialize() {
    if (_isActive) return;
    
    _isActive = true;
    
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
    
    // Listen to system navigation events
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
  }

  /// Handle lifecycle messages from the system
  Future<String?> _handleLifecycleMessage(String? message) async {
    switch (message) {
      case 'AppLifecycleState.paused':
      case 'AppLifecycleState.inactive':
      case 'AppLifecycleState.hidden':
        _onFocusLost();
        break;
      case 'AppLifecycleState.resumed':
        _onFocusGained();
        break;
    }
    return null;
  }

  /// Called when the app loses focus
  void _onFocusLost() {
    if (!_hasFocus) return;
    
    _hasFocus = false;
    
    // Cancel any existing timer
    _autoPauseTimer?.cancel();
    
    // Start auto-pause timer
    _autoPauseTimer = Timer(autoPauseDelay, () {
      for (final callback in _focusLostCallbacks) {
        callback();
      }
    });
  }

  /// Called when the app gains focus
  void _onFocusGained() {
    if (_hasFocus) return;
    
    _hasFocus = true;
    
    // Cancel auto-pause timer if focus is regained quickly
    _autoPauseTimer?.cancel();
    
    for (final callback in _focusGainedCallbacks) {
      callback();
    }
  }

  /// Add a callback for focus lost events
  void addFocusLostCallback(VoidCallback callback) {
    _focusLostCallbacks.add(callback);
  }

  /// Remove a focus lost callback
  void removeFocusLostCallback(VoidCallback callback) {
    _focusLostCallbacks.remove(callback);
  }

  /// Add a callback for focus gained events
  void addFocusGainedCallback(VoidCallback callback) {
    _focusGainedCallbacks.add(callback);
  }

  /// Remove a focus gained callback
  void removeFocusGainedCallback(VoidCallback callback) {
    _focusGainedCallbacks.remove(callback);
  }

  /// Manually trigger focus lost (for testing or special cases)
  void triggerFocusLost() {
    _onFocusLost();
  }

  /// Manually trigger focus gained (for testing or special cases)
  void triggerFocusGained() {
    _onFocusGained();
  }

  /// Get current focus state
  bool get hasFocus => _hasFocus;

  /// Dispose resources
  void dispose() {
    _autoPauseTimer?.cancel();
    _focusLostCallbacks.clear();
    _focusGainedCallbacks.clear();
    _isActive = false;
  }
}

/// App lifecycle observer for focus detection
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final FocusDetector _focusDetector;

  _AppLifecycleObserver(this._focusDetector);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _focusDetector._onFocusLost();
        break;
      case AppLifecycleState.resumed:
        _focusDetector._onFocusGained();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
    }
  }
}