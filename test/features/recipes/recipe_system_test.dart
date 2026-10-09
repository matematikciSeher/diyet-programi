import 'package:diyet_programi/features/activity/domain/models/daily_activity.dart';
import 'package:diyet_programi/features/activity/domain/repositories/activity_repository.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/domain/services/food_calculation_service.dart';
import 'package:diyet_programi/features/meals/data/repositories/daily_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/domain/models/daily_log.dart';
import 'package:diyet_programi/features/recipes/data/datasources/recipe_catalog.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/features/recipes/domain/models/recipe_tags.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_nutrition_calculator.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_portion_service.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_query.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_recommendation_service.dart';
import 'package:diyet_programi/features/recipes/domain/services/recipe_suitability.dart';
import 'package:diyet_programi/features/recipes/domain/usecases/recipe_usecases.dart';
import 'package:diyet_programi/features/shopping/data/repositories/shopping_list_repository_impl.dart';
import 'package:diyet_programi/features/shopping/domain/services/shopping_list_aggregator.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;

  setUp(() => db = InMemoryDocumentDatabase());
  tearDown(() => db.dispose());

  RecipeRepositoryImpl repo({String? uid = 'user-1', List<Recipe>? catalog}) =>
      RecipeRepositoryImpl(db, uid, catalog: catalog ?? RecipeCatalog.all);

  test('repository arama, kategori, öğün, etiket ve favori local çalışır', () async {
    final recipes = repo();
    final all = await recipes.getRecipes();
    expect(all.length, greaterThanOrEqualTo(70));

    final menemen = await recipes.getRecipeById('catalog-menemen');
    expect(menemen, isNotNull);
    expect(await recipes.searchRecipes('menemen'), contains(menemen));
    expect(
      await recipes.getRecipesByCategory('breakfast'),
      everyElement(
        predicate<Recipe>(
          (r) =>
              r.mealTypes.contains(MealType.breakfast) ||
              r.tags.contains('breakfast') ||
              r.category == 'breakfast',
        ),
      ),
    );
    final dinners = await recipes.getRecipesByMealType(MealType.dinner);
    expect(dinners, isNotEmpty);
    expect(
      dinners,
      everyElement(
        predicate<Recipe>((r) => r.mealTypes.contains(MealType.dinner)),
      ),
    );
    final protein = await recipes.getRecipesByTags({RecipeTags.highProtein});
    expect(protein, isNotEmpty);
    expect(
      protein,
      everyElement(predicate<Recipe>((r) => r.protein >= 25)),
    );

    expect((await recipes.toggleFavorite('catalog-menemen')).valueOrNull, isTrue);
    expect(await recipes.getFavoriteRecipes(), [menemen]);
    final again = RecipeRepositoryImpl(
      db,
      'user-1',
      catalog: RecipeCatalog.all,
    );
    expect(await again.watchFavoriteIds().first, {'catalog-menemen'});
    expect((await again.toggleFavorite('catalog-menemen')).valueOrNull, isFalse);
    expect(await again.getFavoriteRecipes(), isEmpty);
  });

  test('oturum yokken katalog ve ayrıntı okunur, favori yazılmaz', () async {
    final recipes = repo(uid: null);
    expect(await recipes.getRecipes(), isNotEmpty);
    expect(await recipes.getRecipeById('catalog-menemen'), isNotNull);
    expect((await recipes.toggleFavorite('catalog-menemen')).isFailure, isTrue);
    expect(await recipes.watchFavoriteIds().first, isEmpty);
    expect(await recipes.watchRecent().first, isEmpty);
  });

  test('son görüntülenenler local kayda yazılır', () async {
    final recipes = repo();
    expect((await recipes.recordView('catalog-menemen')).isSuccess, isTrue);
    expect((await recipes.watchRecent().first).single.id, 'catalog-menemen');
  });

  test('porsiyon 2x besin değerlerini NutritionFacts ile ölçekler', () {
    final recipe = RecipeCatalog.all.firstWhere((r) => r.id == 'catalog-menemen');
    const service = RecipePortionService();
    final doubled = service.forServings(recipe, 2);
    expect(doubled.calories, closeTo(recipe.calories * 2, 1e-6));
    expect(doubled.proteinG, closeTo(recipe.protein * 2, 1e-6));
    expect(doubled.carbsG, closeTo(recipe.carbohydrates * 2, 1e-6));
    expect(doubled.fatG, closeTo(recipe.fat * 2, 1e-6));
    expect(doubled.fiberG, closeTo(recipe.fiber * 2, 1e-6));
    final ingredients = service.ingredientsForServings(recipe, 2);
    expect(
      ingredients.first.quantity,
      closeTo(recipe.ingredients.first.quantity, 1e-9),
    );
  });

  test('Recipe → MealEntry → DailyLog porsiyonla ölçeklenir', () async {
    final meals = MealLogRepositoryImpl(db, 'user-1', clock: () => testNow);
    final daily = CompositeDailyLogRepository(
      meals: meals,
      water: WaterRepositoryImpl(db, 'user-1'),
      activity: const _EmptyActivity(),
      weights: WeightRepositoryImpl(db, 'user-1'),
      userId: 'user-1',
    );
    final recipe = RecipeCatalog.all.firstWhere((r) => r.id == 'catalog-menemen');
    final logged = (await LogRecipe(meals: meals, clock: () => testNow)(
      recipe,
      mealType: MealType.breakfast,
      servings: 2,
    )).valueOrNull!;
    expect(logged.recipeId, recipe.id);
    expect(logged.nutrition.calories, closeTo(recipe.calories * 2, 1e-6));
    expect(logged.source, FoodSource.recipe);

    final log = await daily.watchDay(testNow).first;
    final entry = log.meals
        .expand((meal) => meal.entries)
        .single;
    expect(entry.id, logged.id);
    expect(log.totals.calories, closeTo(recipe.calories * 2, 1e-6));
    expect(
      DailyLog.fromEntries(date: testNow, entries: [logged]).totals.calories,
      closeTo(log.totals.calories, 1e-6),
    );
  });

  test('tarif malzemeleri alışveriş listesinde birleşir', () async {
    final recipe = const Recipe(
      id: 'shop-1',
      title: 'Tavuk tabağı',
      servings: 1,
      nutritionPerServing: NutritionFacts(calories: 200, proteinG: 30),
      ingredients: [
        RecipeIngredient(name: 'Tavuk', quantity: 200, unit: 'g', foodId: 'sample-chicken-breast'),
        RecipeIngredient(name: 'Yoğurt', quantity: 100, unit: 'g', foodId: 'sample-yogurt-whole'),
        RecipeIngredient(name: 'Domates', quantity: 1, unit: 'adet', foodId: 'sample-tomato'),
      ],
    );
    final aggregator = ShoppingListAggregator(
      items: LocalShoppingListRepository(db, 'user-1'),
      recipes: RecipeRepositoryImpl(db, 'user-1', catalog: [recipe]),
      clock: () => testNow,
      uid: () => 'user-1',
    );
    expect(await aggregator.addRecipe(recipe), 3);
    expect(await aggregator.addRecipe(recipe), 3);
    final items = await LocalShoppingListRepository(db, 'user-1').watchItems().first;
    expect(items, hasLength(3));
    expect(
      items.firstWhere((i) => i.name == 'Tavuk').quantity,
      400,
    );
    expect(items.firstWhere((i) => i.name == 'Yoğurt').quantity, 200);
    expect(items.firstWhere((i) => i.name == 'Domates').quantity, 2);
    expect(items.every((i) => i.unit == 'g' || i.unit == 'adet'), isTrue);
  });

  test('alerji ve sevilmeyen besin öneriden çıkar', () {
    const service = RecipeRecommendationService();
    final catalog = RecipeCatalog.all;
    final eggFree = service.recommend(
      catalog,
      testProfile(allergies: [Allergen.egg.name]),
    );
    expect(
      eggFree.any((r) => RecipeSuitability.allergensOf(r).contains(Allergen.egg.name)),
      isFalse,
    );
    expect(eggFree.any((r) => r.id == 'catalog-menemen'), isFalse);
    expect(eggFree.any((r) => r.id == 'catalog-elma-badem'), isTrue);

    final noTomato = service.recommend(
      catalog,
      testProfile(dislikedFoods: const ['domates']),
    );
    expect(noTomato.any((r) => r.id == 'catalog-menemen'), isFalse);
    expect(noTomato.any((r) => r.id == 'catalog-elma-badem'), isTrue);

    const mislabeled = Recipe(
      id: 'mislabeled',
      title: 'Vejetaryen görünen tavuk',
      servings: 1,
      tags: ['vegetarian'],
      nutritionPerServing: NutritionFacts(calories: 180, proteinG: 30),
      ingredients: [
        RecipeIngredient(
          name: 'Tavuk göğsü',
          quantity: 100,
          unit: 'g',
          foodId: 'sample-chicken-breast',
        ),
      ],
    );
    expect(
      RecipeSuitability.matchesDiet(mislabeled, DietType.vegetarian),
      isFalse,
    );
    expect(
      service.recommend(
        [mislabeled],
        testProfile(dietType: DietType.vegetarian),
      ),
      isEmpty,
    );
  });

  test('seed besin değerleri FoodCalculationService ile aynıdır', () {
    final foods = {
      for (final food in SampleFoodCatalog.foods) food.id: food,
    };
    final calculator = RecipeNutritionCalculator(
      (id) => foods[id],
      calculation: const FoodCalculationService(),
    );
    final signatures = <String>{};
    final titles = <String>{};
    for (final recipe in RecipeCatalog.all) {
      expect(recipe.isDemo, isTrue);
      expect(recipe.nutritionReference, SampleFoodCatalog.reference);
      expect(recipe.imageUrl, isNull);
      expect(titles.add(recipe.title), isTrue);
      final signature = recipe.ingredients
          .map((i) => '${i.foodId}|${i.quantity}|${i.unit}')
          .join(';');
      expect(signatures.add(signature), isTrue, reason: recipe.title);
      final again = calculator.build(
        servings: recipe.servings,
        lines: [
          for (final ingredient in recipe.ingredients)
            RecipeIngredientLine(
              foodId: ingredient.foodId!,
              quantity: ingredient.quantity,
              unit: ingredient.unit,
            ),
        ],
      );
      expect(again.perServing.calories, closeTo(recipe.calories, 1e-6));
      expect(again.perServing.proteinG, closeTo(recipe.protein, 1e-6));
      expect(again.perServing.carbsG, closeTo(recipe.carbohydrates, 1e-6));
      expect(again.perServing.fatG, closeTo(recipe.fat, 1e-6));
    }
    expect(
      RecipeCatalog.all.where((r) => r.mealTypes.contains(MealType.breakfast)),
      hasLength(greaterThanOrEqualTo(20)),
    );
    expect(
      RecipeCatalog.all.where((r) => r.mealTypes.contains(MealType.lunch)),
      hasLength(greaterThanOrEqualTo(20)),
    );
    expect(
      RecipeCatalog.all.where((r) => r.mealTypes.contains(MealType.dinner)),
      hasLength(greaterThanOrEqualTo(20)),
    );
    expect(
      RecipeCatalog.all.where((r) => r.mealTypes.contains(MealType.snack)),
      hasLength(greaterThanOrEqualTo(10)),
    );
  });

  test('arama önbelleği aynı sonucu döndürür', () {
    final first = RecipeQuery.search(RecipeCatalog.all, 'mercimek');
    final second = RecipeQuery.search(RecipeCatalog.all, 'mercimek');
    expect(second.map((r) => r.id), first.map((r) => r.id));
    expect(first, isNotEmpty);
  });
}

class _EmptyActivity implements ActivityRepository {
  const _EmptyActivity();

  @override
  Stream<DailyActivity> watchDay(DateTime day) =>
      Stream.value(DailyActivity.empty);
}
