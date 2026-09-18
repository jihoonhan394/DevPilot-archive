import 'package:devpilot_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Light theme with bundled fonts (docs/18 §6.6, docs/02 §10.3). Dark mode is Later.
abstract final class AppTheme {
  static const fontFamily = 'Pretendard';
  static const codeFontFamily = 'JetBrainsMono';

  /// Code and identifiers. Hangul falls back to the bundled Pretendard, never to a CDN font.
  static const codeTextStyle = TextStyle(
    fontFamily: codeFontFamily,
    fontFamilyFallback: [fontFamily],
    fontSize: 14,
    height: 20 / 14,
  );

  static const _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.textSecondary,
    onSecondary: AppColors.onPrimary,
    error: AppColors.danger,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.dangerContainer,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
  );

  // docs/02 §10.3. Pretendard is bundled in 400, 600 and 700 only; styles not listed here keep the
  // Material defaults, and a 500 weight renders with the nearest bundled face.
  static const _textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600),
  );

  static ThemeData light() {
    const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)));
    return ThemeData(
      colorScheme: _colorScheme,
      fontFamily: fontFamily,
      textTheme: _textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.surface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 48), shape: buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: buttonShape),
      ),
    );
  }
}
