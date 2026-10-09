import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/auth_user.dart';
import '../../../../shared/services/account/account_deletion.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/auth/auth_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._auth, this._analytics, {this.accountDeletion});

  final AuthService _auth;
  final AnalyticsService _analytics;
  final AccountDeletion? accountDeletion;

  @override
  Stream<AuthUser?> watchAuthState() => _auth.authStateChanges();

  @override
  Future<Result<AuthUser>> signInWithEmail(String email, String password) =>
      guard(() async {
        final user = await _auth.signInWithEmail(
          email: email.trim(),
          password: password,
        );
        await _analytics.logEvent(
          AnalyticsEvents.login,
          parameters: {'method': 'email'},
        );
        return user;
      });

  @override
  Future<Result<AuthUser>> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) => guard(() async {
    final user = await _auth.signUpWithEmail(
      email: email.trim(),
      password: password,
      displayName: displayName,
    );
    await _analytics.logEvent(
      AnalyticsEvents.signUp,
      parameters: {'method': 'email'},
    );
    return user;
  });

  @override
  Future<Result<AuthUser>> signInWithGoogle() => guard(() async {
    final user = await _auth.signInWithGoogle();
    await _analytics.logEvent(
      AnalyticsEvents.login,
      parameters: {'method': 'google'},
    );
    return user;
  });

  @override
  Future<Result<AuthUser>> signInWithApple() => guard(() async {
    final user = await _auth.signInWithApple();
    await _analytics.logEvent(
      AnalyticsEvents.login,
      parameters: {'method': 'apple'},
    );
    return user;
  });

  @override
  Future<Result<AuthUser>> continueAsGuest() => guard(() async {
    final user = await _auth.signInAnonymously();
    await _analytics.logEvent(
      AnalyticsEvents.login,
      parameters: {'method': 'anonymous'},
    );
    return user;
  });

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      guard(() => _auth.sendPasswordResetEmail(email.trim()));

  @override
  Future<Result<void>> signOut() => guard(_auth.signOut);

  @override
  Future<Result<void>> deleteAccount() => guard(() async {
    final deletion = accountDeletion;
    if (deletion != null) {
      await deletion.deleteAccount();
      return;
    }
    await _auth.deleteAccount();
  });
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(authServiceProvider);
  return AuthRepositoryImpl(
    auth,
    ref.watch(analyticsServiceProvider),
    accountDeletion: AccountDeletion(
      auth: auth,
      sync: ref.watch(syncServiceProvider),
      local: () => ref.read(localDocumentDatabaseProvider),
      remote: () => ref.read(remoteDocumentDatabaseProvider),
      storage: ref.watch(keyValueStorageProvider),
      notifications: ref.watch(localNotificationServiceProvider),
    ),
  );
});
