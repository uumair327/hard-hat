import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/game_widget.dart';

class GamePage extends StatefulWidget {
  final int levelId;

  const GamePage({
    super.key,
    required this.levelId,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  void initState() {
    super.initState();
    // No GameBloc for now - just show the game widget
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton(context);
        }
      },
      child: Scaffold(
        body: const HardHatGameWidget(),
      ),
    );
  }

  /// Handle back button press - show pause menu or confirm quit
  void _handleBackButton(BuildContext context) {
    // Show confirmation dialog
    _showQuitConfirmationDialog(context);
  }

  /// Show quit confirmation dialog
  void _showQuitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Level'),
        content: const Text('Are you sure you want to quit to the main menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/menu');
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