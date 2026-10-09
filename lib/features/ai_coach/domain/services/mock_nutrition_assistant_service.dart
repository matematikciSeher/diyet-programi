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
import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';
import 'assistant_safety.dart';
import 'nutrition_assistant_service.dart';

enum AssistantIntent {
  overTarget,
  swapPlan,
  protein,
  mealSuggestion,
  remainingCalories,
  water,
  weight,
  fasting,
  unknown,
}

/// Yalnızca test ve debug (`useFakeServices`) için kural tabanlı asistan.
/// Release derlemesinde seçilmez ve sahte övgü yanıtı üretmez.
/// Önerilerde plan üreticisi kullanıldığı için diyet tipi, alerjiler ve
/// sevilmeyen yiyecekler korunur.
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
    if (any(['protein'])) return AssistantIntent.protein;
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

  @override
  Future<AssistantReply> reply(String question, AssistantContext c) async {
    final q = normalize(question);
    if (AssistantSafety.check(q) case final concern?) {
      return SafetyReply(concern);
    }
    return switch (intentOf(q)) {
      AssistantIntent.overTarget => OverTargetReply(
        overCalories: -c.remainingCalories,
      ),
      AssistantIntent.swapPlan => SwapPlanReply(
        meal: c.plannedFor(mealTypeIn(q) ?? c.upcomingMealType),
      ),
      AssistantIntent.protein => ProteinStatusReply(
        consumed: c.consumed.proteinG,
        target: c.targets.proteinG,
      ),
      AssistantIntent.mealSuggestion => _suggest(
        c,
        mealTypeIn(q) ?? c.upcomingMealType,
      ),
      AssistantIntent.remainingCalories => RemainingCaloriesReply(
        consumed: c.consumed.calories,
        target: c.targets.calories,
      ),
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
    return MealSuggestionReply(
      mealType: type,
      remainingCalories: c.remainingCalories,
      fromPlan: fromPlan,
      suggestions: _generator.alternativesFor(
        stub,
        c.todayPlan,
        prefs,
        count: 2,
        random: _random ?? Random(c.now.day * 31 + type.index),
      ),
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
