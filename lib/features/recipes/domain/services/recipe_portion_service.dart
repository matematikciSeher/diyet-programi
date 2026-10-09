import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/recipe.dart';

/// Seçilen porsiyon için besin ve malzeme miktarını ölçekler.
///
/// Ölçek [NutritionFacts.scale] üzerinden yapılır; arayüz kendi hesabını
/// kurmaz.
class RecipePortionService {
  const RecipePortionService();

  NutritionFacts forServings(Recipe recipe, double servings) {
    if (servings <= 0) return NutritionFacts.zero;
    return recipe.nutritionPerServing.scale(servings);
  }

  /// [servings], tarifin porsiyon başı değerine göre seçilen porsiyon sayısıdır.
  /// Malzeme listesi tarifin tamamı için saklandığından [Recipe.servings] ile
  /// oranlanır.
  List<RecipeIngredient> ingredientsForServings(
    Recipe recipe,
    double servings,
  ) {
    final base = recipe.servings <= 0 ? 1 : recipe.servings;
    final factor = servings / base;
    return [
      for (final ingredient in recipe.ingredients)
        RecipeIngredient(
          id: ingredient.id,
          foodId: ingredient.foodId,
          name: ingredient.name,
          quantity: ingredient.quantity * factor,
          unit: ingredient.unit,
          grams: ingredient.grams == null ? null : ingredient.grams! * factor,
        ),
    ];
  }
}
