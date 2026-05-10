import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';

/// Intro Comic screen — replicates Godot's comic system
/// Sequential panels telling the story of Hard Hat Havoc
class IntroComicScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const IntroComicScreen({super.key, required this.onComplete});

  @override
  State<IntroComicScreen> createState() => _IntroComicScreenState();
}

class _IntroComicScreenState extends State<IntroComicScreen>
    with SingleTickerProviderStateMixin {
  int _currentPanel = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _panels = [
    _ComicPanel(
      imagePath: 'assets/images/sprites/comic/intro_1.png',
      bgColor: Color(0xFF1A237E),
    ),
    _ComicPanel(
      imagePath: 'assets/images/sprites/comic/intro_2.png',
      bgColor: Color(0xFF4A148C),
    ),
    _ComicPanel(
      imagePath: 'assets/images/sprites/comic/intro_3.png',
      bgColor: Color(0xFFB71C1C),
    ),
    _ComicPanel(
      imagePath: 'assets/images/sprites/comic/intro_4.png',
      bgColor: Color(0xFF006064),
    ),
    _ComicPanel(
      imagePath: 'assets/images/sprites/comic/intro_5.png',
      bgColor: Color(0xFFE65100),
    ),
    _ComicPanel(
      imagePath: 'assets/images/sprites/comic/intro_6.png',
      bgColor: Color(0xFFF57F17),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPanel() {
    if (_currentPanel < _panels.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentPanel++);
        _fadeController.forward();
        // GameAudioManager.playComicLoad();
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousPanel() {
    if (_currentPanel > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentPanel--);
        _fadeController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = _panels[_currentPanel];

    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _nextPanel();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _previousPanel();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              widget.onComplete();
            }
          }
        },
        child: GestureDetector(
          onTap: _nextPanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  panel.bgColor,
                  panel.bgColor.withValues(alpha: 0.7),
                  const Color(0xFF000000),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: CustomPaint(painter: _HalftonePatternPainter()),
                  ),

                  // Panel content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Comic frame
                          Container(
                            width: 600,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFF0),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.black, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 20,
                                  offset: Offset(8, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              panel.imagePath,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none, // Pixel art style
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Panel indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _panels.length,
                              (i) => Container(
                                width: i == _currentPanel ? 24 : 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _currentPanel
                                      ? const Color(0xFFFFD700)
                                      : const Color(0x44FFFFFF),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Navigation hint
                          Text(
                            _currentPanel < _panels.length - 1
                                ? 'TAP or PRESS SPACE to continue  |  ESC to skip'
                                : 'TAP or PRESS SPACE to start!',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0x88FFFFFF),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Panel counter
                  Positioned(
                    bottom: 16,
                    right: 24,
                    child: Text(
                      '${_currentPanel + 1} / ${_panels.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0x88FFFFFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComicPanel {
  final String imagePath;
  final Color bgColor;

  const _ComicPanel({
    required this.imagePath,
    required this.bgColor,
  });
}

// Halftone dot pattern for comic book feel
class _HalftonePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x08FFFFFF);
    for (double x = 0; x < size.width; x += 12) {
      for (double y = 0; y < size.height; y += 12) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Outro/Credits screen — shown after completing Level 4
class OutroScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OutroScreen({super.key, required this.onComplete});

  @override
  State<OutroScreen> createState() => _OutroScreenState();
}

class _OutroScreenState extends State<OutroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    GameAudioManager.playOutroMusic();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _scrollController.forward();
    _scrollController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: widget.onComplete,
        child: KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              widget.onComplete();
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                return Center(
                  child: Transform.translate(
                    offset: Offset(0, 200 * (1 - _scrollController.value)),
                    child: Opacity(
                      opacity: _scrollController.value.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/sprites/comic/outro.png',
                            width: 600,
                            filterQuality: FilterQuality.none,
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'TAP or PRESS ANY KEY to return to menu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0x66FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
