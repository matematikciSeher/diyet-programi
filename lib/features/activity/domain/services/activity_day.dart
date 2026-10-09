import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/utils/extensions/date_extensions.dart';

/// Aktivite gün sınırları. Bildirimlerdeki saat dilimi yaklaşımıyla aynı:
/// cihazın yerel konumu, okunamazsa Europe/Istanbul.
class ActivityDayBounds {
  const ActivityDayBounds({
    required this.from,
    required this.to,
    required this.dayKey,
  });

  /// Aralık [from, to). [to] bir sonraki yerel günün başlangıcıdır.
  final DateTime from;
  final DateTime to;
  final String dayKey;

  static const fallbackTimeZone = 'Europe/Istanbul';

  static bool _zonesReady = false;

  static void ensureTimeZones() {
    if (_zonesReady) return;
    tzdata.initializeTimeZones();
    _zonesReady = true;
  }

  /// [instant] hangi takvim gününe düşüyorsa o günün sınırları.
  static ActivityDayBounds forInstant(
    DateTime instant, {
    String? timeZoneName,
  }) {
    try {
      ensureTimeZones();
      final name = timeZoneName ?? _localName();
      final location = tz.getLocation(name);
      final zoned = tz.TZDateTime.from(instant.toUtc(), location);
      final from = tz.TZDateTime(location, zoned.year, zoned.month, zoned.day);
      final to = tz.TZDateTime(
        location,
        zoned.year,
        zoned.month,
        zoned.day + 1,
      );
      return ActivityDayBounds(
        from: from,
        to: to,
        dayKey: _key(zoned.year, zoned.month, zoned.day),
      );
    } on Object {
      final local = instant.toLocal();
      final from = DateTime(local.year, local.month, local.day);
      return ActivityDayBounds(
        from: from,
        to: DateTime(from.year, from.month, from.day + 1),
        dayKey: from.dayKey,
      );
    }
  }

  static String _localName() {
    try {
      return tz.local.name;
    } on Object {
      return fallbackTimeZone;
    }
  }

  static String _key(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
