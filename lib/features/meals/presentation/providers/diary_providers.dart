import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../food/data/repositories/food_repository_impl.dart';
import '../../../progress/data/datasources/demo_history_seeder.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../weight/presentation/providers/weight_tracker_provider.dart';
import '../../data/repositories/daily_log_repository_impl.dart';
import '../../data/repositories/meal_log_repository_impl.dart';
import '../../data/repositories/nutrition_score_repository_impl.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/models/daily_nutrition_score.dart';
import '../../domain/usecases/diary_actions.dart';

/// Günlük'te gidilebilecek tarih aralığı.
abstract final class DiaryDateRange {
  static const maxPastDays = 365;

  /// Öğünleri önceden planlayabilmek için kısa bir gelecek aralığı.
  static const maxFutureDays = 7;

  static DateTime first(DateTime today) =>
      today.startOfDay.addDays(-maxPastDays);
  static DateTime last(DateTime today) =>
      today.startOfDay.addDays(maxFutureDays);
}

/// Günlük'te seçili gün. Sekme değişse de korunur.
class SelectedDateController extends Notifier<DateTime> {
  DateTime get today => ref.read(clockProvider)().startOfDay;

  @override
  DateTime build() => today;

  bool get canGoBack => state.isAfter(DiaryDateRange.first(today));
  bool get canGoForward => state.isBefore(DiaryDateRange.last(today));

  void select(DateTime date) {
    final first = DiaryDateRange.first(today);
    final last = DiaryDateRange.last(today);
    final day = date.startOfDay;
    state = day.isBefore(first) ? first : (day.isAfter(last) ? last : day);
  }

  void previous() => select(state.addDays(-1));
  void next() => select(state.addDays(1));
  void goToToday() => state = today;
}

final selectedDateProvider = NotifierProvider<SelectedDateController, DateTime>(
  SelectedDateController.new,
);

/// Kalori, makro ve su hedefleri profilden gelir.
final diaryTargetsProvider = Provider<NutritionTargets>(
  (ref) =>
      ref.watch(userProfileProvider.select((p) => p.value?.nutritionTargets)) ??
      NutritionTargets.fallback,
);

/// Seçili günün birleşik kaydı; skor eklenmiş olarak yayınlanır.
final dailyLogProvider = StreamProvider<DailyLog>((ref) async* {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(dailyLogRepositoryProvider);
  final scores = ref.watch(nutritionScoreRepositoryProvider);
  final targets = ref.watch(diaryTargetsProvider);
  final clock = ref.watch(clockProvider);
  await ref.watch(demoHistorySeederProvider.future);
  yield* repo
      .watchDay(date)
      .map(
        (log) =>
            log.withScore(scores.scoreFor(log, targets: targets, now: clock())),
      );
});

/// Sayfa iskeleti yalnızca bu durum değişince yeniden çizilir.
typedef DiaryStatus = ({bool hasValue, Object? error, bool isEmpty});

final diaryStatusProvider = Provider<DiaryStatus>(
  (ref) => ref.watch(
    dailyLogProvider.select(
      (s) => (
        hasValue: s.hasValue,
        error: s.hasValue ? null : s.error,
        isEmpty: s.value?.isEmpty ?? true,
      ),
    ),
  ),
);

/// Her öğün kartı yalnızca kendi öğünü değişince yeniden çizilir.
final mealLogProvider = Provider.family<MealLog?, MealType>(
  (ref, type) => ref.watch(dailyLogProvider.select((s) => s.value?.meal(type))),
);

/// Günlük toplam kalori ve makrolar.
final dailyNutritionTotalsProvider = Provider<NutritionFacts?>(
  (ref) => ref.watch(dailyLogProvider.select((s) => s.value?.totals)),
);

class WaterProgress extends Equatable {
  WaterProgress({required this.logs, required this.goalMl})
    : consumedMl = logs.fold(0, (sum, l) => sum + l.amountMl);

  final List<WaterLog> logs;
  final int goalMl;
  final int consumedMl;

  double get progress => goalMl <= 0 ? 0 : consumedMl / goalMl;
  bool get reachedGoal => goalMl > 0 && consumedMl >= goalMl;

  @override
  List<Object?> get props => [logs, goalMl, consumedMl];
}

final waterProgressProvider = Provider<WaterProgress?>((ref) {
  final logs = ref.watch(dailyLogProvider.select((s) => s.value?.waterLogs));
  if (logs == null) return null;
  final goal = ref.watch(diaryTargetsProvider.select((t) => t.waterMl));
  return WaterProgress(logs: logs, goalMl: goal);
});

final diaryActivityProvider = Provider<DailyActivity?>(
  (ref) => ref.watch(dailyLogProvider.select((s) => s.value?.activity)),
);

final diaryWeightProvider = Provider<double?>(
  (ref) => ref.watch(dailyLogProvider.select((s) => s.value?.weight?.weightKg)),
);

final nutritionScoreProvider = Provider<DailyNutritionScore?>(
  (ref) => ref.watch(dailyLogProvider.select((s) => s.value?.nutritionScore)),
);

/// Kullanıcının daralttığı öğün kartları; sekme değişse de korunur.
class CollapsedMealsController extends Notifier<Set<MealType>> {
  @override
  Set<MealType> build() => const {};

  void toggle(MealType type) => state = state.contains(type)
      ? ({...state}..remove(type))
      : {...state, type};
}

final collapsedMealsProvider =
    NotifierProvider<CollapsedMealsController, Set<MealType>>(
      CollapsedMealsController.new,
    );

final diaryActionsProvider = Provider<DiaryActions>(
  (ref) => DiaryActions(
    meals: ref.watch(mealLogRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    weights: ref.watch(weightTrackerProvider),
    foods: ref.watch(foodRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

class DiaryFocus {
  const DiaryFocus({this.section, this.meal});

  final String? section;
  final MealType? meal;
}

class DiaryFocusController extends Notifier<DiaryFocus?> {
  @override
  DiaryFocus? build() => null;

  void focus(DiaryFocus value) => state = value;

  void clear() => state = null;
}

final diaryFocusProvider = NotifierProvider<DiaryFocusController, DiaryFocus?>(
  DiaryFocusController.new,
);
