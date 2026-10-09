import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../models/meal_plan_preferences.dart';
import '../models/planned_meal.dart';
import '../repositories/meal_plan_repository.dart';
import '../services/meal_plan_generation_service.dart';
import '../services/meal_plan_generator.dart';

/// Pazartesi–Pazar haftalık plan işlemleri. Günlük planlar
/// [MealPlanRepository]'de gün gün tutulur; kalori hedefi ve kısıtlar her
/// zaman [MealPlanPreferences] (yani kullanıcı profili) üzerinden gelir.
class WeeklyMealPlanner {
  const WeeklyMealPlanner({
    required MealPlanRepository plans,
    required MealPlanGenerationService generator,
  }) : _plans = plans,
       _generator = generator;

  final MealPlanRepository _plans;
  final MealPlanGenerationService _generator;

  static DateTime weekStart(DateTime day) =>
      day.startOfDay.addDays(-(day.weekday - DateTime.monday));

  static List<DateTime> weekDays(DateTime day) {
    final start = weekStart(day);
    return [for (var i = 0; i < 7; i++) start.addDays(i)];
  }

  Future<List<PlannedMeal>> _read(DateTime day) =>
      _plans.watchDay(day.startOfDay).first;

  /// Günün planı; yoksa [prefs]'e göre üretilip kaydedilir.
  ///
  /// Aynı haftanın diğer günlerinde seçilmiş tarifler üreticiye iletilir;
  /// böylece günler birbirinden bağımsız aynı yemeği seçmez.
  Future<Result<List<PlannedMeal>>> ensureDay(
    DateTime day,
    MealPlanPreferences prefs,
  ) => guard(() async {
    final existing = await _read(day);
    if (existing.isNotEmpty) return existing;
    final reserved = await _reservedRecipes(day);
    final plan = await _generator.generateDay(
      day.startOfDay,
      prefs,
      reservedRecipeIds: reserved,
    );
    (await _plans.saveDay(day.startOfDay, plan)).requireValue;
    return plan;
  });

  Future<List<String>> _reservedRecipes(DateTime day) async {
    final reserved = <String>[];
    for (final other in weekDays(day)) {
      if (other.isSameDay(day)) continue;
      for (final meal in await _read(other)) {
        final id = meal.recipeId;
        if (id != null && id.isNotEmpty) reserved.add(id);
      }
    }
    return reserved;
  }

  Future<Result<List<PlannedMeal>>> alternatives(
    DateTime day,
    PlannedMeal meal,
    MealPlanPreferences prefs, {
    int count = 3,
  }) => guard(() async {
    final plan = await _read(day);
    return _generator.alternatives(meal, plan, prefs, count: count);
  });

  /// Aynı id'li öğünü [replacement] ile değiştirir.
  Future<Result<void>> replaceMeal(DateTime day, PlannedMeal replacement) =>
      guard(() async {
        final plan = await _read(day);
        (await _plans.saveDay(day.startOfDay, [
          for (final m in plan) m.id == replacement.id ? replacement : m,
        ])).requireValue;
      });

  /// [meal]'i günün [MealType] öğününe yerleştirir (ör. tarifi plana
  /// ekleme). Gün planı yoksa önce üretilir; o tipte öğün varsa ilki
  /// değiştirilir, yoksa yeni öğün eklenir. Kaydedilen öğünü döndürür.
  Future<Result<PlannedMeal>> placeMeal(
    DateTime day,
    PlannedMeal meal,
    MealPlanPreferences prefs,
  ) => guard(() async {
    final plan = (await ensureDay(day, prefs)).requireValue;
    final dayKey = day.dayKey;
    final existing = plan.where((m) => m.mealType == meal.mealType).firstOrNull;
    final placed = PlannedMeal(
      id: existing?.id ?? '$dayKey-${meal.mealType.name}-${plan.length}',
      dayKey: dayKey,
      mealType: meal.mealType,
      title: meal.title,
      nutrition: meal.nutrition,
      items: meal.items,
      templateId: meal.templateId,
      portionFactor: meal.portionFactor,
      description: meal.description,
      recipeId: meal.recipeId,
      timeMinutes:
          existing?.timeMinutes ?? meal.timeMinutes ?? _timeFor(meal, prefs),
    );
    final next = existing == null
        ? [...plan, placed]
        : [for (final m in plan) m.id == existing.id ? placed : m];
    (await _plans.saveDay(day.startOfDay, next)).requireValue;
    return placed;
  });

  static int _timeFor(PlannedMeal meal, MealPlanPreferences prefs) {
    final slots = prefs.slots.contains(meal.mealType)
        ? prefs.slots
        : [meal.mealType];
    final index = slots.indexOf(meal.mealType);
    return switch (prefs.eatingWindow) {
      final window? => MealPlanGenerator.windowTime(
        window,
        slots.length,
        index,
      ),
      null => MealPlanGenerator.defaultTime(slots, index),
    };
  }

  /// Öğünleri değiştirmeden saatlerini [prefs]'e (ör. yeni yeme
  /// penceresine) göre yeniden dağıtır. Planı olmayan günler atlanır.
  Future<Result<void>> retime(
    Iterable<DateTime> days,
    MealPlanPreferences prefs,
  ) => guard(() async {
    for (final day in days) {
      final plan = await _read(day);
      if (plan.isEmpty) continue;
      final window = prefs.eatingWindow;
      final slots = [for (final m in plan) m.mealType];
      final retimed = [
        for (final (i, m) in plan.indexed)
          PlannedMeal(
            id: m.id,
            dayKey: m.dayKey,
            mealType: m.mealType,
            title: m.title,
            nutrition: m.nutrition,
            items: m.items,
            templateId: m.templateId,
            portionFactor: m.portionFactor,
            description: m.description,
            recipeId: m.recipeId,
            timeMinutes: window == null
                ? MealPlanGenerator.defaultTime(slots, i)
                : MealPlanGenerator.windowTime(window, plan.length, i),
          ),
      ];
      (await _plans.saveDay(day.startOfDay, retimed)).requireValue;
    }
  });

  /// [days] için planı yeniden üretir; her gün farklı tohum alır.
  /// Önceki günlerin tarifleri sonrakilere aktarılır.
  Future<Result<void>> regenerate(
    Iterable<DateTime> days,
    MealPlanPreferences prefs, {
    required int seed,
  }) => guard(() async {
    final reserved = <String>[];
    for (final (i, day) in days.indexed) {
      final plan = await _generator.generateDay(
        day.startOfDay,
        prefs,
        seed: seed + i,
        reservedRecipeIds: List<String>.from(reserved),
      );
      reserved.addAll([
        for (final meal in plan)
          if (meal.recipeId != null && meal.recipeId!.isNotEmpty)
            meal.recipeId!,
      ]);
      (await _plans.saveDay(day.startOfDay, plan)).requireValue;
    }
  });
}
