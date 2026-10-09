import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../../recipes/data/repositories/recipe_repository_impl.dart';
import '../../data/datasources/meal_template_catalog.dart';
import '../../data/repositories/meal_plan_repository_impl.dart';
import '../../domain/models/meal_plan_preferences.dart';
import '../../domain/models/plan_ingredient.dart';
import '../../domain/models/planned_meal.dart';
import '../../domain/services/meal_plan_generation_service.dart';
import '../../domain/services/meal_plan_generator.dart';
import '../../domain/services/personalized_meal_plan_service.dart';
import '../../domain/services/plan_change_parser.dart';
import '../../domain/usecases/apply_plan_change.dart';
import '../../domain/usecases/log_planned_meal.dart';
import '../../domain/usecases/weekly_meal_planner.dart';

final mealPlanGeneratorProvider = Provider<MealPlanGenerator>(
  (ref) => MealPlanGenerator(MealTemplateCatalog.all),
);

final personalizedMealPlanServiceProvider =
    Provider<PersonalizedMealPlanService>(
      (ref) => const PersonalizedMealPlanService(),
    );

final mealPlanGenerationServiceProvider = Provider<MealPlanGenerationService>(
  (ref) => RecipeMealPlanGenerationService(
    plans: ref.watch(personalizedMealPlanServiceProvider),
    loadRecipes: () => ref.read(recipeRepositoryProvider).getRecipes(),
    profile: () => ref.read(userProfileProvider).value,
    fallback: RuleBasedMealPlanGenerationService(
      ref.watch(mealPlanGeneratorProvider),
    ),
  ),
);

final weeklyMealPlannerProvider = Provider<WeeklyMealPlanner>(
  (ref) => WeeklyMealPlanner(
    plans: ref.watch(mealPlanRepositoryProvider),
    generator: ref.watch(mealPlanGenerationServiceProvider),
  ),
);

final planChangeParserProvider = Provider<PlanChangeParser>(
  (ref) => const PlanChangeParser(),
);

final applyPlanChangeProvider = Provider<ApplyPlanChange>(
  (ref) => ApplyPlanChange(ref.watch(mealPlanGeneratorProvider)),
);

