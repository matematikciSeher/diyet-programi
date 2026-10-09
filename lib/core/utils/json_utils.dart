/// Veritabanı/JSON haritalarından tip güvenli okuma yardımcıları.
///
/// Tarihler ISO-8601 metin olarak saklanır; Firestore implementasyonu
/// `Timestamp` dönüşümünü kendi adaptöründe yapar.
abstract final class JsonUtils {
  static DateTime? readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is Map) {
      return _dateFromTimestampMap(Map<Object?, Object?>.from(value));
    }
    return null;
  }

  /// Firestore `Timestamp` benzeri `{seconds, nanoseconds}` veya
  /// `{_seconds, _nanoseconds}` haritalarını okur.
  static DateTime? _dateFromTimestampMap(Map<Object?, Object?> map) {
    final seconds = readIntOrNull(map['seconds'] ?? map['_seconds']);
    if (seconds == null) return null;
    final nanos = readIntOrNull(map['nanoseconds'] ?? map['_nanoseconds']) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + nanos ~/ 1000000,
      isUtc: true,
    );
  }

  static DateTime readDateOr(Object? value, DateTime fallback) =>
      readDate(value) ?? fallback;

  static double readDouble(Object? value, [double fallback = 0]) =>
      switch (value) {
        final num n => n.toDouble(),
        final String s => double.tryParse(s) ?? fallback,
        _ => fallback,
      };

  static double? readDoubleOrNull(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  static int readInt(Object? value, [int fallback = 0]) => switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? fallback,
    _ => fallback,
  };

  static int? readIntOrNull(Object? value) => switch (value) {
    final num n when n.isFinite => n.round(),
    final String s => int.tryParse(s) ?? double.tryParse(s)?.round(),
    _ => null,
  };

  static String readString(Object? value, [String fallback = '']) =>
      value is String ? value : fallback;

  static String? readStringOrNull(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static T readEnum<T extends Enum>(
    List<T> values,
    Object? value,
    T fallback,
  ) => readEnumOrNull(values, value) ?? fallback;

  static T? readEnumOrNull<T extends Enum>(List<T> values, Object? value) {
    for (final v in values) {
      if (v.name == value) return v;
    }
    return null;
  }

  static List<String> readStringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  static Map<String, dynamic> readMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Map<String, dynamic>> readMapList(Object? value) => value is List
      ? value
            .whereType<Map<Object?, Object?>>()
            .map(Map<String, dynamic>.from)
            .toList()
      : const [];
}
