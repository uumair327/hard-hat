import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/core/services/services.dart';

void main() {
  group('TransitionSystemImpl', () {
    testWidgets('should initialize with isTransitioning false', (tester) async {
      final transitionSystem = TransitionSystemImpl(vsync: tester);
      
      expect(transitionSystem.isTransitioning, false);
      
      transitionSystem.dispose();
    });

    testWidgets('should set isTransitioning to true when starting popIn', (tester) async {
      final transitionSystem = TransitionSystemImpl(vsync: tester);
      
      // Start the animation but don't await it
      transitionSystem.popIn();
      
      // Pump a frame to start the animation
      await tester.pump();
      
      expect(transitionSystem.isTransitioning, true);
      
      transitionSystem.dispose();
    });

    testWidgets('should have animation value 0.0 initially', (tester) async {
      final transitionSystem = TransitionSystemImpl(vsync: tester);
      
      expect(transitionSystem.animationValue, 0.0);
      
      transitionSystem.dispose();
    });

    test('should wait for specified duration', () async {
      final transitionSystem = TransitionSystemImpl(vsync: const TestVSync());
      
      final stopwatch = Stopwatch()..start();
      await transitionSystem.wait(duration: const Duration(milliseconds: 100));
      stopwatch.stop();
      
      // Allow some tolerance for timing
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
      expect(stopwatch.elapsedMilliseconds, lessThan(150));
      
      transitionSystem.dispose();
    });

    testWidgets('should provide animation for listening', (tester) async {
      final transitionSystem = TransitionSystemImpl(vsync: tester);
      
      expect(transitionSystem.animation, isA<Animation<double>>());
      
      transitionSystem.dispose();
    });

    testWidgets('should call onTransitionStateChanged callback during animation', (tester) async {
      var callbackCount = 0;
      final transitionSystem = TransitionSystemImpl(
        vsync: tester,
        onTransitionStateChanged: () => callbackCount++,
      );

      // Start animation
      transitionSystem.popIn();
      
      // Pump a few frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      
      // Callback should be called at least once
      expect(callbackCount, greaterThan(0));
      
      transitionSystem.dispose();
    });
  });
}
