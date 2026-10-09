import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../activity/data/repositories/activity_repository_impl.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../data/datasources/demo_day_seeder.dart';
import '../../domain/daily_dashboard.dart';
import '../../domain/nutrition_score.dart';

final dashboardDayProvider = Provider<DateTime>(
  (ref) => ref.watch(clockProvider)().startOfDay,
);

final todayMealsProvider = StreamProvider<List<MealEntry>>((ref) async* {
  final repo = ref.watch(mealLogRepositoryProvider);
  final day = ref.watch(dashboardDayProvider);
  await ref.watch(demoDaySeederProvider.future);
  yield* repo.watchDay(day);
});

final todayWaterLogsProvider = StreamProvider<List<WaterLog>>((ref) async* {
  final repo = ref.watch(waterRepositoryProvider);
  final day = ref.watch(dashboardDayProvider);
  await ref.watch(demoDaySeederProvider.future);
  yield* repo.watchDay(day);
});

final todayActivityProvider = StreamProvider<DailyActivity>(
  (ref) => ref
      .watch(activityRepositoryProvider)
      .watchDay(ref.watch(dashboardDayProvider)),
);

final todayPlanProvider = Provider<AsyncValue<List<PlannedMeal>>>(
  (ref) => ref.watch(mealPlanForDayProvider(ref.watch(dashboardDayProvider))),
);

/// Tüm kaynaklar hazır olduğunda birleşik günlük özet. Kaynaklardan biri
/// hata verirse hata, henüz değer yoksa yükleniyor durumu döner.
final dashboardProvider = Provider<AsyncValue<DailyDashboard>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final meals = ref.watch(todayMealsProvider);
  final water = ref.watch(todayWaterLogsProvider);
  final activity = ref.watch(todayActivityProvider);
  final plan = ref.watch(todayPlanProvider);

  final sources = <AsyncValue<Object?>>[profile, meals, water, activity, plan];
  for (final source in sources) {
    if (source.hasError && !source.hasValue) {
      return AsyncError(source.error!, source.stackTrace ?? StackTrace.empty);
    }
  }
  if (sources.any((s) => !s.hasValue)) return const AsyncLoading();

  final targets = profile.value?.nutritionTargets ?? NutritionTargets.fallback;
  final mealList = meals.requireValue;
  final waterMl = water.requireValue.fold(0, (sum, l) => sum + l.amountMl);
  return AsyncData(
    DailyDashboard(
      day: ref.watch(dashboardDayProvider),
      userName: profile.value?.name,
      targets: targets,
      meals: mealList,
      waterMl: waterMl,
      activity: activity.requireValue,
      plan: plan.requireValue,
      score: NutritionScoreCalculator.calculate(
        meals: mealList,
        targets: targets,
        waterMl: waterMl,
        now: ref.read(clockProvider)(),
      ),
    ),
  );
});

/// Dashboard'dan tetiklenen hızlı kayıt işlemleri.
class DashboardActions {
  const DashboardActions(this._water, this._clock);

  final WaterRepository _water;
  final DateTime Function() _clock;

  Future<Result<WaterLog>> addGlass() =>
      _water.addWater(DailyDashboard.glassMl, at: _clock());

  Future<Result<void>> undoWater(String logId) => _water.deleteLog(logId);
}

final dashboardActionsProvider = Provider<DashboardActions>(
  (ref) => DashboardActions(
    ref.watch(waterRepositoryProvider),
    ref.watch(clockProvider),
  ),
);
