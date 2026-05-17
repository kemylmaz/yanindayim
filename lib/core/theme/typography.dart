import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Yaninda tipografi sistemi.
///
/// Plus Jakarta Sans (başlık, karakterli)
/// Inter (gövde, okunabilirlik)
///
/// Min gövde boyutu 16sp, panik anında okumayı kolaylaştırır.
/// Line-height 1.5x — yorgun göz için boşluk önemli.
class AppTypography {
  AppTypography._();

  /// Uygulama logosu için özel font — Yeseva One (klasik display serif).
  /// "Yanındayım" yazısının her kullanımında bu style kullanılır.
  /// Yerel asset olarak yüklü (offline çalışır).
  static TextStyle logoTitle({
    double fontSize = 64,
    Color? color,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: 'YesevaOne',
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.primaryDeep,
      );

  // Başlık (Plus Jakarta Sans)
  static TextStyle displayLarge = GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Gövde (Inter)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Buton
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // Etiket (chip, badge, küçük label)
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.3,
  );
}
