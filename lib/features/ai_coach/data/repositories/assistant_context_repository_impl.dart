import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../activity/data/repositories/activity_repository_impl.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../activity/domain/repositories/activity_repository.dart';
import '../../../fasting/data/repositories/fasting_repository_impl.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../fasting/domain/repositories/fasting_repository.dart';
import '../../../meal_plans/data/repositories/meal_plan_repository_impl.dart';
import '../../../meal_plans/domain/repositories/meal_plan_repository.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../../meals/domain/repositories/meal_log_repository.dart';
import '../../../progress/data/repositories/body_progress_repository_impl.dart';
import '../../../progress/domain/repositories/body_progress_repository.dart';
import '../../../recipes/data/repositories/recipe_repository_impl.dart';
import '../../../recipes/domain/repositories/recipe_repository.dart';
import '../../../recipes/domain/services/recipe_recommendation_service.dart';
import '../../../shopping/data/repositories/shopping_list_repository_impl.dart';
import '../../../shopping/domain/repositories/shopping_list_repository.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../domain/models/assistant_context.dart';
import '../../domain/services/assistant_calendar.dart';
import '../../domain/services/nutrition_assistant_service.dart';

/// Profil, günlük (öğün + su), kilo/ölçüm, plan ve oruç verisini
/// repository'lerden okuyup asistan için birleştirir.
final class RepositoryAssistantContextRepository
    implements AssistantContextRepository {
  const RepositoryAssistantContextRepository({
    required UserProfileRepository profiles,
    required MealLogRepository meals,
    required WaterRepository water,
    required BodyProgressRepository body,
    required MealPlanRepository plans,
    required FastingRepository fasting,
    required DateTime Function() clock,
    ActivityRepository? activity,
    RecipeRepository? recipes,
    ShoppingListRepository? shopping,
  }) : _profiles = profiles,
       _meals = meals,
       _water = water,
       _body = body,
       _plans = plans,
       _fasting = fasting,
       _clock = clock,
       _activity = activity,
       _recipes = recipes,
       _shopping = shopping;

  final UserProfileRepository _profiles;
  final MealLogRepository _meals;
  final WaterRepository _water;
  final BodyProgressRepository _body;
  final MealPlanRepository _plans;
  final FastingRepository _fasting;
  final DateTime Function() _clock;
  final ActivityRepository? _activity;
  final RecipeRepository? _recipes;
  final ShoppingListRepository? _shopping;

  /// [Stream.first] dinleyiciyi kurmadan önce gelen senkron olayı kaçırır.
  Future<T> _firstEvent<T>(Stream<T> stream) {
    final completer = Completer<T>();
    late final StreamSubscription<T> subscription;
    subscription = stream.listen(
      (value) {
        if (completer.isCompleted) return;
        completer.complete(value);
        unawaited(subscription.cancel());
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    return completer.future;
  }

  @override
  Future<AssistantContext> snapshot() async {
    final now = _clock();
    final today = now.startOfDay;
    final profile = (await _profiles.getProfile()).valueOrNull;
    final activity = await _readActivity(today);
    final weekStart = AssistantCalendar.mondayOf(today);
    final (meals, water, body, plan, sessions, weekMeals, weekWater, weekPlan) =
        await (
          _meals.watchDay(today).first,
          _water.watchDay(today).first,
          _firstEvent(_body.watch()),
          _plans.watchDay(today).first,
          _fasting.watchSessions().first,
          _meals.watchRange(weekStart, today).first,
          _water.watchRange(weekStart, today).first,
          _plans.watchWeek(today).first,
        ).wait;
    final recipes = await _knownRecipes(profile);
    final shopping = await _shoppingLines();
    return AssistantContext(
      now: now,
      profile: profile,
      targets: profile?.nutritionTargets ?? NutritionTargets.fallback,
      todayMeals: meals,
      todayWaterMl: water.fold(0, (sum, w) => sum + w.amountMl),
      todayWaterLogCount: water.length,
      weights: body.weights,
      measurements: body.measurements,
      todayPlan: plan,
      fastingSchedule: FastingSchedule.fromProfile(profile),
      activeFast: sessions.where((s) => s.isActive).firstOrNull,
      todayActivity: activity,
      weekMeals: weekMeals,
      weekWaterLogs: weekWater,
      weekPlan: weekPlan,
      knownRecipes: recipes,
      shoppingLines: shopping,
    );
  }

  Future<List<AssistantKnownRecipe>> _knownRecipes(UserProfile? profile) async {
    final recipes = _recipes;
    if (recipes == null) return const [];
    try {
      final all = await recipes.getRecipes();
      const recommender = RecipeRecommendationService();
      return [
        for (final recipe in all)
          AssistantKnownRecipe(
            id: recipe.id,
            title: recipe.title,
            calories: recipe.calories,
            proteinG: recipe.protein,
            suitable: profile == null || recommender.isSuitable(recipe, profile),
          ),
      ];
    } on Object {
      return const [];
    }
  }

  Future<List<AssistantShoppingLine>> _shoppingLines() async {
    final shopping = _shopping;
    if (shopping == null) return const [];
    try {
      final items = await shopping.watchItems().first;
      return [
        for (final item in items)
          AssistantShoppingLine(
            name: item.name,
            manual: (item.sourceMealPlanId == null || item.sourceMealPlanId!.isEmpty),
          ),
      ];
    } on Object {
      return const [];
    }
  }

  Future<DailyActivity?> _readActivity(DateTime today) async {
    final activity = _activity;
    if (activity == null) return null;
    try {
      return await activity.watchDay(today).first.timeout(
        const Duration(seconds: 4),
      );
    } on Object {
      return null;
    }
  }
}

final assistantContextRepositoryProvider = Provider<AssistantContextRepository>(
  (ref) => RepositoryAssistantContextRepository(
    profiles: ref.watch(userProfileRepositoryProvider),
    meals: ref.watch(mealLogRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    body: ref.watch(bodyProgressRepositoryProvider),
    plans: ref.watch(mealPlanRepositoryProvider),
    fasting: ref.watch(fastingRepositoryProvider),
    clock: ref.watch(clockProvider),
    activity: ref.watch(activityRepositoryProvider),
    recipes: ref.watch(recipeRepositoryProvider),
    shopping: ref.watch(shoppingListRepositoryProvider),
  ),
);
