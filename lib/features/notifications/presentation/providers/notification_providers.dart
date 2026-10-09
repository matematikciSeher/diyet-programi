import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../fasting/presentation/providers/fasting_providers.dart';
import '../../../meal_plans/data/repositories/meal_plan_repository_impl.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_settings.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/reminder_planner.dart';

final reminderWeekMealsProvider = StreamProvider<List<PlannedMeal>>((ref) {
  ref.watch(currentUserIdProvider);
  final day = ref.watch(clockProvider)();
  return ref.watch(mealPlanRepositoryProvider).watchWeek(day);
});

final reminderWaterMlProvider = StreamProvider<int>((ref) {
  ref.watch(currentUserIdProvider);
  final day = ref.watch(clockProvider)();
  return ref.watch(waterRepositoryProvider).watchDay(day).map(
    (logs) => logs.fold<int>(0, (sum, log) => sum + log.amountMl),
  );
});

/// Mevcut ayarlarla planlanacak hatırlatmalar (ekrandaki özet için).
final plannedRemindersProvider = Provider<List<PlannedReminder>>((ref) {
  final settings = ref.watch(notificationSettingsProvider).value;
  if (settings == null) return const [];
  final profile = ref.watch(userProfileProvider).value;
  return ReminderPlanner.plan(
    settings: settings,
    now: ref.watch(clockProvider)(),
    fasting: ref.watch(fastingScheduleProvider),
    activeFast: ref.watch(activeFastProvider),
    mealSlots: MealPlanPreferences.fromProfile(profile).slots,
    waterGoalMl: profile?.waterGoal ?? AppConstants.defaultWaterGoalMl,
    waterConsumedMl: ref.watch(reminderWaterMlProvider).value ?? 0,
    planMeals: NotificationService.cuesFrom(
      ref.watch(reminderWeekMealsProvider).value ?? const [],
    ),
  );
});

/// Ayar değişikliklerini kaydedip gerçek planı günceller.
class NotificationSettingsController {
  const NotificationSettingsController(this._ref);

  final Ref _ref;

  NotificationService get _service => _ref.read(notificationServiceProvider);
  NotificationSettings get _current =>
      _ref.read(notificationRepositoryProvider).load();

  /// `Success(false)`: kullanıcı bildirim iznini vermedi.
  Future<Result<bool>> setEnabled({required bool enabled}) =>
      _service.updateSettings(_current.copyWith(enabled: enabled));

  Future<void> openSystemSettings() => _service.openSystemSettings();

  Future<Result<bool>> toggle(ReminderType type, {required bool enabled}) {
    final current = _current;
    return _service.updateSettings(
      current.update(type, current[type].copyWith(enabled: enabled)),
    );
  }

  Future<Result<bool>> setTime(ReminderType type, int minutes) {
    final current = _current;
    return _service.updateSettings(
      current.update(type, current[type].copyWith(minutes: minutes)),
    );
  }

  Future<Result<bool>> setWaterInterval(int minutes) {
    final current = _current;
    return _service.updateSettings(
      current.update(
        ReminderType.water,
        current[ReminderType.water].copyWith(intervalMinutes: minutes),
      ),
    );
  }

  Future<Result<bool>> setSleepHours({
    required int startMinutes,
    required int endMinutes,
  }) => _service.updateSettings(
    _current.copyWith(
      sleepStartMinutes: startMinutes,
      sleepEndMinutes: endMinutes,
    ),
  );
}

final notificationSettingsControllerProvider =
    Provider<NotificationSettingsController>(
      NotificationSettingsController.new,
    );
