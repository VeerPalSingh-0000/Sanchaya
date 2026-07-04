import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/media_details_screen.dart';
import 'widgets/bottom_nav_bar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(
          body: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/media/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MediaDetailsScreen(mediaId: id);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const DiscoverScreen(isSearchMode: true),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider);
              final isGuest = ref.watch(isGuestProvider);
              final isAuth = user != null || isGuest;
              
              if (!isAuth) {
                return const LandingScreen();
              }

              return Scaffold(
                extendBody: true,
                body: child,
                bottomNavigationBar: const AppBottomNavBar(),
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/watchlist',
            builder: (context, state) => const WatchlistScreen(),
          ),
          GoRoute(
            path: '/recommendations',
            builder: (context, state) => const RecommendationsScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
        ],
      ),
    ],
  );
});

class SanchayaApp extends ConsumerWidget {
  const SanchayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Sanchaya',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
