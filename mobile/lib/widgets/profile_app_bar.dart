import 'package:flutter/material.dart';
import 'package:flutter_app/config/theme_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class ProfileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const ProfileAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);

    String greeting = 'Good Evening';
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    }

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.textSubtle,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: settings.avatarUrl.isEmpty ? context.colors.surfaceLight : null,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
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
                      child: Icon(
                        Icons.person_rounded,
                        color: context.colors.textSubtle,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
