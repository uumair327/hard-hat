import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late AnimationController _buttonsAnimationController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _buttonsStaggerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _buttonsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Title animations
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Button stagger animation
    _buttonsStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsAnimationController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await _titleAnimationController.forward();
    await _buttonsAnimationController.forward();
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _buttonsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFF4682B4), // Steel blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              // Animated Game Title
              AnimatedBuilder(
                animation: _titleAnimationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _titleSlideAnimation,
                    child: FadeTransition(
                      opacity: _titleFadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'HARD HAT',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'HAVOC',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              
              // Animated Menu Buttons
              AnimatedBuilder(
                animation: _buttonsStaggerAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      _buildAnimatedButton(
                        text: 'PLAY',
                        delay: 0.0,
                        onPressed: () => _navigateToGame(context),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        text: 'SETTINGS',
                        delay: 0.2,
                        onPressed: () => _navigateToSettings(context),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        text: 'QUIT',
                        delay: 0.4,
                        onPressed: () => _showQuitDialog(context),
                      ),
                    ],
                  );
                },
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String text,
    required double delay,
    required VoidCallback onPressed,
  }) {
    final delayedAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsStaggerAnimation,
      curve: Interval(delay, (delay + 0.6).clamp(0.0, 1.0), curve: Curves.easeOut),
    ));

    return AnimatedBuilder(
      animation: delayedAnimation,
      builder: (context, child) {
        final animationValue = delayedAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: _MenuButton(
              text: text,
              onPressed: onPressed,
            ),
          ),
        );
      },
    );
  }

  void _navigateToGame(BuildContext context) {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Navigate with smooth transition
    context.go('/game?level=1');
  }

  void _navigateToSettings(BuildContext context) {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Navigate to settings
    context.go('/settings');
  }

  void _showQuitDialog(BuildContext context) {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Quit Game',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to quit?'),
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
              // Exit the application
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.orange,
      end: Colors.deepOrange,
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
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorAnimation.value,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}