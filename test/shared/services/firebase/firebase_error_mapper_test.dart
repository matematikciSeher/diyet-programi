import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/shared/services/firebase/firebase_error_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wrong-password kimlik hatasına çevrilir, mesajda e-posta yok', () {
    final mapped = FirebaseErrorMapper.map(
      FirebaseAuthException(code: 'wrong-password'),
    );
    expect(mapped, isA<AuthException>());
    expect(mapped.code, 'wrong-password');
    expect(mapped.message, 'invalid_credentials');
    expect(mapped.toString(), isNot(contains('@')));
  });

  test('permission-denied PermissionException olur', () {
    final mapped = FirebaseErrorMapper.map(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    expect(mapped, isA<PermissionException>());
    expect(mapped.code, 'permission-denied');
  });

  test('bilinmeyen hata kişisel veri içermez', () {
    final mapped = FirebaseErrorMapper.map(StateError('user 80kg'));
    expect(mapped, isA<NetworkException>());
    expect(mapped.message, isNot(contains('80kg')));
  });
}
