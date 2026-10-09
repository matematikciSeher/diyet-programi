import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../measurements/data/repositories/measurement_repository_impl.dart';
import '../../../measurements/domain/repositories/measurement_repository.dart';
import '../../../weight/data/repositories/weight_repository_impl.dart';
import '../../../weight/domain/repositories/weight_repository.dart';
import '../../domain/repositories/body_progress_repository.dart';

/// Kilo ve ölçüm repository'lerini tek akışta birleştirir; iki kaynak da
/// ilk değerini verdikten sonra yayın başlar.
final class CombinedBodyProgressRepository implements BodyProgressRepository {
  const CombinedBodyProgressRepository({
    required WeightRepository weights,
    required MeasurementRepository measurements,
  }) : _weights = weights,
       _measurements = measurements;

  final WeightRepository _weights;
  final MeasurementRepository _measurements;

  @override
  Stream<BodyProgressSnapshot> watch() {
    List<WeightEntry>? weights;
    List<BodyMeasurement>? measurements;
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<BodyProgressSnapshot> controller;

    void emit() {
      final w = weights;
      final m = measurements;
      if (w == null || m == null) return;
      controller.add(BodyProgressSnapshot(weights: w, measurements: m));
    }

    controller = StreamController<BodyProgressSnapshot>(
      onListen: () {
        subscriptions
          ..add(
            _weights.watchEntries().listen((v) {
              weights = v;
              emit();
            }, onError: controller.addError),
          )
          ..add(
            _measurements.watchMeasurements().listen((v) {
              measurements = v;
              emit();
            }, onError: controller.addError),
          );
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      },
    );
    return controller.stream;
  }
}

final bodyProgressRepositoryProvider = Provider<BodyProgressRepository>(
  (ref) => CombinedBodyProgressRepository(
    weights: ref.watch(weightRepositoryProvider),
    measurements: ref.watch(measurementRepositoryProvider),
  ),
);
