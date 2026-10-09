import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Beslenmeye özgü semantik renkler (makro halkaları, grafikler, su vb.).
@immutable
class NutritionColors extends ThemeExtension<NutritionColors> {
  const NutritionColors({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.water,
    required this.success,
    required this.warning,
  });

  static const light = NutritionColors(
    calories: AppColors.calories,
    protein: AppColors.protein,
    carbs: AppColors.carbs,
    fat: AppColors.fat,
    fiber: AppColors.fiber,
    water: AppColors.water,
    success: AppColors.success,
    warning: AppColors.warning,
  );

  static const dark = NutritionColors(
    calories: AppColors.caloriesDark,
    protein: AppColors.proteinDark,
    carbs: AppColors.carbsDark,
    fat: AppColors.fatDark,
    fiber: AppColors.fiberDark,
    water: AppColors.waterDark,
    success: AppColors.successDark,
    warning: AppColors.warningDark,
  );

  final Color calories;
  final Color protein;
  final Color carbs;
  final Color fat;
  final Color fiber;
  final Color water;
  final Color success;
  final Color warning;

  @override
  NutritionColors copyWith({
    Color? calories,
    Color? protein,
    Color? carbs,
    Color? fat,
    Color? fiber,
    Color? water,
    Color? success,
    Color? warning,
  }) {
    return NutritionColors(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      water: water ?? this.water,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  NutritionColors lerp(NutritionColors? other, double t) {
    if (other == null) return this;
    return NutritionColors(
      calories: Color.lerp(calories, other.calories, t)!,
      protein: Color.lerp(protein, other.protein, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      fat: Color.lerp(fat, other.fat, t)!,
      fiber: Color.lerp(fiber, other.fiber, t)!,
      water: Color.lerp(water, other.water, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
