import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../models/recipe_tags.dart';
import 'recipe_suitability.dart';

/// Profil alanlarına göre tarif sırası. Haftalık plan üretmez.
class RecipeRecommendationService {
  const RecipeRecommendationService();

  List<Recipe> recommend(List<Recipe> recipes, UserProfile? profile) {
    if (profile == null) return List<Recipe>.from(recipes);
    final suitable = [
      for (final recipe in recipes)
        if (_suitable(recipe, profile)) recipe,
    ];
    final perMeal = _perMealBudget(profile);
    final preferred = perMeal == null
        ? suitable
        : suitable.where((r) => _withinBudget(r, profile.goal, perMeal)).toList();
    final pool = preferred.isEmpty ? suitable : preferred;
    final sorted = [...pool]..sort((a, b) => _compare(a, b, profile, perMeal));
    return sorted;
  }

  bool isSuitable(Recipe recipe, UserProfile profile) =>
      _suitable(recipe, profile);

  bool _suitable(Recipe recipe, UserProfile profile) {
    for (final allergy in profile.allergies) {
      if (RecipeSuitability.conflictsWithAllergy(recipe, allergy)) {
        return false;
      }
    }
    if (RecipeSuitability.containsDisliked(recipe, profile.dislikedFoods)) {
      return false;
    }
    return RecipeSuitability.matchesDiet(recipe, profile.dietType);
  }

  double? _perMealBudget(UserProfile profile) {
    final calories = profile.dailyCalories;
    final meals = profile.mealsPerDay;
    if (calories == null || meals == null || meals < 1 || calories <= 0) {
      return null;
    }
    return calories / meals;
  }

  bool _withinBudget(Recipe recipe, GoalType? goal, double perMeal) {
    final kcal = recipe.calories;
    return switch (goal) {
      GoalType.loseWeight => kcal <= perMeal * 1.15 && kcal > 0,
      GoalType.gainWeight || GoalType.buildMuscle => kcal >= perMeal * 0.45,
      _ => kcal <= perMeal * 1.35 && kcal >= perMeal * 0.35,
    };
  }

  int _compare(
    Recipe a,
    Recipe b,
    UserProfile profile,
    double? perMeal,
  ) {
    final goal = profile.goal;
    if (goal == GoalType.buildMuscle || goal == GoalType.gainWeight) {
      final protein = b.protein.compareTo(a.protein);
      if (protein != 0) return protein;
    }
    if (goal == GoalType.eatHealthier) {
      final fiber = b.fiber.compareTo(a.fiber);
      if (fiber != 0) return fiber;
    }
    if (goal == GoalType.loseWeight) {
      final kcal = a.calories.compareTo(b.calories);
      if (kcal != 0) return kcal;
    }
    if (perMeal != null) {
      final da = (a.calories - perMeal).abs();
      final db = (b.calories - perMeal).abs();
      final distance = da.compareTo(db);
      if (distance != 0) return distance;
    }
    final proteinTag = _tagRank(b, RecipeTags.highProtein)
        .compareTo(_tagRank(a, RecipeTags.highProtein));
    if (proteinTag != 0) return proteinTag;
    return a.title.compareTo(b.title);
  }

  int _tagRank(Recipe recipe, String tag) => recipe.tags.contains(tag) ? 1 : 0;
}
