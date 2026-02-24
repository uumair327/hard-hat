import 'package:flutter/material.dart';
import '../services/game_save_manager.dart';
import '../services/game_audio_manager.dart';

/// Main Menu screen — replicates Godot main_menu.gd
/// Title screen with Play/Config/Quit + Level Select overlay
class MainMenuScreen extends StatefulWidget {
  final void Function(int levelId) onPlayLevel;
  final void Function() onPlayIntro;
  final void Function() onPlayOutro;

  const MainMenuScreen({
    super.key,
    required this.onPlayLevel,
    required this.onPlayIntro,
    required this.onPlayOutro,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  int _currentSelection = 0;
  bool _showLevelSelect = false;
  int _highlightedLevel = 0;

  late AnimationController _barController;
  late AnimationController _silhouetteController;
  late AnimationController _levelSelectController;

  // Level unlock state
  bool _level2Unlocked = false;
  bool _level3Unlocked = false;
  bool _level4Unlocked = false;
  bool _endCardUnlocked = false;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _silhouetteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _levelSelectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loadUnlockState();
  }

  void _loadUnlockState() {
    setState(() {
      _level2Unlocked = GameSaveManager.level1Completed;
      _level3Unlocked = GameSaveManager.level2Completed;
      _level4Unlocked = GameSaveManager.level3Completed;
      _endCardUnlocked = GameSaveManager.level4Completed;
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    _silhouetteController.dispose();
    _levelSelectController.dispose();
    super.dispose();
  }

  void _onPlay() {
    if (GameSaveManager.introViewed) {
      _showLevelSelectOverlay();
    } else {
      widget.onPlayIntro();
    }
  }

  void _showLevelSelectOverlay() {
    setState(() {
      _showLevelSelect = true;
    });
    _levelSelectController.forward();
    GameAudioManager.playBlueprints();
  }

  void _hideLevelSelectOverlay() {
    _levelSelectController.reverse().then((_) {
      setState(() {
        _showLevelSelect = false;
      });
    });
    GameAudioManager.playBlueprints();
  }

  void _onLevelSelected(int levelId) {
    GameAudioManager.playConfirm();
    widget.onPlayLevel(levelId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Title & Buttons
          if (!_showLevelSelect) _buildTitleScreen(),

          // Level Select overlay
          if (_showLevelSelect) _buildLevelSelect(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B2A), // Dark navy
            Color(0xFF1B2838), // Steel blue dark
            Color(0xFF2D4A6F), // Medium blue
          ],
        ),
      ),
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _ConstructionPatternPainter(),
      ),
    );
  }

  Widget _buildTitleScreen() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          const Text(
            'HARD HAT',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD700),
              letterSpacing: 8,
              shadows: [
                Shadow(
                  color: Color(0xFF000000),
                  blurRadius: 10,
                  offset: Offset(3, 3),
                ),
                Shadow(color: Color(0xFFFF8C00), blurRadius: 20),
              ],
            ),
          ),
          const Text(
            'HAVOC',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF8C00),
              letterSpacing: 12,
              shadows: [
                Shadow(
                  color: Color(0xFF000000),
                  blurRadius: 8,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),

          // Menu buttons
          _MenuButton(
            text: 'PLAY',
            isSelected: _currentSelection == 0,
            onHover: () => setState(() => _currentSelection = 0),
            onPressed: _onPlay,
          ),
          const SizedBox(height: 16),
          _MenuButton(
            text: 'CONFIG',
            isSelected: _currentSelection == 1,
            onHover: () => setState(() => _currentSelection = 1),
            onPressed: () {}, // Placeholder
          ),
          const SizedBox(height: 16),
          _MenuButton(
            text: 'QUIT',
            isSelected: _currentSelection == 2,
            onHover: () => setState(() => _currentSelection = 2),
            onPressed: () {}, // Placeholder
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelect() {
    return GestureDetector(
      onTap: () {}, // Absorb taps
      child: Container(
        color: const Color(0xCC000000),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFD700),
                      size: 32,
                    ),
                    onPressed: _hideLevelSelectOverlay,
                  ),
                ),
              ),

              const Text(
                'SELECT LEVEL',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFD700),
                  letterSpacing: 6,
                  shadows: [Shadow(color: Color(0xFF000000), blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 40),

              // Level grid
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _LevelCard(
                        levelId: 1,
                        label: 'Level 1',
                        subtitle: 'The Foundations',
                        unlocked: true,
                        highlighted: _highlightedLevel == 0,
                        onHover: () => setState(() => _highlightedLevel = 0),
                        onPressed: () => _onLevelSelected(1),
                      ),
                      _LevelCard(
                        levelId: 2,
                        label: 'Level 2',
                        subtitle: 'Breaking Through',
                        unlocked: _level2Unlocked,
                        highlighted: _highlightedLevel == 1,
                        onHover: () => setState(() => _highlightedLevel = 1),
                        onPressed: _level2Unlocked
                            ? () => _onLevelSelected(2)
                            : null,
                      ),
                      _LevelCard(
                        levelId: 3,
                        label: 'Level 3',
                        subtitle: 'Spring Loaded',
                        unlocked: _level3Unlocked,
                        highlighted: _highlightedLevel == 2,
                        onHover: () => setState(() => _highlightedLevel = 2),
                        onPressed: _level3Unlocked
                            ? () => _onLevelSelected(3)
                            : null,
                      ),
                      _LevelCard(
                        levelId: 4,
                        label: 'Level 4',
                        subtitle: 'The Final Floor',
                        unlocked: _level4Unlocked,
                        highlighted: _highlightedLevel == 3,
                        onHover: () => setState(() => _highlightedLevel = 3),
                        onPressed: _level4Unlocked
                            ? () => _onLevelSelected(4)
                            : null,
                      ),
                      _LevelCard(
                        levelId: 0,
                        label: 'Intro',
                        subtitle: 'Story',
                        unlocked: true,
                        highlighted: _highlightedLevel == 4,
                        onHover: () => setState(() => _highlightedLevel = 4),
                        onPressed: widget.onPlayIntro,
                        isSpecial: true,
                      ),
                      _LevelCard(
                        levelId: 5,
                        label: 'End',
                        subtitle: 'Credits',
                        unlocked: _endCardUnlocked,
                        highlighted: _highlightedLevel == 5,
                        onHover: () => setState(() => _highlightedLevel = 5),
                        onPressed: _endCardUnlocked ? widget.onPlayOutro : null,
                        isSpecial: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual menu button with hover animation
class _MenuButton extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onHover;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.isSelected,
    required this.onHover,
    required this.onPressed,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        widget.onHover();
      },
      onExit: (_) {},
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0x33FFD700)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFFFFD700)
                  : const Color(0x44FFFFFF),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          transform: Matrix4.identity()..rotateZ(widget.isSelected ? -0.02 : 0),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isSelected
                  ? const Color(0xFFFFD700)
                  : const Color(0xAAFFFFFF),
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Level card for level select grid
class _LevelCard extends StatefulWidget {
  final int levelId;
  final String label;
  final String subtitle;
  final bool unlocked;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback? onPressed;
  final bool isSpecial;

