import 'dart:ui';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/watchlist')) currentIndex = 1;
    // Recommendations tab temporarily disabled
    if (location.startsWith('/discover')) currentIndex = 2;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.background.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: context.colors.divider.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/watchlist');
                    break;
                  // Recommendations tab temporarily disabled
                  case 2:
                    context.go('/discover');
                    break;
                }
              },
              height: 64,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.play_arrow_outlined),
                  selectedIcon: Icon(Icons.play_arrow_rounded),
                  label: 'My List',
                ),
                // Recommendations tab temporarily disabled
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Discover',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
