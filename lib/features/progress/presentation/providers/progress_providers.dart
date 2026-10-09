import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/progress_photo.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/media/photo_picker_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../measurements/data/repositories/measurement_repository_impl.dart';
import '../../../measurements/domain/repositories/measurement_repository.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../weight/data/repositories/weight_repository_impl.dart';
import '../../../weight/domain/usecases/weight_tracker.dart';
import '../../../weight/presentation/providers/weight_tracker_provider.dart';
import '../../data/datasources/demo_history_seeder.dart';
import '../../data/repositories/progress_photo_repository_impl.dart';
import '../../domain/models/progress_report.dart';
import '../../domain/repositories/progress_photo_repository.dart';
import '../../domain/services/progress_calculator.dart';

class ProgressRangeController extends Notifier<ProgressRange> {
  @override
  ProgressRange build() => ProgressRange.month;

  void select(ProgressRange range) => state = range;
}

final progressRangeProvider =
    NotifierProvider<ProgressRangeController, ProgressRange>(
      ProgressRangeController.new,
    );

final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) async* {
  await ref.watch(demoHistorySeederProvider.future);
  yield* ref.watch(weightRepositoryProvider).watchEntries();
});

final measurementsProvider = StreamProvider<List<BodyMeasurement>>((
  ref,
) async* {
  await ref.watch(demoHistorySeederProvider.future);
  yield* ref.watch(measurementRepositoryProvider).watchMeasurements();
});

final progressPhotosProvider = StreamProvider<List<ProgressPhoto>>(
  (ref) => ref.watch(progressPhotoRepositoryProvider).watchPhotos(),
);

/// Görsel baytları; dosya depolamadan bir kez indirilip önbellekte tutulur.
final progressPhotoImageProvider =
    FutureProvider.family<Uint8List?, ProgressPhoto>((ref, photo) async {
      final result = await ref
          .watch(progressPhotoRepositoryProvider)
          .loadImage(photo);
      return result.when(success: (b) => b, failure: (f) => throw f);
    });

/// Seçili dönemin uyum ve haftalık ortalama hesabı için gereken ilk gün.
final _historyStartProvider = Provider<DateTime>(
  (ref) => ProgressCalculator.historyStart(
    ref.watch(clockProvider)(),
    ref.watch(progressRangeProvider),
  ),
);

final _rangeMealsProvider = StreamProvider<List<MealEntry>>((ref) async* {
  await ref.watch(demoHistorySeederProvider.future);
  yield* ref
      .watch(mealLogRepositoryProvider)
      .watchRange(ref.watch(_historyStartProvider), ref.read(clockProvider)());
});

final _rangeWaterProvider = StreamProvider<List<WaterLog>>((ref) async* {
  await ref.watch(demoHistorySeederProvider.future);
  yield* ref
      .watch(waterRepositoryProvider)
      .watchRange(ref.watch(_historyStartProvider), ref.read(clockProvider)());
});

final progressReportProvider = Provider<AsyncValue<ProgressReport>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final weights = ref.watch(weightEntriesProvider);
  final measurements = ref.watch(measurementsProvider);
  final meals = ref.watch(_rangeMealsProvider);
  final water = ref.watch(_rangeWaterProvider);

  final sources = <AsyncValue<Object?>>[
    profile,
    weights,
    measurements,
    meals,
    water,
  ];
  for (final source in sources) {
    if (source.hasError && !source.hasValue) {
      return AsyncError(source.error!, source.stackTrace ?? StackTrace.empty);
    }
  }
  if (sources.any((s) => !s.hasValue)) return const AsyncLoading();

  return AsyncData(
    ProgressCalculator.build(
      range: ref.watch(progressRangeProvider),
      now: ref.read(clockProvider)(),
      profile: profile.value,
      targets: profile.value?.nutritionTargets ?? NutritionTargets.fallback,
      weightEntries: weights.requireValue,
      measurements: measurements.requireValue,
      meals: meals.requireValue,
      waterLogs: water.requireValue,
    ),
  );
});

/// İlerleme ekranından yapılan kayıt işlemleri.
class ProgressActions {
  const ProgressActions({
    required WeightTracker weights,
    required MeasurementRepository measurements,
    required ProgressPhotoRepository photos,
    required PhotoPickerService picker,
    required DateTime Function() clock,
  }) : _weights = weights,
       _measurements = measurements,
       _photos = photos,
       _picker = picker,
       _clock = clock;

  final WeightTracker _weights;
  final MeasurementRepository _measurements;
  final ProgressPhotoRepository _photos;
  final PhotoPickerService _picker;
  final DateTime Function() _clock;

  Future<Result<WeightEntry>> addWeight(
    double kg, {
    DateTime? at,
    String? note,
  }) => _weights.add(kg, at: at ?? _clock(), note: note);

  Future<Result<void>> deleteWeight(String id) => _weights.delete(id);

  Future<Result<WeightEntry>> restoreWeight(WeightEntry entry) =>
      _weights.restore(entry);

  Future<Result<BodyMeasurement>> addMeasurement(BodyMeasurement m) =>
      _measurements.addMeasurement(m);

  Future<Result<void>> deleteMeasurement(String id) =>
      _measurements.deleteMeasurement(id);

  /// Silinen ölçümü aynı id ile geri yükler.
  Future<Result<BodyMeasurement>> restoreMeasurement(BodyMeasurement m) =>
      _measurements.addMeasurement(m);

  bool supportsPhotoSource(PhotoSource source) => _picker.supports(source);

  /// Kullanıcı seçimden vazgeçerse başarılı sonuç `null` taşır.
  Future<Result<ProgressPhoto?>> addPhoto(
    PhotoSource source, {
    double? currentWeightKg,
  }) async {
    final picked = await guard(() => _picker.pick(source));
    if (picked case Err(:final failure)) return Result.failure(failure);
    final photo = picked.valueOrNull;
    if (photo == null) return const Result.success(null);
    return _photos.addPhoto(
      bytes: photo.bytes,
      contentType: photo.contentType,
      takenAt: _clock(),
      weightKg: currentWeightKg,
    );
  }

  Future<Result<void>> deletePhoto(ProgressPhoto photo) =>
      _photos.deletePhoto(photo);
}

final progressActionsProvider = Provider<ProgressActions>(
  (ref) => ProgressActions(
    weights: ref.watch(weightTrackerProvider),
    measurements: ref.watch(measurementRepositoryProvider),
    photos: ref.watch(progressPhotoRepositoryProvider),
    picker: ref.watch(photoPickerServiceProvider),
    clock: ref.watch(clockProvider),
  ),
);
