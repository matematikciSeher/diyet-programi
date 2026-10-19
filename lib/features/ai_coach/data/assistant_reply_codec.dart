import '../../../shared/models/enums.dart';
import '../../fasting/domain/models/fasting_schedule.dart';
import '../../meal_plans/domain/models/planned_meal.dart';
import '../domain/models/assistant_grounded_facts.dart';
import '../domain/models/assistant_reply.dart';
import '../domain/models/guide_snapshot.dart';

/// Sohbet kaydını yerel belgeye çevirir. Sağlayıcı sırrı veya ham istek gövdesi yok.
abstract final class AssistantReplyCodec {
  static Map<String, dynamic> encode(AssistantReply reply) => switch (reply) {
    RemainingCaloriesReply(:final consumed, :final target) => {
      'type': 'remaining_calories',
      'consumed': consumed,
      'target': target,
    },
    ProteinStatusReply(:final consumed, :final target) => {
      'type': 'protein',
      'consumed': consumed,
      'target': target,
    },
    MealSuggestionReply(
      :final mealType,
      :final remainingCalories,
      :final fromPlan,
      :final suggestions,
    ) =>
      {
        'type': 'meal_suggestion',
        'mealType': mealType.name,
        'remainingCalories': remainingCalories,
        'fromPlan': fromPlan?.toJson(),
        'suggestions': [for (final meal in suggestions) meal.toJson()],
      },
    SwapPlanReply(:final meal) => {
      'type': 'swap',
      'meal': meal?.toJson(),
    },
    OverTargetReply(:final overCalories) => {
      'type': 'over_target',
      'overCalories': overCalories,
    },
    WaterStatusReply(:final consumedMl, :final goalMl) => {
      'type': 'water',
      'consumedMl': consumedMl,
      'goalMl': goalMl,
    },
    WeightProgressReply(
      :final startKg,
      :final currentKg,
      :final targetKg,
      :final latestWaistCm,
    ) =>
      {
        'type': 'weight',
        'startKg': startKg,
        'currentKg': currentKg,
        'targetKg': targetKg,
        'latestWaistCm': latestWaistCm,
      },
    FastingStatusReply(:final phase, :final remaining) => {
      'type': 'fasting',
      'phase': phase?.name,
      'remainingSeconds': remaining?.inSeconds,
    },
    SafetyReply(:final concern) => {
      'type': 'safety',
      'concern': concern.name,
    },
    HelpReply() => {'type': 'help'},
    ClarificationReply(:final choices) => {
      'type': 'clarify',
      'choices': [
        for (final choice in choices)
          {
            'questionId': choice.questionId,
            'labelTr': choice.labelTr,
            'labelEn': choice.labelEn,
            'promptTr': choice.promptTr,
            'promptEn': choice.promptEn,
          },
      ],
    },
    DetailRequestReply() => {'type': 'detail'},
    MacroStatusReply(:final macro, :final consumed, :final target) => {
      'type': 'macro',
      'macro': macro.name,
      'consumed': consumed,
      'target': target,
    },
    DailyNutritionReply(
      :final mealCount,
      :final consumedCalories,
      :final targetCalories,
      :final proteinConsumed,
      :final proteinTarget,
      :final carbsConsumed,
      :final carbsTarget,
      :final fatConsumed,
      :final fatTarget,
      :final macrosRecorded,
      :final hint,
      :final targetBelowSafeFloor,
    ) =>
      {
        'type': 'daily',
        'mealCount': mealCount,
        'consumedCalories': consumedCalories,
        'targetCalories': targetCalories,
        'proteinConsumed': proteinConsumed,
        'proteinTarget': proteinTarget,
        'carbsConsumed': carbsConsumed,
        'carbsTarget': carbsTarget,
        'fatConsumed': fatConsumed,
        'fatTarget': fatTarget,
        'macrosRecorded': macrosRecorded,
        'hint': hint.name,
        'targetBelowSafeFloor': targetBelowSafeFloor,
      },
    MissingRecordReply(:final record) => {
      'type': 'missing',
      'record': record.name,
    },
    PlanStatusReply(:final meals) => {
      'type': 'plan',
      'meals': [for (final meal in meals) meal.toJson()],
    },
    UnavailableAssistantReply(:final code) => {
      'type': 'unavailable',
      'code': code,
    },
    AssistantFailureReply(:final code, :final question) => {
      'type': 'failure',
      'code': code,
      'question': question,
    },
    InterpretedReply(
      :final facts,
      :final recipes,
      :final commentary,
      :final commentarySuppressed,
      :final actions,
    ) =>
      {
        'type': 'interpreted',
        'facts': facts.toJson(),
        'recipes': [for (final recipe in recipes) recipe.toJson()],
        'commentary': commentary,
        'commentarySuppressed': commentarySuppressed,
        'actions': [for (final action in actions) action.name],
      },
    GuideReply(
      :final questionId,
      :final snapshot,
      :final recipes,
      :final disclaimer,
      :final actions,
    ) =>
      {
        'type': 'guide',
        'questionId': questionId,
        'snapshot': snapshot.toJson(),
        'recipes': [for (final recipe in recipes) recipe.toJson()],
        'disclaimer': disclaimer,
        'actions': [for (final action in actions) action.name],
      },
  };

