import 'package:flutter/material.dart';

/// Marka renk paleti.
///
/// Ana kimlik: sakin, güven veren koyu adaçayı/çam yeşili. Vurgu renkleri
/// bilinçli olarak doygunluğu düşük tutulur; makro renkleri grafik ve
/// halkalarda ayırt edilebilir olacak şekilde seçilmiştir.
abstract final class AppColors {
  static const Color brandSeed = Color(0xFF2F6B5E);

  // Makro / metrik renkleri (açık tema)
  static const Color calories = Color(0xFF2F6B5E);
  static const Color protein = Color(0xFF4A6FA5);
  static const Color carbs = Color(0xFFC98B2E);
  static const Color fat = Color(0xFFB0607A);
  static const Color fiber = Color(0xFF6B8E4E);
  static const Color water = Color(0xFF3A8FB7);

  // Makro / metrik renkleri (koyu tema: daha açık tonlar)
  static const Color caloriesDark = Color(0xFF8FD1BE);
  static const Color proteinDark = Color(0xFF9DB9E6);
  static const Color carbsDark = Color(0xFFEBC07A);
  static const Color fatDark = Color(0xFFE3A3B6);
  static const Color fiberDark = Color(0xFFB2CF95);
  static const Color waterDark = Color(0xFF8CC8E6);

  // Durum renkleri
  static const Color success = Color(0xFF2E7D4F);
  static const Color successDark = Color(0xFF86D3A2);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningDark = Color(0xFFF2C46D);
}
