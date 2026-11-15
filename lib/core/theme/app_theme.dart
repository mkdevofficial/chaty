import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String appFontFamily = 'Cairo';
  static const List<String> appFontFallback = [
    'Segoe UI',
    'Roboto',
    'Noto Sans Arabic',
    'sans-serif',
  ];

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      displayMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      displaySmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      titleSmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.25,
      ),
      bodyLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 13.5,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
        height: 1.35,
      ),
      bodyMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 10.5,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurfaceVariant,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      labelMedium: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        height: 1.2,
      ),
      labelSmall: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        height: 1.2,
      ),
    );
  }

  static ThemeData lightTheme(AppAccentColor accent) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: appFontFamily,
      fontFamilyFallback: appFontFallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F9FA),
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          color: colorScheme.onSurface,
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontSize: 12.5,
        ),
        hintStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: appFontFamily,
            fontFamilyFallback: appFontFallback,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData darkTheme(AppAccentColor accent) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: appFontFamily,
      fontFamilyFallback: appFontFallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF111418),
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          color: colorScheme.onSurface,
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontSize: 12.5,
        ),
        hintStyle: TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: appFontFamily,
            fontFamilyFallback: appFontFallback,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
