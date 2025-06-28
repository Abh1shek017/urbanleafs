import 'package:flutter/material.dart';

class ThemeConstants {
  // Light Mode Colors
  static final Color lightPrimaryColor = Colors.green.shade700;
  static final Color lightSecondaryColor = Colors.green.shade300;
  static final Color lightBackgroundColor = Colors.white;
  static final Color lightSurfaceColor = Colors.grey.shade200;
  static final Color lightOnPrimaryColor = Colors.white;
  static final Color lightTextColorPrimary = Colors.black87;
  static final Color lightTextColorSecondary = Colors.black54;

  // Dark Mode Colors
  static final Color darkPrimaryColor = Colors.green.shade900;
  static final Color darkSecondaryColor = Colors.green.shade700;
  static final Color darkBackgroundColor = Colors.grey.shade900;
  static final Color darkSurfaceColor = Colors.grey.shade800;
  static final Color darkOnPrimaryColor = Colors.white;
  static final Color darkTextColorPrimary = Colors.white;
  static final Color darkTextColorSecondary = Colors.white70;

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: lightPrimaryColor,
    colorScheme: ColorScheme.light(
      primary: lightPrimaryColor,
      secondary: lightSecondaryColor,
      surface: lightSurfaceColor,
      onPrimary: lightOnPrimaryColor,
      onSurface: lightTextColorPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightPrimaryColor,
      foregroundColor: lightOnPrimaryColor,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightPrimaryColor,
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: lightTextColorPrimary),
      bodySmall: TextStyle(color: lightTextColorSecondary),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimaryColor,
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      surface: darkSurfaceColor,
      onPrimary: darkOnPrimaryColor,
      onSurface: darkTextColorPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkPrimaryColor,
      foregroundColor: darkOnPrimaryColor,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkPrimaryColor,
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: darkTextColorPrimary),
      bodySmall: TextStyle(color: darkTextColorSecondary),
    ),
  );
}