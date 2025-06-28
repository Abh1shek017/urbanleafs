import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import '../providers/theme_provider.dart';
// enum AppTheme { light, dark }

class AppThemeManager {
  static ThemeData getThemeFromEnum(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return LightTheme.theme;
      case AppTheme.dark:
        return DarkTheme.theme;
    }
  }

  // Helper to toggle theme
  static AppTheme toggleTheme({required AppTheme currentTheme}) {
    return currentTheme == AppTheme.light ? AppTheme.dark : AppTheme.light;
  }
}