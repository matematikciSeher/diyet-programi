import 'dart:async';
import 'dart:convert';

import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/app_logger.dart';
import '../local_storage/key_value_storage.dart';
import 'document_database.dart';
import 'in_memory_document_database.dart';

/// Kullanıcı belgelerinin cihazdaki JSON önbelleği.
///
/// Veri bellekte tutulur, her yazmadan kısa süre sonra tamamı JSON olarak
/// [KeyValueStorage]'a yazılır. Okumalar her zaman buradan (local-first)
/// yapılır; Firestore yalnızca senkron kuyruğu üzerinden yazılır.
class PersistentDocumentDatabase extends InMemoryDocumentDatabase {
  PersistentDocumentDatabase._(this._storage, {super.initial});

  factory PersistentDocumentDatabase.load(KeyValueStorage storage) {
    return PersistentDocumentDatabase._(storage, initial: _read(storage));
  }

  final KeyValueStorage _storage;
  Timer? _pending;

  static const _debounce = Duration(milliseconds: 400);

  static Map<String, Map<String, JsonMap>>? _read(KeyValueStorage storage) {
    final raw = storage.getString(StorageKeys.documentCache);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (value is Map)
            '$key': {
              for (final doc in value.entries)
                if (doc.value is Map)
                  '${doc.key}': Map<String, dynamic>.from(doc.value as Map),
            },
      };
    } on FormatException catch (e) {
      AppLogger.warning('Çevrimdışı veri okunamadı: $e');
      return null;
    }
  }

  @override
  void Function()? get onWrite => _schedule;

  void _schedule() {
    _pending?.cancel();
    _pending = Timer(_debounce, flush);
  }

  /// Bekleyen değişiklikleri hemen yazar.
  Future<void> flush() async {
    _pending?.cancel();
    _pending = null;
    await _storage.setString(StorageKeys.documentCache, jsonEncode(snapshot()));
  }

  @override
  Future<void> dispose() async {
    if (_pending != null) await flush();
    await super.dispose();
  }
}
