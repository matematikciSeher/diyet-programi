import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../activity/data/repositories/activity_repository_impl.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../activity/domain/repositories/activity_repository.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../../weight/data/repositories/weight_repository_impl.dart';
import '../../../weight/domain/repositories/weight_repository.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/repositories/daily_log_repository.dart';
import '../../domain/repositories/meal_log_repository.dart';
import 'meal_log_repository_impl.dart';

/// Öğün, su, aktivite ve kilo kaynaklarını tek bir [DailyLog] akışında
/// birleştirir. Tüm kaynaklar ilk değerini verdikten sonra yayın başlar.
final class CompositeDailyLogRepository implements DailyLogRepository {
  const CompositeDailyLogRepository({
    required MealLogRepository meals,
    required WaterRepository water,
    required ActivityRepository activity,
    required WeightRepository weights,
    String? userId,
  }) : _meals = meals,
       _water = water,
       _activity = activity,
       _weights = weights,
       _userId = userId;

  final MealLogRepository _meals;
  final WaterRepository _water;
  final ActivityRepository _activity;
  final WeightRepository _weights;
  final String? _userId;

  @override
  Stream<DailyLog> watchDay(DateTime day) {
    final date = day.startOfDay;
    List<MealEntry>? entries;
    List<WaterLog>? water;
    DailyActivity? activity;
    List<WeightEntry>? weights;
    final subscriptions = <StreamSubscription<Object?>>[];
    late final StreamController<DailyLog> controller;

    void emit() {
      if (entries == null ||
          water == null ||
          activity == null ||
          weights == null) {
        return;
      }
      controller.add(
        DailyLog.fromEntries(
          date: date,
          userId: _userId,
          entries: entries!,
          waterLogs: water!,
          activity: activity!,
          weight: weights!
              .where((w) => w.recordedAt.isSameDay(date))
              .firstOrNull,
        ),
      );
    }

    void listen<T>(Stream<T> source, void Function(T value) onData) {
      subscriptions.add(
        source.listen((value) {
          onData(value);
          emit();
        }, onError: controller.addError),
      );
    }

    controller = StreamController<DailyLog>(
      onListen: () {
        listen(_meals.watchDay(date), (v) => entries = v);
        listen(_water.watchDay(date), (v) => water = v);
        listen(_activity.watchDay(date), (v) => activity = v);
        listen(_weights.watchEntries(), (v) => weights = v);
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

final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => CompositeDailyLogRepository(
    meals: ref.watch(mealLogRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    activity: ref.watch(activityRepositoryProvider),
    weights: ref.watch(weightRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  ),
);
