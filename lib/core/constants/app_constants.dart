abstract final class AppConstants {
  static const defaultLocale = 'tr';
  static const supportedLocales = ['tr', 'en'];

  static const networkTimeout = Duration(seconds: 20);

  // Makul giriş sınırları (doğrulama için)
  static const minAge = 16;
  static const maxAge = 100;
  static const minWeightKg = 25.0;
  static const maxWeightKg = 350.0;
  static const minHeightCm = 100.0;
  static const maxHeightCm = 250.0;
  static const defaultWaterGoalMl = 2500;
  static const minWaterGoalMl = 1000;
  static const maxWaterGoalMl = 5000;
  static const minMealsPerDay = 2;
  static const maxMealsPerDay = 5;
}
