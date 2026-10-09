import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/nutrition/profile_targets_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/usecases/weekly_meal_planner.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../notifications/domain/services/notification_service.dart';
import '../../../nutrition/domain/models/nutrition_goal_history.dart';
import '../../../weight/presentation/providers/target_change_providers.dart';

/// Kişisel bilgiler kaydının sonucu. Kalori hedefi otomatik değiştirilmez;
/// fark varsa [suggestion] kullanıcı onayına bırakılır.
class PersonalInfoSaveResult {
  const PersonalInfoSaveResult({
    required this.profile,
    this.suggestion,
    this.planUpdated = false,
  });

  final UserProfile profile;
  final TargetSuggestion? suggestion;
  final bool planUpdated;
}

/// Profil alanlarını kaydeder. Diyet, alerji, öğün sayısı ve oruç
/// tercihleri Beslenme Planı'nı; oruç protokolü bildirimleri etkiler.
class PersonalInfoActions {
  const PersonalInfoActions(this._ref);

  final Ref _ref;

  DateTime get _now => _ref.read(clockProvider)();

  Future<Result<PersonalInfoSaveResult>> save(UserProfile next) async {
    final profiles = _ref.read(userProfileRepositoryProvider);
    final previous = (await profiles.getProfile()).valueOrNull;
    final updated = next.copyWith(updatedAt: _now);
    final saved = await profiles.saveProfile(updated);
    if (saved case Err(:final failure)) return Result.failure(failure);

    var planUpdated = false;
    if (previous != null && _affectsPlan(previous, updated)) {
      final prefs = MealPlanPreferences.fromProfile(
        updated,
      ).withExcluded(_ref.read(sessionPlanExclusionsProvider));
      final today = _now.startOfDay;
      final days = [
        for (final d in WeeklyMealPlanner.weekDays(today))
          if (!d.isBefore(today)) d,
      ];
      final planner = _ref.read(weeklyMealPlannerProvider);
      final result = _needsRegenerate(previous, updated)
          ? await planner.regenerate(
              days,
              prefs,
              seed: _now.millisecondsSinceEpoch & 0x7fffffff,
            )
          : await planner.retime(days, prefs);
      if (result case Err(:final failure)) return Result.failure(failure);
      planUpdated = true;
    }

    if (previous?.fastingPreference != updated.fastingPreference ||
        previous?.eatingWindowStartMinutes !=
            updated.eatingWindowStartMinutes ||
        previous?.waterGoal != updated.waterGoal ||
        previous?.mealsPerDay != updated.mealsPerDay ||
        previous?.breakfastPreference != updated.breakfastPreference ||
        planUpdated) {
      await _ref.read(notificationServiceProvider).sync();
    }

    return Result.success(
      PersonalInfoSaveResult(
        profile: updated,
        suggestion: _ref
            .read(profileTargetsServiceProvider)
            .suggest(updated, now: _now),
        planUpdated: planUpdated,
      ),
    );
  }

  /// Kullanıcı onayladığında kalori/makro hedeflerini günceller.
  Future<Result<UserProfile?>> applyTargets(TargetSuggestion suggestion) async {
    return _ref
        .read(applyCalorieTargetProvider)
        .apply(suggestion, reason: GoalChangeReason.profileUpdate);
  }

  static bool _affectsPlan(UserProfile a, UserProfile b) =>
      _needsRegenerate(a, b) ||
      a.fastingPreference != b.fastingPreference ||
      a.eatingWindowStartMinutes != b.eatingWindowStartMinutes;

  static bool _needsRegenerate(UserProfile a, UserProfile b) =>
      a.dietType != b.dietType ||
      a.mealsPerDay != b.mealsPerDay ||
      a.breakfastPreference != b.breakfastPreference ||
      a.dailyCalories != b.dailyCalories ||
      !_same(a.allergies, b.allergies) ||
      !_same(a.dislikedFoods, b.dislikedFoods);

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final left = [...a]..sort();
    final right = [...b]..sort();
    return listEquals(left, right);
  }
}

final personalInfoActionsProvider = Provider<PersonalInfoActions>(
  PersonalInfoActions.new,
);
