import 'package:flutter/material.dart';

/// Yaninda renk paleti.
///
/// Felsefe: berrak, yüksek kontrastlı, huzur veren ama hayat dolu.
/// Beyaza yakın krem arka planın üzerinde derin emerald + sıcak amber +
/// güvenli navy. Modern emergency app standardı.
///
/// Kontrast hedefi: WCAG AAA (7:1+) primary metinde.
class AppColors {
  AppColors._();

  // Emerald yeşil ailesi (huzur + canlılık)
  static const Color primary = Color(0xFF0F5944);         // Derin emerald, premium yeşil
  static const Color primaryDeep = Color(0xFF063226);     // Top bar, en koyu vurgu
  static const Color primarySoft = Color(0xFF3E8B6F);     // Orta emerald, PFA modu
  static const Color primaryLight = Color(0xFF7DBFA3);    // Glow, beacon aktif
  static const Color primarySurface = Color(0xFFDBEDE3);  // Hafif emerald yüzey

  // Sıcak aksanlar
  static const Color amber = Color(0xFFD78640);           // Canlı amber/bakır
  static const Color amberSoft = Color(0xFFF8E2C4);
  static const Color teal = Color(0xFF1F8A85);            // Doygun teal — info
  static const Color tealSoft = Color(0xFFC2E4E1);

  // Beyaza yakın krem nötrler
  static const Color background = Color(0xFFFAF7EF);      // Hafif krem-beyaz
  static const Color backgroundTop = Color(0xFFFDFBF6);   // Neredeyse beyaz
  static const Color backgroundBottom = Color(0xFFF2EDE0);// Hafif krem alt
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFFCF9F1);

  // Yazı
  static const Color textPrimary = Color(0xFF131C16);     // Daha derin koyu (kontrast +)
  static const Color textSecondary = Color(0xFF55615A);   // Mid gri-yeşil
  static const Color textOnPrimary = Color(0xFFFAF7EF);
  static const Color textOnAmber = Color(0xFF3D2410);
  static const Color textDisabled = Color(0xFF9AA39E);

  // Anlam renkleri
  static const Color warning = Color(0xFFE5B928);
  static const Color critical = Color(0xFFC0392B);        // Canlı kritik (sadece kritik aksiyon)
  static const Color criticalSoft = Color(0xFFF6DCD8);
  static const Color info = Color(0xFF1F8A85);
  static const Color rescuer = Color(0xFF1F3A5F);         // Derin navy
  static const Color rescuerLight = Color(0xFF7B9CC4);    // Steel blue

  // Sınır ve gölge
  static const Color border = Color(0xFFE5DCC6);
  static const Color borderStrong = Color(0xFFB0A488);
  static const Color shadow = Color(0x1A063226);
  static const Color shadowStrong = Color(0x33063226);

  static const Color scrim = Color(0x66000000);
}
