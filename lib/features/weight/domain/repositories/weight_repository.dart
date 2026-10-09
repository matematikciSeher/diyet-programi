import '../../../../core/errors/result.dart';
import '../../../../shared/models/weight_entry.dart';

abstract interface class WeightRepository {
  /// En yeni kayıt önce gelir.
  Stream<List<WeightEntry>> watchEntries({int? limit});

  Future<Result<WeightEntry>> addEntry({
    required double weightKg,
    DateTime? recordedAt,
    String? note,
  });

  Future<Result<void>> deleteEntry(String id);
}
