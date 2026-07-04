import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/watchlist')) currentIndex = 1;
    if (location.startsWith('/recommendations')) currentIndex = 2;
    if (location.startsWith('/discover')) currentIndex = 3;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppTheme.divider.withValues(alpha: 0.3),
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
                  case 2:
                    context.go('/recommendations');
                    break;
                  case 3:
                    context.go('/discover');
                    break;
                }
              },
              height: 64,
              destinations: const [
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
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'For You',
                ),
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
