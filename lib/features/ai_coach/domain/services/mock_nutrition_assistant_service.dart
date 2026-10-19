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
import 'assistant_intent.dart';
import 'assistant_phrasing.dart';
import 'assistant_safety.dart';
import 'assistant_utterance_matcher.dart';
import 'nutrition_assistant_service.dart';

export 'assistant_intent.dart';

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
    if (AssistantPhrasing.has(normalized, 'yag') || any([' fat'])) {
      return AssistantIntent.fat;
    }
    if (any(['ne yiyebilirim', 'ne yesem', 'ne yiyeyim', 'öner', 'için ne', 'what can i eat', 'what should i eat', 'suggest'])) {
      return AssistantIntent.mealSuggestion;
    }
    if (AssistantPhrasing.has(normalized, 'kalori') ||
        any(['kcal', 'hakkım', 'calorie'])) {
      return AssistantIntent.remainingCalories;
    }
    if (any(['oruç', 'fasting', 'fast '])) return AssistantIntent.fasting;
    if (AssistantPhrasing.has(normalized, 'su') || any(['water'])) {
      return AssistantIntent.water;
    }
    if (AssistantPhrasing.has(normalized, 'kilo') ||
        any(['ölçü', 'bel ', 'weight'])) {
      return AssistantIntent.weight;
    }
    return AssistantIntent.unknown;
  }

  static MealType? mealTypeIn(String normalized) {
    if (AssistantPhrasing.has(normalized, 'kahvalti') ||
        normalized.contains('breakfast')) {
      return MealType.breakfast;
    }
    if (AssistantPhrasing.has(normalized, 'ogle') ||
        normalized.contains('lunch')) {
      return MealType.lunch;
    }
    if (AssistantPhrasing.has(normalized, 'aksam') ||
        normalized.contains('dinner')) {
      return MealType.dinner;
    }
    if (AssistantPhrasing.has(normalized, 'atistir') ||
        AssistantPhrasing.has(normalized, 'ara ogun') ||
        normalized.contains('snack')) {
      return MealType.snack;
    }
    return null;
  }

  static const _guides = AssistantGuideEngine();

  @override
  Future<AssistantReply> reply(String question, AssistantContext c) async {
    final q = normalize(question);
    if (AssistantSafety.checkUrgent(q) case final concern?) {
      return SafetyReply(concern);
    }

    final pinned = c.pinnedQuestionId == null
        ? null
        : AssistantCatalog.questionById(c.pinnedQuestionId!);
    if (pinned != null) return _fromCatalog(pinned, c);

    final exact = AssistantCatalog.exactMatches(question);
    if (exact.isNotEmpty) {
      final ids = AssistantUtteranceMatcher.preferCategory(
        AssistantUtteranceMatcher.narrow(
          [for (final item in exact) item.id],
          c.priorUserQuestion,
        ),
        c.categoryId,
      );
      if (ids.length == 1) {
        final selected = AssistantCatalog.questionById(ids.first);
        if (selected != null) return _fromCatalog(selected, c);
      }
      return _clarify(ids.isEmpty ? [for (final item in exact) item.id] : ids, c);
    }

    if (AssistantSafety.check(q) case final concern?) {
      return SafetyReply(concern);
    }

    switch (AssistantUtteranceMatcher.resolve(
      question,
      prior: c.priorUserQuestion,
      categoryId: c.categoryId,
    )) {
      case UtteranceQuestion(:final id):
        final selected = AssistantCatalog.questionById(id);
        if (selected != null) return _fromCatalog(selected, c);
      case UtteranceIntent(:final intent):
        return _byIntent(intent, q, c);
      case UtteranceAmbiguous(:final questionIds):
        return _clarify(questionIds, c);
      case UtteranceUnclear():
        return const DetailRequestReply();
      case UtteranceNone():
        break;
    }

    final near = AssistantCatalog.closest(
      question,
      categoryId: c.categoryId,
    );
    if (near.length == 1) return _fromCatalog(near.single, c);
    if (near.length > 1) {
      return _clarify([for (final item in near) item.id], c);
    }

    final contained = AssistantCatalog.matchContained(question);
    if (contained != null) return _fromCatalog(contained, c);
    return _byIntent(intentOf(q), q, c);
  }

  AssistantReply _byIntent(AssistantIntent intent, String q, AssistantContext c) {
    return switch (intent) {
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

  AssistantReply _clarify(List<String> ids, AssistantContext c) {
    final choices = <ClarificationChoice>[];
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) continue;
      final question = AssistantCatalog.questionById(id);
      if (question == null) continue;
      final category = AssistantCatalog.categoryOf(id);
      choices.add(
        ClarificationChoice(
          questionId: question.id,
          labelTr: category?.titleTr ?? question.tr,
          labelEn: category?.titleEn ?? question.en,
          promptTr: question.tr,
          promptEn: question.en,
        ),
      );
      if (choices.length == 3) break;
    }
    if (choices.length == 1) {
      final selected = AssistantCatalog.questionById(choices.first.questionId!);
      if (selected != null) return _fromCatalog(selected, c);
    }
    if (choices.length < 2) return const HelpReply();
    return ClarificationReply(choices: choices);
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

  List<PlannedMeal> _plannedToday(AssistantContext c) {
    if (c.todayPlan.isNotEmpty) return c.todayPlan;
    final key = c.now.dayKey;
    return [
      for (final meal in c.weekPlan)
        if (meal.dayKey == key) meal,
    ];
  }

  AssistantReply _planReview(AssistantContext c) {
    final meals = _plannedToday(c);
    if (meals.isEmpty) {
      return const MissingRecordReply(
        MissingRecord.plan,
        actions: [AssistantAction.openPlan],
      );
    }
    return PlanStatusReply(meals: meals);
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
