import '../../../../core/errors/result.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../meals/domain/repositories/meal_log_repository.dart';
import '../models/plan_item.dart';
import '../models/planned_meal.dart';

/// Planlanan öğünün yiyeceklerini porsiyon çarpanıyla günlüğe ekler.
class LogPlannedMeal {
  const LogPlannedMeal({
    required MealLogRepository meals,
    required DateTime Function() clock,
  }) : _meals = meals,
       _clock = clock;

  final MealLogRepository _meals;
  final DateTime Function() _clock;

  /// [servingLabel] günlükte gösterilecek yerelleştirilmiş miktar metnidir.
  /// Yiyecek listesi olmayan öğünler (ör. plana eklenmiş tarif) tek kayıt
  /// olarak eklenir; miktar metni [mealServingLabel]'dan gelir.
  /// Bir kayıt başarısız olursa eklenenler geri alınır.
  Future<Result<List<MealEntry>>> call(
    PlannedMeal meal, {
    required String Function(PlanItem item) servingLabel,
    String? mealServingLabel,
  }) async {
    final now = _clock();
    if (meal.items.isEmpty) {
      final result = await _meals.addEntry(
        MealEntry(
          id: '',
          dayKey: '',
          mealType: meal.mealType,
          name: meal.title,
          quantityGrams: 0,
          quantity: meal.portionFactor,
          unit: PortionUnit.serving,
          nutrition: meal.nutrition,
          loggedAt: now,
          recipeId: meal.recipeId,
          servingLabel: mealServingLabel,
          source: meal.recipeId == null
              ? FoodSource.mealPlan
              : FoodSource.recipe,
        ),
      );
      return result.map((entry) => [entry]);
    }
    final added = <MealEntry>[];
    for (final item in meal.items) {
      final result = await _meals.addEntry(
        MealEntry(
          id: '',
          dayKey: '',
          mealType: meal.mealType,
          name: item.name,
          quantityGrams: item.grams * meal.portionFactor,
          nutrition: item.nutrition.scale(meal.portionFactor),
          loggedAt: now,
          recipeId: meal.recipeId,
          servingLabel: servingLabel(item),
          source: FoodSource.mealPlan,
          tags: item.tags,
        ),
      );
      switch (result) {
        case Success(:final value):
          added.add(value);
        case Err(:final failure):
          await undo(added);
          return Result.failure(failure);
      }
    }
    return Result.success(added);
  }

  Future<void> undo(List<MealEntry> entries) async {
    for (final entry in entries) {
      await _meals.deleteEntry(entry.id);
    }
  }
}
