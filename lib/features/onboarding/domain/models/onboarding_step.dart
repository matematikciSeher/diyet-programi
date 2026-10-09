import '../../../../shared/models/enums.dart';

/// Onboarding akışındaki ekranlar. Sıra bu enum'daki sıradır; bazı sorular
/// hedefe göre atlanır (bkz. [OnboardingStep.flowFor]).
enum OnboardingStep {
  welcome,
  benefitPlan,
  benefitTracking,
  benefitHabits,
  name,
  goal,
  gender,
  age,
  height,
  weight,
  targetWeight,
  activityLevel,
  exerciseFrequency,
  dietType,
  allergies,
  dislikedFoods,
  mealsPerDay,
  breakfast,
  water,
  fasting,
  targetDate,
  summary;

  static const intro = [welcome, benefitPlan, benefitTracking, benefitHabits];

  bool get isIntro => intro.contains(this);

  /// İlerleme çubuğunda sayılan soru ekranı mı?
  bool get isQuestion => !isIntro && this != summary;

  /// Metin girişi olan (klavye açan) adımlar.
  bool get usesKeyboard =>
      this == name ||
      this == age ||
      this == height ||
      this == weight ||
      this == targetWeight ||
      this == dislikedFoods;

  /// Seçilen hedefe göre gösterilecek adımlar.
  static List<OnboardingStep> flowFor(GoalType? goal) {
    final changesWeight = goal?.changesWeight ?? true;
    return [
      for (final step in values)
        if (changesWeight || (step != targetWeight && step != targetDate)) step,
    ];
  }

  static OnboardingStep? tryParse(Object? value) {
    for (final step in values) {
      if (step.name == value) return step;
    }
    return null;
  }
}
