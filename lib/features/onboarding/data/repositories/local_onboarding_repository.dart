import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/services/local_storage/key_value_storage.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/repositories/onboarding_repository.dart';

final class LocalOnboardingRepository implements OnboardingRepository {
  const LocalOnboardingRepository(this._storage);

  final KeyValueStorage _storage;

  @override
  bool get isCompleted =>
      _storage.getBool(StorageKeys.onboardingCompleted) ?? false;

  @override
  OnboardingDraft? readDraft() {
    final raw = _storage.getString(StorageKeys.onboardingDraft);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return OnboardingDraft.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException catch (e) {
      AppLogger.warning('Onboarding taslağı okunamadı: $e');
      return null;
    }
  }

  @override
  Future<Result<void>> saveDraft(OnboardingDraft draft) => guard(
    () => _storage.setString(
      StorageKeys.onboardingDraft,
      jsonEncode(draft.toJson()),
    ),
  );

  @override
  Future<Result<void>> clearDraft() =>
      guard(() => _storage.remove(StorageKeys.onboardingDraft));

  @override
  Future<Result<void>> markCompleted() => guard(
    () => _storage.setBool(StorageKeys.onboardingCompleted, value: true),
  );

  @override
  Future<Result<void>> reset() => guard(() async {
    await _storage.remove(StorageKeys.onboardingDraft);
    await _storage.remove(StorageKeys.onboardingCompleted);
  });
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => LocalOnboardingRepository(ref.watch(keyValueStorageProvider)),
);
