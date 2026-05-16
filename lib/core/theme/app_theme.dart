import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.critical,
      onError: AppColors.textOnPrimary,
      outline: AppColors.border,
    ),

    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelSmall: AppTypography.labelSmall,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: AppTypography.headlineMedium,
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AppTypography.buttonLarge,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AppTypography.buttonLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.buttonMedium,
        minimumSize: const Size(60, 48),
      ),
    ),
  );
}
