import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class ProfileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const ProfileAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return AppBar(
      title: Text(title),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: user != null && user.email != null
                    ? Text(
                        user.email!.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: AppTheme.textSubtle,
                        size: 20,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
