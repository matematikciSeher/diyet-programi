import 'package:equatable/equatable.dart';

import '../../../../shared/models/body_measurement.dart';
import '../../../progress/domain/models/progress_report.dart';

/// Tek bir ölçünün (ör. bel) zaman serisi ve ilk/son değer özeti.
class MeasurementSeries extends Equatable {
  const MeasurementSeries({required this.field, required this.points});

  final MeasurementField field;

  /// Eskiden yeniye; [WeightPoint.kg] bu seride cm (veya %) değeridir.
  final List<WeightPoint> points;

  double get first => points.first.kg;
  double get latest => points.last.kg;
  double get change => latest - first;
  DateTime get latestAt => points.last.date;

  MeasurementTrend get trend => MeasurementTrend(
    field: field,
    first: first,
    latest: latest,
    latestAt: latestAt,
  );

  @override
  List<Object?> get props => [field, points];
}

abstract final class MeasurementStats {
  /// Kaydı olan ölçüler, [MeasurementField] sırasıyla.
  static List<MeasurementSeries> series(List<BodyMeasurement> measurements) {
    final sorted = [...measurements]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return [
      for (final field in MeasurementField.values)
        if (_points(field, sorted) case final points when points.isNotEmpty)
          MeasurementSeries(field: field, points: points),
    ];
  }

  static List<WeightPoint> _points(
    MeasurementField field,
    List<BodyMeasurement> sorted,
  ) => [
    for (final m in sorted)
      if (field.valueOf(m) case final value?) WeightPoint(m.recordedAt, value),
  ];
}
