import 'dart:async';

import '../../../core/errors/app_exception.dart';
import '../../models/auth_user.dart';
import 'auth_service.dart';

/// Firebase bağlanana kadar geliştirme ve testte kullanılan bellek içi auth.
class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? initialUser}) : _user = initialUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  int _counter = 0;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async =>
      _user == null ? null : 'fake-token-${_user!.uid}';

  void _emit(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }

  AuthUser _newUser({String? email, String? name, bool anonymous = false}) =>
      AuthUser(
        uid: 'local-${++_counter}',
        email: email,
        displayName: name,
        isAnonymous: anonymous,
      );

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (password.isEmpty) {
      throw const AuthException('invalid_credentials', code: 'wrong-password');
    }
    final user = _newUser(email: email);
    _emit(user);
    return user;
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = _newUser(email: email, name: displayName);
    _emit(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = _newUser(email: 'google.user@example.com', name: 'Google');
    _emit(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    final user = _newUser(email: 'apple.user@example.com', name: 'Apple');
    _emit(user);
    return user;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final user = _newUser(anonymous: true);
    _emit(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async => _emit(null);

  @override
  Future<void> deleteAccount() async => _emit(null);

  Future<void> dispose() => _controller.close();
}
