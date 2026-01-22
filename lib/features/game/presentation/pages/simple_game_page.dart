import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SimpleGamePage extends StatefulWidget {
  final int levelId;

  const SimpleGamePage({
    super.key,
    required this.levelId,
  });

  @override
  State<SimpleGamePage> createState() => _SimpleGamePageState();
}

class _SimpleGamePageState extends State<SimpleGamePage> {
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
        backgroundColor: const Color(0xFF87CEEB), // Sky blue
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'HARD HAT HAVOC',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Level ${widget.levelId}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Game is loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.orange,
              ),
              const SizedBox(height: 40),
              const Text(
                'The game engine is being simplified to resolve startup issues.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/menu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle back button press
  void _handleBackButton(BuildContext context) {
    context.go('/menu');
  }
}