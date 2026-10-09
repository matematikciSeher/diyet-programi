import '../../../../core/errors/result.dart';
import '../../../../shared/models/meal_entry.dart';

/// Kullanıcının öğün günlüğü (yenen yemek kayıtları).
abstract interface class MealLogRepository {
  /// [day] gününe ait kayıtlar, eklenme zamanına göre sıralı.
  Stream<List<MealEntry>> watchDay(DateTime day);

  /// [from] ve [to] günleri dahil aralıktaki kayıtlar, güne göre sıralı.
  Stream<List<MealEntry>> watchRange(DateTime from, DateTime to);

  /// `id` boşsa yeni bir id üretilir; `dayKey` [MealEntry.loggedAt]'ten alınır.
  /// Var olan bir id ile çağrılırsa kayıt geri yüklenir (silmeyi geri alma).
  Future<Result<MealEntry>> addEntry(MealEntry entry);

  /// Var olan kaydı değiştirir (miktar, öğün...); `updatedAt` güncellenir.
  Future<Result<MealEntry>> updateEntry(MealEntry entry);

  Future<Result<void>> deleteEntry(String id);
}
