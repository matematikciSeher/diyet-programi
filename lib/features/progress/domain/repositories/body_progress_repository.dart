import 'package:equatable/equatable.dart';

import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/weight_entry.dart';

/// Kilo kayıtları ve vücut ölçümlerinin birlikte okunduğu anlık görüntü.
class BodyProgressSnapshot extends Equatable {
  const BodyProgressSnapshot({
    required this.weights,
    required this.measurements,
  });

  /// En yeni önce.
  final List<WeightEntry> weights;

  /// En eski önce.
  final List<BodyMeasurement> measurements;

  WeightEntry? get latestWeight => weights.firstOrNull;
  BodyMeasurement? get latestMeasurement => measurements.lastOrNull;

  @override
  List<Object?> get props => [weights, measurements];
}

/// İlerleme ekranı ve beslenme asistanının kilo ile ölçüleri tek kaynaktan
/// okuması için birleşik görünüm.
abstract interface class BodyProgressRepository {
  Stream<BodyProgressSnapshot> watch();
}
