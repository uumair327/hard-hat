import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hard_hat/features/game/presentation/overlays/overlays.dart';

void main() {
  group('TransitionOverlay', () {
    testWidgets('should render with animation at 0.0', (tester) async {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: tester,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionOverlay(
              animation: controller,
            ),
          ),
        ),
      );

      expect(find.byType(TransitionOverlay), findsOneWidget);
      
      controller.dispose();
    });

    testWidgets('should render with animation at 1.0', (tester) async {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: tester,
      )..value = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionOverlay(
              animation: controller,
            ),
          ),
        ),
      );

      expect(find.byType(TransitionOverlay), findsOneWidget);
      
      controller.dispose();
    });

    testWidgets('should animate from 0.0 to 1.0', (tester) async {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: tester,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionOverlay(
              animation: controller,
            ),
          ),
        ),
      );

      // Start animation
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      
      // Animation should be in progress
      expect(controller.value, greaterThan(0.0));
      expect(controller.value, lessThan(1.0));
      
      await tester.pumpAndSettle();
      
      // Animation should be complete
      expect(controller.value, 1.0);
      
      controller.dispose();
    });

    testWidgets('should use custom color', (tester) async {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: tester,
      )..value = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransitionOverlay(
              animation: controller,
              color: Colors.red,
            ),
          ),
        ),
      );

      // Find containers with red color
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(
        containers.any((container) => container.color == Colors.red),
        true,
      );
      
      controller.dispose();
    });

    testWidgets('should block input when animation value > 0', (tester) async {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: tester,
      )..value = 0.5;

      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ElevatedButton(
                  onPressed: () => buttonPressed = true,
                  child: const Text('Test Button'),
                ),
                TransitionOverlay(
                  animation: controller,
                ),
              ],
            ),
          ),
        ),
      );

      // Try to tap the button
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      // Button should not be pressed because overlay blocks input
      expect(buttonPressed, false);
      
      controller.dispose();
    });

    testWidgets('should not block input when animation value is 0', (tester) async {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: tester,
      )..value = 0.0;

      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ElevatedButton(
                  onPressed: () => buttonPressed = true,
                  child: const Text('Test Button'),
                ),
                TransitionOverlay(
                  animation: controller,
                ),
              ],
            ),
          ),
        ),
      );

      // Try to tap the button
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      // Button should be pressed because overlay doesn't block input at 0.0
      expect(buttonPressed, true);
      
      controller.dispose();
    });
  });
}
