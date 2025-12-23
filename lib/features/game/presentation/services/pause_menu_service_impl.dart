import 'package:flutter/material.dart';
import 'package:hard_hat/features/game/domain/services/pause_menu_service.dart';
import 'package:hard_hat/features/game/presentation/overlays/pause_menu_overlay.dart';

/// Implementation of pause menu service using Flutter widgets
class PauseMenuServiceImpl implements PauseMenuService {
  /// Current overlay entry
  OverlayEntry? _overlayEntry;
  
  /// Whether the pause menu is currently shown
  bool _isShown = false;
  
  /// Build context for overlays
  BuildContext? _overlayContext;
  
  /// Callbacks for menu actions
  void Function()? _onRestart;
  void Function()? _onQuit;
  void Function()? _onResume;

  /// Set the overlay context for showing overlays
  void setOverlayContext(BuildContext context) {
    _overlayContext = context;
  }

  @override
  void showPauseMenu() {
    if (_isShown || _overlayContext == null) return;
    
    // Create overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => PauseMenuOverlay(
        onResume: _onResume ?? () {},
        onRestart: _onRestart ?? () {},
        onQuit: _onQuit ?? () {},
      ),
    );
    
    // Insert overlay
    Overlay.of(_overlayContext!).insert(_overlayEntry!);
    _isShown = true;
  }

  @override
  void hidePauseMenu() {
    if (!_isShown || _overlayEntry == null) return;
    
    _overlayEntry!.remove();
    _overlayEntry = null;
    _isShown = false;
  }

  @override
  bool get isShown => _isShown;

  @override
  void setOnRestart(void Function() callback) {
    _onRestart = callback;
  }

  @override
  void setOnQuit(void Function() callback) {
    _onQuit = callback;
  }

  @override
  void setOnResume(void Function() callback) {
    _onResume = callback;
  }

  /// Dispose resources
  void dispose() {
    hidePauseMenu();
  }
}