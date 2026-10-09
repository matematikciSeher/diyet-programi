import 'dart:math';

import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../models/meal_plan_preferences.dart';
import '../models/planned_meal.dart';
import 'meal_plan_generator.dart';
import 'personalized_meal_plan_service.dart';

/// Plan üretim kaynağı. Uygulama tarif kataloğunu kullanan
/// [RecipeMealPlanGenerationService] ile bağlanır; şablon üretici
/// katalog boşsa yedek olarak kalır.
abstract interface class MealPlanGenerationService {
  Future<List<PlannedMeal>> generateDay(
    DateTime day,
    MealPlanPreferences prefs, {
    int? seed,
    List<String> reservedRecipeIds = const [],
  });

  /// [meal] yerine seçilebilecek öneriler; en uygunu önce.
  Future<List<PlannedMeal>> alternatives(
    PlannedMeal meal,
    List<PlannedMeal> plan,
    MealPlanPreferences prefs, {
    int count = 3,
  });
}

final class RuleBasedMealPlanGenerationService
    implements MealPlanGenerationService {
  const RuleBasedMealPlanGenerationService(this._generator);

  final MealPlanGenerator _generator;

  @override
  Future<List<PlannedMeal>> generateDay(
    DateTime day,
    MealPlanPreferences prefs, {
    int? seed,
    List<String> reservedRecipeIds = const [],
  }) async => _generator.generateDay(day, prefs, seed: seed);

  @override
  Future<List<PlannedMeal>> alternatives(
    PlannedMeal meal,
    List<PlannedMeal> plan,
    MealPlanPreferences prefs, {
    int count = 3,
  }) async => _generator.alternativesFor(
    meal,
    plan,
    prefs,
    count: count,
    random: Random(),
  );
}

/// Tarif kataloğundan [PersonalizedMealPlanService] ile plan üretir.
/// Katalog boşsa [fallback] şablon planına döner.
final class RecipeMealPlanGenerationService
    implements MealPlanGenerationService {
  const RecipeMealPlanGenerationService({
    required PersonalizedMealPlanService plans,
    required Future<List<Recipe>> Function() loadRecipes,
    required UserProfile? Function() profile,
    required MealPlanGenerationService fallback,
  }) : _plans = plans,
       _loadRecipes = loadRecipes,
       _profile = profile,
       _fallback = fallback;

  final PersonalizedMealPlanService _plans;
  final Future<List<Recipe>> Function() _loadRecipes;
  final UserProfile? Function() _profile;
  final MealPlanGenerationService _fallback;

  @override
  Future<List<PlannedMeal>> generateDay(
    DateTime day,
    MealPlanPreferences prefs, {
    int? seed,
    List<String> reservedRecipeIds = const [],
  }) async {
    final recipes = await _loadRecipes();
    if (recipes.isEmpty) {
      return _fallback.generateDay(day, prefs, seed: seed);
    }
    final plan = _plans.generateDay(
      day: day,
      recipes: recipes,
      prefs: prefs,
      profile: _profile(),
      reservedRecipeIds: reservedRecipeIds,
      seed: seed,
    );
    if (plan.isEmpty) return _fallback.generateDay(day, prefs, seed: seed);
    return plan;
  }

  @override
  Future<List<PlannedMeal>> alternatives(
    PlannedMeal meal,
    List<PlannedMeal> plan,
    MealPlanPreferences prefs, {
    int count = 3,
  }) async {
    final recipes = await _loadRecipes();
    if (recipes.isEmpty) {
      return _fallback.alternatives(meal, plan, prefs, count: count);
    }
    final options = _plans.alternatives(
      meal: meal,
      dayPlan: plan,
      recipes: recipes,
      prefs: prefs,
      profile: _profile(),
      count: count,
    );
    if (options.isEmpty) {
      return _fallback.alternatives(meal, plan, prefs, count: count);
    }
    return options;
  }
}
