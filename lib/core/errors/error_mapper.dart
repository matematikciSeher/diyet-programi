import '../utils/app_logger.dart';
import 'app_exception.dart';
import 'failures.dart';
import 'result.dart';

/// Exception'ları [Failure]'a çevirir.
Failure mapExceptionToFailure(Object error, [StackTrace? stackTrace]) {
  return switch (error) {
    final Failure failure => failure,
    NetworkException(:final message, :final code) => NetworkFailure(
      message,
      code: code,
      cause: error,
      stackTrace: stackTrace,
    ),
    ServerException(:final message, :final statusCode, :final code) =>
      ServerFailure(
        message,
        statusCode: statusCode,
        code: code,
        cause: error,
        stackTrace: stackTrace,
      ),
    AuthException(:final message, :final code) => AuthFailure(
      message,
      code: code,
      cause: error,
      stackTrace: stackTrace,
    ),
    NotFoundException(:final message) => NotFoundFailure(message),
    IncompleteCatalogFoodException(:final message, :final barcode, :final code) =>
      IncompleteCatalogFoodFailure(
        message,
        barcode: barcode,
        code: code,
        cause: error,
        stackTrace: stackTrace,
      ),
    PermissionException(:final message) => PermissionFailure(message),
    CacheException(:final message) => CacheFailure(
      message,
      cause: error,
      stackTrace: stackTrace,
    ),
    ServiceUnavailableException(:final message) => NotImplementedFailure(
      message.isEmpty ? 'not_implemented' : message,
    ),
    PurchaseException(userCancelled: true) => const PurchaseCancelledFailure(),
    PurchaseException(:final message, :final code) => PurchaseFailure(
      message,
      code: code,
      cause: error,
      stackTrace: stackTrace,
    ),
    _ => UnexpectedFailure(
      error.toString(),
      cause: error,
      stackTrace: stackTrace,
    ),
  };
}

/// Repository metotlarını saran yardımcı: exception'ları yakalayıp
/// [Result.failure] döndürür.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Result.success(await body());
  } catch (error, stackTrace) {
    AppLogger.error('Repository error', error: error, stackTrace: stackTrace);
    return Result.failure(mapExceptionToFailure(error, stackTrace));
  }
}
