import '../../../core/utils/app_logger.dart';

/// Hata raporlama. Hedef: `FirebaseCrashReportingService` (Crashlytics).
abstract interface class CrashReportingService {
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  });

  Future<void> log(String message);
  Future<void> setUserId(String? userId);
  Future<void> setCollectionEnabled({required bool enabled});
}

class LoggingCrashReportingService implements CrashReportingService {
  const LoggingCrashReportingService();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    AppLogger.error(
      '${fatal ? 'FATAL' : 'Non-fatal'}: ${reason ?? ''}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> log(String message) async => AppLogger.debug(message);

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}
