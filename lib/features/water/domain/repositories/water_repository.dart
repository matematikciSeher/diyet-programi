import '../../../../core/errors/result.dart';
import '../../../../shared/models/water_log.dart';

abstract interface class WaterRepository {
  Stream<List<WaterLog>> watchDay(DateTime day);

  /// [from] ve [to] günleri dahil aralıktaki kayıtlar, güne göre sıralı.
  Stream<List<WaterLog>> watchRange(DateTime from, DateTime to);

  Future<Result<WaterLog>> addWater(int amountMl, {DateTime? at});

  /// Kaydın miktarını değiştirir (ör. yanlış eklenen suyu azaltmak için).
  Future<Result<WaterLog>> updateLog(WaterLog log);

  Future<Result<void>> deleteLog(String id);
}
