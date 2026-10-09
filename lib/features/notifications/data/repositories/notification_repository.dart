import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/services/local_storage/key_value_storage.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/notification_settings.dart';

abstract interface class NotificationRepository {
  NotificationSettings load();
  Stream<NotificationSettings> watch();
  Future<Result<void>> save(NotificationSettings settings);
}

/// Bildirim tercihleri cihaz ayarı olduğu için kullanıcı id'sine göre
/// anahtarlanmış yerel depoda tutulur; hesaplar birbirinin ayarını görmez.
final class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository(this._storage, this._uid);

  final KeyValueStorage _storage;
  final String? _uid;
  final _changes = StreamController<NotificationSettings>.broadcast();

  String get _key => StorageKeys.notificationSettings(_uid ?? 'anonymous');

  @override
  NotificationSettings load() {
    final raw = _storage.getString(_key);
    if (raw == null) return const NotificationSettings();
    try {
      return NotificationSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      return const NotificationSettings();
    }
  }

  @override
  Stream<NotificationSettings> watch() async* {
    yield load();
    yield* _changes.stream;
  }

  @override
  Future<Result<void>> save(NotificationSettings settings) => guard(() async {
    await _storage.setString(_key, jsonEncode(settings.toJson()));
    _changes.add(settings);
  });

  void dispose() => _changes.close();
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repo = LocalNotificationRepository(
    ref.watch(keyValueStorageProvider),
    ref.watch(currentUserIdProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final notificationSettingsProvider = StreamProvider<NotificationSettings>(
  (ref) => ref.watch(notificationRepositoryProvider).watch(),
);
