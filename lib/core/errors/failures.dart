import 'package:equatable/equatable.dart';

/// Katmanlar arası taşınan, kullanıcıya gösterilebilir hata modeli.
///
/// Data katmanı exception yakalar ve [Failure]'a çevirir; domain ve
/// presentation katmanları yalnızca [Failure] ile çalışır.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code, this.cause, this.stackTrace});

  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [runtimeType, message, code];
}

final class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    this.statusCode,
    super.code,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.cause, super.stackTrace});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'not_found']);
}

/// Katalog kaydı var; kullanılabilir besin/ad verisi yok.
final class IncompleteCatalogFoodFailure extends Failure {
  const IncompleteCatalogFoodFailure(
    super.message, {
    this.barcode,
    super.code,
    super.cause,
    super.stackTrace,
  });

  final String? barcode;
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'permission_denied']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause, super.stackTrace});
}

/// Premium gerektiren bir özelliğe erişim denemesi.
final class SubscriptionRequiredFailure extends Failure {
  const SubscriptionRequiredFailure([super.message = 'subscription_required']);
}

final class PurchaseFailure extends Failure {
  const PurchaseFailure(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Kullanıcı satın almayı kendisi iptal etti; hata olarak gösterilmez.
final class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure([super.message = 'purchase_cancelled']);
}

final class NotImplementedFailure extends Failure {
  const NotImplementedFailure([super.message = 'not_implemented']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.code,
    super.cause,
    super.stackTrace,
  });
}
