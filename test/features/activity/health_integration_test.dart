import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/features/activity/data/datasources/health_activity_cache.dart';
import 'package:diyet_programi/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:diyet_programi/features/activity/domain/models/daily_activity.dart';
import 'package:diyet_programi/features/activity/domain/services/activity_day.dart';
import 'package:diyet_programi/features/activity/domain/services/activity_health_mapper.dart';
import 'package:diyet_programi/features/activity/presentation/providers/health_link_providers.dart';
import 'package:diyet_programi/shared/services/health/fake_health_data_service.dart';
import 'package:diyet_programi/shared/services/health/health_data_service.dart';
import 'package:diyet_programi/shared/services/health/health_service_selector.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/sync/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/test_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  });

  group('health service selection', () {
    test('release uses the platform adapter when the device supports it', () {
      expect(
        resolveHealthServiceKind(
          useFakeServices: true,
          isRelease: true,
          platformSupported: true,
        ),
        HealthServiceKind.platform,
      );
    });

    test('release on an unsupported platform stays unavailable', () {
      expect(
        resolveHealthServiceKind(
          useFakeServices: false,
          isRelease: true,
          platformSupported: false,
        ),
        HealthServiceKind.unavailable,
      );
    });

    test('debug fake services do not install fake health data', () {
      expect(
        resolveHealthServiceKind(
          useFakeServices: true,
          isRelease: false,
          platformSupported: true,
        ),
        HealthServiceKind.unavailable,
      );
    });

    test('fake health service refuses release', () {
      expect(
        () => FakeHealthDataService(isRelease: true),
        throwsStateError,
      );
    });
  });

  group('fake health repository', () {
    late FakeHealthDataService health;
    late HealthActivityCache cache;
    late HealthActivityRepository repo;
    final now = DateTime.utc(2026, 9, 29, 9);

    setUp(() {
      health = FakeHealthDataService(
        steps: 6000,
        activeCalories: 500,
        distanceMeters: 2500,
        workouts: [
          HealthWorkout(
            from: DateTime.utc(2026, 9, 29, 8),
            to: DateTime.utc(2026, 9, 29, 8, 30),
            activityType: 'RUNNING',
            steps: 2000,
          ),
        ],
      );
      cache = HealthActivityCache(InMemoryKeyValueStorage());
      repo = HealthActivityRepository(
        health: health,
        cache: cache,
        clock: () => now,
        timeZoneName: ActivityDayBounds.fallbackTimeZone,
      );
    });

    test('permission granted reads steps, calories, distance and workouts', () async {
      await cache.setLinked(value: true);
      final day = await repo.loadDay(now, force: true);

      expect(day.steps, 6000);
      expect(day.activeCalories, 500);
      expect(day.distanceMeters, 2500);
      expect(day.workoutCount, 1);
      expect(day.exerciseMinutes, 30);
      expect(day.stepsKnown, isTrue);
      expect(day.source, ActivitySource.health);
    });

    test('permission denied does not read and the app keeps going', () async {
      health.permission = FakeHealthPermission.denied;
      final outcome = await HealthLinkController(
        health: health,
        cache: cache,
        onChanged: () {},
      ).connect();

      expect(outcome, HealthLinkOutcome.denied);
      expect(cache.isLinked, isFalse);
      expect(health.stepsReads, 0);

      final day = await repo.loadDay(now);
      expect(day.source, ActivitySource.local);
      expect(day.steps, 0);
      expect(health.stepsReads, 0);
    });

    test('unavailable platform does not throw', () async {
      health.available = false;
      final outcome = await HealthLinkController(
        health: health,
        cache: cache,
        onChanged: () {},
      ).connect();

      expect(outcome, HealthLinkOutcome.unavailable);
      expect(await health.getSteps(from: now, to: now), isNull);
      expect(await health.getActiveCalories(from: now, to: now), isNull);
      expect(await health.getDistanceMeters(from: now, to: now), isNull);
      expect(await health.getWorkouts(from: now, to: now), isNull);
      expect(await health.write(HealthSample(
        type: HealthDataType.steps,
        value: 1,
        from: now,
        to: now,
      )), isFalse);
    });

    test('unsupported measurements stay null', () async {
      health
        ..steps = null
        ..activeCalories = null
        ..distanceMeters = null
        ..workouts = null;
      await cache.setLinked(value: true);
      final day = await repo.loadDay(now, force: true);

      expect(day.stepsKnown, isFalse);
      expect(day.caloriesKnown, isFalse);
      expect(day.distanceKnown, isFalse);
      expect(day.workoutsKnown, isFalse);
    });
  });

  group('mapping and duplicates', () {
    test('health totals replace the day instead of adding manual steps', () {
      final health = ActivityHealthMapper.fromRead(
        syncedAt: DateTime.utc(2026, 9, 29, 12),
        steps: 6000,
        activeCalories: 500,
        distanceMeters: 4000,
        workouts: const [],
      );
      final merged = ActivityHealthMapper.merge(
        manual: const DailyActivity(steps: 6000, source: ActivitySource.manual),
        health: health,
      );

      expect(merged.steps, 6000);
      expect(merged.activeCalories, 500);
    });

    test('the same health snapshot is not stored twice', () async {
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      final activity = ActivityHealthMapper.fromRead(
        syncedAt: DateTime.utc(2026, 9, 29, 12),
        steps: 6000,
        activeCalories: 180,
        distanceMeters: 1000,
        workouts: const [],
      );
      await cache.upsertHealth('2026-09-29', activity);
      await cache.upsertHealth(
        '2026-09-29',
        activity.copyWith(lastSyncedAt: DateTime.utc(2026, 9, 29, 12, 5)),
      );

      expect(cache.healthFor('2026-09-29')!.steps, 6000);
    });

    test('a later reading replaces the total', () async {
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      final first = ActivityHealthMapper.fromRead(
        syncedAt: DateTime.utc(2026, 9, 29, 8),
        steps: 6000,
        activeCalories: 100,
        distanceMeters: 1000,
        workouts: const [],
      );
      final later = first.copyWith(steps: 6100);
      await cache.upsertHealth('2026-09-29', first);
      await cache.upsertHealth('2026-09-29', later);

      expect(cache.healthFor('2026-09-29')!.steps, 6100);
    });

    test('active calories do not change the calorie goal', () {
      final profile = testProfile(dailyCalories: 1800);
      final activity = ActivityHealthMapper.fromRead(
        syncedAt: DateTime.utc(2026, 9, 29),
        steps: 8000,
        activeCalories: 500,
        distanceMeters: 5000,
        workouts: const [],
      );

      expect(profile.dailyCalories, 1800);
      expect(activity.activeCalories, 500);
      expect(activity.activeCalories, isNot(profile.dailyCalories));
    });

    test('workout steps are not added to the daily total', () {
      final day = ActivityHealthMapper.fromRead(
        syncedAt: DateTime.utc(2026, 9, 29, 12),
        steps: 6000,
        activeCalories: 100,
        distanceMeters: 1000,
        workouts: [
          HealthWorkout(
            from: DateTime.utc(2026, 9, 29, 8),
            to: DateTime.utc(2026, 9, 29, 8, 40),
            steps: 2000,
            activeCalories: 80,
            distanceMeters: 1500,
          ),
        ],
      );

      expect(day.steps, 6000);
      expect(day.activeCalories, 100);
      expect(day.distanceMeters, 1000);
      expect(day.exerciseMinutes, 40);
    });

    test('progress week keeps unknown distance out of the total', () {
      final summary = ActivityWeekSummary.fromDays([
        ActivityHealthMapper.fromRead(
          syncedAt: DateTime.utc(2026, 9, 28, 12),
          steps: 1000,
          activeCalories: 50,
          distanceMeters: 800,
          workouts: const [],
        ),
        ActivityHealthMapper.fromRead(
          syncedAt: DateTime.utc(2026, 9, 29, 12),
          steps: 6100,
          activeCalories: 200,
          distanceMeters: null,
          workouts: const [],
        ),
      ]);

      expect(summary.today.steps, 6100);
      expect(summary.today.distanceKnown, isFalse);
      expect(summary.weekSteps, 7100);
      expect(summary.weekCalories, 250);
      expect(summary.weekDistanceMeters, 800);
    });
  });

  group('day bounds and cache', () {
    test('just after midnight in Istanbul belongs to the new day', () async {
      final instant = DateTime.utc(2026, 9, 28, 21, 30);
      final health = FakeHealthDataService(steps: 120);
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      await cache.setLinked(value: true);
      final repo = HealthActivityRepository(
        health: health,
        cache: cache,
        clock: () => instant,
        timeZoneName: 'Europe/Istanbul',
      );

      final day = await repo.loadDay(instant, force: true);
      final bounds = ActivityDayBounds.forInstant(
        instant,
        timeZoneName: 'Europe/Istanbul',
      );

      expect(bounds.dayKey, '2026-09-29');
      expect(health.lastFrom, bounds.from);
      expect(health.lastTo, bounds.to);
      expect(cache.healthFor('2026-09-29')!.steps, day.steps);
      expect(cache.healthFor('2026-09-28'), isNull);
    });

    test('one minute before midnight stays on the previous day', () {
      final instant = DateTime.utc(2026, 9, 28, 20, 59);
      final bounds = ActivityDayBounds.forInstant(
        instant,
        timeZoneName: 'Europe/Istanbul',
      );
      expect(bounds.dayKey, '2026-09-28');
    });

    test('a fresh cache is reused without calling the platform', () async {
      final health = FakeHealthDataService(steps: 4200);
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      await cache.setLinked(value: true);
      final now = DateTime.utc(2026, 9, 29, 15);
      final repo = HealthActivityRepository(
        health: health,
        cache: cache,
        clock: () => now,
        timeZoneName: 'Europe/Istanbul',
      );

      await repo.loadDay(now, force: true);
      final reads = health.stepsReads;
      health
        ..throwOnRead = true
        ..steps = 1;
      final cached = await repo.loadDay(now);

      expect(cached.steps, 4200);
      expect(health.stepsReads, reads);
    });

    test('a failed refresh keeps the last cached day', () async {
      final health = FakeHealthDataService(steps: 4200);
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      await cache.setLinked(value: true);
      var now = DateTime.utc(2026, 9, 29, 10);
      final repo = HealthActivityRepository(
        health: health,
        cache: cache,
        clock: () => now,
        timeZoneName: 'Europe/Istanbul',
      );

      await repo.loadDay(now, force: true);
      now = now.add(const Duration(minutes: 20));
      health
        ..throwOnRead = true
        ..steps = 9999;
      final cached = await repo.loadDay(now);

      expect(cached.steps, 4200);
    });

    test('a null platform read keeps the last cached day', () async {
      final health = FakeHealthDataService(steps: 4200);
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      await cache.setLinked(value: true);
      var now = DateTime.utc(2026, 9, 29, 10);
      final repo = HealthActivityRepository(
        health: health,
        cache: cache,
        clock: () => now,
        timeZoneName: 'Europe/Istanbul',
      );

      await repo.loadDay(now, force: true);
      now = now.add(const Duration(minutes: 20));
      health
        ..steps = null
        ..activeCalories = null
        ..distanceMeters = null
        ..workouts = null;
      final cached = await repo.loadDay(now);

      expect(cached.steps, 4200);
      expect(cached.stepsKnown, isTrue);
      expect(cache.healthFor('2026-09-29')!.steps, 4200);
    });

    test('health cache is not a cloud sync path', () async {
      final cache = HealthActivityCache(InMemoryKeyValueStorage());
      final queue = InMemorySyncQueue();
      await cache.upsertHealth(
        '2026-09-29',
        ActivityHealthMapper.fromRead(
          syncedAt: DateTime.utc(2026, 9, 29),
          steps: 10,
          activeCalories: 1,
          distanceMeters: 2,
          workouts: const [],
        ),
      );

      expect(
        FirestorePaths.userCollectionPaths('user').any(
          (path) => path.contains('health'),
        ),
        isFalse,
      );
      expect(StorageKeys.healthActivityCache.contains('users/'), isFalse);
      expect(queue.snapshot, isEmpty);
      await queue.dispose();
    });
  });
}
