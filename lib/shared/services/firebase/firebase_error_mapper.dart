import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';

/// Firebase Auth / Firestore hatalarını uygulama exception'larına çevirir.
/// Kişisel veri mesaja yazılmaz; yalnızca kod ve genel sınıf adı kullanılır.
abstract final class FirebaseErrorMapper {
  static AppException map(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      return AuthException(_authMessage(error.code), code: error.code);
    }
    if (error is FirebaseException) {
      return _fromCode(error.code, error.plugin);
    }
    return const NetworkException('firebase_unavailable', code: 'unavailable');
  }

  static AppException _fromCode(String code, String plugin) {
    return switch (code) {
      'permission-denied' => const PermissionException(
        'permission_denied',
        code: 'permission-denied',
      ),
      'unauthenticated' => const AuthException(
        'not_authenticated',
        code: 'unauthenticated',
      ),
      'not-found' => const NotFoundException('not_found', code: 'not-found'),
      'unavailable' ||
      'network-request-failed' ||
      'cloud_firestore/unavailable' => const NetworkException(
        'network_unavailable',
        code: 'unavailable',
      ),
      'deadline-exceeded' || 'timeout' => const NetworkException(
        'timeout',
        code: 'timeout',
      ),
      _ => NetworkException(
        plugin.isEmpty ? 'firebase_error' : plugin,
        code: code,
      ),
    };
  }

  static String _authMessage(String code) => switch (code) {
    'invalid-email' => 'invalid_email',
    'user-disabled' => 'user_disabled',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'invalid_credentials',
    'email-already-in-use' => 'email_already_in_use',
    'weak-password' => 'weak_password',
    'operation-not-allowed' => 'operation_not_allowed',
    'network-request-failed' => 'network_unavailable',
    'too-many-requests' => 'too_many_requests',
    'requires-recent-login' => 'requires_recent_login',
    _ => 'auth_error',
  };
}
