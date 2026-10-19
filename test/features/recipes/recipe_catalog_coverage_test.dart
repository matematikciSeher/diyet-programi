import 'dart:io';

import 'package:diyet_programi/features/recipes/data/datasources/recipe_catalog.dart';
import 'package:diyet_programi/features/recipes/data/datasources/recipe_images.dart';
import 'package:diyet_programi/features/recipes/domain/models/recipe_category.dart';
import 'package:diyet_programi/features/recipes/domain/models/recipe_tags.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_query.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recipes = RecipeCatalog.all;

  test('kategori başına en az 15 tarif ve kalori sınırları', () {
    final ids = recipes.map((r) => r.id).toSet();
    expect(ids, hasLength(recipes.length));

    final highProtein = recipes.where((r) => r.protein >= 25);
    final lowCalorie = recipes.where(
      (r) => r.calories > 0 && r.calories <= RecipeCategory.lowCalorieKcal,
    );
    final vegetarian = recipes.where(
      (r) => r.tags.contains(RecipeTags.vegetarian),
    );
    final salads = recipes.where((r) => r.tags.contains(RecipeTags.salad));
    final soups = recipes.where((r) => r.tags.contains(RecipeTags.soup));
    final practical = recipes.where(
      (r) => r.tags.contains(RecipeTags.practical),
    );
    final under300 = RecipeQuery.apply(
      recipes,
      const RecipeCriteria(maxCalories: 300),
    );
    final under500 = RecipeQuery.apply(
      recipes,
      const RecipeCriteria(maxCalories: 500),
    );

    expect(highProtein, hasLength(greaterThanOrEqualTo(15)));
    expect(lowCalorie, hasLength(greaterThanOrEqualTo(15)));
    expect(vegetarian, hasLength(greaterThanOrEqualTo(15)));
    expect(salads, hasLength(greaterThanOrEqualTo(15)));
    expect(soups, hasLength(greaterThanOrEqualTo(15)));
    expect(practical, hasLength(greaterThanOrEqualTo(15)));
    expect(under300, hasLength(greaterThanOrEqualTo(15)));
    expect(under500, hasLength(greaterThanOrEqualTo(15)));

    expect(under300.every((r) => r.calories > 0 && r.calories <= 300), isTrue);
    expect(under500.every((r) => r.calories > 0 && r.calories <= 500), isTrue);
    expect(
      recipes.where((r) => r.calories > 300).every((r) => !under300.contains(r)),
      isTrue,
    );
    expect(
      recipes.where((r) => r.calories > 500).every((r) => !under500.contains(r)),
      isTrue,
    );
    expect(lowCalorie.every((r) => r.calories <= 300), isTrue);
    expect(
      salads.every((r) => r.category == RecipeTags.salad),
      isTrue,
    );
    expect(soups.every((r) => r.category == RecipeTags.soup), isTrue);

    for (final recipe in recipes) {
      expect(recipe.description, isNotNull);
      expect(recipe.steps.length, greaterThanOrEqualTo(2));
      expect(recipe.ingredients, isNotEmpty);
      expect(recipe.gramsPerServing, isNotNull);
      expect(recipe.prepMinutes, isNotNull);
      expect(recipe.cookMinutes, isNotNull);
      expect(recipe.nutritionPerServing.calories, greaterThan(0));
    }
  });

  test('yoğurtlu tavuk kasesi verilen malzemelerden hesaplanır', () {
    final recipe = recipes.firstWhere((r) => r.id == 'catalog-yogurtlu-tavuk');
    expect(recipe.calories, closeTo(336, 2));
    expect(recipe.protein, closeTo(42, 1));
    expect(recipe.totalMinutes, 25);
    expect(recipe.servings, 1);
    expect(recipe.protein, greaterThanOrEqualTo(25));
    expect(recipe.calories, lessThan(500));
    expect(recipe.tags.contains(RecipeTags.highProtein), isTrue);
  });

  test('katalog görselleri yerel dosyaya bağlıdır', () {
    for (final recipe in recipes) {
      expect(recipe.imageUrl, isNull, reason: recipe.id);
      final asset = RecipeImages.assetFor(recipe);
      if (asset == null) {
        expect(recipe.id.startsWith('recipe_'), isTrue, reason: recipe.id);
        continue;
      }
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('bir tarif tek kayıttır ve birden fazla kategoride görünebilir', () {
    final chicken = recipes.singleWhere((r) => r.id == 'catalog-ton-balikli-salata');
    expect(chicken.tags.contains(RecipeTags.salad), isTrue);
    expect(chicken.tags.contains(RecipeTags.highProtein), isTrue);
    expect(
      recipes.where((r) => r.title == chicken.title),
      hasLength(1),
    );
    expect(chicken.mealTypes, contains(MealType.lunch));
  });

  test('görseli olan tarifler listenin üstünde kalır', () {
    final ordered = RecipeImages.withImagesFirst(recipes);
    expect(ordered, hasLength(recipes.length));
    final firstWithout = ordered.indexWhere((r) => !RecipeImages.hasImage(r));
    expect(firstWithout, greaterThan(0));
    expect(
      ordered.take(firstWithout).every(RecipeImages.hasImage),
      isTrue,
    );
    expect(
      ordered.skip(firstWithout).every((r) => !RecipeImages.hasImage(r)),
      isTrue,
    );
    expect(
      ordered.where(RecipeImages.hasImage).map((r) => r.id),
      recipes.where(RecipeImages.hasImage).map((r) => r.id),
    );
  });
}
