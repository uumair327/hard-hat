import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
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
    context.read<GameBloc>().add(LoadLevelEvent(widget.levelId));
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
        body: BlocListener<GameBloc, GameState>(
          listener: (context, state) {
            // Handle state changes that require navigation
            if (state.status == GameStatus.error) {
              _showErrorDialog(context, state.errorMessage ?? 'Unknown error');
            }
          },
          child: BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              switch (state.status) {
                case GameStatus.loading:
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading level...'),
                      ],
                    ),
                  );
                case GameStatus.error:
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.errorMessage}',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.go('/menu'),
                          child: const Text('Back to Menu'),
                        ),
                      ],
                    ),
                  );
                case GameStatus.playing:
                case GameStatus.paused:
                case GameStatus.levelComplete:
                  return const HardHatGameWidget();
                default:
                  return const Center(
                    child: Text('Initializing...'),
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  /// Handle back button press - show pause menu or confirm quit
  void _handleBackButton(BuildContext context) {
    final gameBloc = context.read<GameBloc>();
    
    if (gameBloc.state.status == GameStatus.playing) {
      // Pause the game instead of immediately going back
      gameBloc.add(PauseGameEvent());
    } else {
      // Show confirmation dialog
      _showQuitConfirmationDialog(context);
    }
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/menu');
            },
            child: const Text('Back to Menu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<GameBloc>().add(LoadLevelEvent(widget.levelId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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