import '../../../../shared/models/enums.dart';
import '../../../../shared/models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/recipe_tags.dart';

/// Türkçe büyük/küçük harf farklarını (İ/ı) yok sayarak karşılaştırma.
String normalizeRecipeSearch(String text) =>
    text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();

/// Local katalog üzerinde arama ölçütü. Ağ çağrısı yoktur.
class RecipeCriteria {
  const RecipeCriteria({
    this.query = '',
    this.category,
    this.mealType,
    this.tags = const {},
    this.maxCalories,
    this.favoritesOnly = false,
  });

  final String query;
  final String? category;
  final MealType? mealType;
  final Set<String> tags;
  final double? maxCalories;
  final bool favoritesOnly;
}

abstract final class RecipeQuery {
  static List<Recipe> search(List<Recipe> recipes, String query) =>
      apply(recipes, RecipeCriteria(query: query));

  static List<Recipe> byCategory(List<Recipe> recipes, String category) =>
      apply(recipes, RecipeCriteria(category: category));

  static List<Recipe> byMealType(List<Recipe> recipes, MealType type) =>
      apply(recipes, RecipeCriteria(mealType: type));

  static List<Recipe> byTags(List<Recipe> recipes, Set<String> tags) =>
      apply(recipes, RecipeCriteria(tags: tags));

  static bool hasTag(Recipe recipe, String tag) {
    if (recipe.tags.contains(tag) || recipe.category == tag) return true;
    final categories = RecipeCategory.of(recipe);
    return switch (tag) {
      RecipeTags.highProtein => categories.contains(RecipeCategory.highProtein),
      RecipeTags.lowCalorie => categories.contains(RecipeCategory.lowCalorie),
      _ => categories.any((c) => c.name == tag),
    };
  }

  static List<Recipe> apply(
    List<Recipe> recipes,
    RecipeCriteria criteria, {
    Set<String> favorites = const {},
  }) {
    final query = normalizeRecipeSearch(criteria.query);
    return [
      for (final recipe in recipes)
        if ((!criteria.favoritesOnly || favorites.contains(recipe.id)) &&
            (criteria.category == null ||
                _matchesCategory(recipe, criteria.category!)) &&
            (criteria.mealType == null ||
                _matchesMeal(recipe, criteria.mealType!)) &&
            criteria.tags.every((tag) => hasTag(recipe, tag)) &&
            (criteria.maxCalories == null ||
                (recipe.calories > 0 &&
                    recipe.calories <= criteria.maxCalories!)) &&
            (query.isEmpty || _matchesQuery(recipe, query)))
          recipe,
    ];
  }

  static bool _matchesQuery(Recipe recipe, String query) =>
      normalizeRecipeSearch(recipe.title).contains(query) ||
      normalizeRecipeSearch(recipe.description ?? '').contains(query) ||
      recipe.ingredients.any(
        (i) => normalizeRecipeSearch(i.name).contains(query),
      ) ||
      recipe.tags.any((t) => normalizeRecipeSearch(t).contains(query));

  static bool _matchesCategory(Recipe recipe, String category) {
    if (recipe.category == category || recipe.tags.contains(category)) {
      return true;
    }
    return RecipeCategory.of(recipe).any((c) => c.name == category);
  }

  static bool _matchesMeal(Recipe recipe, MealType type) {
    if (recipe.mealTypes.contains(type) || recipe.tags.contains(type.name)) {
      return true;
    }
    return type == MealType.snack &&
        (recipe.tags.contains('dessert') || recipe.tags.contains('drink'));
  }
}
