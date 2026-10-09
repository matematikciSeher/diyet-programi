import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recipe alanları NutritionFacts ile saklanır ve JSON döner', () {
    final created = DateTime.utc(2026, 1, 15);
    const nutrition = NutritionFacts(
      calories: 210,
      proteinG: 18,
      carbsG: 12,
      fatG: 9,
      fiberG: 4,
    );
    final recipe = Recipe(
      id: 'r1',
      title: 'Test tabağı',
      description: 'Açıklama',
      servings: 2,
      prepMinutes: 5,
      cookMinutes: 10,
      nutritionPerServing: nutrition,
      ingredients: const [
        RecipeIngredient(
          id: 'i1',
          foodId: 'sample-egg-raw',
          name: 'Yumurta',
          quantity: 2,
          unit: 'adet',
          grams: 100,
        ),
      ],
      steps: const ['Çırpın.'],
      tags: const ['breakfast', 'high_protein'],
      category: 'breakfast',
      mealTypes: const [MealType.breakfast],
      source: RecipeSource.seed,
      createdAt: created,
      updatedAt: created,
      isDemo: true,
      nutritionReference: 'demo',
      allergens: const ['egg'],
    );

    expect(recipe.name, 'Test tabağı');
    expect(recipe.prepTimeMinutes, 5);
    expect(recipe.cookTimeMinutes, 10);
    expect(recipe.instructions, ['Çırpın.']);
    expect(recipe.calories, 210);
    expect(recipe.protein, 18);
    expect(recipe.carbohydrates, 12);
    expect(recipe.fat, 9);
    expect(recipe.fiber, 4);
    expect(recipe.nutritionPerServing, nutrition);

    final restored = Recipe.fromJson(recipe.toJson());
    expect(restored, recipe);
  });

  test('eski JSON title ve name alanlarını okur', () {
    final recipe = Recipe.fromJson({
      'id': 'old',
      'name': 'Eski ad',
      'servings': 1,
      'nutritionPerServing': const NutritionFacts(calories: 10).toJson(),
      'instructions': ['Karıştırın.'],
      'prepTimeMinutes': 4,
      'authorId': 'user-1',
    });
    expect(recipe.title, 'Eski ad');
    expect(recipe.steps, ['Karıştırın.']);
    expect(recipe.prepMinutes, 4);
    expect(recipe.source, RecipeSource.user);
    expect(recipe.isDemo, isFalse);
  });
}
