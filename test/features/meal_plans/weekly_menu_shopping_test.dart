import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/meal_plan_preferences.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generation_service.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/personalized_meal_plan_service.dart';
import 'package:diyet_programi/features/meal_plans/domain/usecases/weekly_meal_planner.dart';
import 'package:diyet_programi/features/recipes/data/datasources/recipe_catalog.dart';
import 'package:diyet_programi/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:diyet_programi/features/shopping/data/repositories/shopping_list_repository_impl.dart';
import 'package:diyet_programi/features/shopping/domain/models/shopping_list_item.dart';
import 'package:diyet_programi/features/shopping/domain/services/shopping_list_aggregator.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  test('haftalık menü saklanır, yeniden açılır ve alışverişle eşleşir', () async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    const uid = 'user-1';
    final plans = MealPlanRepositoryImpl(db, uid);
    final recipes = RecipeRepositoryImpl(db, uid, catalog: RecipeCatalog.all);
    final profile = testProfile(mealsPerDay: 4, dailyCalories: 2000);
    final prefs = MealPlanPreferences.fromProfile(profile);
    final planner = WeeklyMealPlanner(
      plans: plans,
      generator: RecipeMealPlanGenerationService(
        plans: const PersonalizedMealPlanService(),
        loadRecipes: recipes.getRecipes,
        profile: () => profile,
        fallback: RuleBasedMealPlanGenerationService(
          MealPlanGenerator(MealTemplateCatalog.all),
        ),
      ),
    );
    final monday = DateTime(2026, 9, 28);
    final days = WeeklyMealPlanner.weekDays(monday);

    final first = <String>[];
    for (final day in days) {
      final meals = (await planner.ensureDay(day, prefs)).requireValue;
      expect(meals, isNotEmpty);
      expect(
        meals.map((meal) => meal.mealType).toSet(),
        prefs.slots.toSet(),
      );
      first.addAll(meals.map((meal) => '${meal.id}:${meal.recipeId}'));
    }

    final second = <String>[];
    for (final day in days) {
      final meals = (await planner.ensureDay(day, prefs)).requireValue;
      second.addAll(meals.map((meal) => '${meal.id}:${meal.recipeId}'));
    }
    expect(second, first);

    final stored = await plans.getCurrentPlan(monday);
    expect(stored.map((meal) => meal.dayKey).toSet(), {
      for (final day in days) day.dayKey,
    });

    final items = LocalShoppingListRepository(db, uid);
    final now = DateTime(2026, 9, 28);
    await items.addItem(
      ShoppingListItem(
        id: 'manual',
        userId: uid,
        name: 'Ekmek',
        quantity: 1,
        unit: 'adet',
        category: ShoppingCategory.other,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final aggregator = ShoppingListAggregator(
      items: items,
      recipes: recipes,
      clock: () => now,
      uid: () => uid,
    );
    await aggregator.replaceWeek(stored);
    final list = await items.watchItems().first;
    expect(list.any((item) => item.name == 'Ekmek'), isTrue);
    final fromPlan = [
      for (final item in list)
        if (item.sourceMealPlanId != null) item,
    ];
    expect(fromPlan, isNotEmpty);
    for (final meal in stored) {
      final recipe = meal.recipeId == null
          ? null
          : RecipeCatalog.byId(meal.recipeId!);
      if (recipe == null || recipe.ingredients.isEmpty) continue;
      expect(meal.nutrition.calories, greaterThan(0));
      for (final ingredient in recipe.ingredients) {
        if (ingredient.name.trim().isEmpty) continue;
        final key = DraftShoppingItem(
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
        ).mergeKey;
        expect(
          list.any(
            (item) =>
                DraftShoppingItem(
                  name: item.name,
                  quantity: item.quantity,
                  unit: item.unit,
                ).mergeKey ==
                key,
          ),
          isTrue,
          reason: '${meal.title} / ${ingredient.name}',
        );
      }
    }

    await aggregator.replaceWeek(await plans.getCurrentPlan(monday));
    final reopened = await items.watchItems().first;
    expect(reopened.where((item) => item.name == 'Ekmek'), hasLength(1));
    expect(
      reopened.where((item) => item.sourceMealPlanId != null),
      hasLength(fromPlan.length),
    );
  });
}
