import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporting_service.dart';

/// Crashlytics. Beslenme, kilo, boy veya profil alanları loglanmaz.
class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
      printDetails: false,
    );
  }

  @override
  Future<void> log(String message) {
    // Mesajda kişisel sağlık verisi olmamalı; çağıran süzgeçler.
    return _crashlytics.log(message);
  }

  @override
  Future<void> setUserId(String? userId) {
    return _crashlytics.setUserIdentifier(userId ?? '');
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
}
