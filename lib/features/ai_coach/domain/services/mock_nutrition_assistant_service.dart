import 'dart:math';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../fasting/domain/services/fasting_timer.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/domain/services/meal_plan_generator.dart';
import '../../../progress/domain/models/progress_report.dart';
import '../catalog/assistant_catalog.dart';
import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';
import 'assistant_guide_engine.dart';
import 'assistant_safety.dart';
import 'nutrition_assistant_service.dart';

enum AssistantIntent {
  overTarget,
  swapPlan,
  planReview,
  dailyReview,
  protein,
  carbs,
  fat,
  mealSuggestion,
  remainingCalories,
  water,
  weight,
  fasting,
  unknown,
}

/// Kayıtlı verilere bakan kural tabanlı asistan.
///
/// Proxy yapılandırılmamış ilk sürümde ve `useFakeServices` açıkken seçilir.
/// Günlük alımı, makroları veya planı kayıt yokken uydurmaz. Önerilerde plan
/// üreticisi kullanıldığı için diyet tipi, alerjiler ve sevilmeyen yiyecekler
/// korunur. Tıbbi teşhis, ilaç veya tehlikeli derecede düşük kalori hedefi
/// üretmez.
class MockNutritionAssistantService implements NutritionAssistantService {
  const MockNutritionAssistantService(this._generator, {Random? random})
    : _random = random;

  final MealPlanGenerator _generator;
  final Random? _random;

  /// Türkçe İ/ı farkını yok sayan küçük harf.
  static String normalize(String text) =>
      text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();

  static AssistantIntent intentOf(String normalized) {
    bool any(List<String> words) => words.any(normalized.contains);
    if (any(['çok fazla', 'fazla kalori', 'fazla yedim', 'hedefi aştım', 'hedefimi aştım', 'fazla kaçırdım', 'overate', 'too much', 'over my'])) {
      return AssistantIntent.overTarget;
    }
    if (any(['değiştir', 'başka bir şey', 'swap', 'replace', 'change my'])) {
      return AssistantIntent.swapPlan;
    }
    if (any([
      'planımı',
      'planimi',
      'bugünkü plan',
      'bugunku plan',
      "today's plan",
      'review my plan',
      'review today',
    ])) {
      return AssistantIntent.planReview;
    }
    if (any([
      'nasıl beslen',
      'nasil beslen',
      'günlük değerlendirme',
      'gunluk degerlendirme',
      'bugünkü beslenme',
      'bugunku beslenme',
      'how am i eating',
      'review my day',
      'değerlendir',
      'degerlendir',
    ])) {
      return AssistantIntent.dailyReview;
    }
    if (any(['protein'])) return AssistantIntent.protein;
    if (any(['karbonhidrat', 'carb'])) return AssistantIntent.carbs;
    if (any(['yağ', 'yag', ' fat'])) return AssistantIntent.fat;
    if (any(['ne yiyebilirim', 'ne yesem', 'ne yiyeyim', 'öner', 'için ne', 'what can i eat', 'what should i eat', 'suggest'])) {
      return AssistantIntent.mealSuggestion;
    }
    if (any(['kalori', 'kcal', 'hakkım', 'calorie'])) {
      return AssistantIntent.remainingCalories;
    }
    if (any(['oruç', 'fasting', 'fast '])) return AssistantIntent.fasting;
    if (any(['su ', 'su?', 'suyu', 'su içt', 'water'])) {
      return AssistantIntent.water;
    }
    if (any(['kilo', 'ölçü', 'bel ', 'weight'])) return AssistantIntent.weight;
    return AssistantIntent.unknown;
  }

  static MealType? mealTypeIn(String normalized) {
    if (normalized.contains('kahvaltı') || normalized.contains('breakfast')) {
      return MealType.breakfast;
    }
    if (normalized.contains('öğle') || normalized.contains('lunch')) {
      return MealType.lunch;
    }
    if (normalized.contains('akşam') || normalized.contains('dinner')) {
      return MealType.dinner;
    }
    if (normalized.contains('atıştır') ||
        normalized.contains('ara öğün') ||
        normalized.contains('snack')) {
      return MealType.snack;
    }
    return null;
  }

