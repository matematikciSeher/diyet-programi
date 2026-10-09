import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/services/messaging/push_notification_service.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../models/notification_settings.dart';
import '../models/plan_meal_cue.dart';

/// Platforma verilecek tek bir hatırlatma (yerelleştirilmiş metinler hariç).
class PlannedReminder extends Equatable {
  const PlannedReminder({
    required this.id,
    required this.type,
    required this.repeat,
    this.minutes,
    this.weekday,
    this.at,
    this.meal,
    this.subject,
  });

  final int id;
  final ReminderType type;
  final LocalNotificationRepeat repeat;

  /// Günlük/haftalık tekrarda gece yarısından itibaren dakika.
  /// Tek seferlik hatırlatmada da saati taşır.
  final int? minutes;
  final int? weekday;

  /// Tek seferlik bildirimin zamanı.
  final DateTime? at;

  /// Plan hatırlatmasında öğün tipi.
  final MealType? meal;

  /// Plan hatırlatmasında tarif adı. Kilo, sağlık veya alerji içermez.
  final String? subject;

  int? get hour => minutes == null ? null : minutes! ~/ 60;
  int? get minute => minutes == null ? null : minutes! % 60;

  @override
  List<Object?> get props => [
    id,
    type,
    repeat,
    minutes,
    weekday,
    at,
    meal,
    subject,
  ];
}

/// Ayarlar, oruç düzeni, su hedefi ve haftalık plandan planlanacak
/// hatırlatmaları hesaplar. Yan etkisizdir; platform çağrıları
/// `NotificationService`'te.
abstract final class ReminderPlanner {
  static const _day = 24 * 60;

  /// Günlükteki bardak. Su hatırlatma sayısı buna göre belirlenir.
  static const waterGlassMl = 250;

  /// Su ve plan hatırlatmaları uygulama kapalıyken de gelsin diye
  /// ileriye dönük kaç gün kurulur.
  static const horizonDays = 7;

  static int idFor(ReminderType type, [int index = 0]) =>
      1000 + type.index * 100 + index;

  /// Gün + sıra. Aynı günün su hatırlatmaları sabit kimlik taşır.
  static int waterDayId(DateTime day, int slot) {
    final days = DateTime(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime(2020)).inDays;
    return 40000 + days * 16 + slot.clamp(0, 15);
  }

  /// Gün + öğün tipi + aynı tipteki sıra. Öğün değişince kimlik kalır.
  static int planMealId(String dayKey, MealType type, int index) {
    final parts = dayKey.split('-');
    final year = parts.length == 3 ? int.tryParse(parts[0]) ?? 0 : 0;
    final month = parts.length == 3 ? int.tryParse(parts[1]) ?? 0 : 0;
    final day = parts.length == 3 ? int.tryParse(parts[2]) ?? 0 : 0;
    final dayNumber = year * 372 + month * 31 + day;
    return 8000000 + dayNumber * 16 + type.index * 3 + index.clamp(0, 2);
  }

  /// Bu uygulamanın kurduğu bildirim kimlikleri. Başka bildirimlere dokunulmaz.
  static bool ownsId(int id) =>
      (id >= 1000 && id < 4000) ||
      (id >= 40000 && id < 2000000) ||
      (id >= 8000000 && id < 30000000);

  static List<PlannedReminder> plan({
    required NotificationSettings settings,
    required DateTime now,
    FastingSchedule? fasting,
    FastingSession? activeFast,
    List<MealType>? mealSlots,
    int? waterGoalMl,
    int waterConsumedMl = 0,
    List<PlanMealCue> planMeals = const [],
  }) {
    if (!settings.enabled) return const [];
    final result = <PlannedReminder>[];
    final coveredMeals = <MealType>{};

    if (settings[ReminderType.plannedMeal].enabled) {
      result.addAll(
        _planMeals(
          settings: settings,
          now: now,
          fasting: fasting,
          mealSlots: mealSlots,
          planMeals: planMeals,
          coveredMeals: coveredMeals,
        ),
      );
    }

    PlannedReminder daily(ReminderType type, int minutes, [int index = 0]) =>
        PlannedReminder(
          id: idFor(type, index),
          type: type,
          repeat: LocalNotificationRepeat.daily,
          minutes: minutes % _day,
        );

    for (final type in ReminderType.values) {
      final setting = settings[type];
      if (!setting.enabled) continue;
      final minutes = setting.minutes ?? type.defaultMinutes;
      switch (type) {
        case ReminderType.breakfast ||
            ReminderType.lunch ||
            ReminderType.snack ||
            ReminderType.dinner:
          final meal = type.mealType;
          if (meal != null && mealSlots != null && !mealSlots.contains(meal)) {
            continue;
          }
          if (meal != null && coveredMeals.contains(meal)) continue;
          if (fasting != null && !fasting.isInEatingWindow(minutes!)) {
            continue;
          }
          result.add(daily(type, minutes!));
        case ReminderType.water:
          if (waterGoalMl == null) {
            final interval =
                setting.intervalMinutes ??
                NotificationSettings.defaultWaterIntervalMinutes;
            var index = 0;
            for (
              var m = minutes!;
              m <= NotificationSettings.waterEndMinutes;
              m += interval
            ) {
              if (settings.isSleepMinutes(m)) continue;
              result.add(daily(type, m, index++));
            }
          } else {
            result.addAll(
              _waterReminders(
                settings: settings,
                now: now,
                goalMl: waterGoalMl,
                consumedMl: waterConsumedMl,
              ),
            );
          }
        case ReminderType.dailyGoal || ReminderType.motivation:
          result.add(daily(type, minutes!));
        case ReminderType.weighIn:
          result.add(
            PlannedReminder(
              id: idFor(type),
              type: type,
              repeat: LocalNotificationRepeat.weekly,
              minutes: minutes,
              weekday: DateTime.monday,
            ),
          );
        case ReminderType.fastingStart:
          if (fasting != null) {
            result.add(daily(type, fasting.fastingStartMinutes));
          }
        case ReminderType.eatingWindowStart:
          if (fasting != null) {
            result.add(daily(type, fasting.eatingStartMinutes));
          }
        case ReminderType.eatingWindowEnd:
          if (fasting != null) {
            result.add(
              daily(
                type,
                fasting.eatingEndMinutes -
                    NotificationSettings.eatingWindowEndLeadMinutes,
              ),
            );
          }
        case ReminderType.fastingEnd:
          final session = activeFast;
          if (session == null || session.isPaused) continue;
          final at = now.add(session.targetDuration - session.elapsed(now));
          if (at.isAfter(now)) {
            result.add(
              PlannedReminder(
                id: idFor(type),
                type: type,
                repeat: LocalNotificationRepeat.once,
                at: at,
              ),
            );
          }
        case ReminderType.plannedMeal:
          break;
      }
    }
    return result;
  }

