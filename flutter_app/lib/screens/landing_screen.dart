import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Immersive Background (Blur Orbs) ──
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurOrb(AppTheme.primary.withValues(alpha: 0.3), 300),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: _buildBlurOrb(AppTheme.secondary.withValues(alpha: 0.3), 300),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 50,
            child: _buildBlurOrb(Colors.purple.withValues(alpha: 0.2), 250),
          ),

          // ── Main Content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.movie_creation_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'The Ultimate Media Tracker',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5),

                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Your Entertainment\nUniverse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Subtitle
                  Text(
                    'Discover, save, and track your favorite movies, TV series, and anime all in one beautifully designed place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 48),

                  // Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Try Google Sign In
                          ref.read(authNotifierProvider.notifier).signInWithGoogle().catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sign in error: $e')),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          // Bypass Auth
                          ref.read(isGuestProvider.notifier).setGuest(true);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue as Guest',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final url = Uri.parse('https://github.com/VeerPalSingh-0000/Sanchaya');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.code_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'View GitHub',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 64),

                  // Features Grid
                  _FeatureCard(
                    icon: Icons.checklist_rtl_rounded,
                    title: 'Track Everything',
                    description: 'Keep a comprehensive list of movies, TV shows, and anime you have watched.',
                    color: Colors.blue,
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.explore_rounded,
                    title: 'Discover New Favorites',
                    description: 'Get personalized recommendations and explore trending media across the globe.',
                    color: Colors.pink,
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Beautiful Interface',
                    description: 'Enjoy a premium, ad-free experience designed for media lovers, by media lovers.',
                    color: Colors.orange,
                  ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                  const SizedBox(height: 60),

                  // Footer
                  Text(
                    'made with 🍿 for the culture.\n© ${DateTime.now().year} sanchaya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size * 1.5,
      height: size * 1.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.1, 1.0],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
