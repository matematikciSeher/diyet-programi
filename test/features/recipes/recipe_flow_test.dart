import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/meal_plan_preferences.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generation_service.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/features/meal_plans/domain/usecases/weekly_meal_planner.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/features/recipes/domain/usecases/recipe_usecases.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late RecipeRepositoryImpl recipes;
  late MealLogRepositoryImpl meals;
  late MealPlanRepositoryImpl plans;
  late WeeklyMealPlanner planner;

  setUp(() {
    db = InMemoryDocumentDatabase();
    recipes = RecipeRepositoryImpl(db, 'user-1');
    meals = MealLogRepositoryImpl(db, 'user-1', clock: () => testNow);
    plans = MealPlanRepositoryImpl(db, 'user-1');
    planner = WeeklyMealPlanner(
      plans: plans,
      generator: RuleBasedMealPlanGenerationService(
        MealPlanGenerator(MealTemplateCatalog.all),
      ),
    );
  });
  tearDown(() => db.dispose());

  test('tarif oluşturulur, günlüğe ve plana eklenir', () async {
    final recipe = (await recipes.saveRecipe(
      const Recipe(
        id: '',
        title: 'Proteinli Omlet',
        servings: 1,
        nutritionPerServing: NutritionFacts(
          calories: 420,
          proteinG: 35,
          carbsG: 12,
          fatG: 25,
          fiberG: 3,
        ),
        ingredients: [
          RecipeIngredient(name: 'Yumurta', quantity: 3, unit: 'adet'),
        ],
        steps: ['Yumurtaları çırpın.', 'Tavada pişirin.'],
        tags: ['breakfast'],
      ),
    )).valueOrNull!;
    expect(recipe.id, isNotEmpty);
    expect(recipe.authorId, 'user-1');
    expect((await recipes.watchRecipes().first).any((r) => r.id == recipe.id), isTrue);

    final logged = (await LogRecipe(meals: meals, clock: () => testNow)(
      recipe,
      mealType: MealType.breakfast,
      servingLabel: '1 porsiyon',
    )).valueOrNull!;
    expect(logged.name, 'Proteinli Omlet');
    expect(logged.mealType, MealType.breakfast);
    expect(logged.nutrition.calories, 420);
    expect(logged.nutrition.proteinG, 35);
    expect(logged.recipeId, recipe.id);
    expect(logged.source, FoodSource.recipe);
    expect(logged.dayKey, testNow.dayKey);

    final placed = (await AddRecipeToPlan(planner)(
      recipe,
      day: testNow.startOfDay,
      mealType: MealType.lunch,
      prefs: MealPlanPreferences.fromProfile(testProfile()),
    )).valueOrNull!;
    expect(placed.recipeId, recipe.id);
    expect(placed.mealType, MealType.lunch);
    expect(placed.nutrition.calories, 420);

    final plan = await plans.watchDay(testNow.startOfDay).first;
    expect(plan.where((m) => m.recipeId == recipe.id), [placed]);
  });
}
