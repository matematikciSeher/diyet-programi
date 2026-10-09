import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import '../../../../shared/models/user_profile.dart';
import '../services/plan_change_parser.dart';
import 'plan_ingredient.dart';

/// Yeme penceresi; gece yarısından itibaren dakika. [end] ertesi güne
/// taşabilir (ör. 20:00 + 8 saat → 1680).
typedef EatingWindow = ({int start, int end});

/// Plan üretirken uyulan kısıtlar: günlük kalori, öğün düzeni,
/// önerilmeyecek bileşenler ve varsa aralıklı oruç yeme penceresi.
class MealPlanPreferences extends Equatable {
  const MealPlanPreferences({
    this.dailyCalories = defaultCalories,
    this.slots = defaultSlots,
    this.excluded = const {},
    this.eatingWindow,
  });

  /// Diyet tipi, alerjiler ve sevilmeyen yiyecekler [excluded]'a çevrilir.
  /// Oruç protokolü seçiliyse öğün saatleri yeme penceresine yerleşir;
  /// pencere 8 saat veya daha kısaysa kahvaltı yerine öğle ile başlanır.
  factory MealPlanPreferences.fromProfile(UserProfile? profile) {
    if (profile == null) return const MealPlanPreferences();
    final excluded = <PlanIngredient>{
      ...PlanIngredient.excludedByDiet(profile.dietType),
      for (final allergy in profile.allergies)
        ...switch (Allergen.tryParse(allergy)) {
          final Allergen a => PlanIngredient.forAllergen(a),
          null => PlanChangeParser.ingredientsIn(allergy),
        },
      for (final food in profile.dislikedFoods)
        ...PlanChangeParser.ingredientsIn(food),
    };
    final fasting = profile.isFasting ? profile.fastingPreference : null;
    final window = fasting == null
        ? null
        : (
            start: profile.effectiveEatingWindowStart,
            end: profile.effectiveEatingWindowStart + fasting.eatingHours * 60,
          );
    final shortWindow = fasting != null && fasting.eatingHours <= 8;
    return MealPlanPreferences(
      dailyCalories: profile.dailyCalories?.toDouble() ?? defaultCalories,
      slots: slotsFor(
        profile.mealsPerDay,
        shortWindow ? BreakfastPreference.never : profile.breakfastPreference,
      ),
      excluded: excluded,
      eatingWindow: window,
    );
  }

  static const defaultCalories = 2000.0;
  static const defaultSlots = [
    MealType.breakfast,
    MealType.lunch,
    MealType.snack,
    MealType.dinner,
  ];

  final double dailyCalories;

  /// Günün öğün sırası; ara öğün birden fazla olabilir.
  final List<MealType> slots;
  final Set<PlanIngredient> excluded;
  final EatingWindow? eatingWindow;

  MealPlanPreferences withExcluded(Set<PlanIngredient> more) => more.isEmpty
      ? this
      : MealPlanPreferences(
          dailyCalories: dailyCalories,
          slots: slots,
          excluded: {...excluded, ...more},
          eatingWindow: eatingWindow,
        );

  /// Her öğünün günlük kaloriden payı; toplamı 1 olacak şekilde ölçeklenir.
  List<double> get calorieTargets {
    double share(MealType type) => switch (type) {
      MealType.breakfast => 0.25,
      MealType.lunch => 0.35,
      MealType.dinner => 0.30,
      MealType.snack => 0.10,
    };
    final total = slots.fold(0.0, (sum, t) => sum + share(t));
    return [for (final t in slots) dailyCalories * share(t) / total];
  }

  static List<MealType> slotsFor(int? mealsPerDay, BreakfastPreference? pref) {
    final count = (mealsPerDay ?? defaultSlots.length).clamp(2, 6);
    final skipBreakfast = pref == BreakfastPreference.never;
    if (count == 2) {
      return skipBreakfast
          ? const [MealType.lunch, MealType.dinner]
          : const [MealType.breakfast, MealType.dinner];
    }
    final mains = skipBreakfast ? 2 : 3;
    final snacks = count - mains;
    return [
      if (!skipBreakfast) MealType.breakfast,
      if (snacks >= 2) MealType.snack,
      MealType.lunch,
      if (snacks >= 1) MealType.snack,
      MealType.dinner,
      if (snacks >= 3) MealType.snack,
    ];
  }

  @override
  List<Object?> get props => [dailyCalories, slots, excluded, eatingWindow];
}
