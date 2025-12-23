import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/menu/presentation/pages/main_menu_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/menu',
    routes: [
      GoRoute(
        path: '/menu',
        name: 'menu',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const MainMenuPage(),
          transitionType: PageTransitionType.fade,
        ),
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
          return _buildPageWithTransition(
            context,
            state,
            GamePage(levelId: levelId),
            transitionType: PageTransitionType.slideFromRight,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SettingsPage(),
          transitionType: PageTransitionType.slideFromBottom,
        ),
      ),
    ],
    errorPageBuilder: (context, state) => _buildPageWithTransition(
      context,
      state,
      Scaffold(
        body: Center(
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
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.matchedLocation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/menu'),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      ),
      transitionType: PageTransitionType.fade,
    ),
  );

  /// Build a page with custom transition animation
  static Page<void> _buildPageWithTransition(
    BuildContext context,
    GoRouterState state,
    Widget child, {
    PageTransitionType transitionType = PageTransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          animation,
          secondaryAnimation,
          child,
          transitionType,
        );
      },
    );
  }

  /// Build the actual transition animation
  static Widget _buildTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    PageTransitionType type,
  ) {
    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      
      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: child,
        );
    }
  }
}

/// Enum for different page transition types
enum PageTransitionType {
  fade,
  slideFromRight,
  slideFromBottom,
  scale,
}