import 'dart:convert';

import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../food/domain/services/food_calculation_service.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../domain/models/assistant_context.dart';
import '../../domain/models/assistant_grounded_facts.dart';
import 'assistant_text.dart';

/// Soruya göre modele gidecek en küçük bağlam.
///
/// Sayılar [FoodCalculationService] ve mevcut kayıtlardan yazılır.
/// Tüm katalog, tüm geçmiş ve tüm haftalık plan her istekte gönderilmez.
class AssistantContextPackage {
  const AssistantContextPackage({
    required this.scope,
    required this.facts,
    required this.payload,
    required this.recipes,
  });

  final AssistantQuestionScope scope;
  final AssistantGroundedFacts facts;
  final Map<String, Object?> payload;
  final List<Recipe> recipes;
}

class AssistantContextBuilder {
  const AssistantContextBuilder({
    this.maxInputChars = 6000,
    this.maxRecipes = 6,
    this.maxLoggedMeals = 8,
    this.maxPlanLines = 14,
    FoodCalculationService? calculator,
  }) : _calculator = calculator ?? const FoodCalculationService();

  final int maxInputChars;
  final int maxRecipes;
  final int maxLoggedMeals;
  final int maxPlanLines;
  final FoodCalculationService _calculator;

  AssistantContextPackage build({
    required String question,
    required AssistantContext context,
    List<Recipe> recipes = const [],
    List<PlannedMeal> weekPlan = const [],
  }) {
    final scope = AssistantText.scopeOf(question);
    final totals = _calculator.sum(context.todayMeals.map((e) => e.nutrition));
    final targets = context.profile?.nutritionTargets;
    final limitedRecipes = recipes.take(maxRecipes).toList();
    final facts = _facts(
      scope: scope,
      context: context,
      totalsCalories: totals.calories,
      totalsProtein: totals.proteinG,
      totalsCarbs: totals.carbsG,
      totalsFat: totals.fatG,
      targets: targets,
      weekPlan: weekPlan,
    );
    final payload = _payload(
      question: question,
      scope: scope,
      context: context,
      facts: facts,
      recipes: limitedRecipes,
    );
    final fitted = _fit(payload);
    return AssistantContextPackage(
      scope: scope,
      facts: facts,
      payload: fitted,
      recipes: limitedRecipes,
    );
  }

  AssistantGroundedFacts _facts({
    required AssistantQuestionScope scope,
    required AssistantContext context,
    required double totalsCalories,
    required double totalsProtein,
    required double totalsCarbs,
    required double totalsFat,
    required NutritionTargets? targets,
    required List<PlannedMeal> weekPlan,
  }) {
    final nutrition =
        scope == AssistantQuestionScope.daily ||
        scope == AssistantQuestionScope.calories ||
        scope == AssistantQuestionScope.protein ||
        scope == AssistantQuestionScope.meal ||
        scope == AssistantQuestionScope.recipe ||
        scope == AssistantQuestionScope.todayPlan;
    final showAllMacros = scope == AssistantQuestionScope.daily;
    final activity = context.todayActivity;
    final planMeals = scope == AssistantQuestionScope.weekPlan
        ? weekPlan
        : context.todayPlan;
    final planLines = [
      for (final meal in planMeals.take(maxPlanLines))
        '${meal.dayKey} ${meal.mealType.name}: ${meal.title} (${meal.nutrition.calories.round()} kcal)',
    ];
    final missing = <String>[];
    if (scope == AssistantQuestionScope.activity &&
        (activity == null || !activity.stepsKnown)) {
      missing.add('steps');
    }
    if (targets == null &&
        (scope == AssistantQuestionScope.calories ||
            scope == AssistantQuestionScope.daily ||
            scope == AssistantQuestionScope.protein)) {
      missing.add('targets');
    }
    return AssistantGroundedFacts(
      showCalories: nutrition && scope != AssistantQuestionScope.protein,
      showProtein:
          showAllMacros ||
          scope == AssistantQuestionScope.protein ||
          scope == AssistantQuestionScope.meal,
      showCarbs: showAllMacros,
      showFat: showAllMacros,
      showWater:
          scope == AssistantQuestionScope.water ||
          scope == AssistantQuestionScope.daily,
      showActivity:
          scope == AssistantQuestionScope.activity ||
          scope == AssistantQuestionScope.daily,
      showPlan:
          scope == AssistantQuestionScope.todayPlan ||
          scope == AssistantQuestionScope.weekPlan,
      targetsKnown: targets != null,
      consumedCalories: totalsCalories,
      calorieTarget: targets?.calories,
      consumedProteinG: totalsProtein,
      proteinTargetG: targets?.proteinG,
      consumedCarbsG: totalsCarbs,
      carbTargetG: targets?.carbsG,
      consumedFatG: totalsFat,
      fatTargetG: targets?.fatG,
      waterMl: context.todayWaterMl,
      waterGoalMl: context.profile?.waterGoal ?? targets?.waterMl,
      steps: activity != null && activity.stepsKnown ? activity.steps : null,
      stepsKnown: activity?.stepsKnown ?? false,
      distanceMeters: activity != null && activity.distanceKnown
          ? activity.distanceMeters
          : null,
      distanceKnown: activity?.distanceKnown ?? false,
      activeCalories: activity != null && activity.caloriesKnown
          ? activity.activeCalories
          : null,
      activeCaloriesKnown: activity?.caloriesKnown ?? false,
      workoutCount: activity != null && activity.workoutsKnown
          ? activity.workoutCount
          : null,
      workoutsKnown: activity?.workoutsKnown ?? false,
      planLines: planLines,
      missing: missing,
    );
  }