  static List<PlannedReminder> _planMeals({
    required NotificationSettings settings,
    required DateTime now,
    required FastingSchedule? fasting,
    required List<MealType>? mealSlots,
    required List<PlanMealCue> planMeals,
    required Set<MealType> coveredMeals,
  }) {
    final result = <PlannedReminder>[];
    final occurrence = <String, int>{};
    for (final cue in planMeals) {
      if (mealSlots != null && !mealSlots.contains(cue.mealType)) continue;
      final day = _parseDay(cue.dayKey);
      if (day == null) continue;
      final reminderType = ReminderType.forMeal(cue.mealType);
      if (reminderType == null) continue;
      final minutes =
          cue.timeMinutes ??
          settings[reminderType].minutes ??
          reminderType.defaultMinutes;
      if (minutes == null) continue;
      final minute = minutes % _day;
      if (fasting != null && !fasting.isInEatingWindow(minute)) continue;
      final at = DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);
      if (!at.isAfter(now)) continue;
      final key = '${cue.dayKey}:${cue.mealType.name}';
      final index = occurrence[key] ?? 0;
      occurrence[key] = index + 1;
      coveredMeals.add(cue.mealType);
      final title = cue.title.trim();
      result.add(
        PlannedReminder(
          id: planMealId(cue.dayKey, cue.mealType, index),
          type: ReminderType.plannedMeal,
          repeat: LocalNotificationRepeat.once,
          minutes: minute,
          at: at,
          meal: cue.mealType,
          subject: title.isEmpty ? null : title,
        ),
      );
    }
    return result;
  }

  static List<PlannedReminder> _waterReminders({
    required NotificationSettings settings,
    required DateTime now,
    required int goalMl,
    required int consumedMl,
  }) {
    if (goalMl <= 0) return const [];
    final clock = _waterClock(settings);
    if (clock.isEmpty) return const [];
    final result = <PlannedReminder>[];
    final today = DateTime(now.year, now.month, now.day);
    final nowMinutes = now.hour * 60 + now.minute;
    for (var offset = 0; offset < horizonDays; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      final remaining = offset == 0 ? goalMl - consumedMl : goalMl;
      if (remaining <= 0) continue;
      final upcoming = offset == 0
          ? clock.where((minute) => minute > nowMinutes).toList()
          : clock;
      if (upcoming.isEmpty) continue;
      final count = (remaining / waterGlassMl).ceil().clamp(1, upcoming.length);
      final chosen = _take(upcoming, count);
      for (final (index, minute) in chosen.indexed) {
        result.add(
          PlannedReminder(
            id: waterDayId(day, index),
            type: ReminderType.water,
            repeat: LocalNotificationRepeat.once,
            minutes: minute,
            at: DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60),
          ),
        );
      }
    }
    return result;
  }

  /// Uyanık saatlere, kullanıcının su aralığından daha sık olmayacak
  /// şekilde dizilmiş saatler. Uyku penceresine düşenler elenir.
  static List<int> _waterClock(NotificationSettings settings) {
    final preferred =
        settings[ReminderType.water].minutes ??
        ReminderType.water.defaultMinutes!;
    final gap =
        (settings[ReminderType.water].intervalMinutes ??
                NotificationSettings.defaultWaterIntervalMinutes)
            .clamp(30, 12 * 60);
    var minute = preferred % _day;
    if (settings.isSleepMinutes(minute)) {
      minute = settings.sleepEndMinutes % _day;
    }
    final slots = <int>[];
    for (var i = 0; i < 8; i++) {
      if (minute >= _day || settings.isSleepMinutes(minute)) break;
      slots.add(minute);
      minute += gap;
    }
    return slots;
  }

  static List<int> _take(List<int> slots, int count) {
    if (count >= slots.length) return slots;
    if (count <= 1) return [slots.first];
    final last = slots.length - 1;
    final picked = <int>[];
    for (var i = 0; i < count; i++) {
      final value = slots[(last * i / (count - 1)).round()];
      if (picked.isEmpty || picked.last != value) picked.add(value);
    }
    return picked;
  }

  static DateTime? _parseDay(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }
}
