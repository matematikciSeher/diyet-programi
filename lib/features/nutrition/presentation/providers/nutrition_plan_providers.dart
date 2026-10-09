import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/models/plan_item.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/domain/usecases/log_planned_meal.dart';
import '../../../meal_plans/domain/usecases/weekly_meal_planner.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';

/// Haftalık planda seçili gün (gün başlangıcı).
class SelectedPlanDay extends Notifier<DateTime> {
  @override
  DateTime build() => ref.read(clockProvider)().startOfDay;

  void select(DateTime day) => state = day.startOfDay;

  void shiftWeek(int weeks) => state = state.addDays(7 * weeks);
}

final selectedPlanDayProvider = NotifierProvider<SelectedPlanDay, DateTime>(
  SelectedPlanDay.new,
);

final selectedWeekProvider = Provider<List<DateTime>>(
  (ref) => WeeklyMealPlanner.weekDays(ref.watch(selectedPlanDayProvider)),
);

/// "Yeni Plan Oluştur" formunda profile yazılan tercihler.
typedef NewPlanInput = ({
  int mealsPerDay,
  DietType dietType,
  List<String> dislikedFoods,
});

/// Beslenme Planı ekranının eylemleri. Plan verisi [WeeklyMealPlanner],
/// günlük kaydı [LogPlannedMeal] üzerinden aynı repository'lere yazılır;
/// Dashboard ve Günlük bu akışları dinlediği için anında güncellenir.
class NutritionPlanActions {
  const NutritionPlanActions(this._ref);

  final Ref _ref;

  WeeklyMealPlanner get _planner => _ref.read(weeklyMealPlannerProvider);
  MealPlanPreferences get _prefs => _ref.read(mealPlanPreferencesProvider);
  DateTime get _now => _ref.read(clockProvider)();

  /// Seçili gün hangisi olursa olsun öğün bugünün günlüğüne eklenir.
  Future<Result<List<MealEntry>>> logToToday(
    PlannedMeal meal, {
    required String Function(PlanItem item) servingLabel,
    String? mealServingLabel,
  }) => _ref.read(logPlannedMealProvider)(
    meal,
    servingLabel: servingLabel,
    mealServingLabel: mealServingLabel,
  );

  Future<void> undoLog(List<MealEntry> entries) =>
      _ref.read(logPlannedMealProvider).undo(entries);

  Future<Result<List<PlannedMeal>>> alternatives(
    DateTime day,
    PlannedMeal meal,
  ) => _planner.alternatives(day, meal, _prefs);

  Future<Result<void>> replace(DateTime day, PlannedMeal replacement) =>
      _planner.replaceMeal(day, replacement);

  /// Tercihleri profile yazar ve seçili haftanın bugünden sonraki
  /// günlerini yeni tercihlere göre yeniden üretir. Kalori ve makro
  /// hedefleri profilde kalır; plan onları okur.
  Future<Result<void>> createNewPlan(NewPlanInput input) async {
    final profiles = _ref.read(userProfileRepositoryProvider);
    final profile = (await profiles.getProfile()).valueOrNull;
    var prefs = _prefs;
    if (profile != null) {
      final updated = profile.copyWith(
        mealsPerDay: input.mealsPerDay,
        dietType: input.dietType,
        dislikedFoods: input.dislikedFoods,
        updatedAt: _now,
      );
      final saved = await profiles.saveProfile(updated);
      if (saved case Err(:final failure)) return Result.failure(failure);
      prefs = MealPlanPreferences.fromProfile(
        updated,
      ).withExcluded(_ref.read(sessionPlanExclusionsProvider));
    }
    final today = _now.startOfDay;
    final days = [
      for (final d in _ref.read(selectedWeekProvider))
        if (!d.isBefore(today)) d,
    ];
    return _planner.regenerate(
      days.isEmpty ? [today] : days,
      prefs,
      seed: _now.millisecondsSinceEpoch & 0x7fffffff,
    );
  }
}

final nutritionPlanActionsProvider = Provider<NutritionPlanActions>(
  NutritionPlanActions.new,
);
