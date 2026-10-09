enum Gender { female, male, unspecified }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const ActivityLevel(this.multiplier);

  /// TDEE hesaplamasında BMR ile çarpılan fiziksel aktivite katsayısı (PAL).
  final double multiplier;
}

/// Haftalık yapılandırılmış egzersiz sıklığı. Aktivite katsayısına ek olarak
/// TDEE'ye eklenmez (çift sayımı önlemek için); protein hedefini etkiler.
enum ExerciseFrequency {
  none(0),
  oneToTwo(1.5),
  threeToFour(3.5),
  fiveToSix(5.5),
  daily(7);

  const ExerciseFrequency(this.sessionsPerWeek);

  final double sessionsPerWeek;
}

enum GoalType {
  loseWeight,
  maintainWeight,
  gainWeight,
  buildMuscle,
  eatHealthier;

  /// Hedef kilo ve hedef tarih sorularının anlamlı olduğu hedefler.
  bool get changesWeight =>
      this == loseWeight || this == gainWeight || this == buildMuscle;
}

enum DietType { omnivore, vegetarian, vegan, pescatarian }

enum BreakfastPreference { always, sometimes, never }

enum FastingPreference {
  none(0),
  twelveTwelve(12),
  fourteenTen(14),
  sixteenEight(16),
  eighteenSix(18),

  /// Yalnızca Aralıklı Oruç ekranında seçilebilir; onboarding'de sunulmaz.
  twentyFour(20);

  const FastingPreference(this.fastingHours);

  final int fastingHours;
  int get eatingHours => this == none ? 24 : 24 - fastingHours;

  /// Onboarding'de sunulan protokoller.
  static const onboardingOptions = [
    none,
    twelveTwelve,
    fourteenTen,
    sixteenEight,
    eighteenSix,
  ];

  /// Oruç ekranındaki protokol seçenekleri.
  static const protocols = [
    twelveTwelve,
    fourteenTen,
    sixteenEight,
    eighteenSix,
    twentyFour,
  ];
}

/// Seçilebilir yaygın alerji / intoleranslar. Profilde `name` olarak saklanır;
/// kullanıcının eklediği serbest metinler de aynı listede tutulur.
enum Allergen {
  gluten,
  lactose,
  milk,
  egg,
  peanut,
  treeNuts,
  soy,
  fish,
  shellfish,
  sesame;

  static Allergen? tryParse(String value) {
    for (final a in values) {
      if (a.name == value) return a;
    }
    return null;
  }
}

enum UnitSystem { metric, imperial }

enum MealType { breakfast, lunch, dinner, snack }

enum FoodSource { database, barcode, custom, recipe, aiPhoto, voice, mealPlan }

/// Beslenme skorunda kullanılan besin nitelikleri. Yemek veritabanı veya
/// kullanıcı tarafından kayda eklenir.
enum FoodTag { vegetable, fruit, wholeGrain, processed }

enum SubscriptionTier { free, premium }
