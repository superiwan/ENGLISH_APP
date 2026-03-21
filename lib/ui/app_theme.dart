import 'package:flutter/material.dart';

class AppUi {
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double radius12 = 12;
  static const double radius16 = 16;
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3F51B5),
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  final scaffoldBackgroundColor =
      isDark ? scheme.surface : const Color(0xFFF6F7FB);
  final cardBackgroundColor =
      isDark ? scheme.surfaceContainerHighest : Colors.white;
  final inputFillColor = isDark ? scheme.surfaceContainerHigh : Colors.white;
  final borderColor = isDark ? scheme.outlineVariant : const Color(0xFFD5DAE6);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: scaffoldBackgroundColor,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUi.radius16),
        side: BorderSide(color: borderColor),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppUi.radius12),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scaffoldBackgroundColor,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
  );
}
