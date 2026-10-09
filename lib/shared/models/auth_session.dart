import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// Kimlik doğrulama oturumunun UI'dan bağımsız durumu.
enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthSession extends Equatable {
  const AuthSession({
    required this.status,
    this.user,
    this.errorCode,
  });

  const AuthSession.loading()
    : status = AuthStatus.loading,
      user = null,
      errorCode = null;

  const AuthSession.authenticated(AuthUser this.user)
    : status = AuthStatus.authenticated,
      errorCode = null;

  const AuthSession.unauthenticated()
    : status = AuthStatus.unauthenticated,
      user = null,
      errorCode = null;

  const AuthSession.error([this.errorCode])
    : status = AuthStatus.error,
      user = null;

  final AuthStatus status;
  final AuthUser? user;
  final String? errorCode;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  @override
  List<Object?> get props => [status, user, errorCode];
}