final logPlannedMealProvider = Provider<LogPlannedMeal>(
  (ref) => LogPlannedMeal(
    meals: ref.watch(mealLogRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Bu oturumda söylenen, profile yazılmayan kısıtlar (ör. "vejetaryen
/// olsun") ya da profil henüz yokken söylenen tercihler.
class SessionPlanExclusions extends Notifier<Set<PlanIngredient>> {
  @override
  Set<PlanIngredient> build() => const {};

  void add(Set<PlanIngredient> ingredients) {
    if (ingredients.every(state.contains)) return;
    state = {...state, ...ingredients};
  }
}

final sessionPlanExclusionsProvider =
    NotifierProvider<SessionPlanExclusions, Set<PlanIngredient>>(
      SessionPlanExclusions.new,
    );

final mealPlanPreferencesProvider = Provider<MealPlanPreferences>(
  (ref) => MealPlanPreferences.fromProfile(
    ref.watch(userProfileProvider).value,
  ).withExcluded(ref.watch(sessionPlanExclusionsProvider)),
);

final planDayProvider = Provider<DateTime>(
  (ref) => ref.watch(clockProvider)().startOfDay,
);

/// Plan ekranında seçili gün.
class PlanScreenDay extends Notifier<DateTime> {
  @override
  DateTime build() => ref.watch(clockProvider)().startOfDay;

  void select(DateTime day) => state = day.startOfDay;
}

final planScreenDayProvider = NotifierProvider<PlanScreenDay, DateTime>(
  PlanScreenDay.new,
);

/// Bu haftanın tarif planı. Eksik günler profile göre bir kez üretilir;
/// yenileme ayrıca onay ister.
final weeklyMealPlanProvider = StreamProvider<List<PlannedMeal>>((ref) async* {
  final today = ref.watch(planDayProvider);
  await ref.read(userProfileProvider.future);
  final planner = ref.read(weeklyMealPlannerProvider);
  final prefs = ref.read(mealPlanPreferencesProvider);
  for (final day in WeeklyMealPlanner.weekDays(today)) {
    await planner.ensureDay(day, prefs);
  }
  yield* ref.watch(mealPlanRepositoryProvider).watchWeek(today);
});

/// Günün planı; henüz plan yoksa profile göre üretilip kaydedilir.
final mealPlanForDayProvider =
    StreamProvider.family<List<PlannedMeal>, DateTime>((ref, day) async* {
      final repo = ref.watch(mealPlanRepositoryProvider);
      await ref.read(userProfileProvider.future);
      await ref
          .read(weeklyMealPlannerProvider)
          .ensureDay(day, ref.read(mealPlanPreferencesProvider));
      yield* repo.watchDay(day);
    });

/// Günlüğe kaydı yapılmış öğün tipleri; plan kartlarında "eklendi" durumu.
final loggedMealTypesProvider = StreamProvider.family<Set<MealType>, DateTime>(
  (ref, day) => ref
      .watch(mealLogRepositoryProvider)
      .watchDay(day)
      .map((entries) => {for (final e in entries) e.mealType}),
);

sealed class PlanChatMessage extends Equatable {
  const PlanChatMessage();
}

final class PlanUserMessage extends PlanChatMessage {
  const PlanUserMessage(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class PlanAssistantMessage extends PlanChatMessage {
  const PlanAssistantMessage(this.outcome);

  final PlanChangeOutcome outcome;

  @override
  List<Object?> get props => [outcome];
}

class MealPlanEditorState extends Equatable {
  const MealPlanEditorState({
    this.messages = const [],
    this.highlightedMealIds = const {},
    this.busy = false,
  });

  final List<PlanChatMessage> messages;

  /// Son değişiklikte yenilenen öğünler.
  final Set<String> highlightedMealIds;
  final bool busy;

  MealPlanEditorState copyWith({
    List<PlanChatMessage>? messages,
    Set<String>? highlightedMealIds,
    bool? busy,
  }) => MealPlanEditorState(
    messages: messages ?? this.messages,
    highlightedMealIds: highlightedMealIds ?? this.highlightedMealIds,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [messages, highlightedMealIds, busy];
}

/// "Bu planı değiştir" etkileşimleri: serbest metin istekleri, tek öğün
/// değiştirme ve planı yenileme.
class MealPlanEditor extends Notifier<MealPlanEditorState> {
  @override
  MealPlanEditorState build() => const MealPlanEditorState();

  DateTime get _day => ref.read(planDayProvider);

  /// [labelOf], profile "sevmediklerim" olarak yazılacak yerelleştirilmiş
  /// bileşen adını verir.
  Future<Result<PlanChangeOutcome>?> submit(
    String text, {
    required String Function(PlanIngredient) labelOf,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.busy) return null;
    state = state.copyWith(
      messages: [...state.messages, PlanUserMessage(trimmed)],
      busy: true,
    );
    final request = ref.read(planChangeParserProvider).parse(trimmed);
    return _run(
      (plan, prefs) => ref.read(applyPlanChangeProvider)(
        day: _day,
        plan: plan,
        request: request,
        prefs: prefs,
      ),
      labelOf: labelOf,
      reply: true,
    );
  }

  Future<Result<PlanChangeOutcome>?> swap(PlannedMeal meal) {
    if (state.busy) return Future.value();
    state = state.copyWith(busy: true);
    return _run(
      (plan, prefs) => ref
          .read(applyPlanChangeProvider)
          .swapMeal(plan: plan, meal: meal, prefs: prefs),
    );
  }

  Future<Result<PlanChangeOutcome>?> regenerate() {
    if (state.busy) return Future.value();
    state = state.copyWith(busy: true);
    return _run(
      (plan, prefs) => ref.read(applyPlanChangeProvider)(
        day: _day,
        plan: plan,
        request: const PlanChangeRequest(regenerateAll: true),
        prefs: prefs,
      ),
    );
  }

  Future<Result<PlanChangeOutcome>> _run(
    PlanChangeOutcome Function(List<PlannedMeal>, MealPlanPreferences) apply, {
    String Function(PlanIngredient)? labelOf,
    bool reply = false,
  }) async {
    final day = _day;
    final plan = await ref.read(mealPlanForDayProvider(day).future);
    final outcome = apply(plan, ref.read(mealPlanPreferencesProvider));

    if (outcome.changed) {
      final saved = await ref
          .read(mealPlanRepositoryProvider)
          .saveDay(day, outcome.plan);
      if (saved case Err(:final failure)) {
        state = state.copyWith(busy: false);
        return Result.failure(failure);
      }
    }
    if (outcome.remember && labelOf != null) {
      await _remember(outcome.request, labelOf);
    }
    state = state.copyWith(
      messages: reply
          ? [...state.messages, PlanAssistantMessage(outcome)]
          : state.messages,
      highlightedMealIds: {for (final c in outcome.changes) c.after.id},
      busy: false,
    );
    return Result.success(outcome);
  }

  /// Genel tercihler sonraki planlarda da uygulanır: sevilmeyen
  /// bileşenler profile, diyet değişikliği oturuma yazılır.
  Future<void> _remember(
    PlanChangeRequest request,
    String Function(PlanIngredient) labelOf,
  ) async {
    final diet = request.diet;
    ref.read(sessionPlanExclusionsProvider.notifier).add({
      ...request.excluded,
      if (diet != null) ...PlanIngredient.excludedByDiet(diet),
    });
    if (request.excluded.isEmpty) return;

    final profiles = ref.read(userProfileRepositoryProvider);
    final profile = (await profiles.getProfile()).valueOrNull;
    if (profile == null) return;
    final known = MealPlanPreferences.fromProfile(profile).excluded;
    final labels = [
      for (final i in request.excluded)
        if (!known.contains(i)) labelOf(i),
    ];
    if (labels.isEmpty) return;
    await profiles.saveProfile(
      profile.copyWith(dislikedFoods: [...profile.dislikedFoods, ...labels]),
    );
  }
}

final mealPlanEditorProvider =
    NotifierProvider<MealPlanEditor, MealPlanEditorState>(MealPlanEditor.new);
