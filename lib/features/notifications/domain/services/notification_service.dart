import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/local_storage/key_value_storage.dart';
import '../../../../shared/services/messaging/push_notification_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../fasting/data/repositories/fasting_repository_impl.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../fasting/domain/repositories/fasting_repository.dart';
import '../../../meal_plans/data/repositories/meal_plan_repository_impl.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/domain/repositories/meal_plan_repository.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../water/domain/repositories/water_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../models/applied_reminder.dart';
import '../models/notification_settings.dart';
import '../models/plan_meal_cue.dart';
import 'reminder_planner.dart';

/// Hatırlatıcıların tek yöneticisi. Ayar, profil, oruç, su ve haftalık planı
/// okuyup değişen bildirimleri [LocalNotificationService]'e yazar.
class NotificationService {
  const NotificationService({
    required LocalNotificationService local,
    required NotificationRepository settings,
    required UserProfileRepository profiles,
    required FastingRepository fasting,
    required MealPlanRepository plans,
    required WaterRepository water,
    required KeyValueStorage storage,
    required String? userId,
    required DateTime Function() clock,
    required AppLocalizations l10n,
  }) : _local = local,
       _settings = settings,
       _profiles = profiles,
       _fasting = fasting,
       _plans = plans,
       _water = water,
       _storage = storage,
       _userId = userId,
       _clock = clock,
       _l10n = l10n;

  final LocalNotificationService _local;
  final NotificationRepository _settings;
  final UserProfileRepository _profiles;
  final FastingRepository _fasting;
  final MealPlanRepository _plans;
  final WaterRepository _water;
  final KeyValueStorage _storage;
  final String? _userId;
  final DateTime Function() _clock;
  final AppLocalizations _l10n;

  String get _snapshotKey =>
      StorageKeys.notificationSchedule(_userId ?? 'anonymous');

  Future<bool> requestPermission() async {
    try {
      return await _local.requestPermission();
    } on Object {
      return false;
    }
  }

  Future<void> openSystemSettings() => _local.openSystemSettings();

  /// Ayarları kaydeder ve planı günceller. Bildirimler ilk kez açılıyorsa
  /// izin istenir; izin verilmezse ayar kapalı kalır ve `false` döner.
  Future<Result<bool>> updateSettings(NotificationSettings next) async {
    final previous = _settings.load();
    var settings = next;
    var granted = true;
    if (next.enabled && !previous.enabled) {
      granted = await requestPermission();
      if (!granted) settings = next.copyWith(enabled: false);
    }
    final saved = await _settings.save(settings);
    if (saved case Err(:final failure)) return Result.failure(failure);
    await sync();
    return Result.success(granted);
  }

  Future<List<PlannedReminder>> sync() async {
    final settings = _settings.load();
    final now = _clock();
    final profile = (await _profiles.getProfile()).valueOrNull;
    final sessions = await _safeSessions();
    final meals = await _safeMeals(now);
    final consumed = await _safeWater(now);
    final planned = ReminderPlanner.plan(
      settings: settings,
      now: now,
      fasting: FastingSchedule.fromProfile(profile),
      activeFast: sessions.where((session) => session.isActive).firstOrNull,
      mealSlots: MealPlanPreferences.fromProfile(profile).slots,
      waterGoalMl: profile?.waterGoal ?? AppConstants.defaultWaterGoalMl,
      waterConsumedMl: consumed,
      planMeals: cuesFrom(meals),
    );
    await _apply(planned);
    return planned;
  }

  static List<PlanMealCue> cuesFrom(Iterable<PlannedMeal> meals) => [
    for (final meal in meals)
      PlanMealCue(
        dayKey: meal.dayKey,
        mealType: meal.mealType,
        title: meal.title,
        timeMinutes: meal.timeMinutes,
      ),
  ];

  Future<List<FastingSession>> _safeSessions() async {
    try {
      return await _fasting.watchSessions().first;
    } on Object {
      return const [];
    }
  }

  Future<List<PlannedMeal>> _safeMeals(DateTime now) async {
    try {
      return await _plans.getCurrentPlan(now);
    } on Object {
      return const [];
    }
  }

