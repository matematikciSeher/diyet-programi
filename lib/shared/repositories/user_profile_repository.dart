import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/result.dart';
import '../models/user_profile.dart';
import '../services/service_providers.dart';
import 'local_user_profile_repository.dart';
import 'user_scoped_repository.dart';

/// Birden çok özelliğin (onboarding, dashboard, profil, plan) ortak
/// kullandığı profil verisi.
abstract interface class UserProfileRepository {
  Stream<UserProfile?> watchProfile();
  Future<Result<UserProfile?>> getProfile();
  Future<Result<void>> saveProfile(UserProfile profile);
  Future<Result<void>> deleteProfile();
}

/// `users/{uid}` dökümanında saklayan implementasyon. Firestore
/// bağlandığında `userProfileRepositoryProvider` bununla değiştirilir.
final class DocumentUserProfileRepository extends UserScopedRepository
    implements UserProfileRepository {
  const DocumentUserProfileRepository(super.db, super.uid);

  @override
  Stream<UserProfile?> watchProfile() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return db
        .watchDocument(FirestorePaths.user(id))
        .map((doc) => doc == null ? null : UserProfile.fromJson(doc.data));
  }

  @override
  Future<Result<UserProfile?>> getProfile() => guard(() async {
    final doc = await db.getDocument(FirestorePaths.user(requireUid()));
    return doc == null ? null : UserProfile.fromJson(doc.data);
  });

  @override
  Future<Result<void>> saveProfile(UserProfile profile) => guard(
    () => db.setDocument(
      FirestorePaths.user(requireUid()),
      profile.copyWith(updatedAt: DateTime.now()).toJson(),
      merge: true,
    ),
  );

  @override
  Future<Result<void>> deleteProfile() =>
      guard(() => db.deleteDocument(FirestorePaths.user(requireUid())));
}

/// Şimdilik profil cihazda saklanır; Firebase bağlanınca `bootstrap`
/// [SyncingUserProfileRepository] ile sarar.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final repo = LocalUserProfileRepository(ref.watch(keyValueStorageProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final userProfileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(userProfileRepositoryProvider).watchProfile(),
);
