import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/planned_meal.dart';
import '../../domain/repositories/meal_plan_repository.dart';

/// `users/{uid}/meal_plans` altındaki plan kayıtlarını okur ve yazar.
/// Her öğün ayrı bir dokümandır; id'si `{dayKey}-{sıra}` biçimindedir.
final class MealPlanRepositoryImpl extends UserScopedRepository
    implements MealPlanRepository {
  const MealPlanRepositoryImpl(
    super.db,
    super.uid, {
    AnalyticsService? analytics,
  }) : _analytics = analytics;

  final AnalyticsService? _analytics;

  DocumentQuery _dayQuery(DateTime day) => DocumentQuery(
    filters: [QueryFilter('dayKey', FilterOperator.isEqualTo, day.dayKey)],
  );

  @override
  Stream<List<PlannedMeal>> watchDay(DateTime day) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(FirestorePaths.mealPlans(id), query: _dayQuery(day))
        .map(
          (docs) =>
              docs
                  .map((d) => PlannedMeal.fromJson({...d.data, 'id': d.id}))
                  .toList()
                ..sort(_byTime),
        );
  }

  @override
  Stream<List<PlannedMeal>> watchWeek(DateTime day) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    final keys = _weekKeys(day);
    return db.watchCollection(FirestorePaths.mealPlans(id)).map((docs) {
      final meals = [
        for (final doc in docs)
          if (keys.contains(doc.data['dayKey']))
            PlannedMeal.fromJson({...doc.data, 'id': doc.id}),
      ]..sort(_byDayThenTime);
      return meals;
    });
  }

  @override
  Future<List<PlannedMeal>> getDay(DateTime day) => watchDay(day).first;

  @override
  Future<List<PlannedMeal>> getCurrentPlan(DateTime day) =>
      watchWeek(day).first;

  @override
  Future<PlannedMeal?> getMealById(String id) async {
    final userId = uid;
    if (userId == null || id.isEmpty) return null;
    final doc = await db.getDocument('${FirestorePaths.mealPlans(userId)}/$id');
    if (doc == null) return null;
    return PlannedMeal.fromJson({...doc.data, 'id': doc.id});
  }

  @override
  Future<Result<void>> saveDay(DateTime day, List<PlannedMeal> meals) =>
      guard(() async {
        final collection = FirestorePaths.mealPlans(requireUid());
        final keep = {for (final m in meals) m.id};
        final existing = await db.getCollection(
          collection,
          query: _dayQuery(day),
        );
        for (final doc in existing) {
          if (!keep.contains(doc.id)) {
            await db.deleteDocument('$collection/${doc.id}');
          }
        }
        for (final meal in meals) {
          await db.setDocument('$collection/${meal.id}', meal.toJson());
        }
        unawaited(_analytics?.logEvent(AnalyticsEvents.mealPlanCreated));
      });

  @override
  Future<Result<void>> savePlan(List<PlannedMeal> meals) => guard(() async {
    final byDay = <String, List<PlannedMeal>>{};
    for (final meal in meals) {
      byDay.putIfAbsent(meal.dayKey, () => []).add(meal);
    }
    for (final entry in byDay.entries) {
      final day = _parseDayKey(entry.key);
      if (day == null) continue;
      (await saveDay(day, entry.value)).requireValue;
    }
  });

  @override
  Future<Result<void>> deleteDay(DateTime day) => saveDay(day, const []);

  @override
  Future<Result<void>> deleteWeek(DateTime day) => guard(() async {
    final start = _weekStart(day);
    for (var i = 0; i < 7; i++) {
      (await deleteDay(start.add(Duration(days: i)))).requireValue;
    }
  });

  @override
  Future<Result<void>> replaceMeal(DateTime day, PlannedMeal meal) =>
      guard(() async {
        final current = await getDay(day);
        final next = <PlannedMeal>[
          for (final existing in current)
            if (existing.id != meal.id) existing,
          meal,
        ];
        (await saveDay(day, next)).requireValue;
      });

  @override
  Future<Result<void>> updateMealPortion(DateTime day, PlannedMeal meal) =>
      replaceMeal(day, meal);

  @override
  Future<Result<void>> addMeal(DateTime day, PlannedMeal meal) =>
      replaceMeal(day, meal);

  @override
  Future<Result<void>> removeMeal(DateTime day, String mealId) =>
      guard(() async {
        final current = await getDay(day);
        (await saveDay(day, [
          for (final meal in current)
            if (meal.id != mealId) meal,
        ])).requireValue;
      });

  static DateTime _weekStart(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return start.subtract(Duration(days: start.weekday - DateTime.monday));
  }

  static Set<String> _weekKeys(DateTime day) {
    final start = _weekStart(day);
    return {for (var i = 0; i < 7; i++) start.add(Duration(days: i)).dayKey};
  }

  static DateTime? _parseDayKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static int _byDayThenTime(PlannedMeal a, PlannedMeal b) {
    final byDay = a.dayKey.compareTo(b.dayKey);
    if (byDay != 0) return byDay;
    return _byTime(a, b);
  }

  static int _byTime(PlannedMeal a, PlannedMeal b) {
    final byTime = (a.timeMinutes ?? 24 * 60).compareTo(
      b.timeMinutes ?? 24 * 60,
    );
    return byTime != 0 ? byTime : a.mealType.index.compareTo(b.mealType.index);
  }
}

final mealPlanRepositoryProvider = Provider<MealPlanRepository>(
  (ref) => MealPlanRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);
