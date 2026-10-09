import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/measurement_repository.dart';

final class MeasurementRepositoryImpl extends UserScopedRepository
    implements MeasurementRepository {
  const MeasurementRepositoryImpl(super.db, super.uid);

  @override
  Stream<List<BodyMeasurement>> watchMeasurements() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.measurements(id),
          query: const DocumentQuery(orderBy: 'recordedAt'),
        )
        .map(
          (docs) => docs
              .map((d) => BodyMeasurement.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Future<Result<BodyMeasurement>> addMeasurement(BodyMeasurement measurement) =>
      guard(() async {
        final collection = FirestorePaths.measurements(requireUid());
        final saved = measurement.id.isEmpty
            ? BodyMeasurement.fromJson({
                ...measurement.toJson(),
                'id': db.generateId(collection),
              })
            : measurement;
        await db.setDocument('$collection/${saved.id}', saved.toJson());
        return saved;
      });

  @override
  Future<Result<void>> deleteMeasurement(String id) => guard(
    () => db.deleteDocument('${FirestorePaths.measurements(requireUid())}/$id'),
  );
}

final measurementRepositoryProvider = Provider<MeasurementRepository>(
  (ref) => MeasurementRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
  ),
);
