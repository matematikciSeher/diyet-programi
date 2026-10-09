import 'dart:convert';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../auth/auth_service.dart';
import '../database/document_database.dart';
import '../database/persistent_document_database.dart';
import '../local_storage/key_value_storage.dart';
import '../messaging/push_notification_service.dart';
import '../sync/sync_service.dart';

/// Hesap silinirken bulut verisini, senkron kuyruğunu ve yerel kişisel
/// kayıtları Auth silinmeden önce temizler.
///
/// Firestore istemcisinde alt koleksiyonları tek çağrıda silen bir API yok.
/// Silinen yollar [FirestorePaths.userCollectionPaths] ve `users/{uid}`
/// profil belgesidir; bunlar tek seviye koleksiyonlardır.
class AccountDeletion {
  AccountDeletion({
    required AuthService auth,
    required SyncService sync,
    required DocumentDatabase Function() local,
    required DocumentDatabase? Function() remote,
    required KeyValueStorage storage,
    required LocalNotificationService notifications,
  }) : _auth = auth,
       _sync = sync,
       _local = local,
       _remote = remote,
       _storage = storage,
       _notifications = notifications;

  final AuthService _auth;
  final SyncService _sync;
  final DocumentDatabase Function() _local;
  final DocumentDatabase? Function() _remote;
  final KeyValueStorage _storage;
  final LocalNotificationService _notifications;
  Future<void>? _inFlight;

  static Set<String> readBlockedUserIds(KeyValueStorage storage) {
    final raw = storage.getString(StorageKeys.deletedAccountUids);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return {
        for (final item in decoded)
          if (item is String && item.isNotEmpty) item,
      };
    } on FormatException {
      return {};
    }
  }

  /// Eşzamanlı çağrılar aynı silme işlemini bekler.
  Future<void> deleteAccount() {
    final current = _inFlight;
    if (current != null) return current;
    final run = _run();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  Future<void> _run() async {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      throw const AuthException('not_authenticated', code: 'unauthenticated');
    }
    final uid = user.uid;
    final previouslyBlocked = readBlockedUserIds(_storage).contains(uid);
    _sync.blockUserUploads(uid);
    var cloudDeleted = false;
    try {
      await _sync.waitUntilIdle();
      await _deleteCloud(uid);
      cloudDeleted = true;
      await _rememberBlocked(uid);
      await _sync.discardUserOperations(uid);
      await _auth.deleteAccount();
      await _clearLocal(uid);
    } on Object {
      if (!cloudDeleted && !previouslyBlocked) {
        _sync.unblockUserUploads(uid);
      }
      rethrow;
    }
  }

  Future<void> _deleteCloud(String uid) async {
    final remote = _remote();
    if (remote == null) return;
    for (final collection in FirestorePaths.userCollectionPaths(uid)) {
      final docs = await remote.getCollection(collection);
      for (final doc in docs) {
        await remote.deleteDocument('$collection/${doc.id}');
      }
    }
    await remote.deleteDocument(FirestorePaths.user(uid));
  }

  Future<void> _rememberBlocked(String uid) async {
    final ids = readBlockedUserIds(_storage)..add(uid);
    await _storage.setString(
      StorageKeys.deletedAccountUids,
      jsonEncode(ids.toList()),
    );
    _sync.blockUserUploads(uid);
  }

  Future<void> _clearLocal(String uid) async {
    final local = _local();
    for (final collection in FirestorePaths.userCollectionPaths(uid)) {
      final docs = await local.getCollection(collection);
      for (final doc in docs) {
        await local.deleteDocument('$collection/${doc.id}');
      }
    }
    await local.deleteDocument(FirestorePaths.user(uid));
    final chat = await local.getCollection(FirestorePaths.assistantChatLocal);
    for (final doc in chat) {
      await local.deleteDocument(
        '${FirestorePaths.assistantChatLocal}/${doc.id}',
      );
    }
    if (local is PersistentDocumentDatabase) {
      await local.flush();
    }
    await _storage.remove(StorageKeys.userProfile);
    // Ad, yaş, boy, kilo gibi kişisel onboarding taslağı cihaz anahtarında kalır.
    await _storage.remove(StorageKeys.onboardingDraft);
    await _storage.remove(StorageKeys.notificationSettings(uid));
    await _storage.remove(StorageKeys.notificationSchedule(uid));
    await _storage.remove(StorageKeys.dismissedCalorieTarget(uid));
    await _storage.remove(StorageKeys.fakeSubscription(uid));
    // Sağlık önbelleği UID ile ayrılmıyor; cihazdaki kayıt oturumdaki
    // kullanıcıya ait olduğu için hesapla birlikte silinir.
    await _storage.remove(StorageKeys.healthActivityCache);
    await _storage.remove(StorageKeys.healthLinked);
    await _storage.remove(StorageKeys.healthSyncApplied);
    try {
      await _notifications.cancelAll();
    } on Object catch (error) {
      AppLogger.warning('Yerel bildirimler temizlenemedi', error: error);
    }
  }
}
