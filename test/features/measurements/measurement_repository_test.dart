import 'package:diyet_programi/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:diyet_programi/features/measurements/domain/services/measurement_stats.dart';
import 'package:diyet_programi/features/progress/domain/models/progress_report.dart';
import 'package:diyet_programi/shared/models/body_measurement.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late MeasurementRepositoryImpl repo;

  setUp(() {
    db = InMemoryDocumentDatabase();
    repo = MeasurementRepositoryImpl(db, 'user-1');
  });
  tearDown(() => db.dispose());

  test('ölçüm eklenince bel değişimi hesaplanır', () async {
    await repo.addMeasurement(
      BodyMeasurement(
        id: '',
        recordedAt: DateTime(2026, 8, 1),
        waistCm: 98,
        hipCm: 110,
        chestCm: 102,
        neckCm: 38,
        armCm: 33,
        thighCm: 61,
      ),
    );
    final latest = (await repo.addMeasurement(
      BodyMeasurement(
        id: '',
        recordedAt: DateTime(2026, 9, 28),
        waistCm: 92,
        hipCm: 106,
        chestCm: 100,
        armCm: 32,
        thighCm: 59,
      ),
    )).valueOrNull!;
    expect(latest.waistCm, 92);

    final list = await repo.watchMeasurements().first;
    expect(list, hasLength(2));
    final waist = MeasurementStats.series(list)
        .firstWhere((s) => s.field == MeasurementField.waist);
    expect(waist.first, 98);
    expect(waist.latest, 92);
    expect(waist.change, -6);
  });
}
