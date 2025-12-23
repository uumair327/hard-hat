import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../game/hard_hat_game.dart';

class HardHatGameWidget extends StatefulWidget {
  const HardHatGameWidget({super.key});

  @override
  State<HardHatGameWidget> createState() => _HardHatGameWidgetState();
}

class _HardHatGameWidgetState extends State<HardHatGameWidget> {
  late final HardHatGame game;

  @override
  void initState() {
    super.initState();
    game = HardHatGame();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the overlay context to the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      game.setOverlayContext(context);
    });

    return GameWidget<HardHatGame>.controlled(
      gameFactory: () => game,
    );
  }
}