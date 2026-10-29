import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color textMain;
  final Color textMuted;
  final Color textSubtle;
  final Color divider;
  final Color error;
  final Color success;
  final Color warning;

  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.textMain,
    required this.textMuted,
    required this.textSubtle,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
  });

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    Color? textMain,
    Color? textMuted,
    Color? textSubtle,
    Color? divider,
    Color? error,
    Color? success,
    Color? warning,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      divider: divider ?? this.divider,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}