  static const _guides = AssistantGuideEngine();

  @override
  Future<AssistantReply> reply(String question, AssistantContext c) async {
    final q = normalize(question);
    final matched = AssistantCatalog.match(q);
    if (matched != null) {
      if (AssistantSafety.checkUrgent(q) case final concern?) {
        return SafetyReply(concern);
      }
      return _fromCatalog(matched, c);
    }
    if (AssistantSafety.check(q) case final concern?) {
      return SafetyReply(concern);
    }
    return switch (intentOf(q)) {
      AssistantIntent.overTarget => _overTarget(c),
      AssistantIntent.swapPlan => SwapPlanReply(
        meal: c.plannedFor(mealTypeIn(q) ?? c.upcomingMealType),
      ),
      AssistantIntent.planReview => _planReview(c),
      AssistantIntent.dailyReview => _dailyReview(c),
      AssistantIntent.protein => _protein(c),
      AssistantIntent.carbs => _macro(c, TrackedMacro.carbs),
      AssistantIntent.fat => _macro(c, TrackedMacro.fat),
      AssistantIntent.mealSuggestion => _suggest(
        c,
        mealTypeIn(q) ?? c.upcomingMealType,
      ),
      AssistantIntent.remainingCalories => _remaining(c),
      AssistantIntent.water => WaterStatusReply(
        consumedMl: c.todayWaterMl,
        goalMl: c.targets.waterMl,
      ),
      AssistantIntent.weight => WeightProgressReply(
        startKg: c.profile?.effectiveStartWeight,
        currentKg: c.weights.firstOrNull?.weightKg ?? c.profile?.weight,
        targetKg: c.profile?.targetWeight,
        latestWaistCm: c.measurements.reversed
            .map(MeasurementField.waist.valueOf)
            .nonNulls
            .firstOrNull,
      ),
      AssistantIntent.fasting => _fasting(c),
      AssistantIntent.unknown => const HelpReply(),
    };
  }

  AssistantReply _fromCatalog(AssistantQuestion question, AssistantContext c) {
    return switch (question.route) {
      AssistantRoute.daily => _dailyReview(c),
      AssistantRoute.calories => _remaining(c),
      AssistantRoute.protein => _protein(c),
      AssistantRoute.water => WaterStatusReply(
        consumedMl: c.todayWaterMl,
        goalMl: c.targets.waterMl,
      ),
      AssistantRoute.meal => _suggest(
        c,
        question.mealType ?? mealTypeIn(normalize(question.tr)) ?? c.upcomingMealType,
      ),
      AssistantRoute.guide => _guides.reply(question, c),
    };
  }

  bool _hasMeals(AssistantContext c) => c.todayMeals.isNotEmpty;

  bool _macrosRecorded(AssistantContext c) => c.todayMeals.any(
    (meal) =>
        meal.nutrition.proteinG > 0 ||
        meal.nutrition.carbsG > 0 ||
        meal.nutrition.fatG > 0,
  );

  AssistantReply _remaining(AssistantContext c) {
    if (!_hasMeals(c)) return const MissingRecordReply(MissingRecord.meals);
    return RemainingCaloriesReply(
      consumed: c.consumed.calories,
      target: c.targets.calories,
    );
  }

  AssistantReply _overTarget(AssistantContext c) {
    if (!_hasMeals(c)) return const MissingRecordReply(MissingRecord.meals);
    return OverTargetReply(overCalories: -c.remainingCalories);
  }

  AssistantReply _protein(AssistantContext c) {
    if (!_hasMeals(c)) return const MissingRecordReply(MissingRecord.meals);
    if (!_macrosRecorded(c)) {
      return const MissingRecordReply(MissingRecord.macros);
    }
    return ProteinStatusReply(
      consumed: c.consumed.proteinG,
      target: c.targets.proteinG,
    );
  }

