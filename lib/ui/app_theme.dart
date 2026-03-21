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
  final baseTheme = ThemeData(brightness: brightness);
  const fontFamilyFallback = <String>[
    'Segoe UI',
    'SF Pro Text',
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Roboto',
  ];
  final shapedTextTheme = baseTheme.textTheme.apply(
    fontFamily: 'Segoe UI',
    fontFamilyFallback: fontFamilyFallback,
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5368E7),
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  final scaffoldBackgroundColor =
      isDark ? const Color(0xFF0E121A) : const Color(0xFFF4F6FA);
  final cardBackgroundColor =
      isDark ? const Color(0xFF171D29) : const Color(0xFFFFFFFF);
  final inputFillColor =
      isDark ? const Color(0xFF1B2230) : const Color(0xFFF9FAFC);
  final borderColor =
      isDark ? const Color(0xFF2B3445) : const Color(0xFFDCE2EE);
  final bodyColor = isDark ? const Color(0xFFF4F7FD) : const Color(0xFF182133);
  final secondaryColor =
      isDark ? const Color(0xFFB6C0D4) : const Color(0xFF667085);
  final mutedColor = isDark ? const Color(0xFF8590A6) : const Color(0xFF8B95A7);
  final navigationSurface =
      isDark ? const Color(0xFF121826) : const Color(0xFFFFFFFF);
  final navigationIndicator =
      isDark ? scheme.primary.withValues(alpha: 0.22) : scheme.primaryContainer;
  final navigationSelected =
      isDark ? const Color(0xFFF4F7FD) : const Color(0xFF1B2A4A);
  final navigationUnselected =
      isDark ? const Color(0xFF8A94A8) : const Color(0xFF6E778C);
  final textTheme = shapedTextTheme.copyWith(
    displaySmall: shapedTextTheme.displaySmall?.copyWith(
      color: bodyColor,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    headlineMedium: shapedTextTheme.headlineMedium?.copyWith(
      color: bodyColor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleLarge: shapedTextTheme.titleLarge?.copyWith(
      color: bodyColor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: shapedTextTheme.titleMedium?.copyWith(
      color: bodyColor,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: shapedTextTheme.bodyLarge?.copyWith(
      color: bodyColor,
      height: 1.45,
    ),
    bodyMedium: shapedTextTheme.bodyMedium?.copyWith(
      color: secondaryColor,
      height: 1.45,
    ),
    bodySmall: shapedTextTheme.bodySmall?.copyWith(
      color: mutedColor,
      height: 1.35,
    ),
    labelLarge: shapedTextTheme.labelLarge?.copyWith(
      color: secondaryColor,
      fontWeight: FontWeight.w600,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      toolbarHeight: 72,
      titleSpacing: 20,
      centerTitle: false,
      backgroundColor: scaffoldBackgroundColor,
      foregroundColor: bodyColor,
      iconTheme: IconThemeData(color: bodyColor),
      actionsIconTheme: IconThemeData(color: bodyColor),
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: bodyColor,
        letterSpacing: -0.2,
        fontFamily: 'Segoe UI',
        fontFamilyFallback: fontFamilyFallback,
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
        borderRadius: BorderRadius.circular(AppUi.radius16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppUi.radius16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppUi.radius16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navigationSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      height: 74,
      indicatorColor: navigationIndicator,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? navigationSelected : navigationUnselected,
          size: selected ? 25 : 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? navigationSelected : navigationUnselected,
        );
      }),
    ),
  );
}
