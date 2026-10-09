import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_exception.dart';
import '../../models/auth_user.dart';
import '../firebase/firebase_error_mapper.dart';
import 'auth_service.dart';

/// Firebase Authentication. Google oturumu [google_sign_in] ile alınır;
/// yapılandırma yoksa [ServiceUnavailableException] fırlatılır.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    String? googleServerClientId,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _google = googleSignIn ?? GoogleSignIn.instance,
       _googleServerClientId = googleServerClientId;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final String? _googleServerClientId;
  var _googleReady = false;

  AuthUser _map(User user) => AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isAnonymous: user.isAnonymous,
    emailVerified: user.emailVerified,
  );

  AuthUser _require(User? user) {
    if (user == null) {
      throw const AuthException('not_authenticated', code: 'unauthenticated');
    }
    return _map(user);
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw FirebaseErrorMapper.map(error);
    }
  }

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _map(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user == null ? null : _map(user));

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) => _guard(() async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  });

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _require(result.user);
  });

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => _guard(() async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user == null) {
      throw const AuthException('not_authenticated', code: 'unauthenticated');
    }
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }
    return _require(_auth.currentUser);
  });

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    final serverId = _googleServerClientId;
    await _google.initialize(
      serverClientId: serverId == null || serverId.isEmpty ? null : serverId,
    );
    _googleReady = true;
  }

  @override
  Future<AuthUser> signInWithGoogle() => _guard(() async {
    try {
      await _ensureGoogle();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'missing_id_token',
          code: 'missing-id-token',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      return _require(result.user);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('cancelled', code: 'aborted');
      }
      throw ServiceUnavailableException(
        'google_sign_in_not_configured',
        code: error.code.name,
      );
    }
  });

  /// Sign in with Apple entitlement ve Firebase Apple provider yok.
  /// UI bu yöntemi göstermez; credential uydurulmaz.
  @override
  Future<AuthUser> signInWithApple() => throw const ServiceUnavailableException(
    'apple_sign_in_not_configured',
  );

  @override
  Future<AuthUser> signInAnonymously() => _guard(() async {
    final result = await _auth.signInAnonymously();
    return _require(result.user);
  });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _guard(() async {
    try {
      await _google.signOut();
    } on Object {
      // Google oturumu yoksa devam.
    }
    await _auth.signOut();
  });

  @override
  Future<void> deleteAccount() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('not_authenticated', code: 'unauthenticated');
    }
    await user.delete();
  });
}