  AssistantReply _macro(AssistantContext c, TrackedMacro macro) {
    if (!_hasMeals(c)) return const MissingRecordReply(MissingRecord.meals);
    if (!_macrosRecorded(c)) {
      return const MissingRecordReply(MissingRecord.macros);
    }
    final consumed = macro == TrackedMacro.carbs
        ? c.consumed.carbsG
        : c.consumed.fatG;
    final target = macro == TrackedMacro.carbs
        ? c.targets.carbsG
        : c.targets.fatG;
    return MacroStatusReply(macro: macro, consumed: consumed, target: target);
  }

  AssistantReply _planReview(AssistantContext c) {
    if (c.todayPlan.isEmpty) {
      return const MissingRecordReply(
        MissingRecord.plan,
        actions: [AssistantAction.openPlan],
      );
    }
    return PlanStatusReply(meals: c.todayPlan);
  }

  AssistantReply _dailyReview(AssistantContext c) {
    if (!_hasMeals(c)) return const MissingRecordReply(MissingRecord.meals);
    final macros = _macrosRecorded(c);
    final over = c.consumed.calories > c.targets.calories;
    final proteinShort =
        macros && c.consumed.proteinG < c.targets.proteinG * 0.6 && !over;
    return DailyNutritionReply(
      mealCount: c.todayMeals.length,
      consumedCalories: c.consumed.calories,
      targetCalories: c.targets.calories,
      proteinConsumed: c.consumed.proteinG,
      proteinTarget: c.targets.proteinG,
      carbsConsumed: c.consumed.carbsG,
      carbsTarget: c.targets.carbsG,
      fatConsumed: c.consumed.fatG,
      fatTarget: c.targets.fatG,
      macrosRecorded: macros,
      hint: over
          ? DailyNutritionHint.overCalories
          : proteinShort
          ? DailyNutritionHint.proteinShort
          : DailyNutritionHint.onTrack,
      targetBelowSafeFloor:
          c.targets.calories > 0 &&
          c.targets.calories < AssistantSafety.minSafeDailyKcal,
    );
  }

  MealSuggestionReply _suggest(AssistantContext c, MealType type) {
    final prefs = MealPlanPreferences.fromProfile(c.profile);
    final fromPlan = c.plannedFor(type);
    final remaining = max(c.remainingCalories, 0.0);
    final slotIndex = prefs.slots.indexOf(type);
    final slotTarget = slotIndex < 0
        ? prefs.dailyCalories * 0.15
        : prefs.calorieTargets[slotIndex];
    // Kalan hak az olsa bile öğün atlatılmaz; hafif bir öğün önerilir.
    final target = max(min(slotTarget, remaining), 150.0);
    final stub = PlannedMeal(
      id: 'assistant-${c.now.dayKey}-${type.name}',
      dayKey: c.now.dayKey,
      mealType: type,
      title: '',
      nutrition: NutritionFacts(calories: target),
      templateId: fromPlan?.templateId,
    );
    final alternatives = _generator.alternativesFor(
      stub,
      c.todayPlan,
      prefs,
      count: 2,
      random: _random ?? Random(c.now.day * 31 + type.index),
    );
    return MealSuggestionReply(
      mealType: type,
      remainingCalories: c.remainingCalories,
      fromPlan: fromPlan != null && fromPlan.nutrition.calories > 0
          ? fromPlan
          : null,
      suggestions: [
        for (final meal in alternatives)
          if (meal.nutrition.calories > 0) meal,
      ],
    );
  }

  FastingStatusReply _fasting(AssistantContext c) {
    final schedule = c.fastingSchedule;
    if (schedule == null) return const FastingStatusReply();
    final timer = FastingTimer.compute(
      schedule: schedule,
      now: c.now,
      active: c.activeFast,
    );
    return FastingStatusReply(
      phase: timer.isFasting ? FastingPhase.fasting : FastingPhase.eating,
      remaining: timer.remaining,
    );
  }
}
