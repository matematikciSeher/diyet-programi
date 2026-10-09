import '../../models/enums.dart';

/// Bazal metabolizma hızı (BMR, kcal/gün) formülü.
///
/// Yeni bir formül (ör. vücut yağ oranı biliniyorsa Katch-McArdle)
/// eklemek için bu arayüzü uygulamak ve `nutritionCalculatorProvider`'a
/// vermek yeterlidir.
abstract interface class BmrFormula {
  String get id;

  double calculate({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  });
}

/// Mifflin-St Jeor (1990). Güncel kılavuzlarda sağlıklı yetişkinler için
/// en isabetli kabul edilen formül; varsayılan olarak kullanılır.
final class MifflinStJeorFormula implements BmrFormula {
  const MifflinStJeorFormula();

  @override
  String get id => 'mifflin_st_jeor';

  @override
  double calculate({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return base +
        switch (gender) {
          Gender.male => 5,
          Gender.female => -161,
          // Cinsiyet belirtilmediğinde iki sabitin ortalaması kullanılır.
          Gender.unspecified => -78,
        };
  }
}

/// Revize Harris-Benedict (Roza & Shizgal, 1984).
final class HarrisBenedictFormula implements BmrFormula {
  const HarrisBenedictFormula();

  @override
  String get id => 'harris_benedict_revised';

  @override
  double calculate({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    double male() =>
        88.362 + 13.397 * weightKg + 4.799 * heightCm - 5.677 * age;
    double female() =>
        447.593 + 9.247 * weightKg + 3.098 * heightCm - 4.330 * age;
    return switch (gender) {
      Gender.male => male(),
      Gender.female => female(),
      Gender.unspecified => (male() + female()) / 2,
    };
  }
}