  Map<String, Object?> _payload({
    required String question,
    required AssistantQuestionScope scope,
    required AssistantContext context,
    required AssistantGroundedFacts facts,
    required List<Recipe> recipes,
  }) {
    final profile = _profileSlice(context.profile, scope);
    final meals = [
      for (final meal in context.todayMeals.take(maxLoggedMeals))
        {
          'name': meal.name,
          'meal': meal.mealType.name,
          'kcal': meal.nutrition.calories.round(),
        },
    ];
    return {
      'question': question.trim(),
      'scope': scope.name,
      'numbersSource': 'app_calculated',
      if (facts.showCalories || facts.showProtein)
        'nutrition': {
          'source': 'daily_log',
          if (facts.showCalories) 'consumedKcal': facts.consumedCalories,
          if (facts.showCalories) 'targetKcal': facts.calorieTarget,
          if (facts.showCalories &&
              facts.consumedCalories != null &&
              facts.calorieTarget != null)
            'remainingKcal': facts.calorieTarget! - facts.consumedCalories!,
          if (facts.showProtein) 'consumedProteinG': facts.consumedProteinG,
          if (facts.showProtein) 'targetProteinG': facts.proteinTargetG,
          if (facts.showCarbs) 'consumedCarbsG': facts.consumedCarbsG,
          if (facts.showCarbs) 'targetCarbsG': facts.carbTargetG,
          if (facts.showFat) 'consumedFatG': facts.consumedFatG,
          if (facts.showFat) 'targetFatG': facts.fatTargetG,
          'targetsKnown': facts.targetsKnown,
        },
      if (facts.showWater)
        'water': {
          'source': 'water_log',
          'consumedMl': facts.waterMl,
          'goalMl': facts.waterGoalMl,
        },
      if (facts.showActivity)
        'activity': {
          'source': 'daily_activity',
          'deviceLocalOnly': true,
          if (facts.stepsKnown) 'steps': facts.steps,
          if (facts.distanceKnown) 'distanceMeters': facts.distanceMeters,
          if (facts.activeCaloriesKnown) 'activeKcal': facts.activeCalories,
          if (facts.workoutsKnown) 'workouts': facts.workoutCount,
          if (facts.missing.contains('steps')) 'steps': 'unavailable',
        },
      if (facts.showPlan)
        'plan': {
          'source': 'planned_meal',
          'lines': facts.planLines,
          'note': 'read_only',
        },
      if (meals.isNotEmpty &&
          (scope == AssistantQuestionScope.daily ||
              scope == AssistantQuestionScope.meal ||
              scope == AssistantQuestionScope.calories))
        'loggedMeals': meals,
      if (profile.isNotEmpty) 'profile': profile,
      if (recipes.isNotEmpty)
        'recipeCandidates': [
          for (final recipe in recipes)
            {
              'id': recipe.id,
              'title': recipe.title,
              'kcal': recipe.calories.round(),
              'proteinG': recipe.protein.round(),
              'mealTypes': [for (final type in recipe.mealTypes) type.name],
            },
        ],
      if (facts.missing.isNotEmpty) 'missing': facts.missing,
    };
  }

  Map<String, Object?> _profileSlice(
    UserProfile? profile,
    AssistantQuestionScope scope,
  ) {
    if (profile == null) return const {};
    final needsProfile =
        scope == AssistantQuestionScope.meal ||
        scope == AssistantQuestionScope.recipe ||
        scope == AssistantQuestionScope.todayPlan ||
        scope == AssistantQuestionScope.weekPlan ||
        scope == AssistantQuestionScope.daily ||
        scope == AssistantQuestionScope.protein;
    if (!needsProfile) return const {};
    return {
      'age': profile.age,
      'gender': profile.gender?.name,
      'heightCm': profile.height,
      'weightKg': profile.weight,
      'targetWeightKg': profile.targetWeight,
      'activityLevel': profile.activityLevel?.name,
      'goal': profile.goal?.name,
      'dietType': profile.dietType?.name,
      'allergies': profile.allergies,
      'dislikedFoods': profile.dislikedFoods,
      'mealsPerDay': profile.mealsPerDay,
      'breakfast': profile.breakfastPreference?.name,
      'waterGoalMl': profile.waterGoal,
      'fasting': profile.fastingPreference?.name,
      'dailyCalories': profile.dailyCalories,
      'proteinGoal': profile.proteinGoal,
      'carbGoal': profile.carbGoal,
      'fatGoal': profile.fatGoal,
    };
  }

  Map<String, Object?> _fit(Map<String, Object?> payload) {
    var encoded = jsonEncode(payload);
    if (encoded.length <= maxInputChars) return payload;
    final copy = Map<String, Object?>.of(payload)..remove('recipeCandidates');
    encoded = jsonEncode(copy);
    if (encoded.length <= maxInputChars) return copy;
    copy.remove('plan');
    copy.remove('loggedMeals');
    return copy;
  }
}
