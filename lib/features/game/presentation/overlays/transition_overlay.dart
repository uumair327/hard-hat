import 'package:flutter/material.dart';

/// Full-screen overlay widget for screen transitions
/// Displays a wipe animation from edges to center (pop-in) or center to edges (pop-out)
class TransitionOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  
  const TransitionOverlay({
    super.key,
    required this.animation,
    this.color = Colors.black,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: animation.value == 0.0,
          child: Stack(
            children: [
              // Left wipe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * animation.value / 2,
                child: Container(color: color),
              ),
              // Right wipe
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * animation.value / 2,
                child: Container(color: color),
              ),
              // Top wipe
              Positioned(
                left: MediaQuery.of(context).size.width * animation.value / 2,
                right: MediaQuery.of(context).size.width * animation.value / 2,
                top: 0,
                height: MediaQuery.of(context).size.height * animation.value / 2,
                child: Container(color: color),
              ),
              // Bottom wipe
              Positioned(
                left: MediaQuery.of(context).size.width * animation.value / 2,
                right: MediaQuery.of(context).size.width * animation.value / 2,
                bottom: 0,
                height: MediaQuery.of(context).size.height * animation.value / 2,
                child: Container(color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
