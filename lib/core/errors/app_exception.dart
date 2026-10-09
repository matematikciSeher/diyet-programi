/// Data katmanında (servisler, data source'lar) fırlatılan exception tipleri.
/// Repository katmanında `Failure`'a dönüştürülür.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

final class ServerException extends AppException {
  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.cause,
  });

  final int? statusCode;
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

final class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

final class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException(super.message, {super.code});
}

/// OFF'ta ürün var (status=1) ancak adı veya besin değerleri Food için yetersiz.
final class IncompleteCatalogFoodException extends AppException {
  const IncompleteCatalogFoodException(
    super.message, {
    this.barcode,
    super.code,
  });

  final String? barcode;
}

/// Mağaza satın alma hatası. RevenueCat `PurchasesErrorCode` → [code].
final class PurchaseException extends AppException {
  const PurchaseException(
    super.message, {
    this.userCancelled = false,
    super.code,
    super.cause,
  });

  final bool userCancelled;
}
