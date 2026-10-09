import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/enums.dart';

enum ReminderGroup { meal, water, goal, fasting, motivation, plan }

/// Ayarlardan açılıp kapatılabilen hatırlatıcılar. Oruç hatırlatıcıları
/// yalnızca profilde bir oruç protokolü seçiliyse planlanır; saatleri
/// protokol ve yeme penceresinden gelir.
enum ReminderType {
  breakfast(ReminderGroup.meal, 8 * 60 + 30),
  lunch(ReminderGroup.meal, 13 * 60),
  snack(ReminderGroup.meal, 16 * 60),
  dinner(ReminderGroup.meal, 19 * 60),
  water(ReminderGroup.water, 9 * 60),
  dailyGoal(ReminderGroup.goal, 21 * 60),
  weighIn(ReminderGroup.goal, 8 * 60),
  fastingStart(ReminderGroup.fasting, null),
  eatingWindowStart(ReminderGroup.fasting, null),
  eatingWindowEnd(ReminderGroup.fasting, null),
  fastingEnd(ReminderGroup.fasting, null),
  motivation(ReminderGroup.motivation, 10 * 60),
  plannedMeal(ReminderGroup.plan, null);

  const ReminderType(this.group, this.defaultMinutes);

  final ReminderGroup group;

  /// Kullanıcının seçebildiği saat; `null` ise saat otomatik hesaplanır.
  final int? defaultMinutes;

  bool get hasTime => defaultMinutes != null;

  static Iterable<ReminderType> inGroup(ReminderGroup group) =>
      values.where((t) => t.group == group);

  /// Öğün hatırlatmasının karşılığı. Plan ve su türlerinde `null`.
  MealType? get mealType => switch (this) {
    ReminderType.breakfast => MealType.breakfast,
    ReminderType.lunch => MealType.lunch,
    ReminderType.snack => MealType.snack,
    ReminderType.dinner => MealType.dinner,
    _ => null,
  };

  static ReminderType? forMeal(MealType meal) => switch (meal) {
    MealType.breakfast => ReminderType.breakfast,
    MealType.lunch => ReminderType.lunch,
    MealType.snack => ReminderType.snack,
    MealType.dinner => ReminderType.dinner,
  };
}

class ReminderSetting extends Equatable {
  const ReminderSetting({
    required this.enabled,
    this.minutes,
    this.intervalMinutes,
  });

  factory ReminderSetting.fromJson(Map<String, dynamic> json) =>
      ReminderSetting(
        enabled: json['enabled'] == true,
        minutes: JsonUtils.readIntOrNull(json['minutes']),
        intervalMinutes: JsonUtils.readIntOrNull(json['intervalMinutes']),
      );

  final bool enabled;

  /// Gece yarısından itibaren dakika; su için ilk hatırlatma.
  final int? minutes;

  /// Yalnızca su: tekrar aralığı (ör. 120 → her 2 saatte bir).
  final int? intervalMinutes;

  ReminderSetting copyWith({bool? enabled, int? minutes, int? intervalMinutes}) =>
      ReminderSetting(
        enabled: enabled ?? this.enabled,
        minutes: minutes ?? this.minutes,
        intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'minutes': minutes,
    'intervalMinutes': intervalMinutes,
  };

  @override
  List<Object?> get props => [enabled, minutes, intervalMinutes];
}

/// Kullanıcıya özel bildirim tercihleri. [enabled] kapalıyken hiçbir
/// hatırlatıcı planlanmaz; kullanıcı açınca bildirim izni istenir.
class NotificationSettings extends Equatable {
  const NotificationSettings({
    this.enabled = false,
    this.reminders = const {},
    this.sleepStartMinutes = defaultSleepStartMinutes,
    this.sleepEndMinutes = defaultSleepEndMinutes,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final raw = JsonUtils.readMap(json['reminders']);
    return NotificationSettings(
      enabled: json['enabled'] == true,
      reminders: {
        for (final type in ReminderType.values)
          if (raw[type.name] is Map)
            type: ReminderSetting.fromJson(
              Map<String, dynamic>.from(raw[type.name] as Map),
            ),
      },
      sleepStartMinutes:
          JsonUtils.readIntOrNull(json['sleepStartMinutes']) ??
          defaultSleepStartMinutes,
      sleepEndMinutes:
          JsonUtils.readIntOrNull(json['sleepEndMinutes']) ??
          defaultSleepEndMinutes,
    );
  }

  static const defaultWaterIntervalMinutes = 120;
  static const waterIntervals = [30, 60, 90, 120, 180];

  /// Su hatırlatmalarının son saati.
  static const waterEndMinutes = 21 * 60;

  /// Varsayılan uyku: 23:00–07:00.
  static const defaultSleepStartMinutes = 23 * 60;
  static const defaultSleepEndMinutes = 7 * 60;

  /// Yeme penceresi kapanmadan bu kadar önce hatırlatılır.
  static const eatingWindowEndLeadMinutes = 30;

  final bool enabled;
  final Map<ReminderType, ReminderSetting> reminders;
  final int sleepStartMinutes;
  final int sleepEndMinutes;

  /// Uyku penceresi gece yarısını aşıyorsa (23:00–07:00) doğru çalışır.
  bool isSleepMinutes(int minutes) {
    final start = sleepStartMinutes % (24 * 60);
    final end = sleepEndMinutes % (24 * 60);
    final m = minutes % (24 * 60);
    if (start == end) return false;
    if (start < end) return m >= start && m < end;
    return m >= start || m < end;
  }

  static ReminderSetting defaultFor(ReminderType type) => ReminderSetting(
    enabled: type != ReminderType.motivation,
    minutes: type.defaultMinutes,
    intervalMinutes: type == ReminderType.water
        ? defaultWaterIntervalMinutes
        : null,
  );

  ReminderSetting operator [](ReminderType type) =>
      reminders[type] ?? defaultFor(type);

  NotificationSettings copyWith({
    bool? enabled,
    Map<ReminderType, ReminderSetting>? reminders,
    int? sleepStartMinutes,
    int? sleepEndMinutes,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    reminders: reminders ?? this.reminders,
    sleepStartMinutes: sleepStartMinutes ?? this.sleepStartMinutes,
    sleepEndMinutes: sleepEndMinutes ?? this.sleepEndMinutes,
  );

  NotificationSettings update(ReminderType type, ReminderSetting setting) =>
      copyWith(reminders: {...reminders, type: setting});

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'reminders': {
      for (final e in reminders.entries) e.key.name: e.value.toJson(),
    },
    'sleepStartMinutes': sleepStartMinutes,
    'sleepEndMinutes': sleepEndMinutes,
  };

  @override
  List<Object?> get props => [
    enabled,
    reminders,
    sleepStartMinutes,
    sleepEndMinutes,
  ];
}
