import '../../models/auth_user.dart';

/// Kimlik doğrulama soyutlaması.
///
/// Hedef implementasyon: `FirebaseAuthService` (firebase_auth,
/// google_sign_in, sign_in_with_apple). Hatalar `AuthException` olarak
/// fırlatılır.
abstract interface class AuthService {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;

  /// Backend istekleri için ID token; oturum yoksa `null`.
  Future<String?> getIdToken({bool forceRefresh = false});

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInAnonymously();

  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();

  /// App Store / Play Store politikaları gereği hesap silme zorunludur.
  Future<void> deleteAccount();
}
