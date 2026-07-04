import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core palette ──
  static const Color background = Color(0xFF06060C);
  static const Color surface = Color(0xFF111118);
  static const Color surfaceLight = Color(0xFF1A1A24);
  static const Color primary = Color(0xFF8B5CF6);     // Violet-500
  static const Color primaryLight = Color(0xFFA78BFA); // Violet-400
  static const Color secondary = Color(0xFF06B6D4);    // Cyan-500
  static const Color textMain = Color(0xFFEDEDF3);
  static const Color textMuted = Color(0xFF71717A);     // Zinc-500
  static const Color textSubtle = Color(0xFF52525B);    // Zinc-600
  static const Color divider = Color(0xFF27272A);       // Zinc-800
  static const Color error = Color(0xFFF43F5E);         // Rose-500
  static const Color success = Color(0xFF22C55E);       // Green-500
  static const Color warning = Color(0xFFF59E0B);       // Amber-500

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111118), Color(0xFF0F0F16)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF252530), Color(0xFF1A1A24)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme data ──
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: textMain,
        error: error,
        brightness: Brightness.dark,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: textMain,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textMain),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textMain),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: textMain,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: textMuted),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: textSubtle),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: baseTextTheme.labelMedium?.copyWith(color: textMuted),
        secondaryLabelStyle: baseTextTheme.labelMedium?.copyWith(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: divider.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: textSubtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: divider.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 0,
      ),
      // NavigationBar theme for the bottom nav
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseTextTheme.labelSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            );
          }
          return baseTextTheme.labelSmall?.copyWith(
            color: textSubtle,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: textSubtle, size: 22);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      // Suppress ugly ripple / hover overlays
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      // Keep the old bottomNavigationBar theme too, just in case
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: textSubtle,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
