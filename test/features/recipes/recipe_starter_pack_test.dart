import 'dart:convert';
import 'dart:io';

import 'package:diyet_programi/features/recipes/data/datasources/recipe_catalog.dart';
import 'package:diyet_programi/features/recipes/data/datasources/recipe_images.dart';
import 'package:diyet_programi/features/recipes/domain/models/recipe_category.dart';
import 'package:diyet_programi/features/recipes/domain/models/recipe_tags.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_query.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_suitability.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rawRecipes = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final path in const [
    'lib/features/recipes/data/datasources/diyet_tarifleri_baslangic.json',
    'lib/features/recipes/data/datasources/diyet_tarifleri_baslangic (2).json',
    'lib/features/recipes/data/datasources/diyet_tarifleri_55.json',
  ]) {
    final pack = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    for (final raw in (pack['recipes'] as List).cast<Map<String, dynamic>>()) {
      if (seen.add(raw['id'] as String)) rawRecipes.add(raw);
    }
  }
  final catalog = RecipeCatalog.all;
  final byId = {for (final recipe in catalog) recipe.id: recipe};

  test('üç paket 55 tarifi kimlikle bir kez ekler', () {
    expect(rawRecipes, hasLength(55));
    final ids = rawRecipes.map((r) => r['id']).toSet();
    expect(ids, hasLength(55));
    expect(catalog.map((r) => r.id).toSet(), hasLength(catalog.length));
    expect(byId.containsKey('catalog-menemen'), isTrue);
    for (final raw in rawRecipes) {
      final id = raw['id'] as String;
      final matches = catalog.where((r) => r.id == id);
      expect(matches, hasLength(1), reason: id);
      final recipe = matches.single;
      expect(recipe.title, raw['name']);
      expect(recipe.description, raw['description']);
      expect(recipe.steps, raw['steps']);
      expect(recipe.servings, raw['servings']);
      expect(recipe.imageUrl, isNull);
      expect(recipe.isUserCreated, isFalse);
      expect(recipe.nutritionPerServing.fiberG, isNotNull);
      expect(recipe.gramsPerServing, isNotNull);
      expect(recipe.ingredients, isNotEmpty);
      final asset = RecipeImages.assetFor(recipe);
      if (asset != null) {
        expect(File(asset).existsSync(), isTrue, reason: id);
      }
    }
  });

  test('sekiz kategori mevcut filtrelerle eşleşir', () {
    for (final raw in rawRecipes) {
      final recipe = byId[raw['id']]!;
      final categories = (raw['categories'] as List).cast<String>();
      expect(
        RecipeQuery.hasTag(recipe, RecipeTags.highProtein),
        recipe.protein >= RecipeCategory.highProteinGrams,
        reason: recipe.id,
      );
      expect(
        RecipeQuery.hasTag(recipe, RecipeTags.lowCalorie),
        recipe.calories > 0 &&
            recipe.calories <= RecipeCategory.lowCalorieKcal,
        reason: recipe.id,
      );
      if (categories.contains('Yüksek Protein') &&
          recipe.protein >= RecipeCategory.highProteinGrams) {
        expect(RecipeQuery.hasTag(recipe, RecipeTags.highProtein), isTrue);
      }
      if (categories.contains('Düşük Kalori') &&
          recipe.calories <= RecipeCategory.lowCalorieKcal) {
        expect(RecipeQuery.hasTag(recipe, RecipeTags.lowCalorie), isTrue);
      }
      if (categories.contains('Vejetaryen')) {
        expect(RecipeQuery.hasTag(recipe, RecipeTags.vegetarian), isTrue);
        expect(
          RecipeSuitability.matchesDiet(recipe, DietType.vegetarian),
          isTrue,
          reason: recipe.id,
        );
      }
      if (categories.contains('Vegan')) {
        // recipe_037 JSON'da vegan yazılı; malzeme listesinde yoğurt var.
        // Yoğurt korunur, tarif vejetaryen kalır.
        final vegan = recipe.id != 'recipe_037';
        expect(
          RecipeSuitability.matchesDiet(recipe, DietType.vegan),
          vegan,
          reason: recipe.id,
        );
      }
      if (categories.contains('Salatalar')) {
        expect(recipe.category, RecipeTags.salad);
        expect(RecipeQuery.hasTag(recipe, RecipeTags.salad), isTrue);
      }
      if (categories.contains('Çorbalar')) {
        expect(recipe.category, RecipeTags.soup);
        expect(RecipeQuery.hasTag(recipe, RecipeTags.soup), isTrue);
      }
      if (categories.contains('Pratik Tarifler')) {
        expect(RecipeQuery.hasTag(recipe, RecipeTags.practical), isTrue);
      }
      if (categories.contains('300 Kalori Altı')) {
        expect(recipe.calories, greaterThan(0));
        expect(recipe.calories, lessThanOrEqualTo(300), reason: recipe.id);
      }
      if (categories.contains('500 Kalori Altı')) {
        expect(recipe.calories, greaterThan(0));
        expect(recipe.calories, lessThanOrEqualTo(500), reason: recipe.id);
      }
      expect(recipe.mealTypes, isNotEmpty);
    }
  });
}