  const _LevelCard({
    required this.levelId,
    required this.label,
    required this.subtitle,
    required this.unlocked,
    required this.highlighted,
    required this.onHover,
    this.onPressed,
    this.isSpecial = false,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  @override
  Widget build(BuildContext context) {
    final isActive = widget.unlocked && widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) {
        if (isActive) widget.onHover();
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          height: 120,
          decoration: BoxDecoration(
            color: isActive
                ? (widget.highlighted
                      ? const Color(0x44FFD700)
                      : const Color(0x22FFFFFF))
                : const Color(0x11FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.highlighted && isActive
                  ? const Color(0xFFFFD700)
                  : isActive
                  ? const Color(0x44FFFFFF)
                  : const Color(0x22FFFFFF),
              width: widget.highlighted ? 2 : 1,
            ),
          ),
          transform: Matrix4.identity()
            ..rotateZ(widget.highlighted && isActive ? -0.05 : 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSpecial
                    ? Icons.movie
                    : (isActive ? Icons.construction : Icons.lock),
                color: isActive
                    ? const Color(0xFFFFD700)
                    : const Color(0x66FFFFFF),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x66FFFFFF),
                ),
              ),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? const Color(0xAAFFFFFF)
                      : const Color(0x44FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Background pattern painter for construction theme
class _ConstructionPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08FFFFFF)
      ..strokeWidth = 1.0;

    // Diagonal lines for blueprint feel
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Grid dots
    final dotPaint = Paint()..color = const Color(0x0AFFFFFF);
    for (double x = 0; x < size.width; x += 20) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
