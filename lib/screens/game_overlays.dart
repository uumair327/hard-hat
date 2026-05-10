import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';

/// Screen Transition — replicates Godot transition.gd
/// Pop-in/pop-out transition with rotating construction sign.
class ScreenTransition extends StatefulWidget {
  final Widget child;
  final bool visible;
  final VoidCallback? onPoppedIn;
  final VoidCallback? onPoppedOut;

  const ScreenTransition({
    super.key,
    required this.child,
    this.visible = false,
    this.onPoppedIn,
    this.onPoppedOut,
  });

  @override
  State<ScreenTransition> createState() => ScreenTransitionState();
}

class ScreenTransitionState extends State<ScreenTransition>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation = Tween<double>(
      begin: -1.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _rotationAnimation = Tween<double>(
      begin: 0.15,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onPoppedIn?.call();
      } else if (status == AnimationStatus.dismissed) {
        widget.onPoppedOut?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void popIn() {
    // Randomize rotation direction
    final rot = _rng.nextDouble() * 0.15 + 0.05;
    final sign = _rng.nextBool() ? 1.0 : -1.0;
    _rotationAnimation = Tween<double>(
      begin: rot * sign,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    GameAudioManager.playTransitionIn();
    _controller.forward(from: 0.0);
  }

  void popOut() {
    GameAudioManager.playTransitionOut();
    _controller.reverse(from: 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed) return const SizedBox.shrink();

        return Stack(
          children: [
            // Black fade background
            Opacity(
              opacity: _fadeAnimation.value,
              child: Container(color: Colors.black),
            ),

            // Construction sign overlay
            Center(
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value * 400),
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Image.asset(
                    'assets/images/sprites/game/transition.png',
                    width: 300,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Pause Menu Overlay — replicates Godot pause_menu.gd
/// Blueprint-style slide-in with Resume/Restart/Quit and 3-2-1 countdown
class PauseMenuOverlay extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const PauseMenuOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  State<PauseMenuOverlay> createState() => PauseMenuOverlayState();
}

class PauseMenuOverlayState extends State<PauseMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _countdownController;
  int _highlightedButton = 0;
  bool _showCountdown = false;
  int _countdownValue = 3;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2250), // 3 × 0.75s
    );

    _slideController.forward();
    GameAudioManager.playBlueprints();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _onResume() {
    // Start countdown
    setState(() {
      _showCountdown = true;
      _countdownValue = 3;
    });

    // Slide out
    _slideController.reverse();

    // Countdown sequence
    GameAudioManager.playTick();
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() => _countdownValue = 2);
        GameAudioManager.playTick();
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _countdownValue = 1);
        GameAudioManager.playTick();
      }
    });
    Future.delayed(const Duration(milliseconds: 2250), () {
      if (mounted) {
        setState(() => _showCountdown = false);
        GameAudioManager.playConfirm();
        widget.onResume();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Stack(
          children: [
            // Dim background
            Opacity(
              opacity: _slideController.value * 0.6,
              child: Container(color: const Color(0xFF002D4A)),
            ),

            // Pause menu panel
            if (!_showCountdown)
              Positioned(
                left: -500 + _slideController.value * 500,
                top: 0,
                bottom: 0,
                width: 400,
                child: Opacity(
                  opacity: _slideController.value,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF0D2137), Color(0xFF1B3A5C)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/sprites/ui/paused.png',
                          height: 60,
                          filterQuality: FilterQuality.none,
                        ),
                        const SizedBox(height: 40),
                        _PauseButton(
                          imagePath: 'assets/images/sprites/ui/resume.png',
                          isHighlighted: _highlightedButton == 0,
                          onHover: () => setState(() => _highlightedButton = 0),
                          onPressed: _onResume,
                        ),
                        const SizedBox(height: 16),
                        _PauseButton(
                          imagePath: 'assets/images/sprites/ui/restart.png',
                          isHighlighted: _highlightedButton == 1,
                          onHover: () => setState(() => _highlightedButton = 1),
                          onPressed: widget.onRestart,
                        ),
                        const SizedBox(height: 16),
                        _PauseButton(
                          imagePath: 'assets/images/sprites/ui/quit.png',
                          isHighlighted: _highlightedButton == 2,
                          onHover: () => setState(() => _highlightedButton = 2),
                          onPressed: widget.onQuit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Countdown display
            if (_showCountdown)
              Center(
                child: Image.asset(
                  'assets/images/sprites/ui/$_countdownValue.png',
                  height: 150,
                  filterQuality: FilterQuality.none,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String imagePath;
  final bool isHighlighted;
  final VoidCallback onHover;
  final VoidCallback onPressed;

  const _PauseButton({
    required this.imagePath,
    required this.isHighlighted,
    required this.onHover,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0x33FFD700) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFFFD700)
                  : const Color(0x33FFFFFF),
            ),
          ),
          transform: Matrix4.identity()..rotateZ(isHighlighted ? -0.03 : 0),
          child: Opacity(
            opacity: isHighlighted ? 1.0 : 0.6,
            child: Image.asset(
              imagePath,
              height: 30,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Level Splash overlay — replicates Godot splash.gd
/// Shows the level name briefly at the start of each level
class LevelSplash extends StatefulWidget {
  final int levelId;
  final VoidCallback? onComplete;

  const LevelSplash({super.key, required this.levelId, this.onComplete});

  @override
  State<LevelSplash> createState() => LevelSplashState();
}

class LevelSplashState extends State<LevelSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    _rotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLevelName(int id) {
    switch (id) {
      case 1:
        return 'THE FOUNDATIONS';
      case 2:
        return 'BREAKING THROUGH';
      case 3:
        return 'SPRING LOADED';
      case 4:
        return 'THE FINAL FLOOR';
      default:
        return 'LEVEL $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _fadeIn.value * _fadeOut.value;
        if (opacity <= 0) return const SizedBox.shrink();

        return Opacity(
          opacity: opacity,
          child: Center(
            child: Transform.rotate(
              angle: _rotation.value,
              child: Image.asset(
                'assets/images/sprites/splash/level_${widget.levelId}.png',
                width: 600,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 20),
                    ],
                  ),
                  child: Text(
                    'LEVEL ${widget.levelId}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
