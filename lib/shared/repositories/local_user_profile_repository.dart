import 'dart:async';
import 'dart:convert';

import '../../core/constants/storage_keys.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/result.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import '../services/local_storage/key_value_storage.dart';
import 'user_profile_repository.dart';

/// Profili cihazdaki key-value depoda JSON olarak saklar.
final class LocalUserProfileRepository implements UserProfileRepository {
  LocalUserProfileRepository(this._storage);

  final KeyValueStorage _storage;
  final _changes = StreamController<UserProfile?>.broadcast();

  UserProfile? _read() {
    final raw = _storage.getString(StorageKeys.userProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? UserProfile.fromJson(Map<String, dynamic>.from(decoded))
          : null;
    } on FormatException catch (e) {
      AppLogger.warning('Profil okunamadı: $e');
      return null;
    }
  }

  @override
  Stream<UserProfile?> watchProfile() async* {
    yield _read();
    yield* _changes.stream;
  }

  @override
  Future<Result<UserProfile?>> getProfile() => guard(() async => _read());

  @override
  Future<Result<void>> saveProfile(UserProfile profile) => guard(() async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _storage.setString(
      StorageKeys.userProfile,
      jsonEncode(updated.toJson()),
    );
    _changes.add(updated);
  });

  @override
  Future<Result<void>> deleteProfile() => guard(() async {
    await _storage.remove(StorageKeys.userProfile);
    _changes.add(null);
  });

  Future<void> dispose() => _changes.close();
}
