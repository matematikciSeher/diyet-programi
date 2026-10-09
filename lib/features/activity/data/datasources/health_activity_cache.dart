import 'dart:convert';

import '../../../../core/constants/storage_keys.dart';
import '../../../../shared/services/local_storage/key_value_storage.dart';
import '../../domain/models/daily_activity.dart';

/// Günün sağlık ve manuel aktivite özeti.
///
/// Yalnızca [KeyValueStorage]. Belge veritabanına ve Firebase kuyruğuna yazılmaz.
final class HealthActivityCache {
  HealthActivityCache(this._storage);

  final KeyValueStorage _storage;

  bool get isLinked => _storage.getBool(StorageKeys.healthLinked) ?? false;

  int get appliedEpoch => _storage.getInt(StorageKeys.healthSyncApplied) ?? 0;

  Future<void> setLinked({required bool value}) =>
      _storage.setBool(StorageKeys.healthLinked, value: value);

  Future<void> setAppliedEpoch(int epoch) =>
      _storage.setInt(StorageKeys.healthSyncApplied, epoch);

  DailyActivity? healthFor(String dayKey) => _bucket('health')[dayKey];

  DailyActivity? manualFor(String dayKey) => _bucket('manual')[dayKey];

  Map<String, DailyActivity> healthDays() => _bucket('health');

  Future<DailyActivity> upsertHealth(String dayKey, DailyActivity incoming) async {
    final stored = incoming.source == ActivitySource.health
        ? incoming
        : incoming.copyWith(source: ActivitySource.health);
    final existing = healthFor(dayKey);
    final next = existing != null && existing.sameMeasurement(stored)
        ? existing.copyWith(lastSyncedAt: stored.lastSyncedAt)
        : stored;
    await _writeBucket('health', dayKey, next);
    return next;
  }

  Future<void> saveManual(String dayKey, DailyActivity activity) =>
      _writeBucket(
        'manual',
        dayKey,
        activity.copyWith(source: ActivitySource.manual),
      );

  Map<String, DailyActivity> _bucket(String name) {
    final root = _root();
    final raw = root[name];
    if (raw is! Map) return {};
    final result = <String, DailyActivity>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (entry.key is! String || value is! Map) continue;
      result[entry.key as String] = DailyActivity.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    return result;
  }

  Future<void> _writeBucket(
    String name,
    String dayKey,
    DailyActivity activity,
  ) async {
    final root = _root();
    final current = root[name];
    final bucket = current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};
    bucket[dayKey] = activity.toJson();
    root[name] = bucket;
    await _storage.setString(StorageKeys.healthActivityCache, jsonEncode(root));
  }

  Map<String, dynamic> _root() {
    final raw = _storage.getString(StorageKeys.healthActivityCache);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on Object {
      return {};
    }
    return {};
  }
}
