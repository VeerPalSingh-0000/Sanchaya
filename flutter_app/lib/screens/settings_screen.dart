import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── User card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    AppTheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email?.split('@').first ?? 'Guest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Not signed in',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(
                  begin: 0.05,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 32),

            // ── Account section ──
            _SectionTitle(title: 'Account'),
            const SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                if (user == null)
                  _SettingsTile(
                    icon: Icons.login_rounded,
                    title: 'Sign in with Google',
                    iconColor: AppTheme.primary,
                    onTap: () {
                      ref.read(authNotifierProvider.notifier).signInWithGoogle();
                    },
                  )
                else
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Account',
                    subtitle: user.email,
                  ),
              ],
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

            const SizedBox(height: 24),

            // ── Appearance section ──
            _SectionTitle(title: 'Appearance'),
            const SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  subtitle: 'Dark',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme customization coming soon!')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: 'Text Size',
                  subtitle: 'Default',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text size settings coming soon!')),
                    );
                  },
                ),
              ],
            ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

            const SizedBox(height: 24),

            // ── About section ──
            _SectionTitle(title: 'About'),
            const SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are on the latest version.')),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'Built with',
                  subtitle: 'Flutter + TMDB + AniList',
                ),
              ],
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

            // ── Sign out ──
            if (user != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Sign Out',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .signOut();
                            },
                            child: const Text('Sign Out',
                                style: TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 250.ms),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Helper widgets
// ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSubtle,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> tiles;
  const _SettingsGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.divider.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: List.generate(tiles.length, (i) {
          return Column(
            children: [
              tiles[i],
              if (i < tiles.length - 1)
                Divider(
                  height: 0.5,
                  indent: 52,
                  color: AppTheme.divider.withValues(alpha: 0.3),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.textMuted, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppTheme.textSubtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}
