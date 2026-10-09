import 'package:diyet_programi/features/fasting/domain/models/fasting_schedule.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/meal_plan_preferences.dart';
import 'package:diyet_programi/features/notifications/domain/models/notification_settings.dart';
import 'package:diyet_programi/features/notifications/domain/models/plan_meal_cue.dart';
import 'package:diyet_programi/features/notifications/domain/services/reminder_planner.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/fasting_session.dart';
import 'package:diyet_programi/shared/services/messaging/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fasting = FastingSchedule(
    protocol: FastingPreference.sixteenEight,
    eatingStartMinutes: 12 * 60,
  );

  test('bildirimler kapalıyken hiçbir hatırlatıcı planlanmaz', () {
    expect(
      ReminderPlanner.plan(
        settings: const NotificationSettings(),
        now: DateTime(2026, 9, 28, 9),
        fasting: fasting,
      ),
      isEmpty,
    );
  });

  test('öğün, su, hedef ve oruç hatırlatıcıları ayarlara göre planlanır', () {
    var settings = const NotificationSettings(enabled: true);
    settings = settings.update(
      ReminderType.breakfast,
      const ReminderSetting(enabled: true, minutes: 8 * 60 + 30),
    );
    settings = settings.update(
      ReminderType.lunch,
      const ReminderSetting(enabled: true, minutes: 13 * 60),
    );
    settings = settings.update(
      ReminderType.water,
      const ReminderSetting(
        enabled: true,
        minutes: 9 * 60,
        intervalMinutes: 120,
      ),
    );

    final planned = ReminderPlanner.plan(
      settings: settings,
      now: DateTime(2026, 9, 28, 9),
      fasting: fasting,
    );

    expect(
      planned.where((r) => r.type == ReminderType.breakfast),
      isEmpty,
      reason: '16:8 yeme penceresi 12:00’de başlar, kahvaltı atlanır',
    );
    expect(
      planned.where((r) => r.type == ReminderType.lunch).single.minutes,
      13 * 60,
    );
    expect(
      planned.where((r) => r.type == ReminderType.eatingWindowStart).single.minutes,
      12 * 60,
    );
    expect(
      planned.where((r) => r.type == ReminderType.fastingStart).single.minutes,
      20 * 60,
    );
    expect(
      planned.where((r) => r.type == ReminderType.eatingWindowEnd).single.minutes,
      20 * 60 - NotificationSettings.eatingWindowEndLeadMinutes,
    );
    expect(
      planned.where((r) => r.type == ReminderType.water),
      isNotEmpty,
    );
    expect(
      planned.where((r) => r.type == ReminderType.weighIn).single.repeat,
      LocalNotificationRepeat.weekly,
    );
  });

  test('aktif oruç bitişi tek seferlik planlanır', () {
    final now = DateTime(2026, 9, 28, 21);
    final settings = const NotificationSettings(enabled: true).update(
      ReminderType.fastingEnd,
      const ReminderSetting(enabled: true),
    );
    final planned = ReminderPlanner.plan(
      settings: settings,
      now: now,
      fasting: fasting,
      activeFast: FastingSession(
        id: 'fast',
        startedAt: DateTime(2026, 9, 28, 20),
        targetDuration: const Duration(hours: 16),
        protocol: FastingPreference.sixteenEight,
      ),
    );
    final end = planned.singleWhere((r) => r.type == ReminderType.fastingEnd);
    expect(end.repeat, LocalNotificationRepeat.once);
    expect(end.at, DateTime(2026, 9, 29, 12));
  });

  NotificationSettings enabledMeals() {
    var settings = const NotificationSettings(enabled: true);
    for (final type in ReminderType.values) {
      final meal = type.group == ReminderGroup.meal;
      settings = settings.update(
        type,
        ReminderSetting(
          enabled: meal || type == ReminderType.water,
          minutes: type.defaultMinutes,
          intervalMinutes: type == ReminderType.water
              ? NotificationSettings.defaultWaterIntervalMinutes
              : null,
        ),
      );
    }
    return settings;
  }

  test('3 öğün yalnızca kahvaltı, öğle ve akşam hatırlatır', () {
    final slots = MealPlanPreferences.slotsFor(3, BreakfastPreference.always);
    final planned = ReminderPlanner.plan(
      settings: enabledMeals(),
      now: DateTime(2026, 9, 29, 7),
      mealSlots: slots,
    );
    final meals = planned.where((r) => r.type.group == ReminderGroup.meal);
    expect(meals.map((r) => r.type).toSet(), {
      ReminderType.breakfast,
      ReminderType.lunch,
      ReminderType.dinner,
    });
    expect(meals.length, 3);
  });

  test('4 öğün mevcut öğün tiplerine uygun hatırlatır', () {
    final slots = MealPlanPreferences.slotsFor(4, BreakfastPreference.always);
    final planned = ReminderPlanner.plan(
      settings: enabledMeals(),
      now: DateTime(2026, 9, 29, 7),
      mealSlots: slots,
    );
    expect(
      planned.where((r) => r.type.group == ReminderGroup.meal).map((r) => r.type).toSet(),
      {ReminderType.breakfast, ReminderType.lunch, ReminderType.snack, ReminderType.dinner},
    );
  });

  test('öğün hatırlatması kapatılınca öğün kurulmaz', () {
    final planned = ReminderPlanner.plan(
      settings: const NotificationSettings(enabled: true).update(
        ReminderType.breakfast,
        const ReminderSetting(enabled: false, minutes: 8 * 60),
      ),
      now: DateTime(2026, 9, 29, 7),
      mealSlots: const [MealType.breakfast],
    );
    expect(planned.where((r) => r.type == ReminderType.breakfast), isEmpty);
  });

  test('su hedefi uyanık saatlere yayılır', () {
    final planned = ReminderPlanner.plan(
      settings: enabledMeals(),
      now: DateTime(2026, 9, 29, 7),
      waterGoalMl: 2000,
    );
    final today = planned.where(
      (r) =>
          r.type == ReminderType.water &&
          r.at != null &&
          r.at!.day == 29,
    );
    expect(today.map((r) => r.minutes), [
      9 * 60,
      11 * 60,
      13 * 60,
      15 * 60,
      17 * 60,
      19 * 60,
      21 * 60,
    ]);
    expect(today.every((r) => r.repeat == LocalNotificationRepeat.once), isTrue);
  });

  test('kalan su azsa bugün tek hatırlatma yeter', () {
    final planned = ReminderPlanner.plan(
      settings: enabledMeals(),
      now: DateTime(2026, 9, 29, 8),
      waterGoalMl: 2000,
      waterConsumedMl: 1800,
    );
    final today = planned.where(
      (r) => r.type == ReminderType.water && r.at!.day == 29,
    );
    final tomorrow = planned.where(
      (r) => r.type == ReminderType.water && r.at!.day == 30,
    );
    expect(today.length, 1);
    expect(tomorrow.length, 7);
  });

  test('su hedefi tamamsa bugün su hatırlatması kurulmaz', () {
    final planned = ReminderPlanner.plan(
      settings: enabledMeals(),
      now: DateTime(2026, 9, 29, 8),
      waterGoalMl: 2000,
      waterConsumedMl: 2000,
    );
    expect(
      planned.where((r) => r.type == ReminderType.water && r.at!.day == 29),
      isEmpty,
    );
  });

  test('su hatırlatması kapatılınca su kurulmaz', () {
    final planned = ReminderPlanner.plan(
      settings: const NotificationSettings(enabled: true).update(
        ReminderType.water,
        const ReminderSetting(enabled: false, minutes: 9 * 60),
      ),
      now: DateTime(2026, 9, 29, 7),
      waterGoalMl: 2000,
    );
    expect(planned.where((r) => r.type == ReminderType.water), isEmpty);
  });

  test('plan hatırlatması tarif adını taşır ve aynı öğünü çiftlemez', () {
    final planned = ReminderPlanner.plan(
      settings: enabledMeals().update(
        ReminderType.plannedMeal,
        const ReminderSetting(enabled: true),
      ),
      now: DateTime(2026, 9, 29, 9),
      mealSlots: const [MealType.breakfast, MealType.lunch, MealType.dinner],
      planMeals: const [
        PlanMealCue(
          dayKey: '2026-09-29',
          mealType: MealType.lunch,
          title: 'Tavuklu pilav',
          timeMinutes: 13 * 60,
        ),
      ],
    );
    final plan = planned.where((r) => r.type == ReminderType.plannedMeal);
    expect(plan.single.subject, 'Tavuklu pilav');
    expect(plan.single.at, DateTime(2026, 9, 29, 13));
    expect(planned.where((r) => r.type == ReminderType.lunch), isEmpty);
    expect(planned.where((r) => r.type == ReminderType.breakfast), isNotEmpty);
  });

  test('oruç penceresi dışındaki plan öğünü hatırlatılmaz', () {
    final planned = ReminderPlanner.plan(
      settings: const NotificationSettings(enabled: true),
      now: DateTime(2026, 9, 29, 7),
      fasting: fasting,
      planMeals: const [
        PlanMealCue(
          dayKey: '2026-09-29',
          mealType: MealType.breakfast,
          title: 'Yulaf',
          timeMinutes: 8 * 60,
        ),
      ],
    );
    expect(planned.where((r) => r.type == ReminderType.plannedMeal), isEmpty);
  });

  test('öğün saati değişince planlanan dakika da değişir', () {
    final before = ReminderPlanner.plan(
      settings: const NotificationSettings(enabled: true).update(
        ReminderType.lunch,
        const ReminderSetting(enabled: true, minutes: 13 * 60),
      ),
      now: DateTime(2026, 9, 29, 7),
      mealSlots: const [MealType.lunch],
    );
    final after = ReminderPlanner.plan(
      settings: const NotificationSettings(enabled: true).update(
        ReminderType.lunch,
        const ReminderSetting(enabled: true, minutes: 14 * 60),
      ),
      now: DateTime(2026, 9, 29, 7),
      mealSlots: const [MealType.lunch],
    );
    expect(before.where((r) => r.type == ReminderType.lunch).single.minutes, 13 * 60);
    expect(after.where((r) => r.type == ReminderType.lunch).single.minutes, 14 * 60);
    expect(
      before.where((r) => r.type == ReminderType.lunch).single.id,
      after.where((r) => r.type == ReminderType.lunch).single.id,
    );
  });
}
