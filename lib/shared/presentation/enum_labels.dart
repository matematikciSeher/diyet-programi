import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../models/enums.dart';

/// Profil enum'larının yerelleştirilmiş etiketleri ve ikonları.
extension GoalTypeL10n on GoalType {
  String label(AppLocalizations l10n) => switch (this) {
    GoalType.loseWeight => l10n.goalLoseWeight,
    GoalType.maintainWeight => l10n.goalMaintainWeight,
    GoalType.gainWeight => l10n.goalGainWeight,
    GoalType.buildMuscle => l10n.goalBuildMuscle,
    GoalType.eatHealthier => l10n.goalEatHealthier,
  };

  String description(AppLocalizations l10n) => switch (this) {
    GoalType.loseWeight => l10n.goalLoseWeightDesc,
    GoalType.maintainWeight => l10n.goalMaintainWeightDesc,
    GoalType.gainWeight => l10n.goalGainWeightDesc,
    GoalType.buildMuscle => l10n.goalBuildMuscleDesc,
    GoalType.eatHealthier => l10n.goalEatHealthierDesc,
  };

  IconData get icon => switch (this) {
    GoalType.loseWeight => Icons.trending_down_rounded,
    GoalType.maintainWeight => Icons.balance_rounded,
    GoalType.gainWeight => Icons.trending_up_rounded,
    GoalType.buildMuscle => Icons.fitness_center_rounded,
    GoalType.eatHealthier => Icons.eco_outlined,
  };
}

extension GenderL10n on Gender {
  String label(AppLocalizations l10n) => switch (this) {
    Gender.female => l10n.genderFemale,
    Gender.male => l10n.genderMale,
    Gender.unspecified => l10n.genderUnspecified,
  };

  IconData get icon => switch (this) {
    Gender.female => Icons.female_rounded,
    Gender.male => Icons.male_rounded,
    Gender.unspecified => Icons.person_outline_rounded,
  };
}

extension ActivityLevelL10n on ActivityLevel {
  String label(AppLocalizations l10n) => switch (this) {
    ActivityLevel.sedentary => l10n.activitySedentary,
    ActivityLevel.light => l10n.activityLight,
    ActivityLevel.moderate => l10n.activityModerate,
    ActivityLevel.active => l10n.activityActive,
    ActivityLevel.veryActive => l10n.activityVeryActive,
  };

  String description(AppLocalizations l10n) => switch (this) {
    ActivityLevel.sedentary => l10n.activitySedentaryDesc,
    ActivityLevel.light => l10n.activityLightDesc,
    ActivityLevel.moderate => l10n.activityModerateDesc,
    ActivityLevel.active => l10n.activityActiveDesc,
    ActivityLevel.veryActive => l10n.activityVeryActiveDesc,
  };

  IconData get icon => switch (this) {
    ActivityLevel.sedentary => Icons.weekend_outlined,
    ActivityLevel.light => Icons.directions_walk_rounded,
    ActivityLevel.moderate => Icons.directions_bike_rounded,
    ActivityLevel.active => Icons.directions_run_rounded,
    ActivityLevel.veryActive => Icons.bolt_rounded,
  };
}

extension ExerciseFrequencyL10n on ExerciseFrequency {
  String label(AppLocalizations l10n) => switch (this) {
    ExerciseFrequency.none => l10n.exerciseNone,
    ExerciseFrequency.oneToTwo => l10n.exerciseOneToTwo,
    ExerciseFrequency.threeToFour => l10n.exerciseThreeToFour,
    ExerciseFrequency.fiveToSix => l10n.exerciseFiveToSix,
    ExerciseFrequency.daily => l10n.exerciseDaily,
  };
}

extension DietTypeL10n on DietType {
  String label(AppLocalizations l10n) => switch (this) {
    DietType.omnivore => l10n.dietOmnivore,
    DietType.vegetarian => l10n.dietVegetarian,
    DietType.vegan => l10n.dietVegan,
    DietType.pescatarian => l10n.dietPescatarian,
  };

