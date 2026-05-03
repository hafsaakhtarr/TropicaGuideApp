import 'package:flutter/material.dart';

class TColors {
  // Backgrounds
  static const Color bg       = Color(0xFF0D1F2D);
  static const Color surface  = Color(0xFF132637);
  static const Color surface2 = Color(0xFF1A3347);
  static const Color border   = Color(0xFF1E3A50);

  // Accents
  static const Color lime     = Color(0xFF8AE000);
  static const Color limeText = Color(0xFF9EE864);
  static const Color coral    = Color(0xFFFF4D3D);
  static const Color ocean    = Color(0xFF1A9ECC);

  // Text
  static const Color textPrimary   = Color(0xFFE8F0F5);
  static const Color textSecondary = Color(0xFF7A9BB5);
  static const Color textMuted     = Color(0xFF4A6B82);
}

class TText {
  static const h1 = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w900,
    fontSize: 26, color: TColors.textPrimary,
  );
  static const h2 = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w800,
    fontSize: 18, color: TColors.textPrimary,
  );
  static const h3 = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w700,
    fontSize: 15, color: TColors.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w400,
    fontSize: 13, color: TColors.textSecondary,
  );
  static const label = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w600,
    fontSize: 13, color: TColors.textPrimary,
  );
  static const caption = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w600,
    fontSize: 10, color: TColors.textMuted, letterSpacing: 1.0,
  );
  static const limeStyle = TextStyle(
    fontFamily: 'Nunito', fontWeight: FontWeight.w800,
    fontSize: 13, color: TColors.limeText,
  );
}