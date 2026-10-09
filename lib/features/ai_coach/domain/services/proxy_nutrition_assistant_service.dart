import 'dart:convert';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/services/ai/ai_nutrition_service.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../fasting/domain/services/fasting_timer.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../progress/domain/models/progress_report.dart';
import '../../../recipes/domain/services/recipe_recommendation_service.dart';
import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';
import 'assistant_context_builder.dart';
import 'assistant_limits.dart';
import 'assistant_response_guard.dart';
import 'assistant_response_parser.dart';
import 'assistant_safety.dart';
import 'assistant_text.dart';
import 'nutrition_assistant_service.dart';

/// Kayıtları uygulamada hesaplar, yorumu [AiNutritionService] üzerinden ister.
///
/// Günlük, plan, su ve kalori hedefini yazmaz. Tarif kimliği katalogda yoksa
/// veya profile uymuyorsa gösterilmez.
class ProxyNutritionAssistantService implements NutritionAssistantService {
  ProxyNutritionAssistantService({
    required AiNutritionService ai,
    required this.loadRecipes,
    required this.loadWeek,
    required AssistantLimits limits,
    AssistantContextBuilder? builder,
    AssistantResponseGuard? guard,
    RecipeRecommendationService? recommender,
    AssistantRateLimiter? limiter,
  }) : _ai = ai,
       _limits = limits,
       _builder = builder ?? AssistantContextBuilder(maxInputChars: limits.maxInputChars),
       _guard = guard ?? const AssistantResponseGuard(),
       _recommender = recommender ?? const RecipeRecommendationService(),
       _limiter = limiter ?? AssistantRateLimiter(maxPerMinute: limits.maxRequestsPerMinute);

  final AiNutritionService _ai;
  final AssistantLimits _limits;
  final AssistantContextBuilder _builder;
  final AssistantResponseGuard _guard;
  final RecipeRecommendationService _recommender;
  final AssistantRateLimiter _limiter;
  final Future<List<Recipe>> Function(UserProfile? profile) loadRecipes;
  final Future<List<PlannedMeal>> Function(DateTime day) loadWeek;

  bool _inFlight = false;

  static const _systemPrompt = '''
Sen bir beslenme asistanısın. Yalnızca kullanıcı mesajındaki JSON bağlamını kullan.
Sayı uydurma. Kayıtta olmayan kalori, protein, su, adım, yiyecek, tarif, plan, alerji veya hedef söyleme.
Bilgi yoksa "Bu bilgiye erişemiyorum." de.
Günlüğü, planı, suyu veya kalori hedefini değiştirme; yalnızca öner.
Tarif için yalnızca recipeCandidates içindeki id değerlerini kullan. Yeni id üretme.
Alerji, sevilmeyen yiyecek ve diyet tipine uymayan yiyecek önerme.
"Alerjin olsa da az miktarda tüket" gibi ifadeler kullanma.
Tanı koyma, ilaç önerme veya ilaç bıraktırma.
Ciddi bir sağlık sorusunda doktora yönlendir. Sıradan beslenme sorularında her cevabı doktora bağlama.
Yanıtın tamamı şu JSON olsun:
{"text":"...","actions":[{"type":"open_plan"}]}
İzinli type değerleri: recommend_recipe, open_plan, open_diary, open_recipes, open_weight, open_fasting.
recommend_recipe kullanırsan recipeId zorunludur ve listede olmalıdır.
''';

