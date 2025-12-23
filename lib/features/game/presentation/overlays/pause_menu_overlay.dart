import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Pause menu overlay that appears over the game when paused
class PauseMenuOverlay extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback? onQuit;

  const PauseMenuOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    this.onQuit,
  });

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _overlayAnimationController;
  late AnimationController _menuAnimationController;
  late Animation<double> _overlayOpacityAnimation;
  late Animation<double> _menuScaleAnimation;
  late Animation<Offset> _menuSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Overlay fade animation
    _overlayOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.easeOut,
    ));

    // Menu scale animation
    _menuScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.elasticOut,
    ));

    // Menu slide animation
    _menuSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await _overlayAnimationController.forward();
    await _menuAnimationController.forward();
  }

  @override
  void dispose() {
    _overlayAnimationController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _overlayAnimationController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: _overlayOpacityAnimation.value),
            child: Center(
              child: AnimatedBuilder(
                animation: _menuAnimationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _menuSlideAnimation,
                    child: ScaleTransition(
                      scale: _menuScaleAnimation,
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pause title
                            Text(
                              'PAUSED',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Menu buttons
                            _PauseMenuButton(
                              text: 'RESUME',
                              icon: Icons.play_arrow,
                              color: Colors.green,
                              onPressed: () => _handleResume(context),
                            ),
                            const SizedBox(height: 16),
                            _PauseMenuButton(
                              text: 'RESTART',
                              icon: Icons.refresh,
                              color: Colors.orange,
                              onPressed: () => _handleRestart(context),
                            ),
                            const SizedBox(height: 16),
                            _PauseMenuButton(
                              text: 'QUIT TO MENU',
                              icon: Icons.home,
                              color: Colors.red,
                              onPressed: () => _handleQuit(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleResume(BuildContext context) {
    HapticFeedback.lightImpact();
    widget.onResume();
  }

  void _handleRestart(BuildContext context) {
    HapticFeedback.mediumImpact();
    _showConfirmDialog(
      context,
      title: 'Restart Level',
      message: 'Are you sure you want to restart the current level?',
      confirmText: 'Restart',
      onConfirm: widget.onRestart,
    );
  }

  void _handleQuit(BuildContext context) {
    HapticFeedback.mediumImpact();
    _showConfirmDialog(
      context,
      title: 'Quit to Menu',
      message: 'Are you sure you want to quit to the main menu?',
      confirmText: 'Quit',
      onConfirm: () {
        if (widget.onQuit != null) {
          widget.onQuit!();
        } else {
          context.go('/menu');
        }
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Individual button for the pause menu
class _PauseMenuButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PauseMenuButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_PauseMenuButton> createState() => _PauseMenuButtonState();
}

class _PauseMenuButtonState extends State<_PauseMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: widget.onPressed,
              icon: Icon(widget.icon),
              label: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}