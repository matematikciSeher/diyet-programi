import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../food/domain/repositories/food_repository.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../../weight/domain/usecases/weight_tracker.dart';
import '../repositories/meal_log_repository.dart';

/// Günlük ekranından yapılan kayıt işlemleri. Arayüz yalnızca bu sınıfı
/// kullanır; veri kaynakları repository arayüzlerinin arkasındadır.
class DiaryActions {
  const DiaryActions({
    required MealLogRepository meals,
    required WaterRepository water,
    required WeightTracker weights,
    required FoodRepository foods,
    required DateTime Function() clock,
  }) : _meals = meals,
       _water = water,
       _weights = weights,
       _foods = foods,
       _clock = clock;

  final MealLogRepository _meals;
  final WaterRepository _water;
  final WeightTracker _weights;
  final FoodRepository _foods;
  final DateTime Function() _clock;

  /// [day] bugünse şimdiki an, değilse o günün şimdiki saati.
  DateTime timestampFor(DateTime day) {
    final now = _clock();
    return day.isSameDay(now) ? now : day.withTimeOf(now);
  }

  // --- Yiyecekler ---

  /// Miktarı [factor] oranında değiştirir ve/veya öğününü değiştirir.
  Future<Result<MealEntry>> updateEntry(
    MealEntry entry, {
    double factor = 1,
    MealType? mealType,
  }) => _meals.updateEntry(entry.scaled(factor).copyWith(mealType: mealType));

  Future<Result<MealEntry>> moveEntry(MealEntry entry, MealType to) =>
      _meals.updateEntry(entry.copyWith(mealType: to));

  /// [day] gününe, aynı öğün ve saatle yeni bir kopya ekler.
  Future<Result<MealEntry>> copyEntry(MealEntry entry, DateTime day) =>
      _meals.addEntry(
        MealEntry(
          id: '',
          dayKey: day.dayKey,
          mealType: entry.mealType,
          name: entry.name,
          quantityGrams: entry.quantityGrams,
          nutrition: entry.nutrition,
          loggedAt: day.withTimeOf(entry.loggedAt),
          foodId: entry.foodId,
          recipeId: entry.recipeId,
          servingLabel: entry.servingLabel,
          quantity: entry.quantity,
          unit: entry.unit,
          source: entry.source,
          tags: entry.tags,
        ),
      );

  Future<Result<void>> deleteEntry(MealEntry entry) =>
      _meals.deleteEntry(entry.id);

  /// Silinen kaydı aynı id ile geri yükler.
  Future<Result<MealEntry>> restoreEntry(MealEntry entry) =>
      _meals.addEntry(entry);

  // --- Favoriler ---

  /// Favori listesinde kaydı temsil eden yiyecek id'si. Veritabanından
  /// gelmeyen kayıtlar (plan, örnek veri) için isimden türetilir.
  static String favoriteIdFor(MealEntry entry) {
    final foodId = entry.foodId;
    if (foodId != null && foodId.isNotEmpty) return foodId;
    final slug = entry.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'diary-$slug';
  }

  Future<Result<void>> setFavorite(
    MealEntry entry, {
    required bool favorite,
  }) async {
    final food = await _foodFor(entry);
    return _foods.setFavorite(food, favorite: favorite);
  }

  Future<Food> _foodFor(MealEntry entry) async {
    final foodId = entry.foodId;
    if (foodId != null && foodId.isNotEmpty) {
      final found = (await _foods.getById(foodId)).valueOrNull;
      if (found != null) return found;
    }
    final grams = entry.quantityGrams;
    final quantity = entry.quantity ?? 1;
    return Food(
      id: favoriteIdFor(entry),
      name: entry.name,
      nutritionPer100: grams > 0
          ? entry.nutrition.scale(100 / grams)
          : entry.nutrition,
      portions: [
        if (grams > 0 && quantity > 0)
          FoodPortion(
            unit: entry.unit ?? PortionUnit.serving,
            baseAmount: grams / quantity,
          ),
      ],
      tags: entry.tags,
      source: entry.source,
    );
  }

  // --- Su ---

  Future<Result<WaterLog>> addWater(int amountMl, DateTime day) =>
      _water.addWater(amountMl, at: timestampFor(day));

  /// En son eklenenlerden başlayarak [amountMl] kadar suyu geri alır.
  Future<Result<void>> removeWater(int amountMl, List<WaterLog> logs) async {
    final newestFirst = [...logs]
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    var remaining = amountMl;
    for (final log in newestFirst) {
      if (remaining <= 0) break;
      final Result<Object?> result;
      if (log.amountMl <= remaining) {
        remaining -= log.amountMl;
        result = await _water.deleteLog(log.id);
      } else {
        result = await _water.updateLog(
          WaterLog(
            id: log.id,
            dayKey: log.dayKey,
            amountMl: log.amountMl - remaining,
            loggedAt: log.loggedAt,
          ),
        );
        remaining = 0;
      }
      if (result case Err(:final failure)) return Result.failure(failure);
    }
    return const Result.success(null);
  }

  // --- Kilo ---

  Future<Result<WeightEntry>> addWeight(double kg, DateTime at) =>
      _weights.add(kg, at: at);
}
