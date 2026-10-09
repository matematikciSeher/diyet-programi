import '../../../../core/errors/result.dart';
import '../../../../shared/models/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchAuthState();

  Future<Result<AuthUser>> signInWithEmail(String email, String password);
  Future<Result<AuthUser>> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  });
  Future<Result<AuthUser>> signInWithGoogle();
  Future<Result<AuthUser>> signInWithApple();
  Future<Result<AuthUser>> continueAsGuest();
  Future<Result<void>> sendPasswordReset(String email);
  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
}
