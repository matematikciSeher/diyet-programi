extension DateTimeX on DateTime {
  /// Günlük kayıtlar için gün başlangıcı (yerel saat).
  DateTime get startOfDay => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Takvim günü ekler; yaz saati geçişlerinden etkilenmez.
  DateTime addDays(int days) =>
      DateTime(year, month, day + days, hour, minute, second);

  /// Bu günün tarihini [time]'ın saatiyle birleştirir.
  DateTime withTimeOf(DateTime time) =>
      DateTime(year, month, day, time.hour, time.minute, time.second);

  /// Firestore döküman id'si / gün anahtarı olarak kullanılan `yyyy-MM-dd`.
  String get dayKey =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
