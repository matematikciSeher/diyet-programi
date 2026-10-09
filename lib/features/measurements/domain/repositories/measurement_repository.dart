import '../../../../core/errors/result.dart';
import '../../../../shared/models/body_measurement.dart';

abstract interface class MeasurementRepository {
  /// En eski kayıt önce gelir.
  Stream<List<BodyMeasurement>> watchMeasurements();

  /// `id` boşsa yeni bir id üretilir.
  Future<Result<BodyMeasurement>> addMeasurement(BodyMeasurement measurement);

  Future<Result<void>> deleteMeasurement(String id);
}
