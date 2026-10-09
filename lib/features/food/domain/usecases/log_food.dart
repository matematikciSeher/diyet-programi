import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../meals/domain/repositories/meal_log_repository.dart';
import '../models/portion_selection.dart';
import '../repositories/food_repository.dart';
import '../services/food_calculation_service.dart';

/// Yiyeceği seçilen porsiyonla öğün günlüğüne ekler ve son kullanılanlara
/// kaydeder.
class LogFood {
  const LogFood({
    required MealLogRepository meals,
    required FoodRepository foods,
    required FoodCalculationService calculator,
    required DateTime Function() clock,
  }) : _meals = meals,
       _foods = foods,
       _calculator = calculator,
       _clock = clock;

  final MealLogRepository _meals;
  final FoodRepository _foods;
  final FoodCalculationService _calculator;
  final DateTime Function() _clock;

  /// [servingLabel] günlükte gösterilecek yerelleştirilmiş porsiyon metnidir
  /// (ör. "2 dilim (50 g)"). [day] verilirse (ör. Günlük'te geçmiş bir gün
  /// seçiliyken) kayıt o güne, şimdiki saatle eklenir.
  Future<Result<MealEntry>> call({
    required Food food,
    required PortionSelection selection,
    required MealType mealType,
    required String servingLabel,
    DateTime? day,
  }) async {
    final now = _clock();
    final entry = MealEntry(
      id: '',
      dayKey: '',
      mealType: mealType,
      name: food.name,
      quantityGrams:
          _calculator.gramsFor(food, selection) ?? selection.baseAmount,
      nutrition: _calculator.nutritionFor(food, selection),
      loggedAt: day == null ? now : day.withTimeOf(now),
      foodId: food.id,
      recipeId: food.isRecipe ? food.id : null,
      servingLabel: servingLabel,
      quantity: selection.quantity,
      unit: selection.portion.unit,
      source: food.source,
      tags: food.tags,
    );
    final result = await _meals.addEntry(entry);
    if (result.isSuccess) {
      await _foods.recordRecent(food, selection, at: now);
    }
    return result;
  }

  Future<Result<void>> undo(String entryId) => _meals.deleteEntry(entryId);

  /// Saate göre en olası öğün.
  static MealType suggestedMeal(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes >= 4 * 60 && minutes < 10 * 60 + 30) return MealType.breakfast;
    if (minutes >= 10 * 60 + 30 && minutes < 15 * 60) return MealType.lunch;
    if (minutes >= 17 * 60 + 30 && minutes < 22 * 60) return MealType.dinner;
    return MealType.snack;
  }
}
