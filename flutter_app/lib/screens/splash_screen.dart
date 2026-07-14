import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/trending_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/aesthetic_loader.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Minimum delay to let the user enjoy the premium splash screen, reduced for faster loading
    final minimumDelay = Future.delayed(Duration(milliseconds: 800));

    // Pre-fetch critical home screen data in the background without awaiting them
    // so the user isn't stuck on the splash screen if the network is slow.
    // The home screen has its own loading (shimmer) states.
    ref.read(trendingMoviesProvider.future).catchError((_) => []);
    ref.read(trendingTVProvider.future).catchError((_) => []);
    ref.read(trendingAnimeProvider.future).catchError((_) => []);
    ref.read(watchlistProvider.future).catchError((_) => []);

    // Wait for the minimum aesthetic delay
    await minimumDelay;
    
    // Proceed to the main application
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AestheticLoader(size: 80),
            SizedBox(height: 40),
            Text(
              'Sanchaya',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                color: context.colors.textMain,
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            SizedBox(height: 12),
            Text(
              'Your Ultimate Media Tracker',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.textSubtle,
                letterSpacing: 1.2,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 800.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
