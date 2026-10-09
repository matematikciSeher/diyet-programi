import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/nutrition_targets.dart';
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
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../domain/models/assistant_context.dart';
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
  }) : _profiles = profiles,
       _meals = meals,
       _water = water,
       _body = body,
       _plans = plans,
       _fasting = fasting,
       _clock = clock,
       _activity = activity;

  final UserProfileRepository _profiles;
  final MealLogRepository _meals;
  final WaterRepository _water;
  final BodyProgressRepository _body;
  final MealPlanRepository _plans;
  final FastingRepository _fasting;
  final DateTime Function() _clock;
  final ActivityRepository? _activity;

  @override
  Future<AssistantContext> snapshot() async {
    final now = _clock();
    final today = now.startOfDay;
    final profile = (await _profiles.getProfile()).valueOrNull;
    final activity = await _readActivity(today);
    final (meals, water, body, plan, sessions) = await (
      _meals.watchDay(today).first,
      _water.watchDay(today).first,
      _body.watch().first,
      _plans.watchDay(today).first,
      _fasting.watchSessions().first,
    ).wait;
    return AssistantContext(
      now: now,
      profile: profile,
      targets: profile?.nutritionTargets ?? NutritionTargets.fallback,
      todayMeals: meals,
      todayWaterMl: water.fold(0, (sum, w) => sum + w.amountMl),
      weights: body.weights,
      measurements: body.measurements,
      todayPlan: plan,
      fastingSchedule: FastingSchedule.fromProfile(profile),
      activeFast: sessions.where((s) => s.isActive).firstOrNull,
      todayActivity: activity,
    );
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
  ),
);
