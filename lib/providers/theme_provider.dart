import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
// import '../themes/app_theme.dart';
// Define an enum for theme mode
enum AppTheme { light, dark }

// StateProvider to hold current theme mode
final themeModeProvider = StateProvider<AppTheme>((ref) => AppTheme.light);


final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  void _loadTheme() async {
    final localStorage = LocalStorageService();
    await localStorage.init();
    final theme = localStorage.getThemeMode();
    state = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final localStorage = LocalStorageService();
    await localStorage.init();
    await localStorage.saveThemeMode(isDark ? 'dark' : 'light');
  }
}
