import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/services/health/health_data_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/daily_activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/services/activity_day.dart';
import '../../domain/services/activity_health_mapper.dart';
import '../datasources/health_activity_cache.dart';

/// Aynı gün için sağlık platformunu yeniden sorgulamadan önce beklenen süre.
const healthSyncFreshness = Duration(minutes: 15);

class HealthSyncEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final healthSyncEpochProvider = NotifierProvider<HealthSyncEpoch, int>(
  HealthSyncEpoch.new,
);

final healthActivityCacheProvider = Provider<HealthActivityCache>(
  (ref) => HealthActivityCache(ref.watch(keyValueStorageProvider)),
);

/// Sağlık platformundan okur. İzin yoksa yerel/manuel kaydı bozmadan döner.
/// Ağ gerekmez; okuma başarısızsa son önbellek gösterilir.
final class HealthActivityRepository implements ActivityRepository {
  HealthActivityRepository({
    required HealthDataService health,
    required HealthActivityCache cache,
    required DateTime Function() clock,
    this.syncEpoch = 0,
    this.freshness = healthSyncFreshness,
    this.timeZoneName,
  }) : _health = health,
       _cache = cache,
       _clock = clock;

  final HealthDataService _health;
  final HealthActivityCache _cache;
  final DateTime Function() _clock;
  final int syncEpoch;
  final Duration freshness;
  final String? timeZoneName;

  @override
  Stream<DailyActivity> watchDay(DateTime day) async* {
    yield await loadDay(day);
  }

  Future<DailyActivity> loadDay(DateTime day, {bool force = false}) async {
    final now = _clock();
    final today = ActivityDayBounds.forInstant(now, timeZoneName: timeZoneName);
    final dayBounds = ActivityDayBounds.forInstant(
      day,
      timeZoneName: timeZoneName,
    );
    final isFuture =
        dayBounds.from.isAfter(today.to) ||
        dayBounds.from.isAtSameMomentAs(today.to);
    if (isFuture) return _merge(dayBounds.dayKey, health: null);

    if (!_cache.isLinked) {
      return _merge(dayBounds.dayKey, health: null);
    }

    final permitted = await _permissionAllowsRead();
    if (permitted == false) {
      await _cache.setLinked(value: false);
      return _merge(dayBounds.dayKey, health: null);
    }

    final cached = _cache.healthFor(dayBounds.dayKey);
    final shouldRead =
        force ||
        syncEpoch != _cache.appliedEpoch ||
        !_isFresh(cached, dayBounds, now);
    if (!shouldRead) return _merge(dayBounds.dayKey, health: cached);

    try {
      final read = await _read(dayBounds, now);
      if (_platformReadFailed(read)) {
        return _merge(dayBounds.dayKey, health: cached ?? read);
      }
      final saved = await _cache.upsertHealth(dayBounds.dayKey, read);
      if (dayBounds.dayKey == today.dayKey) {
        await _cache.setAppliedEpoch(syncEpoch);
      }
      return _merge(dayBounds.dayKey, health: saved);
    } on Object {
      return _merge(dayBounds.dayKey, health: cached);
    }
  }

  Future<bool?> _permissionAllowsRead() async {
    try {
      return await _health.hasPermissions(healthActivityReadTypes);
    } on Object {
      return null;
    }
  }

  Future<DailyActivity> _read(ActivityDayBounds bounds, DateTime now) async {
    final steps = await _health.getSteps(from: bounds.from, to: bounds.to);
    final calories = await _health.getActiveCalories(
      from: bounds.from,
      to: bounds.to,
    );
    final distance = await _health.getDistanceMeters(
      from: bounds.from,
      to: bounds.to,
    );
    final workouts = await _health.getWorkouts(from: bounds.from, to: bounds.to);
    return ActivityHealthMapper.fromRead(
      syncedAt: now,
      steps: steps,
      activeCalories: calories,
      distanceMeters: distance,
      workouts: workouts,
    );
  }

  DailyActivity _merge(String dayKey, {required DailyActivity? health}) =>
      ActivityHealthMapper.merge(
        manual: _cache.manualFor(dayKey),
        health: health,
      );

  /// İzin var ama platform hiçbir ölçümü döndürmediyse okuma başarısızdır.
  /// Son önbellek korunur. Önbellek yoksa bilinmeyen ölçüm gösterilir;
  /// başarısız okuma taze kayıt olarak yazılmaz.
  bool _platformReadFailed(DailyActivity read) =>
      !read.stepsKnown &&
      !read.caloriesKnown &&
      !read.distanceKnown &&
      !read.workoutsKnown;

  bool _isFresh(DailyActivity? cached, ActivityDayBounds day, DateTime now) {
    final syncedAt = cached?.lastSyncedAt;
    if (cached == null || syncedAt == null) return false;
    if (!now.isBefore(day.to)) return !syncedAt.isBefore(day.to);
    return now.difference(syncedAt) < freshness;
  }
}

/// Sağlık entegrasyonu bağlanana kadar örnek veri. Her gün için sabit ama
/// farklı değerler üretir; gelecek günler boştur.
final class DemoActivityRepository implements ActivityRepository {
  const DemoActivityRepository({DateTime Function() clock = DateTime.now})
    : _clock = clock;

  final DateTime Function() _clock;

  static const today = DailyActivity(
    steps: 6842,
    activeCalories: 312,
    exerciseMinutes: 35,
  );

  @override
  Stream<DailyActivity> watchDay(DateTime day) {
    final now = _clock();
    if (day.isSameDay(now)) return Stream.value(today);
    if (day.startOfDay.isAfter(now)) return Stream.value(DailyActivity.empty);
    final seed = day.difference(DateTime(2000)).inDays;
    final variation = (seed * 37) % 100 / 100;
    return Stream.value(
      DailyActivity(
        steps: 4200 + (variation * 6800).round(),
        activeCalories: 180 + (variation * 320).roundToDouble(),
        exerciseMinutes: 15 + ((seed * 13) % 50),
      ),
    );
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  if (ref.watch(appConfigProvider).useFakeServices) {
    return DemoActivityRepository(clock: ref.watch(clockProvider));
  }
  return HealthActivityRepository(
    health: ref.watch(healthDataServiceProvider),
    cache: ref.watch(healthActivityCacheProvider),
    clock: ref.watch(clockProvider),
    syncEpoch: ref.watch(healthSyncEpochProvider),
  );
});
