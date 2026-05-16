import 'package:flutter/material.dart';

/// Yaninda renk paleti.
///
/// Felsefe: canlı mint-yeşil arka plan + beyaz aksiyon kartları.
/// Yeşil hayatın, umudun ve yardımın simgesi — emergency app için pozitif
/// bir psikolojik mesaj. Beyaz kartlar yüksek kontrast verir.
///
/// Kontrast hedefi: WCAG AAA (7:1+).
class AppColors {
  AppColors._();

  // Emerald yeşil ailesi (vurgu + aksiyon)
  static const Color primary = Color(0xFF0F5944);         // Derin emerald
  static const Color primaryDeep = Color(0xFF063226);     // En koyu — metin
  static const Color primarySoft = Color(0xFF3E8B6F);     // Orta emerald
  static const Color primaryLight = Color(0xFF7DBFA3);    // Glow
  static const Color primarySurface = Color(0xFFCEE5D6);

  // Sıcak aksanlar
  static const Color amber = Color(0xFFD78640);
  static const Color amberSoft = Color(0xFFF8E2C4);
  static const Color teal = Color(0xFF1F8A85);
  static const Color tealSoft = Color(0xFFC2E4E1);

  // Canlı mint arka plan
  static const Color background = Color(0xFF5DCB7E);      // Ana mint yeşil
  static const Color backgroundTop = Color(0xFF7DD896);   // Üst — daha açık
  static const Color backgroundBottom = Color(0xFF42B468);// Alt — daha doygun
  static const Color surface = Color(0xFFFFFFFF);         // Saf beyaz
  static const Color surfaceTint = Color(0xFFF6FAF7);

  // Yazı
  static const Color textPrimary = Color(0xFF0F1F16);
  static const Color textSecondary = Color(0xFF4B5A52);
  static const Color textOnPrimary = Color(0xFFFFFFFF);   // Beyaz on emerald
  static const Color textOnAmber = Color(0xFF3D2410);
  static const Color textDisabled = Color(0xFF9AA89F);

  // Anlam renkleri
  static const Color warning = Color(0xFFE5B928);
  static const Color critical = Color(0xFFC0392B);
  static const Color criticalSoft = Color(0xFFF6DCD8);
  static const Color info = Color(0xFF1F8A85);
  static const Color rescuer = Color(0xFFFFFFFF);         // Beyaz (artık kart rengi)
  static const Color rescuerLight = Color(0xFFE8F4ED);

  // Sınır ve gölge
  static const Color border = Color(0xFFBFD3C5);
  static const Color borderStrong = Color(0xFF8DAD99);
  static const Color shadow = Color(0x29063226);          // Daha güçlü (canlı bg için)
  static const Color shadowStrong = Color(0x40063226);

  static const Color scrim = Color(0x66000000);
}
