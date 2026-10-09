import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import '../../../../shared/models/user_profile.dart';

enum FastingPhase { fasting, eating }

/// Protokol ve yeme penceresi başlangıcından türeyen günlük düzen
/// (ör. 16:8, yeme 12:00–20:00 → oruç 20:00–12:00). Değerler
/// [UserProfile.fastingPreference] ve [UserProfile.eatingWindowStartMinutes]
/// alanlarından gelir; ayrıca saklanmaz.
class FastingSchedule extends Equatable {
  const FastingSchedule({
    required this.protocol,
    this.eatingStartMinutes = UserProfile.defaultEatingWindowStartMinutes,
  }) : assert(protocol != FastingPreference.none);

  static FastingSchedule? fromProfile(UserProfile? profile) {
    if (profile == null || !profile.isFasting) return null;
    return FastingSchedule(
      protocol: profile.fastingPreference!,
      eatingStartMinutes: profile.effectiveEatingWindowStart,
    );
  }

  static const _day = 24 * 60;

  final FastingPreference protocol;

  /// Gece yarısından itibaren dakika.
  final int eatingStartMinutes;

  Duration get fastingDuration => Duration(hours: protocol.fastingHours);
  Duration get eatingDuration => Duration(hours: protocol.eatingHours);

  int get eatingEndMinutes =>
      (eatingStartMinutes + protocol.eatingHours * 60) % _day;

  /// Oruç yeme penceresi kapanınca başlar.
  int get fastingStartMinutes => eatingEndMinutes;
  int get fastingEndMinutes => eatingStartMinutes;

  /// [now]'u içeren ya da en son başlamış yeme penceresinin başlangıcı.
  DateTime _latestEatingStart(DateTime now) {
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: eatingStartMinutes));
    return today.isAfter(now) ? _addDays(today, -1) : today;
  }

  static DateTime _addDays(DateTime d, int days) => DateTime(
    d.year,
    d.month,
    d.day + days,
    d.hour,
    d.minute,
    d.second,
  );

  FastingPhase phaseAt(DateTime now) {
    final start = _latestEatingStart(now);
    return now.isBefore(start.add(eatingDuration))
        ? FastingPhase.eating
        : FastingPhase.fasting;
  }

  /// Şu anki pencerenin (yeme ya da oruç) bittiği an.
  DateTime currentPhaseEnd(DateTime now) {
    final start = _latestEatingStart(now);
    final eatingEnd = start.add(eatingDuration);
    return now.isBefore(eatingEnd) ? eatingEnd : _addDays(start, 1);
  }

  /// [now]'dan sonraki ilk yeme penceresi başlangıcı.
  DateTime nextEatingStart(DateTime now) =>
      _addDays(_latestEatingStart(now), 1);

  /// [now]'dan sonraki ilk yeme penceresi bitişi (= oruç başlangıcı).
  DateTime nextEatingEnd(DateTime now) {
    final end = _latestEatingStart(now).add(eatingDuration);
    return end.isAfter(now) ? end : _addDays(end, 1);
  }

  /// Dakikanın yeme penceresine düşüp düşmediği (gece yarısını aşan
  /// pencereler dahil).
  bool isInEatingWindow(int minutesOfDay) {
    final offset = (minutesOfDay - eatingStartMinutes) % _day;
    return offset < protocol.eatingHours * 60;
  }

  @override
  List<Object?> get props => [protocol, eatingStartMinutes];
}
