/// Haftalık özet, içinde bulunulan takvim haftasının pazartesinden bugüne
/// kadar olan günlerini kullanır. Gelecek günler eksik kayıt sayılmaz.
abstract final class AssistantCalendar {
  static DateTime mondayOf(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  static DateTime dateOf(DateTime day) => DateTime(day.year, day.month, day.day);

  static bool dayKeyInOpenWeek(String dayKey, DateTime now) {
    final parsed = tryParseDayKey(dayKey);
    if (parsed == null) return false;
    final start = mondayOf(now);
    final today = dateOf(now);
    return !parsed.isBefore(start) && !parsed.isAfter(today);
  }

  static DateTime? tryParseDayKey(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}
