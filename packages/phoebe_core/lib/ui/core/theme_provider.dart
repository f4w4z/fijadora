import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_load());

  static ThemeMode _load() {
    try {
      final box = Hive.box('app_preferences');
      final stored = box.get('theme_mode', defaultValue: 'system') as String;
      switch (stored) {
        case 'light': return ThemeMode.light;
        case 'dark': return ThemeMode.dark;
        default: return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    try {
      final box = Hive.box('app_preferences');
      switch (mode) {
        case ThemeMode.light: box.put('theme_mode', 'light'); break;
        case ThemeMode.dark: box.put('theme_mode', 'dark'); break;
        case ThemeMode.system: box.put('theme_mode', 'system'); break;
      }
    } catch (_) {}
  }

  void toggleTheme() {
    switch (state) {
      case ThemeMode.light: setThemeMode(ThemeMode.dark); break;
      case ThemeMode.dark: setThemeMode(ThemeMode.light); break;
      case ThemeMode.system: setThemeMode(ThemeMode.dark); break;
    }
  }
}
