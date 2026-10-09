import 'package:diyet_programi/core/errors/failures.dart';
import 'package:diyet_programi/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:diyet_programi/shared/services/analytics/analytics_service.dart';
import 'package:diyet_programi/shared/services/auth/fake_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthService auth;
  late AuthRepositoryImpl repo;

  setUp(() {
    auth = FakeAuthService();
    repo = AuthRepositoryImpl(auth, const DebugAnalyticsService());
  });

  tearDown(() => auth.dispose());

  test('e-posta ile kayıt authenticated kullanıcı döner', () async {
    final result = await repo.signUpWithEmail(
      'a@b.com',
      'secret',
      displayName: 'Ayşe',
    );
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.email, 'a@b.com');
    expect(result.valueOrNull?.isAnonymous, isFalse);
    expect(auth.currentUser, isNotNull);
  });

  test('e-posta ile giriş boş parolada AuthFailure döner', () async {
    final result = await repo.signInWithEmail('a@b.com', '');
    expect(result.failureOrNull, isA<AuthFailure>());
  });

  test('misafir giriş anonim kullanıcı üretir', () async {
    final result = await repo.continueAsGuest();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.isAnonymous, isTrue);
  });

  test('Google ile giriş authenticated kullanıcı döner', () async {
    final result = await repo.signInWithGoogle();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.email, 'google.user@example.com');
    expect(auth.currentUser, isNotNull);
  });

  test('çıkış unauthenticated yapar', () async {
    await repo.continueAsGuest();
    await repo.signOut();
    expect(auth.currentUser, isNull);
    expect(await repo.watchAuthState().first, isNull);
  });

  test('parola sıfırlama hata fırlatmaz', () async {
    final result = await repo.sendPasswordReset('a@b.com');
    expect(result.isSuccess, isTrue);
  });
}
