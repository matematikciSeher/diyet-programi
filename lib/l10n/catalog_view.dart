import '../features/food/domain/models/recent_food.dart';
import '../features/meal_plans/domain/models/plan_item.dart';
import '../features/meal_plans/domain/models/planned_meal.dart';
import '../features/meals/domain/models/daily_log.dart';
import '../features/shopping/domain/models/shopping_list_item.dart';
import '../shared/models/food.dart';
import '../shared/models/meal_entry.dart';
import '../shared/models/recipe.dart';
import 'catalog_text.dart';

String localizeCatalog(String text, String languageCode) =>
    CatalogText.localize(text, languageCode);

Food localizeFood(Food food, String languageCode) {
  final name = localizeCatalog(food.name, languageCode);
  final portions = [
    for (final portion in food.portions)
      FoodPortion(
        unit: portion.unit,
        baseAmount: portion.baseAmount,
        description: portion.description == null
            ? null
            : localizeCatalog(portion.description!, languageCode),
      ),
  ];
  final ingredients = [
    for (final item in food.ingredients)
      FoodIngredient(
        foodId: item.foodId,
        name: localizeCatalog(item.name, languageCode),
        portion: FoodPortion(
          unit: item.portion.unit,
          baseAmount: item.portion.baseAmount,
          description: item.portion.description == null
              ? null
              : localizeCatalog(item.portion.description!, languageCode),
        ),
        quantity: item.quantity,
        grams: item.grams,
        nutrition: item.nutrition,
      ),
  ];
  return food.copyWith(
    name: name,
    portions: portions,
    ingredients: ingredients,
  );
}

RecentFood localizeRecentFood(RecentFood recent, String languageCode) {
  final description = recent.lastSelection.portion.description;
  final portion = description == null
      ? recent.lastSelection.portion
      : FoodPortion(
          unit: recent.lastSelection.portion.unit,
          baseAmount: recent.lastSelection.portion.baseAmount,
          description: localizeCatalog(description, languageCode),
        );
  return RecentFood(
    food: localizeFood(recent.food, languageCode),
    lastSelection: recent.lastSelection.copyWith(portion: portion),
    lastUsedAt: recent.lastUsedAt,
  );
}

Recipe localizeRecipe(Recipe recipe, String languageCode) {
  final description = recipe.description;
  return recipe.copyWith(
    title: localizeCatalog(recipe.title, languageCode),
    description: description == null
        ? null
        : localizeCatalog(description, languageCode),
    steps: [
      for (final step in recipe.steps) localizeCatalog(step, languageCode),
    ],
    ingredients: [
      for (final item in recipe.ingredients)
        RecipeIngredient(
          id: item.id,
          foodId: item.foodId,
          name: localizeCatalog(item.name, languageCode),
          quantity: item.quantity,
          unit: localizeCatalog(item.unit, languageCode),
          grams: item.grams,
        ),
    ],
  );
}

MealEntry localizeMealEntry(MealEntry entry, String languageCode) {
  final label = entry.servingLabel;
  return MealEntry(
    id: entry.id,
    dayKey: entry.dayKey,
    mealType: entry.mealType,
    name: localizeCatalog(entry.name, languageCode),
    quantityGrams: entry.quantityGrams,
    nutrition: entry.nutrition,
    loggedAt: entry.loggedAt,
    foodId: entry.foodId,
    recipeId: entry.recipeId,
    servingLabel: label == null ? null : localizeCatalog(label, languageCode),
    quantity: entry.quantity,
    unit: entry.unit,
    source: entry.source,
    tags: entry.tags,
    updatedAt: entry.updatedAt,
  );
}

DailyLog localizeDailyLog(DailyLog log, String languageCode) {
  return DailyLog(
    date: log.date,
    userId: log.userId,
    meals: [
      for (final meal in log.meals)
        MealLog(
          type: meal.type,
          entries: [
            for (final entry in meal.entries)
              localizeMealEntry(entry, languageCode),
          ],
        ),
    ],
    waterLogs: log.waterLogs,
    activity: log.activity,
    weight: log.weight,
    nutritionScore: log.nutritionScore,
    createdAt: log.createdAt,
    updatedAt: log.updatedAt,
  );
}

PlanItem localizePlanItem(PlanItem item, String languageCode) => PlanItem(
  emoji: item.emoji,
  name: localizeCatalog(item.name, languageCode),
  amount: localizeCatalog(item.amount, languageCode),
  grams: item.grams,
  nutrition: item.nutrition,
  ingredients: item.ingredients,
  tags: item.tags,
);

PlannedMeal localizePlannedMeal(PlannedMeal meal, String languageCode) {
  final description = meal.description;
  return PlannedMeal(
    id: meal.id,
    dayKey: meal.dayKey,
    mealType: meal.mealType,
    title: localizeCatalog(meal.title, languageCode),
    nutrition: meal.nutrition,
    items: [
      for (final item in meal.items) localizePlanItem(item, languageCode),
    ],
    templateId: meal.templateId,
    portionFactor: meal.portionFactor,
    description: description == null
        ? null
        : localizeCatalog(description, languageCode),
    recipeId: meal.recipeId,
    timeMinutes: meal.timeMinutes,
  );
}

ShoppingListItem localizeShoppingItem(
  ShoppingListItem item,
  String languageCode,
) => ShoppingListItem(
  id: item.id,
  userId: item.userId,
  name: localizeCatalog(item.name, languageCode),
  quantity: item.quantity,
  unit: localizeCatalog(item.unit, languageCode),
  category: item.category,
  isCompleted: item.isCompleted,
  sourceRecipeId: item.sourceRecipeId,
  sourceMealPlanId: item.sourceMealPlanId,
  createdAt: item.createdAt,
  updatedAt: item.updatedAt,
);
