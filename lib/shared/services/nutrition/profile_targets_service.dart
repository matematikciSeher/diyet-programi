import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/user_profile.dart';
import 'nutrition_calculator.dart';

/// Profilden yeniden hesaplanan ve kullanıcı onayı bekleyen hedefler.
class TargetSuggestion extends Equatable {
  const TargetSuggestion({
    required this.currentCalories,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.maintenanceCalories,
    this.currentProteinG,
    this.currentCarbsG,
    this.currentFatG,
    this.weightKg,
    this.previousWeightKg,
    this.estimatedGoalDate,
    this.limited = false,
    this.notices = const {},
  });

  final int? currentCalories;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int? currentProteinG;
  final int? currentCarbsG;
  final int? currentFatG;
  final int maintenanceCalories;
  final double? weightKg;
  final double? previousWeightKg;
  final DateTime? estimatedGoalDate;

  /// Değişim tek adımda uygulanabilecek sınırı aştığı için kısıldı.
  final bool limited;
  final Set<HealthNotice> notices;

  int get deltaCalories => calories - (currentCalories ?? calories);

  bool get hasWeightChange =>
      previousWeightKg != null &&
      weightKg != null &&
      (previousWeightKg! - weightKg!).abs() >= 0.05;

  @override
  List<Object?> get props => [
    currentCalories,
    calories,
    proteinG,
    carbsG,
    fatG,
    currentProteinG,
    currentCarbsG,
    currentFatG,
    maintenanceCalories,
    weightKg,
    previousWeightKg,
    estimatedGoalDate,
    limited,
    notices,
  ];
}

/// Kilo veya profil bilgisi değişince kalori/makro hedeflerini
/// [NutritionCalculator]'ın güvenlik kurallarıyla yeniden hesaplar.
///
/// Hedefler asla otomatik değiştirilmez: [suggest] yalnızca öneri üretir,
/// [apply] kullanıcı onayladığında çağrılır. Tek seferde en fazla
/// [maxStepKcal] değişim önerilir; ani kalori düşüşleri engellenir.
class ProfileTargetsService {
  const ProfileTargetsService(this._calculator);

  final NutritionCalculator _calculator;

  /// Bu kadar küçük farklar için öneri gösterilmez.
  static const minDeltaKcal = 50;
  static const maxStepKcal = 200;

  static NutritionInput? inputFor(UserProfile profile) {
    final gender = profile.gender;
    final age = profile.age;
    final height = profile.height;
    final weight = profile.weight;
    final activity = profile.activityLevel;
    final goal = profile.goal;
    if (gender == null ||
        age == null ||
        height == null ||
        weight == null ||
        activity == null ||
        goal == null) {
      return null;
    }
    return NutritionInput(
      gender: gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      targetWeightKg: goal.changesWeight ? profile.targetWeight : weight,
      activityLevel: activity,
      exerciseFrequency: profile.exerciseFrequency ?? ExerciseFrequency.none,
      goal: goal,
      fastingPreference: profile.fastingPreference ?? FastingPreference.none,
      targetDate: goal.changesWeight ? profile.targetDate : null,
    );
  }

  /// Profil hesaplamaya yetmiyorsa ya da fark önemsizse `null`.
  TargetSuggestion? suggest(
    UserProfile profile, {
    DateTime? now,
    double? previousWeightKg,
  }) {
    final input = inputFor(profile);
    if (input == null) return null;
    final plan = _calculator.calculate(input, now: now);
    final current = profile.dailyCalories;
    var kcal = plan.targetCalories;
    var protein = plan.proteinG;
    var carbs = plan.carbsG;
    var fat = plan.fatG;
    var limited = false;

    if (current != null) {
      final delta = kcal - current;
      if (delta.abs() < minDeltaKcal &&
          profile.proteinGoal != null &&
          profile.carbGoal != null &&
          profile.fatGoal != null) {
        return null;
      }
      if (delta.abs() > maxStepKcal) {
        limited = true;
        kcal = current + (delta.isNegative ? -maxStepKcal : maxStepKcal);
        final fatRatio = plan.targetCalories <= 0
            ? 0.3
            : plan.fatG * 9 / plan.targetCalories;
        fat = (kcal * fatRatio / 9).round();
        protein = plan.proteinG;
        carbs = ((kcal - protein * 4 - fat * 9) / 4).round().clamp(0, 1000);
      }
    }
    return TargetSuggestion(
      currentCalories: current,
      calories: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      currentProteinG: profile.proteinGoal,
      currentCarbsG: profile.carbGoal,
      currentFatG: profile.fatGoal,
      maintenanceCalories: plan.maintenanceCalories,
      weightKg: profile.weight,
      previousWeightKg: previousWeightKg,
      estimatedGoalDate: plan.estimatedGoalDate,
      limited: limited,
      notices: plan.notices,
    );
  }

  UserProfile apply(UserProfile profile, TargetSuggestion suggestion) =>
      profile.copyWith(
        dailyCalories: suggestion.calories,
        proteinGoal: suggestion.proteinG,
        carbGoal: suggestion.carbsG,
        fatGoal: suggestion.fatG,
        maintenanceCalories: suggestion.maintenanceCalories,
        estimatedGoalDate: suggestion.estimatedGoalDate,
      );
}

final profileTargetsServiceProvider = Provider<ProfileTargetsService>(
  (ref) => ProfileTargetsService(ref.watch(nutritionCalculatorProvider)),
);