  String description(AppLocalizations l10n) => switch (this) {
    DietType.omnivore => l10n.dietOmnivoreDesc,
    DietType.vegetarian => l10n.dietVegetarianDesc,
    DietType.vegan => l10n.dietVeganDesc,
    DietType.pescatarian => l10n.dietPescatarianDesc,
  };

  IconData get icon => switch (this) {
    DietType.omnivore => Icons.restaurant_rounded,
    DietType.vegetarian => Icons.egg_alt_outlined,
    DietType.vegan => Icons.spa_outlined,
    DietType.pescatarian => Icons.set_meal_outlined,
  };
}

extension AllergenL10n on Allergen {
  String label(AppLocalizations l10n) => switch (this) {
    Allergen.gluten => l10n.allergenGluten,
    Allergen.lactose => l10n.allergenLactose,
    Allergen.milk => l10n.allergenMilk,
    Allergen.egg => l10n.allergenEgg,
    Allergen.peanut => l10n.allergenPeanut,
    Allergen.treeNuts => l10n.allergenTreeNuts,
    Allergen.soy => l10n.allergenSoy,
    Allergen.fish => l10n.allergenFish,
    Allergen.shellfish => l10n.allergenShellfish,
    Allergen.sesame => l10n.allergenSesame,
  };
}

extension BreakfastPreferenceL10n on BreakfastPreference {
  String label(AppLocalizations l10n) => switch (this) {
    BreakfastPreference.always => l10n.breakfastAlways,
    BreakfastPreference.sometimes => l10n.breakfastSometimes,
    BreakfastPreference.never => l10n.breakfastNever,
  };

  IconData get icon => switch (this) {
    BreakfastPreference.always => Icons.free_breakfast_outlined,
    BreakfastPreference.sometimes => Icons.schedule_rounded,
    BreakfastPreference.never => Icons.no_meals_outlined,
  };
}

extension MealTypeL10n on MealType {
  String label(AppLocalizations l10n) => switch (this) {
    MealType.breakfast => l10n.mealBreakfast,
    MealType.lunch => l10n.mealLunch,
    MealType.dinner => l10n.mealDinner,
    MealType.snack => l10n.mealSnack,
  };

  IconData get icon => switch (this) {
    MealType.breakfast => Icons.free_breakfast_outlined,
    MealType.lunch => Icons.lunch_dining_outlined,
    MealType.dinner => Icons.dinner_dining_outlined,
    MealType.snack => Icons.cookie_outlined,
  };
}

extension FastingPreferenceL10n on FastingPreference {
  String label(AppLocalizations l10n) => this == FastingPreference.none
      ? l10n.fastingNone
      : l10n.fastingWindow(fastingHours, eatingHours);

  String description(AppLocalizations l10n) => this == FastingPreference.none
      ? l10n.fastingNoneDesc
      : l10n.fastingWindowDesc(fastingHours, eatingHours);
}

/// Yerel ayara uygun sayı biçimlendirme.
abstract final class AppFormat {
  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  static String integer(BuildContext context, num value) =>
      NumberFormat.decimalPattern(_locale(context)).format(value.round());

  /// En fazla [digits] ondalık basamak; gereksiz sıfırlar gösterilmez.
  static String decimal(BuildContext context, num value, {int digits = 1}) {
    final format = NumberFormat.decimalPattern(_locale(context))
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = digits;
    return format.format(value);
  }

  static String liters(BuildContext context, int ml) =>
      decimal(context, ml / 1000, digits: 2);

  static String date(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);

  /// Gece yarısından itibaren dakikayı saat olarak gösterir (ör. 750 → 12:30).
  static String minutesOfDay(BuildContext context, int minutes) {
    final m = minutes % (24 * 60);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: m ~/ 60, minute: m % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
}