  Future<int> _safeWater(DateTime now) async {
    try {
      final logs = await _water.watchDay(now).first;
      return logs.fold<int>(0, (sum, log) => sum + log.amountMl);
    } on Object {
      return 0;
    }
  }

  Future<void> _apply(List<PlannedReminder> planned) async {
    final desired = <int, AppliedReminder>{
      for (final reminder in planned) reminder.id: _fingerprint(reminder),
    };
    final previous = _loadSnapshot();
    final pending = await _pending();
    final desiredIds = desired.keys.toSet();
    final unchanged =
        previous.length == desired.length &&
        desired.entries.every((entry) => previous[entry.key] == entry.value) &&
        pending.where(ReminderPlanner.ownsId).every(desiredIds.contains) &&
        desiredIds.every(pending.contains);
    if (unchanged) return;

    final stale = <int>{
      ...previous.keys.where((id) => !desiredIds.contains(id)),
      ...pending.where(
        (id) => ReminderPlanner.ownsId(id) && !desiredIds.contains(id),
      ),
    };
    for (final id in stale) {
      try {
        await _local.cancel(id);
      } on Object {
        // İptal edilemeyen eski bildirim bir sonraki eşitlemede yeniden denenir.
      }
    }

    final applied = <int, AppliedReminder>{};
    for (final reminder in planned) {
      final fingerprint = desired[reminder.id]!;
      if (previous[reminder.id] == fingerprint &&
          pending.contains(reminder.id)) {
        applied[reminder.id] = fingerprint;
        continue;
      }
      try {
        await _schedule(reminder);
        applied[reminder.id] = fingerprint;
      } on Object {
        // Kurulamayan hatırlatma anlık görüntüye yazılmaz; sonra yeniden denenir.
      }
    }
    await _saveSnapshot(applied);
  }

  Future<Set<int>> _pending() async {
    try {
      return await _local.pendingIds();
    } on Object {
      return const {};
    }
  }

  Future<void> _schedule(PlannedReminder reminder) {
    final (title, body) = textsFor(_l10n, reminder);
    final payload = payloadFor(reminder.type);
    return switch (reminder.repeat) {
      LocalNotificationRepeat.daily => _local.scheduleDaily(
        id: reminder.id,
        title: title,
        body: body,
        hour: reminder.hour!,
        minute: reminder.minute!,
        payload: payload,
      ),
      LocalNotificationRepeat.weekly => _local.scheduleWeekly(
        id: reminder.id,
        title: title,
        body: body,
        weekday: reminder.weekday!,
        hour: reminder.hour!,
        minute: reminder.minute!,
        payload: payload,
      ),
      LocalNotificationRepeat.once => _local.scheduleOnce(
        id: reminder.id,
        title: title,
        body: body,
        at: reminder.at!,
        payload: payload,
      ),
    };
  }

  AppliedReminder _fingerprint(PlannedReminder reminder) {
    final (title, body) = textsFor(_l10n, reminder);
    return AppliedReminder(
      id: reminder.id,
      title: title,
      body: body,
      payload: payloadFor(reminder.type),
      repeat: reminder.repeat.name,
      minutes: reminder.minutes,
      weekday: reminder.weekday,
      at: reminder.at?.toIso8601String(),
    );
  }

