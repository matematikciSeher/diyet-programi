import '../models/daily_activity.dart';

/// Adım, aktif kalori ve egzersiz süresi. Kaynak Apple Health /
/// Health Connect ya da manuel kayıtlardır.
abstract interface class ActivityRepository {
  Stream<DailyActivity> watchDay(DateTime day);
}
