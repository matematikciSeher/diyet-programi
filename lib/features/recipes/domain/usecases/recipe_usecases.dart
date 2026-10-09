import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/recipe.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/domain/usecases/weekly_meal_planner.dart';
import '../../../meals/domain/repositories/meal_log_repository.dart';

/// Tarifi seçilen öğüne, porsiyon sayısıyla ölçeklenmiş tüm besin
/// değerleriyle günlüğe ekler (ör. Proteinli Omlet → 420 kcal, 35 g
/// protein). Kayıt `recipeId` taşır.
class LogRecipe {
  const LogRecipe({
    required MealLogRepository meals,
    required DateTime Function() clock,
  }) : _meals = meals,
       _clock = clock;

  final MealLogRepository _meals;
  final DateTime Function() _clock;

  Future<Result<MealEntry>> call(
    Recipe recipe, {
    required MealType mealType,
    double servings = 1,
    String? servingLabel,
    DateTime? day,
  }) {
    final now = _clock();
    return _meals.addEntry(
      MealEntry(
        id: '',
        dayKey: '',
        mealType: mealType,
        name: recipe.title,
        quantityGrams: 0,
        quantity: servings,
        unit: PortionUnit.serving,
        nutrition: recipe.nutritionPerServing.scale(servings),
        loggedAt: day == null ? now : day.withTimeOf(now),
        recipeId: recipe.id,
        servingLabel: servingLabel,
        source: FoodSource.recipe,
      ),
    );
  }
}

/// Tarifi haftalık planda seçilen gün ve öğüne yerleştirir; plan yoksa
/// önce profile göre üretilir.
class AddRecipeToPlan {
  const AddRecipeToPlan(this._planner);

  final WeeklyMealPlanner _planner;

  Future<Result<PlannedMeal>> call(
    Recipe recipe, {
    required DateTime day,
    required MealType mealType,
    required MealPlanPreferences prefs,
    double servings = 1,
  }) => _planner.placeMeal(
    day,
    PlannedMeal(
      id: '',
      dayKey: '',
      mealType: mealType,
      title: recipe.title,
      nutrition: recipe.nutritionPerServing.scale(servings),
      portionFactor: servings,
      description: recipe.description,
      recipeId: recipe.id,
    ),
    prefs,
  );
}