  Map<int, AppliedReminder> _loadSnapshot() {
    final raw = _storage.getString(_snapshotKey);
    if (raw == null) return const {};
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const {};
      return {
        for (final item in list)
          if (item is Map)
            AppliedReminder.fromJson(Map<String, dynamic>.from(item)).id:
                AppliedReminder.fromJson(Map<String, dynamic>.from(item)),
      };
    } on Object {
      return const {};
    }
  }

  Future<void> _saveSnapshot(Map<int, AppliedReminder> applied) =>
      _storage.setString(
        _snapshotKey,
        jsonEncode([for (final item in applied.values) item.toJson()]),
      );

  static String payloadFor(ReminderType type) => switch (type) {
    ReminderType.breakfast => AppRoutes.diaryFocus(meal: MealType.breakfast),
    ReminderType.lunch => AppRoutes.diaryFocus(meal: MealType.lunch),
    ReminderType.snack => AppRoutes.diaryFocus(meal: MealType.snack),
    ReminderType.dinner => AppRoutes.diaryFocus(meal: MealType.dinner),
    ReminderType.water => AppRoutes.diaryFocus(section: AppRoutes.waterSection),
    ReminderType.weighIn => AppRoutes.weight,
    ReminderType.fastingStart ||
    ReminderType.eatingWindowStart ||
    ReminderType.eatingWindowEnd ||
    ReminderType.fastingEnd => AppRoutes.fasting,
    ReminderType.plannedMeal => AppRoutes.plans,
    ReminderType.dailyGoal || ReminderType.motivation => AppRoutes.dashboard,
  };

  static (String, String) textsFor(
    AppLocalizations l10n,
    PlannedReminder reminder,
  ) {
    final meal = reminder.meal;
    final subject = reminder.subject;
    if (reminder.type == ReminderType.plannedMeal &&
        meal != null &&
        subject != null &&
        subject.isNotEmpty) {
      return (
        l10n.reminderPlanMealTitle(mealTitle(l10n, meal), subject),
        mealBody(l10n, meal),
      );
    }
    return texts(l10n, reminder.type);
  }

  static String mealTitle(AppLocalizations l10n, MealType meal) =>
      switch (meal) {
        MealType.breakfast => l10n.reminderBreakfastTitle,
        MealType.lunch => l10n.reminderLunchTitle,
        MealType.snack => l10n.reminderSnackTitle,
        MealType.dinner => l10n.reminderDinnerTitle,
      };

  static String mealBody(AppLocalizations l10n, MealType meal) =>
      switch (meal) {
        MealType.breakfast => l10n.reminderBreakfastBody,
        MealType.lunch => l10n.reminderLunchBody,
        MealType.snack => l10n.reminderSnackBody,
        MealType.dinner => l10n.reminderDinnerBody,
      };

  static (String, String) texts(AppLocalizations l10n, ReminderType type) =>
      switch (type) {
        ReminderType.breakfast => (
          l10n.reminderBreakfastTitle,
          l10n.reminderBreakfastBody,
        ),
        ReminderType.lunch => (l10n.reminderLunchTitle, l10n.reminderLunchBody),
        ReminderType.snack => (l10n.reminderSnackTitle, l10n.reminderSnackBody),
        ReminderType.dinner => (
          l10n.reminderDinnerTitle,
          l10n.reminderDinnerBody,
        ),
        ReminderType.water => (l10n.reminderWaterTitle, l10n.reminderWaterBody),
        ReminderType.dailyGoal => (
          l10n.reminderDailyGoalTitle,
          l10n.reminderDailyGoalBody,
        ),
        ReminderType.weighIn => (
          l10n.reminderWeighInTitle,
          l10n.reminderWeighInBody,
        ),
        ReminderType.fastingStart => (
          l10n.reminderFastingStartTitle,
          l10n.reminderFastingStartBody,
        ),
        ReminderType.eatingWindowStart => (
          l10n.reminderEatingStartTitle,
          l10n.reminderEatingStartBody,
        ),
        ReminderType.eatingWindowEnd => (
          l10n.reminderEatingEndTitle,
          l10n.reminderEatingEndBody(
            NotificationSettings.eatingWindowEndLeadMinutes,
          ),
        ),
        ReminderType.fastingEnd => (
          l10n.reminderFastingEndTitle,
          l10n.reminderFastingEndBody,
        ),
        ReminderType.motivation => (
          l10n.reminderMotivationTitle,
          l10n.reminderMotivationBody,
        ),
        ReminderType.plannedMeal => (
          l10n.reminderLunchTitle,
          l10n.reminderLunchBody,
        ),
      };
}

/// Bildirim metinleri arka planda, `BuildContext` olmadan üretilir.
final notificationLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );
  return lookupAppLocalizations(supported ? locale : const Locale('tr'));
});

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    local: ref.watch(localNotificationServiceProvider),
    settings: ref.watch(notificationRepositoryProvider),
    profiles: ref.watch(userProfileRepositoryProvider),
    fasting: ref.watch(fastingRepositoryProvider),
    plans: ref.watch(mealPlanRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    storage: ref.watch(keyValueStorageProvider),
    userId: ref.watch(currentUserIdProvider),
    clock: ref.watch(clockProvider),
    l10n: ref.watch(notificationLocalizationsProvider),
  ),
);
