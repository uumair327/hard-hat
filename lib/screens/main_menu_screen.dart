import 'package:flutter/material.dart';
import 'package:hard_hat/save/game_save_manager.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';

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
    return SizedBox.expand(
      child: Image.asset(
        'assets/images/sprites/level_select/background.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
      ),
    );
  }

  Widget _buildTitleScreen() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale factor for small screens (e.g. Android landscape ~411px)
          final h = constraints.maxHeight;
          final compact = h < 500;
          final titleSize = compact ? 48.0 : 72.0;
          final subtitleSize = compact ? 32.0 : 48.0;
          final gap = compact ? 20.0 : 60.0;
          final silhouetteSize = compact ? 120.0 : 200.0;
          final menuHeight = compact ? 170.0 : 230.0;
          final btnHeight = compact ? 46.0 : 62.0;
          final btnSpacing = compact ? 12.0 : 16.0;
          final barStep = btnHeight + btnSpacing;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'HARD HAT',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 8,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF000000),
                      blurRadius: 10,
                      offset: Offset(3, 3),
                    ),
                    Shadow(color: Color(0xFFFF8C00), blurRadius: 20),
                  ],
                ),
              ),
              Text(
                'HAVOC',
                style: TextStyle(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF8C00),
                  letterSpacing: 12,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF000000),
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),

              // Menu buttons wrapped in Stack for sliding bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Silhouette Twirl (Godot background_set.gd)
                  AnimatedBuilder(
                    animation: _silhouetteController,
                    builder: (context, child) {
                      String currentSilhouette = 'assets/images/sprites/ui/play_silhouette.png';
                      if (_currentSelection == 1) currentSilhouette = 'assets/images/sprites/ui/config_silhouette.png';
                      if (_currentSelection == 2) currentSilhouette = 'assets/images/sprites/ui/quit_silhouette.png';

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_silhouetteController.value * 2 * 3.14159),
                        alignment: Alignment.center,
                        child: Image.asset(
                          currentSilhouette,
                          height: silhouetteSize,
                          filterQuality: FilterQuality.none,
                          color: const Color(0x44FFFFFF),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: compact ? 40 : 80),
                  // Menu selection
                  SizedBox(
                    width: 280,
                    height: menuHeight,
                    child: Stack(
                      children: [
                        // Sliding bar
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          left: 0,
                          top: _currentSelection * barStep,
                          child: Image.asset(
                            'assets/images/sprites/ui/bar.png',
                            width: 280,
                            height: btnHeight,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                        // Buttons
                        Column(
                          children: [
                            _MenuButton(
                              imagePath: 'assets/images/sprites/ui/play.png',
                              silhouettePath: 'assets/images/sprites/ui/play_silhouette.png',
                              isSelected: _currentSelection == 0,
                              height: btnHeight,
                              onHover: () {
                                if (_currentSelection != 0) {
                                  setState(() => _currentSelection = 0);
                                  _silhouetteController.forward(from: 0.0);
                                }
                              },
                              onPressed: _onPlay,
                            ),
                            SizedBox(height: btnSpacing),
                            _MenuButton(
                              imagePath: 'assets/images/sprites/ui/config.png',
                              silhouettePath: 'assets/images/sprites/ui/config_silhouette.png',
                              isSelected: _currentSelection == 1,
                              height: btnHeight,
                              onHover: () {
                                if (_currentSelection != 1) {
                                  setState(() => _currentSelection = 1);
                                  _silhouetteController.forward(from: 0.0);
                                }
                              },
                              onPressed: () {},
                            ),
                            SizedBox(height: btnSpacing),
                            _MenuButton(
                              imagePath: 'assets/images/sprites/ui/quit.png',
                              silhouettePath: 'assets/images/sprites/ui/quit_silhouette.png',
                              isSelected: _currentSelection == 2,
                              height: btnHeight,
                              onHover: () {
                                if (_currentSelection != 2) {
                                  setState(() => _currentSelection = 2);
                                  _silhouetteController.forward(from: 0.0);
                                }
                              },
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLevelSelect() {
    return GestureDetector(
      onTap: () {}, // Absorb taps
      child: Container(
        color: const Color(0xAA000000), // Darken the background slightly for readability
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

              Image.asset(
                'assets/images/sprites/level_select/level_select.png',
                height: 40,
                filterQuality: FilterQuality.none,
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
                        imagePath: 'assets/images/sprites/level_select/1.png',
                        unlocked: true,
                        highlighted: _highlightedLevel == 0,
                        onHover: () => setState(() => _highlightedLevel = 0),
                        onPressed: () => _onLevelSelected(1),
                      ),
                      _LevelCard(
                        levelId: 2,
                        imagePath: 'assets/images/sprites/level_select/2.png',
                        unlocked: _level2Unlocked,
                        highlighted: _highlightedLevel == 1,
                        onHover: () => setState(() => _highlightedLevel = 1),
                        onPressed: _level2Unlocked
                            ? () => _onLevelSelected(2)
                            : null,
                      ),
                      _LevelCard(
                        levelId: 3,
                        imagePath: 'assets/images/sprites/level_select/3.png',
                        unlocked: _level3Unlocked,
                        highlighted: _highlightedLevel == 2,
                        onHover: () => setState(() => _highlightedLevel = 2),
                        onPressed: _level3Unlocked
                            ? () => _onLevelSelected(3)
                            : null,
                      ),
                      _LevelCard(
                        levelId: 4,
                        imagePath: 'assets/images/sprites/level_select/4.png',
                        unlocked: _level4Unlocked,
                        highlighted: _highlightedLevel == 3,
                        onHover: () => setState(() => _highlightedLevel = 3),
                        onPressed: _level4Unlocked
                            ? () => _onLevelSelected(4)
                            : null,
                      ),
                      _LevelCard(
                        levelId: 0,
                        imagePath: 'assets/images/sprites/level_select/intro comic.png',
                        unlocked: true,
                        highlighted: _highlightedLevel == 4,
                        onHover: () => setState(() => _highlightedLevel = 4),
                        onPressed: widget.onPlayIntro,
                      ),
                      _LevelCard(
                        levelId: 5,
                        imagePath: 'assets/images/sprites/level_select/end_card.png',
                        unlocked: _endCardUnlocked,
                        highlighted: _highlightedLevel == 5,
                        onHover: () => setState(() => _highlightedLevel = 5),
                        onPressed: _endCardUnlocked ? widget.onPlayOutro : null,
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
  final String imagePath;
  final String silhouettePath;
  final bool isSelected;
  final VoidCallback onHover;
  final VoidCallback onPressed;
  final double height;

  const _MenuButton({
    required this.imagePath,
    required this.silhouettePath,
    required this.isSelected,
    required this.onHover,
    required this.onPressed,
    this.height = 62,
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
          height: widget.height,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : const Color(0x44FFFFFF),
              width: 1,
            ),
          ),
          transform: Matrix4.identity()..rotateZ(widget.isSelected ? -0.02 : 0),
          child: Opacity(
            opacity: widget.isSelected ? 1.0 : 0.7,
            child: Image.asset(
              widget.isSelected ? widget.silhouettePath : widget.imagePath,
              filterQuality: FilterQuality.none,
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
  final String imagePath;
  final bool unlocked;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback? onPressed;

  const _LevelCard({
    required this.levelId,
    required this.imagePath,
    required this.unlocked,
    required this.highlighted,
    required this.onHover,
    this.onPressed,
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
              Opacity(
                opacity: isActive ? 1.0 : 0.3,
                child: Image.asset(
                  isActive ? widget.imagePath : 'assets/images/sprites/level_select/placeholder.png',
                  height: 60,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