  @override
  Future<AssistantReply> reply(String question, AssistantContext context) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return const AssistantFailureReply(code: AssistantErrorCodes.emptyMessage);
    }
    if (_inFlight) {
      return AssistantFailureReply(
        code: AssistantErrorCodes.duplicate,
        question: trimmed,
      );
    }
    _inFlight = true;
    try {
      return await _reply(trimmed, context);
    } finally {
      _inFlight = false;
    }
  }

  Future<AssistantReply> _reply(String question, AssistantContext context) async {
    if (question.length > _limits.maxMessageChars) {
      return AssistantFailureReply(
        code: AssistantErrorCodes.messageTooLong,
        question: question,
      );
    }
    final concern = AssistantSafety.check(AssistantText.normalize(question));
    if (concern != null) return SafetyReply(concern);

    final scope = AssistantText.scopeOf(question);
    final local = _localReply(scope, question, context);
    if (local != null) return local;

    if (!_limiter.tryAcquire()) {
      return AssistantFailureReply(
        code: AssistantErrorCodes.rateLimited,
        question: question,
      );
    }

    final recipes = await _candidates(scope, question, context);
    final week = scope == AssistantQuestionScope.weekPlan
        ? await _safeWeek(context.now)
        : const <PlannedMeal>[];
    final pack = _builder.build(
      question: question,
      context: context,
      recipes: recipes,
      weekPlan: week,
    );
    try {
      final raw = await _complete(_messages(pack.payload));
      final parsed = AssistantResponseParser.parse(raw);
      final guarded = _guard.apply(
        parsed: parsed,
        facts: pack.facts,
        allowedRecipes: recipes,
        profile: context.profile,
      );
      final noCommentary =
          guarded.commentary == null || guarded.commentary!.isEmpty;
      if (noCommentary &&
          guarded.recipes.isEmpty &&
          !guarded.commentarySuppressed &&
          !guarded.facts.hasVisibleRecord) {
        return AssistantFailureReply(
          code: AssistantErrorCodes.emptyResponse,
          question: question,
        );
      }
      return guarded;
    } on AssistantParseException catch (error) {
      return AssistantFailureReply(
        code: AssistantResponseParser.failureCode(error.problem),
        question: question,
      );
    } on ServiceUnavailableException catch (error) {
      if (error.code == AssistantErrorCodes.notConfigured) {
        return const UnavailableAssistantReply();
      }
      return AssistantFailureReply(
        code: error.code ?? AssistantErrorCodes.unavailable,
        question: question,
      );
    } on NetworkException catch (error) {
      return AssistantFailureReply(
        code: error.code ?? AssistantErrorCodes.offline,
        question: question,
      );
    } on ServerException {
      return AssistantFailureReply(
        code: AssistantErrorCodes.unavailable,
        question: question,
      );
    } on Object {
      return AssistantFailureReply(
        code: AssistantErrorCodes.unavailable,
        question: question,
      );
    }
  }

  AssistantReply? _localReply(
    AssistantQuestionScope scope,
    String question,
    AssistantContext context,
  ) {
    return switch (scope) {
      AssistantQuestionScope.swap => SwapPlanReply(
        meal: context.plannedFor(
          AssistantText.mealTypeIn(question) ?? context.upcomingMealType,
        ),
      ),
      AssistantQuestionScope.overTarget => OverTargetReply(
        overCalories: -context.remainingCalories,
      ),
      AssistantQuestionScope.weight => WeightProgressReply(
        startKg: context.profile?.effectiveStartWeight,
        currentKg:
            context.weights.firstOrNull?.weightKg ?? context.profile?.weight,
        targetKg: context.profile?.targetWeight,
        latestWaistCm: context.measurements.reversed
            .map(MeasurementField.waist.valueOf)
            .nonNulls
            .firstOrNull,
      ),
      AssistantQuestionScope.fasting => _fasting(context),
      _ => null,
    };
  }

  FastingStatusReply _fasting(AssistantContext context) {
    final schedule = context.fastingSchedule;
    if (schedule == null) return const FastingStatusReply();
    final timer = FastingTimer.compute(
      schedule: schedule,
      now: context.now,
      active: context.activeFast,
    );
    return FastingStatusReply(
      phase: timer.isFasting ? FastingPhase.fasting : FastingPhase.eating,
      remaining: timer.remaining,
    );
  }

  Future<List<Recipe>> _candidates(
    AssistantQuestionScope scope,
    String question,
    AssistantContext context,
  ) async {
    final needsRecipes =
        scope == AssistantQuestionScope.meal ||
        scope == AssistantQuestionScope.recipe ||
        scope == AssistantQuestionScope.protein;
    if (!needsRecipes) return const [];
    final List<Recipe> raw;
    try {
      raw = await loadRecipes(context.profile);
    } on Object {
      return const [];
    }
    final profile = context.profile;
    final suitable = [
      for (final recipe in raw)
        if (profile == null || _recommender.isSuitable(recipe, profile))
          recipe,
    ];
    final type = AssistantText.mealTypeIn(question);
    final typed = type == null
        ? suitable
        : suitable
              .where(
                (recipe) =>
                    recipe.mealTypes.contains(type) ||
                    recipe.tags.contains(type.name),
              )
              .toList();
    final pool = typed.isEmpty ? suitable : typed;
    final normalized = AssistantText.normalize(question);
    final ranked = [...pool];
    if (normalized.contains('protein')) {
      ranked.sort((a, b) => b.protein.compareTo(a.protein));
    } else if (normalized.contains('düşük kalori') ||
        normalized.contains('dusuk kalori')) {
      ranked.sort((a, b) => a.calories.compareTo(b.calories));
    }
    if (scope == AssistantQuestionScope.recipe &&
        (normalized.contains('malzeme') || normalized.contains('evde'))) {
      final matched = _matchingIngredients(ranked, normalized);
      return matched.take(6).toList();
    }
    return ranked.take(6).toList();
  }

  List<Recipe> _matchingIngredients(List<Recipe> recipes, String normalized) {
    final tokens = normalized
        .split(RegExp(r'[^a-z0-9çğıöşü]+'))
        .where((token) => token.length > 3)
        .toSet();
    if (tokens.isEmpty) return recipes;
    return [
      for (final recipe in recipes)
        if (recipe.ingredients.any((ingredient) {
          final name = AssistantText.normalize(ingredient.name);
          return tokens.any(name.contains);
        }))
          recipe,
    ];
  }

  Future<List<PlannedMeal>> _safeWeek(DateTime day) async {
    try {
      return await loadWeek(day);
    } on Object {
      return const [];
    }
  }

  List<AiChatMessage> _messages(Map<String, Object?> payload) => [
    const AiChatMessage(role: AiChatRole.system, content: _systemPrompt),
    AiChatMessage(
      role: AiChatRole.user,
      content: jsonEncode(payload),
    ),
  ];

  Future<String> _complete(List<AiChatMessage> messages) async {
    var attempt = 0;
    while (true) {
      try {
        final buffer = StringBuffer();
        await for (final chunk in _ai.chat(messages)) {
          buffer.write(chunk);
          if (buffer.length > 8000) break;
        }
        return buffer.toString();
      } on NetworkException catch (error) {
        final retryable =
            error.code == AssistantErrorCodes.timeout ||
            error.code == AssistantErrorCodes.offline;
        if (!retryable || attempt >= _limits.maxRetries) rethrow;
        attempt++;
      }
    }
  }
}
