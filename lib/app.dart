import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hard_hat/game/hard_hat_game.dart';
import 'package:hard_hat/game/constants.dart';
import 'package:hard_hat/audio/game_audio_manager.dart';
import 'package:hard_hat/save/game_save_manager.dart';
import 'package:hard_hat/screens/main_menu_screen.dart';
import 'package:hard_hat/screens/game_overlays.dart';
import 'package:hard_hat/screens/comic_screen.dart';

class HardHatApp extends StatefulWidget {
  const HardHatApp({super.key});

  @override
  State<HardHatApp> createState() => _HardHatAppState();
}

class _HardHatAppState extends State<HardHatApp> {
  Offset _mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hard Hat Havoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.none,
          onHover: (event) {
            setState(() {
              _mousePosition = event.position;
            });
          },
          child: Stack(
            children: [
              if (child != null) child,
              Positioned(
                left: _mousePosition.dx,
                top: _mousePosition.dy,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/sprites/misc/cursor.png',
                    width: 32,
                    height: 32,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      home: const GameFlowManager(),
    );
  }
}

enum GameFlowState { mainMenu, intro, playing, outro }

/// Manages the entire game flow: Menu → Intro → Play → Complete → Next Level → Outro
/// Replicates Godot's autoload game_manager.gd flow control.
class GameFlowManager extends StatefulWidget {
  const GameFlowManager({super.key});

  @override
  State<GameFlowManager> createState() => _GameFlowManagerState();
}

class _GameFlowManagerState extends State<GameFlowManager> {
  GameFlowState _flowState = GameFlowState.mainMenu;
  int _currentLevelId = 1;
  HardHatGameActual? _game;
  bool _isPaused = false;
  bool _showLevelSplash = false;

  void _startLevel(int levelId) {
    final game = HardHatGameActual()
      ..currentLevelId = levelId
      ..onLevelCompleted = _onLevelCompleted
      ..onOutroTriggered = _showOutro;

    // Start gameplay music
    GameAudioManager.playGameplayMusic();

    setState(() {
      _currentLevelId = levelId;
      _flowState = GameFlowState.playing;
      _isPaused = false;
      _showLevelSplash = true;
      _game = game;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLevelSplash = false);
    });
  }

  void _onLevelCompleted(int nextLevelId) {
    // Brief delay then auto-start next level
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _startLevel(nextLevelId);
    });
  }

  void _showIntro() {
    GameSaveManager.setIntroViewed();
    GameAudioManager.stopMusic();
    setState(() => _flowState = GameFlowState.intro);
  }

  void _showOutro() {
    GameSaveManager.setOutroViewed();
    GameAudioManager.fadeOutForTransition();
    setState(() => _flowState = GameFlowState.outro);
  }

  void _returnToMenu() {
    if (_isPaused && _game != null) {
      _game!.resumeEngine();
    }
    GameAudioManager.fadeOutForTransition();
    Future.delayed(const Duration(milliseconds: 300), () {
      GameAudioManager.playTitleMusic();
    });
    setState(() {
      _flowState = GameFlowState.mainMenu;
      _isPaused = false;
      _game = null;
    });
  }

  void _restartLevel() {
    if (_game != null) {
      _game!.resumeEngine();
    }
    _startLevel(_currentLevelId);
  }

  void _togglePause() {
    if (_game == null) return;
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _game!.gameState = GameplayState.paused;
      _game!.pauseEngine();
      GameAudioManager.duckForPause();
    }
  }

  void _resumeFromPause() {
    if (_game == null) return;
    setState(() => _isPaused = false);
    _game!.gameState = GameplayState.playing;
    _game!.resumeEngine();
    GameAudioManager.restoreFromPause();
  }

  @override
  Widget build(BuildContext context) {
    switch (_flowState) {
      case GameFlowState.mainMenu:
        // Start title music if not already playing
        GameAudioManager.playTitleMusic();
        return MainMenuScreen(
          onPlayLevel: _startLevel,
          onPlayIntro: _showIntro,
          onPlayOutro: _showOutro,
        );

      case GameFlowState.intro:
        return IntroComicScreen(
          onComplete: () {
            // After intro, go to level select via menu
            setState(() => _flowState = GameFlowState.mainMenu);
          },
        );

      case GameFlowState.playing:
        return Scaffold(
          body: Stack(
            children: [
              // The Flame game
              if (_game != null) GameWidget(game: _game!, mouseCursor: SystemMouseCursors.none),

              // Level splash overlay
              if (_showLevelSplash)
                LevelSplash(
                  levelId: _currentLevelId,
                  onComplete: () => setState(() => _showLevelSplash = false),
                ),

              // Pause overlay
              if (_isPaused)
                PauseMenuOverlay(
                  onResume: _resumeFromPause,
                  onRestart: _restartLevel,
                  onQuit: _returnToMenu,
                ),

              // HUD buttons (only when playing)
              if (!_isPaused && !_showLevelSplash)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _HudButton(icon: Icons.pause, onPressed: _togglePause),
                      const SizedBox(width: 8),
                      _HudButton(icon: Icons.home, onPressed: _returnToMenu),
                    ],
                  ),
                ),
            ],
          ),
        );

      case GameFlowState.outro:
        return OutroScreen(onComplete: _returnToMenu);
    }
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HudButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0x44000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x44FFFFFF)),
          ),
          child: Icon(icon, color: const Color(0xAAFFFFFF), size: 20),
        ),
      ),
    );
  }
}
