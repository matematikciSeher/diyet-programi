import 'package:equatable/equatable.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/meal_entry.dart';
import '../../../shared/models/nutrition_facts.dart';
import '../../../shared/models/nutrition_targets.dart';
import '../../activity/domain/models/daily_activity.dart';
import '../../meal_plans/domain/models/planned_meal.dart';
import 'nutrition_score.dart';

/// Dashboard'un tek bakışta gösterdiği günlük özet.
class DailyDashboard extends Equatable {
  DailyDashboard({
    required this.day,
    required this.targets,
    required this.meals,
    required this.waterMl,
    required this.activity,
    required this.plan,
    required this.score,
    this.userName,
  }) : consumed = meals.fold(
         NutritionFacts.zero,
         (sum, m) => sum + m.nutrition,
       );

  final DateTime day;
  final String? userName;
  final NutritionTargets targets;
  final List<MealEntry> meals;
  final int waterMl;
  final DailyActivity activity;
  final List<PlannedMeal> plan;
  final NutritionScore score;
  final NutritionFacts consumed;

  static const glassMl = 250;

  /// Negatifse hedef aşılmıştır.
  double get remainingCalories => targets.calories - consumed.calories;

  int get waterGlasses => waterMl ~/ glassMl;
  int get waterGoalGlasses => (targets.waterMl / glassMl).ceil();

  List<MealEntry> mealsOf(MealType type) =>
      meals.where((m) => m.mealType == type).toList();

  NutritionFacts totalOf(MealType type) =>
      mealsOf(type).fold(NutritionFacts.zero, (sum, m) => sum + m.nutrition);

  @override
  List<Object?> get props => [
    day,
    userName,
    targets,
    meals,
    waterMl,
    activity,
    plan,
    score,
  ];
}
