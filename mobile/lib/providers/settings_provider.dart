import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

class SettingsState {
  final ThemeMode themeMode;
  final double textScale;
  final String avatarUrl;

  SettingsState({
    this.themeMode = ThemeMode.dark,
    this.textScale = 1.0,
    this.avatarUrl = '',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? textScale,
    String? avatarUrl,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final cacheService = ref.watch(cacheServiceProvider);
    final themeStr = cacheService.getSetting('themeMode', defaultValue: 'dark');
    final textScale = cacheService.getSetting('textScale', defaultValue: 1.0) as double;
    final avatarUrl = cacheService.getSetting('avatarUrl', defaultValue: '') as String;
    
    ThemeMode mode = ThemeMode.dark;
    if (themeStr == 'light') mode = ThemeMode.light;
    if (themeStr == 'system') mode = ThemeMode.system;

    return SettingsState(themeMode: mode, textScale: textScale, avatarUrl: avatarUrl);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(cacheServiceProvider).setSetting('themeMode', mode.name);
  }

  void setTextScale(double scale) {
    state = state.copyWith(textScale: scale);
    ref.read(cacheServiceProvider).setSetting('textScale', scale);
  }

  void setAvatarUrl(String url) {
    state = state.copyWith(avatarUrl: url);
    ref.read(cacheServiceProvider).setSetting('avatarUrl', url);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
