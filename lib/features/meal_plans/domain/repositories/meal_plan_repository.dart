import '../../../../core/errors/result.dart';
import '../models/planned_meal.dart';

/// Günlük plan belgeleri. Haftalık plan ayrı bir koleksiyon değildir;
/// Pazartesi–Pazar, gün anahtarıyla saklanan [PlannedMeal] kayıtlarıdır.
///
/// Tarif ekleme ve porsiyon hesabı domain servislerindedir. Bu arayüz
/// yalnızca yerel belgeyi okur ve yazar.
abstract interface class MealPlanRepository {
  /// [day] için planlanan öğünler, saat ve öğün sırasına göre.
  Stream<List<PlannedMeal>> watchDay(DateTime day);

  /// [day] hangi güne denk gelirse gelsin, o haftanın (Pazartesi–Pazar)
  /// tüm öğünleri.
  Stream<List<PlannedMeal>> watchWeek(DateTime day);

  Future<List<PlannedMeal>> getDay(DateTime day);

  Future<List<PlannedMeal>> getCurrentPlan(DateTime day);

  Future<PlannedMeal?> getMealById(String id);

  /// [day] gününün planını [meals] ile değiştirir; listede olmayan eski
  /// öğünler silinir. Var olan günü güncellemek de bu metottur.
  Future<Result<void>> saveDay(DateTime day, List<PlannedMeal> meals);

  /// Verilen öğünlerin günlerini oluşturur veya günceller.
  Future<Result<void>> savePlan(List<PlannedMeal> meals);

  Future<Result<void>> deleteDay(DateTime day);

  Future<Result<void>> deleteWeek(DateTime day);

  Future<Result<void>> replaceMeal(DateTime day, PlannedMeal meal);

  /// [meal.nutrition] çağıran tarafça ölçeklenmiş olmalıdır.
  Future<Result<void>> updateMealPortion(DateTime day, PlannedMeal meal);

  Future<Result<void>> addMeal(DateTime day, PlannedMeal meal);

  Future<Result<void>> removeMeal(DateTime day, String mealId);
}
