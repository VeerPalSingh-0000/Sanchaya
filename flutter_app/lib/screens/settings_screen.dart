import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: context.colors.textMain),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                SizedBox(width: 8),
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            SizedBox(height: 24),

            // ── User card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.12),
                    context.colors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: context.colors.surface,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => _AvatarSelectionSheet(
                          currentUrl: settings.avatarUrl,
                          onChanged: (url) {
                            ref.read(settingsProvider.notifier).setAvatarUrl(url);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: settings.avatarUrl.isEmpty ? AppTheme.primaryGradient : null,
                            border: Border.all(color: context.colors.primary.withValues(alpha: 0.3), width: 2),
                            image: settings.avatarUrl.isNotEmpty
                                ? DecorationImage(
                                    image: settings.avatarUrl.startsWith('http') 
                                      ? NetworkImage(settings.avatarUrl) 
                                      : AssetImage(settings.avatarUrl) as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: settings.avatarUrl.isEmpty
                              ? Center(
                                  child: Text(
                                    user?.email?.substring(0, 1).toUpperCase() ?? '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.colors.surface, width: 2),
                            ),
                            child: Icon(Icons.edit, size: 12, color: context.colors.surface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email?.split('@').first ?? 'Guest',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Not signed in',
                          style: TextStyle(
                            color: context.colors.textMuted,
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

            SizedBox(height: 32),

            // ── Account section ──
            _SectionTitle(title: 'Account'),
            SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                if (user == null)
                  _SettingsTile(
                    icon: Icons.login_rounded,
                    title: 'Sign in with Google',
                    iconColor: context.colors.primary,
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

            SizedBox(height: 24),

            // ── Appearance section ──
            _SectionTitle(title: 'Appearance'),
            SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Theme',
                  subtitle: settings.themeMode == ThemeMode.system
                      ? 'System'
                      : (settings.themeMode == ThemeMode.light
                          ? 'Light'
                          : 'Dark'),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: context.colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => _ThemeSelectionSheet(
                        currentMode: settings.themeMode,
                        onChanged: (mode) {
                          ref.read(settingsProvider.notifier).setThemeMode(mode);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: 'Text Size',
                  subtitle: settings.textScale == 1.0 ? 'Default' : (settings.textScale > 1.0 ? 'Large' : 'Small'),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: context.colors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => _TextSizeSelectionSheet(
                        currentScale: settings.textScale,
                        onChanged: (scale) {
                          ref.read(settingsProvider.notifier).setTextScale(scale);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ],
            ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

            SizedBox(height: 24),

            // ── Social section ──
            _SectionTitle(title: 'Social'),
            SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'GitHub Repository',
                  subtitle: 'Star on GitHub',
                  onTap: () async {
                    final url = Uri.parse('https://github.com/VeerPalSingh-0000/Sanchaya');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
                _SettingsTile(
                  icon: Icons.coffee_rounded,
                  title: 'Buy Me a Coffee',
                  subtitle: 'Support the developer',
                  onTap: () async {
                    final url = Uri.parse('https://buymeacoffee.com/veerpalsingh');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ],
            ).animate().fadeIn(duration: 300.ms, delay: 175.ms),

            SizedBox(height: 24),

            // ── About section ──
            _SectionTitle(title: 'About'),
            SizedBox(height: 10),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You are on the latest version.')),
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
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: context.colors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: Text('Sign Out',
                            style: TextStyle(color: Colors.white)),
                        content: Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Cancel',
                                style: TextStyle(color: context.colors.textMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .signOut();
                            },
                            child: Text('Sign Out',
                                style: TextStyle(color: context.colors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout_rounded, size: 18),
                  label: Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.error,
                    side: BorderSide(color: context.colors.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.symmetric(vertical: 14),
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
      style: TextStyle(
        color: context.colors.textSubtle,
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.divider.withValues(alpha: 0.3),
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
                  color: context.colors.divider.withValues(alpha: 0.3),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? context.colors.textMuted, size: 20),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.colors.textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: context.colors.textSubtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.textSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelectionSheet extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSelectionSheet({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Theme', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.brightness_auto, color: context.colors.textMain),
            title: Text('System', style: TextStyle(color: context.colors.textMain)),
            trailing: currentMode == ThemeMode.system ? Icon(Icons.check, color: context.colors.primary) : null,
            onTap: () => onChanged(ThemeMode.system),
          ),
          ListTile(
            leading: Icon(Icons.light_mode, color: context.colors.textMain),
            title: Text('Light', style: TextStyle(color: context.colors.textMain)),
            trailing: currentMode == ThemeMode.light ? Icon(Icons.check, color: context.colors.primary) : null,
            onTap: () => onChanged(ThemeMode.light),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode, color: context.colors.textMain),
            title: Text('Dark', style: TextStyle(color: context.colors.textMain)),
            trailing: currentMode == ThemeMode.dark ? Icon(Icons.check, color: context.colors.primary) : null,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _TextSizeSelectionSheet extends StatelessWidget {
  final double currentScale;
  final ValueChanged<double> onChanged;

  const _TextSizeSelectionSheet({required this.currentScale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Text Size', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          ListTile(
            title: Text('Small', style: TextStyle(color: context.colors.textMain)),
            trailing: currentScale == 0.85 ? Icon(Icons.check, color: context.colors.primary) : null,
            onTap: () => onChanged(0.85),
          ),
          ListTile(
            title: Text('Default', style: TextStyle(color: context.colors.textMain)),
            trailing: currentScale == 1.0 ? Icon(Icons.check, color: context.colors.primary) : null,
            onTap: () => onChanged(1.0),
          ),
          ListTile(
            title: Text('Large', style: TextStyle(color: context.colors.textMain)),
            trailing: currentScale == 1.15 ? Icon(Icons.check, color: context.colors.primary) : null,
            onTap: () => onChanged(1.15),
          ),
        ],
      ),
    );
  }
}

const _kDefaultAvatars = [
  {'name': 'Lelouch Lamperouge', 'url': 'assets/avatar/lelouch_lamperouge.jpg'},
  {'name': 'Luffy Monkey D.', 'url': 'assets/avatar/luffy_monkey_d_.jpg'},
  {'name': 'Levi', 'url': 'assets/avatar/levi.jpg'},
  {'name': 'L Lawliet', 'url': 'assets/avatar/l_lawliet.jpg'},
  {'name': 'Zoro Roronoa', 'url': 'assets/avatar/zoro_roronoa.jpg'},
  {'name': 'Killua Zoldyck', 'url': 'assets/avatar/killua_zoldyck.jpg'},
  {'name': 'Rintarou Okabe', 'url': 'assets/avatar/rintarou_okabe.jpg'},
  {'name': 'Light Yagami', 'url': 'assets/avatar/light_yagami.jpg'},
  {'name': 'Edward Elric', 'url': 'assets/avatar/edward_elric.jpg'},
  {'name': 'Naruto Uzumaki', 'url': 'assets/avatar/naruto_uzumaki.jpg'},
  {'name': 'Guts', 'url': 'assets/avatar/guts.jpg'},
  {'name': 'Gintoki Sakata', 'url': 'assets/avatar/gintoki_sakata.jpg'},
  {'name': 'Eren Yeager', 'url': 'assets/avatar/eren_yeager.jpg'},
  {'name': 'Kurisu Makise', 'url': 'assets/avatar/kurisu_makise.jpg'},
  {'name': 'Itachi Uchiha', 'url': 'assets/avatar/itachi_uchiha.jpg'},
  {'name': 'Satoru Gojou', 'url': 'assets/avatar/satoru_gojou.jpg'},
  {'name': 'Mikasa Ackerman', 'url': 'assets/avatar/mikasa_ackerman.jpg'},
  {'name': 'Ken Kaneki', 'url': 'assets/avatar/ken_kaneki.jpg'},
  {'name': 'Hachiman', 'url': 'assets/avatar/hachiman.jpg'},
  {'name': 'Kakashi Hatake', 'url': 'assets/avatar/kakashi_hatake.jpg'},
  {'name': 'Son Goku', 'url': 'assets/avatar/son_goku.jpg'},
  {'name': 'Vegeta', 'url': 'assets/avatar/vegeta.jpg'},
  {'name': 'Saitama', 'url': 'assets/avatar/saitama.jpg'},
  {'name': 'Tanjirou Kamado', 'url': 'assets/avatar/tanjirou_kamado.jpg'},
  {'name': 'Nezuko Kamado', 'url': 'assets/avatar/nezuko_kamado.jpg'},
  {'name': 'Ichigo Kurosaki', 'url': 'assets/avatar/ichigo_kurosaki.jpg'},
  {'name': 'Natsu Dragneel', 'url': 'assets/avatar/natsu_dragneel.jpg'},
  {'name': 'Erza Scarlet', 'url': 'assets/avatar/erza_scarlet.jpg'},
  {'name': 'Asuna Yuuki', 'url': 'assets/avatar/asuna_yuuki.jpg'},
  {'name': 'Kirito', 'url': 'assets/avatar/kirito.jpg'},
  {'name': 'Rem', 'url': 'assets/avatar/rem.jpg'},
  {'name': 'Emilia', 'url': 'assets/avatar/emilia.jpg'},
  {'name': 'Megumin', 'url': 'assets/avatar/megumin.jpg'},
  {'name': 'Aqua', 'url': 'assets/avatar/aqua.jpg'},
  {'name': 'Kazuma Satou', 'url': 'assets/avatar/kazuma_satou.jpg'},
  {'name': 'Jotaro Kujo', 'url': 'assets/avatar/jotaro_kujo.jpg'},
  {'name': 'Dio Brando', 'url': 'assets/avatar/dio_brando.jpg'},
  {'name': 'Sanji', 'url': 'assets/avatar/sanji.jpg'},
  {'name': 'Nami', 'url': 'assets/avatar/nami.jpg'},
  {'name': 'Roy Mustang', 'url': 'assets/avatar/roy_mustang.jpg'},
  {'name': 'Alphonse Elric', 'url': 'assets/avatar/alphonse_elric.jpg'},
  {'name': 'Sasuke Uchiha', 'url': 'assets/avatar/sasuke_uchiha.jpg'},
  {'name': 'Hinata Hyuuga', 'url': 'assets/avatar/hinata_hyuuga.jpg'},
  {'name': 'Jiraiya', 'url': 'assets/avatar/jiraiya.jpg'},
  {'name': 'Hisoka Morow', 'url': 'assets/avatar/hisoka_morow.jpg'},
  {'name': 'Gon Freecss', 'url': 'assets/avatar/gon_freecss.jpg'},
  {'name': 'None', 'url': ''},
];

class _AvatarSelectionSheet extends StatelessWidget {
  final String currentUrl;
  final ValueChanged<String> onChanged;

  const _AvatarSelectionSheet({required this.currentUrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        children: [
          Text('Select Avatar', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: _kDefaultAvatars.length,
            itemBuilder: (context, index) {
              final avatar = _kDefaultAvatars[index];
              final isSelected = currentUrl == avatar['url'];
              
              return GestureDetector(
                onTap: () => onChanged(avatar['url']!),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? context.colors.primary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: context.colors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ] : null,
                          image: avatar['url']!.isNotEmpty
                              ? DecorationImage(
                                  image: avatar['url']!.startsWith('http') 
                                    ? NetworkImage(avatar['url']!) 
                                    : AssetImage(avatar['url']!) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: avatar['url']!.isEmpty ? context.colors.divider : null,
                        ),
                        child: avatar['url']!.isEmpty
                            ? Center(child: Icon(Icons.person_off, color: context.colors.textMuted))
                            : null,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      avatar['name']!,
                      style: TextStyle(
                        color: isSelected ? context.colors.primary : context.colors.textMain,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          ),
        ],
      ),
    );
  }
}