  static AssistantReply? decode(Map<String, dynamic> json) {
    final type = json['type'];
    if (type is! String) return null;
    double? d(Object? value) => value is num ? value.toDouble() : null;
    int i(Object? value, [int fallback = 0]) =>
        value is num ? value.toInt() : fallback;
    PlannedMeal? meal(Object? value) =>
        value is Map ? PlannedMeal.fromJson(Map<String, dynamic>.from(value)) : null;
    return switch (type) {
      'remaining_calories' => RemainingCaloriesReply(
        consumed: d(json['consumed']) ?? 0,
        target: d(json['target']) ?? 0,
      ),
      'protein' => ProteinStatusReply(
        consumed: d(json['consumed']) ?? 0,
        target: d(json['target']) ?? 0,
      ),
      'meal_suggestion' => MealSuggestionReply(
        mealType: _mealType(json['mealType']),
        remainingCalories: d(json['remainingCalories']) ?? 0,
        fromPlan: meal(json['fromPlan']),
        suggestions: [
          for (final item in json['suggestions'] is List ? json['suggestions'] as List : const [])
            if (item is Map) PlannedMeal.fromJson(Map<String, dynamic>.from(item)),
        ],
      ),
      'swap' => SwapPlanReply(meal: meal(json['meal'])),
      'over_target' => OverTargetReply(overCalories: d(json['overCalories']) ?? 0),
      'water' => WaterStatusReply(
        consumedMl: i(json['consumedMl']),
        goalMl: i(json['goalMl']),
      ),
      'weight' => WeightProgressReply(
        startKg: d(json['startKg']),
        currentKg: d(json['currentKg']),
        targetKg: d(json['targetKg']),
        latestWaistCm: d(json['latestWaistCm']),
      ),
      'fasting' => FastingStatusReply(
        phase: json['phase'] == null
            ? null
            : FastingPhase.values.where((phase) => phase.name == json['phase']).firstOrNull,
        remaining: json['remainingSeconds'] is num
            ? Duration(seconds: (json['remainingSeconds'] as num).toInt())
            : null,
      ),
      'safety' => SafetyReply(
        SafetyConcern.values.where((item) => item.name == json['concern']).firstOrNull ??
            SafetyConcern.medical,
      ),
      'help' => const HelpReply(),
      'clarify' => ClarificationReply(
        choices: [
          for (final item in json['choices'] is List ? json['choices'] as List : const [])
            if (item is Map)
              ClarificationChoice(
                questionId: item['questionId'] as String?,
                labelTr: item['labelTr'] as String? ?? '',
                labelEn: item['labelEn'] as String? ?? '',
                promptTr: item['promptTr'] as String? ?? '',
                promptEn: item['promptEn'] as String? ?? '',
              ),
        ],
      ),
      'detail' => const DetailRequestReply(),
      'macro' => MacroStatusReply(
        macro: TrackedMacro.values
                .where((item) => item.name == json['macro'])
                .firstOrNull ??
            TrackedMacro.carbs,
        consumed: d(json['consumed']) ?? 0,
        target: d(json['target']) ?? 0,
      ),
      'daily' => DailyNutritionReply(
        mealCount: i(json['mealCount']),
        consumedCalories: d(json['consumedCalories']) ?? 0,
        targetCalories: d(json['targetCalories']) ?? 0,
        proteinConsumed: d(json['proteinConsumed']) ?? 0,
        proteinTarget: d(json['proteinTarget']) ?? 0,
        carbsConsumed: d(json['carbsConsumed']) ?? 0,
        carbsTarget: d(json['carbsTarget']) ?? 0,
        fatConsumed: d(json['fatConsumed']) ?? 0,
        fatTarget: d(json['fatTarget']) ?? 0,
        macrosRecorded: json['macrosRecorded'] == true,
        hint: DailyNutritionHint.values
                .where((item) => item.name == json['hint'])
                .firstOrNull ??
            DailyNutritionHint.onTrack,
        targetBelowSafeFloor: json['targetBelowSafeFloor'] == true,
      ),
      'missing' => MissingRecordReply(
        MissingRecord.values
                .where((item) => item.name == json['record'])
                .firstOrNull ??
            MissingRecord.meals,
        actions: json['record'] == MissingRecord.plan.name
            ? const [AssistantAction.openPlan]
            : const [AssistantAction.openDiary],
      ),
      'plan' => PlanStatusReply(
        meals: [
          for (final item in json['meals'] is List ? json['meals'] as List : const [])
            if (item is Map) PlannedMeal.fromJson(Map<String, dynamic>.from(item)),
        ],
      ),
      'unavailable' => UnavailableAssistantReply(
        code: json['code'] as String? ?? AssistantErrorCodes.notConfigured,
      ),
      'failure' => AssistantFailureReply(
        code: json['code'] as String? ?? AssistantErrorCodes.unavailable,
        question: json['question'] as String? ?? '',
      ),
      'interpreted' => InterpretedReply(
        facts: json['facts'] is Map
            ? AssistantGroundedFacts.fromJson(Map<String, dynamic>.from(json['facts'] as Map))
            : const AssistantGroundedFacts(),
        recipes: [
          for (final item in json['recipes'] is List ? json['recipes'] as List : const [])
            if (item is Map)
              AssistantRecipeRef.fromJson(Map<String, dynamic>.from(item)),
        ],
        commentary: json['commentary'] as String?,
        commentarySuppressed: json['commentarySuppressed'] == true,
        actions: [
          for (final name in json['actions'] is List ? json['actions'] as List : const [])
            if (name is String)
              ?AssistantAction.values.where((action) => action.name == name).firstOrNull,
        ],
      ),
      'guide' => GuideReply(
        questionId: json['questionId'] as String? ?? '',
        snapshot: json['snapshot'] is Map
            ? GuideSnapshot.fromJson(Map<String, dynamic>.from(json['snapshot'] as Map))
            : const GuideSnapshot(),
        recipes: [
          for (final item in json['recipes'] is List ? json['recipes'] as List : const [])
            if (item is Map)
              AssistantRecipeRef.fromJson(Map<String, dynamic>.from(item)),
        ],
        disclaimer: json['disclaimer'] == true,
        actions: [
          for (final name in json['actions'] is List ? json['actions'] as List : const [])
            if (name is String)
              ?AssistantAction.values.where((action) => action.name == name).firstOrNull,
        ],
      ),
      _ => null,
    };
  }

  static MealType _mealType(Object? name) {
    for (final type in MealType.values) {
      if (type.name == name) return type;
    }
    return MealType.dinner;
  }
}
