import '../models/daily_log.dart';

/// Bir günün birleşik kaydı (öğünler, su, aktivite, kilo).
///
/// Şimdiki implementasyon ayrı repository'leri birleştirir. Firestore'a
/// geçildiğinde `daily_logs/{yyyy-MM-dd}` özet dökümanı okuyan bir
/// implementasyonla değiştirilebilir; arayüzü kullananlar etkilenmez.
abstract interface class DailyLogRepository {
  /// Kaynaklardan herhangi biri değiştikçe güncel günlüğü yayınlar.
  Stream<DailyLog> watchDay(DateTime day);
}
