import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../recipes/domain/services/recipe_portion_service.dart';
import '../../../recipes/domain/services/recipe_recommendation_service.dart';
import '../../../recipes/domain/services/recipe_suitability.dart';
import '../models/meal_plan_preferences.dart';
import '../models/plan_ingredient.dart';
import '../models/planned_meal.dart';
import 'meal_plan_generator.dart';

/// Profil hedeflerine göre gerçek tariflerden günlük plan seçer.
///
/// Günlük kalori hedefi [MealPlanPreferences.dailyCalories] üzerinden okunur
/// ve profile geri yazılmaz. Besin değerleri [RecipePortionService] ile
/// [NutritionFacts.scale] kullanılarak hesaplanır.
class PersonalizedMealPlanService {
  const PersonalizedMealPlanService({
    this.recommendations = const RecipeRecommendationService(),
    this.portions = const RecipePortionService(),
  });

  final RecipeRecommendationService recommendations;
  final RecipePortionService portions;

  static const servingChoices = [1.0, 2.0, 3.0];

  /// Aynı gün ve aynı tohum için aynı öğünleri üretir.
  ///
  /// [reservedRecipeIds] önceki günlerde seçilmiş tariflerdir; tekrar
  /// cezalandırılır. Aynı gün içinde aynı tarif iki öğünde kullanılmaz.
  List<PlannedMeal> generateDay({
    required DateTime day,
    required List<Recipe> recipes,
    required MealPlanPreferences prefs,
    UserProfile? profile,
    List<String> reservedRecipeIds = const [],
    int? seed,
  }) {
    final suitable = [
      for (final recipe in recipes)
        if (_allowed(recipe, profile, prefs)) recipe,
    ];
    final counts = <String, int>{};
    for (final id in reservedRecipeIds) {
      if (id.isEmpty) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final shares = _shares(prefs);
    final targets = _macroTargets(prefs, profile);
    final proteinWeight = _proteinWeight(profile);
    final meals = <PlannedMeal>[];
    final today = <String>{};
    final todayProteins = <String>{};
    final effectiveSeed =
        seed ?? (day.year * 10000 + day.month * 100 + day.day);

    for (final (index, type) in prefs.slots.indexed) {
      final pool = _pool(suitable, type, today);
      if (pool.isEmpty) continue;
      final share = shares[index];
      final ranked = [
        for (final recipe in pool)
          _chooseServings(
            recipe: recipe,
            targetKcal: prefs.calorieTargets[index],
            targetProtein: targets.protein * share,
            targetCarbs: targets.carbs * share,
            targetFat: targets.fat * share,
            targetFiber: targets.fiber * share,
            proteinWeight: proteinWeight,
            goal: profile?.goal,
            used: counts[recipe.id] ?? 0,
            proteinRepeat: todayProteins.contains(_proteinKey(recipe)),
            noise: _noise(effectiveSeed, index, recipe.id),
          ),
      ]..sort((a, b) => a.score.compareTo(b.score));
      final best = ranked.first.score;
      final band = ranked.where((c) => c.score <= best + 0.28).take(4).toList();
      final picked = band[_bandIndex(effectiveSeed, day, index, band.length)];
      today.add(picked.recipe.id);
      counts[picked.recipe.id] = (counts[picked.recipe.id] ?? 0) + 1;
      todayProteins.add(_proteinKey(picked.recipe));
      meals.add(
        _fromRecipe(
          dayKey: day.dayKey,
          id: '${day.dayKey}-$index',
          type: type,
          recipe: picked.recipe,
          servings: picked.servings,
          nutrition: picked.nutrition,
          timeMinutes: _time(prefs, index),
        ),
      );
    }
    return meals;
  }

  /// Aynı öğün tipi, kısıtlar ve kalori/protein yakınlığına göre alternatifler.
  /// Yalnızca [meal] değişir; haftanın geri kalanı burada üretilmez.
  List<PlannedMeal> alternatives({
    required PlannedMeal meal,
    required List<PlannedMeal> dayPlan,
    required List<Recipe> recipes,
    required MealPlanPreferences prefs,
    UserProfile? profile,
    int count = 6,
  }) {
    final blocked = <String>{
      for (final other in dayPlan)
        if (other.id != meal.id && other.recipeId != null) other.recipeId!,
      if (meal.recipeId != null) meal.recipeId!,
    };
    final suitable = [
      for (final recipe in recipes)
        if (_allowed(recipe, profile, prefs) && !blocked.contains(recipe.id))
          recipe,
    ];
    final typed = [
      for (final recipe in suitable)
        if (_matchesMeal(recipe, meal.mealType)) recipe,
    ];
    final pool = typed.isNotEmpty ? typed : suitable;
    final ranked = [
      for (final recipe in pool)
        _chooseServings(
          recipe: recipe,
          targetKcal: meal.nutrition.calories,
          targetProtein: meal.nutrition.proteinG,
          targetCarbs: meal.nutrition.carbsG,
          targetFat: meal.nutrition.fatG,
          targetFiber: meal.nutrition.fiberG ?? 0,
          proteinWeight: 1.2,
          goal: profile?.goal,
          used: 0,
          proteinRepeat: false,
        ),
    ]..sort((a, b) => a.score.compareTo(b.score));
    return [
      for (final candidate in ranked.take(count))
        _fromRecipe(
          dayKey: meal.dayKey,
          id: meal.id,
          type: meal.mealType,
          recipe: candidate.recipe,
          servings: candidate.servings,
          nutrition: candidate.nutrition,
          timeMinutes: meal.timeMinutes,
        ),
    ];
  }

  /// Porsiyonu 1, 2 veya 3'e yuvarlar. Tarif varsa besin
  /// [RecipePortionService] ile, yoksa mevcut değer [NutritionFacts.scale]
  /// ile güncellenir.
  PlannedMeal withServings(
    PlannedMeal meal,
    double servings, {
    Recipe? recipe,
  }) {
    final factor = snapServings(servings);
    final nutrition = recipe == null
        ? _rescale(meal, factor)
        : portions.forServings(recipe, factor);
    return PlannedMeal(
      id: meal.id,
      dayKey: meal.dayKey,
      mealType: meal.mealType,
      title: recipe?.title ?? meal.title,
      nutrition: nutrition,
      items: recipe == null ? meal.items : const [],
      templateId: recipe == null ? meal.templateId : null,
      portionFactor: factor,
      description: recipe?.description ?? meal.description,
      recipeId: recipe?.id ?? meal.recipeId,
      timeMinutes: meal.timeMinutes,
    );
  }

  static double snapServings(double servings) => servingChoices.reduce(
    (a, b) => (a - servings).abs() <= (b - servings).abs() ? a : b,
  );

  bool _allowed(
    Recipe recipe,
    UserProfile? profile,
    MealPlanPreferences prefs,
  ) {
    if (recipe.nutritionPerServing.calories <= 0 && recipe.calories <= 0) {
      return false;
    }
    if (profile != null && !recommendations.isSuitable(recipe, profile)) {
      return false;
    }
    for (final ingredient in prefs.excluded) {
      if (_conflicts(recipe, ingredient)) return false;
    }
    return true;
  }

  List<Recipe> _pool(List<Recipe> suitable, MealType type, Set<String> today) {
    final fresh = [
      for (final recipe in suitable)
        if (!today.contains(recipe.id)) recipe,
    ];
    final typed = [
      for (final recipe in fresh)
        if (_matchesMeal(recipe, type)) recipe,
    ];
    if (typed.isNotEmpty) return typed;
    if (fresh.isNotEmpty) return fresh;
    return [
      for (final recipe in suitable)
        if (_matchesMeal(recipe, type)) recipe,
    ];
  }

  bool _matchesMeal(Recipe recipe, MealType type) {
    if (recipe.mealTypes.contains(type) || recipe.tags.contains(type.name)) {
      return true;
    }
    return type == MealType.snack &&
        (recipe.tags.contains('dessert') || recipe.tags.contains('drink'));
  }

  _Candidate _chooseServings({
    required Recipe recipe,
    required double targetKcal,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
    required double targetFiber,
    required double proteinWeight,
    required GoalType? goal,
    required int used,
    required bool proteinRepeat,
    double noise = 0,
  }) {
    _Candidate? best;
    for (final servings in servingChoices) {
      final nutrition = portions.forServings(recipe, servings);
      var score =
          _gap(nutrition.calories, targetKcal) * 1.15 +
          _gap(nutrition.proteinG, targetProtein) * proteinWeight +
          _gap(nutrition.carbsG, targetCarbs) * 0.3 +
          _gap(nutrition.fatG, targetFat) * 0.3 +
          _gap(nutrition.fiberG ?? 0, targetFiber) *
              (goal == GoalType.eatHealthier ? 0.35 : 0.1) +
          used * 0.9 +
          (proteinRepeat ? 0.45 : 0) +
          (servings - 1) * 0.03 +
          noise;
      if (goal == GoalType.loseWeight && nutrition.calories > targetKcal) {
        score += 0.12;
      }
      final candidate = _Candidate(recipe, servings, nutrition, score);
      if (best == null || candidate.score < best.score) best = candidate;
    }
    return best!;
  }

  static double _gap(double value, double target) {
    if (target <= 0) return 0;
    return (value - target).abs() / target;
  }

  /// Aktivite katsayısı kalori hedefini değiştirmez; yüksek aktivitede
  /// protein yakınlığına biraz daha ağırlık verir. Kalori zaten profilde
  /// TDEE üzerinden hesaplanmış hedeftir.
  double _proteinWeight(UserProfile? profile) {
    var weight = switch (profile?.goal) {
      GoalType.buildMuscle || GoalType.gainWeight => 1.35,
      GoalType.loseWeight => 1.05,
      _ => 0.9,
    };
    final activity = profile?.activityLevel;
    if (activity == ActivityLevel.active ||
        activity == ActivityLevel.veryActive) {
      weight += 0.25;
    }
    return weight;
  }

  _Macros _macroTargets(MealPlanPreferences prefs, UserProfile? profile) {
    final kcal = prefs.dailyCalories;
    return _Macros(
      protein: profile?.proteinGoal?.toDouble() ?? kcal * 0.20 / 4,
      carbs: profile?.carbGoal?.toDouble() ?? kcal * 0.50 / 4,
      fat: profile?.fatGoal?.toDouble() ?? kcal * 0.30 / 9,
      fiber: kcal <= 0 ? 25 : (kcal / 1000) * 14,
    );
  }

  List<double> _shares(MealPlanPreferences prefs) {
    final targets = prefs.calorieTargets;
    final total = prefs.dailyCalories;
    if (total <= 0) {
      final even = 1 / prefs.slots.length;
      return [for (final _ in prefs.slots) even];
    }
    return [for (final target in targets) target / total];
  }

  int _time(MealPlanPreferences prefs, int index) =>
      switch (prefs.eatingWindow) {
        final window? => MealPlanGenerator.windowTime(
          window,
          prefs.slots.length,
          index,
        ),
        null => MealPlanGenerator.defaultTime(prefs.slots, index),
      };

  double _noise(int seed, int slot, String id) {
    var hash = seed & 0x7fffffff;
    hash = (hash * 33 + slot) & 0x7fffffff;
    for (final unit in id.codeUnits) {
      hash = (hash * 33 + unit) & 0x7fffffff;
    }
    return (hash % 20) / 100;
  }

  int _bandIndex(int seed, DateTime day, int slot, int length) {
    if (length <= 1) return 0;
    var hash = seed & 0x7fffffff;
    hash = (hash * 33 + day.year) & 0x7fffffff;
    hash = (hash * 33 + day.month * 100 + day.day) & 0x7fffffff;
    hash = (hash * 33 + slot * 17) & 0x7fffffff;
    return hash % length;
  }

  NutritionFacts _rescale(PlannedMeal meal, double factor) {
    final current = meal.portionFactor <= 0 ? 1.0 : meal.portionFactor;
    return meal.nutrition.scale(factor / current);
  }

  PlannedMeal _fromRecipe({
    required String dayKey,
    required String id,
    required MealType type,
    required Recipe recipe,
    required double servings,
    required NutritionFacts nutrition,
    required int? timeMinutes,
  }) => PlannedMeal(
    id: id,
    dayKey: dayKey,
    mealType: type,
    title: recipe.title,
    nutrition: nutrition,
    portionFactor: servings,
    description: recipe.description,
    recipeId: recipe.id,
    timeMinutes: timeMinutes,
  );

  bool _conflicts(Recipe recipe, PlanIngredient ingredient) {
    final terms = _terms[ingredient];
    if (terms != null && RecipeSuitability.containsDisliked(recipe, terms)) {
      return true;
    }
    for (final item in recipe.ingredients) {
      final id = item.foodId ?? '';
      final bare = id.startsWith('sample-') ? id.substring(7) : id;
      final ids = switch (ingredient) {
        PlanIngredient.chicken ||
        PlanIngredient.redMeat => RecipeSuitability.meatFoodIds,
        PlanIngredient.fish ||
        PlanIngredient.shellfish => RecipeSuitability.fishFoodIds,
        PlanIngredient.egg => RecipeSuitability.eggFoodIds,
        PlanIngredient.milk ||
        PlanIngredient.cheese ||
        PlanIngredient.yogurt => RecipeSuitability.dairyFoodIds,
        PlanIngredient.gluten ||
        PlanIngredient.oats => RecipeSuitability.glutenFoodIds,
        PlanIngredient.nuts ||
        PlanIngredient.peanut => RecipeSuitability.nutFoodIds,
        _ => const <String>{},
      };
      if (ids.contains(id) || ids.contains(bare)) return true;
    }
    return false;
  }

  String _proteinKey(Recipe recipe) {
    for (final ingredient in recipe.ingredients) {
      final id = ingredient.foodId ?? '';
      final bare = id.startsWith('sample-') ? id.substring(7) : id;
      if (RecipeSuitability.meatFoodIds.contains(id) ||
          RecipeSuitability.meatFoodIds.contains(bare)) {
        return 'meat';
      }
      if (RecipeSuitability.fishFoodIds.contains(id) ||
          RecipeSuitability.fishFoodIds.contains(bare)) {
        return 'fish';
      }
      if (RecipeSuitability.eggFoodIds.contains(id) ||
          RecipeSuitability.eggFoodIds.contains(bare)) {
        return 'egg';
      }
      if (RecipeSuitability.dairyFoodIds.contains(id) ||
          RecipeSuitability.dairyFoodIds.contains(bare)) {
        return 'dairy';
      }
      final name = RecipeSuitability.fold(ingredient.name);
      if (name.contains('mercimek') ||
          name.contains('nohut') ||
          name.contains('fasulye') ||
          name.contains('barbunya')) {
        return 'legume';
      }
    }
    return recipe.category ?? recipe.id;
  }

  static const _terms = {
    PlanIngredient.chicken: ['tavuk', 'chicken'],
    PlanIngredient.redMeat: ['kuzu', 'dana', 'kiyma', 'kofte', 'hindi'],
    PlanIngredient.fish: ['balik', 'somon', 'ton', 'fish', 'salmon'],
    PlanIngredient.shellfish: ['karides', 'midye'],
    PlanIngredient.egg: ['yumurta', 'egg'],
    PlanIngredient.milk: ['sut', 'milk'],
    PlanIngredient.cheese: ['peynir', 'feta', 'lor'],
    PlanIngredient.yogurt: ['yogurt', 'ayran'],
    PlanIngredient.gluten: ['ekmek', 'makarna', 'bulgur', 'gluten'],
    PlanIngredient.oats: ['yulaf', 'oats'],
    PlanIngredient.nuts: ['ceviz', 'badem', 'findik'],
    PlanIngredient.peanut: ['fistik', 'peanut'],
    PlanIngredient.sesame: ['susam'],
    PlanIngredient.soy: ['soya', 'soy'],
    PlanIngredient.eggplant: ['patlican'],
    PlanIngredient.mushroom: ['mantar'],
    PlanIngredient.legumes: ['mercimek', 'nohut', 'fasulye'],
  };
}

class _Candidate {
  const _Candidate(this.recipe, this.servings, this.nutrition, this.score);

  final Recipe recipe;
  final double servings;
  final NutritionFacts nutrition;
  final double score;
}

class _Macros {
  const _Macros({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
}
