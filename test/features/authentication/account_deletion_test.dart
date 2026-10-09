import 'dart:async';

import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/core/constants/storage_keys.dart';
import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/errors/failure_messages.dart';
import 'package:diyet_programi/core/errors/failures.dart';
import 'package:diyet_programi/features/ai_coach/data/assistant_chat_store.dart';
import 'package:diyet_programi/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/auth_user.dart';
import 'package:diyet_programi/shared/services/account/account_deletion.dart';
import 'package:diyet_programi/shared/services/analytics/analytics_service.dart';
import 'package:diyet_programi/shared/services/auth/fake_auth_service.dart';
import 'package:diyet_programi/shared/services/database/document_database.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/database/persistent_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/messaging/push_notification_service.dart';
import 'package:diyet_programi/shared/services/sync/sync_queue.dart';
import 'package:diyet_programi/shared/services/sync/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/failing_document_database.dart';

const _uid = 'user-1';
const _other = 'user-1b';

void main() {
  test('authenticated kullanıcı silinince Auth kapanır', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);

    final result = await env.repo.deleteAccount();

    expect(result.isSuccess, isTrue);
    expect(env.auth.currentUser, isNull);
    expect(env.auth.deleteCalls, 1);
  });

  test('Firestore verisi Auth silinmeden önce silinir', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);

    final result = await env.repo.deleteAccount();

    expect(result.isSuccess, isTrue);
    expect(env.auth.cloudPresentAtAuthDelete, isFalse);
    expect(env.auth.deleteCalls, 1);
    await _expectUserGone(env.remote, _uid);
  });

  test(
    'Firestore silme hatası Auth hesabını silmez ve tekrar denenebilir',
    () async {
      final env = await _Env.signedIn();
      addTearDown(env.dispose);
      env.activeRemote = FailingDocumentDatabase();

      final failed = await env.repo.deleteAccount();

      expect(failed.isFailure, isTrue);
      expect(failed.failureOrNull, isA<NetworkFailure>());
      expect(env.auth.currentUser?.uid, _uid);
      expect(env.auth.deleteCalls, 0);
      expect(env.sync.uploadsBlockedFor(FirestorePaths.user(_uid)), isFalse);
      await _expectUserPresent(env.remote, _uid);
      expect(await env.local.getDocument(FirestorePaths.user(_uid)), isNotNull);

      env.activeRemote = env.remote;
      final retried = await env.repo.deleteAccount();
      expect(retried.isSuccess, isTrue);
      expect(env.auth.currentUser, isNull);
      await _expectUserGone(env.remote, _uid);
    },
  );

  testWidgets('Auth silme hatası güvenli mesaj döner, hesabı silmez', (
    tester,
  ) async {
    final env = await _Env.signedIn(
      auth: _ScriptedAuth(
        uid: _uid,
        onDelete: () async {
          throw const AuthException('auth_error', code: 'auth_error');
        },
      ),
    );
    addTearDown(env.dispose);

    final result = await env.repo.deleteAccount();
    final failure = result.failureOrNull;

    expect(result.isSuccess, isFalse);
    expect(failure, isA<AuthFailure>());
    expect(failure?.code, 'auth_error');
    expect(failure?.message, 'auth_error');
    expect(env.auth.currentUser?.uid, _uid);
    await _expectUserGone(env.remote, _uid);
    expect(await env.local.getDocument(FirestorePaths.user(_uid)), isNotNull);
    final message = await _message(tester, failure!);
    expect(message, lookupAppLocalizations(const Locale('tr')).errorGeneric);
    expect(message.contains('Firebase'), isFalse);
    expect(message.contains('#'), isFalse);
    expect(message.contains('\n'), isFalse);
  });

  test(
    'bekleyen senkron silinen kullaniciyi Firebase e geri yazamaz',
    () async {
      final env = await _Env.signedIn();
      addTearDown(env.dispose);
      final userPath = '${FirestorePaths.mealEntries(_uid)}/pending';
      final otherPath = '${FirestorePaths.mealEntries(_other)}/pending';
      await env.sync.enqueueSet(userPath, {'kcal': 1});
      await env.sync.enqueueSet(otherPath, {'kcal': 2});

      final result = await env.repo.deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(
        env.queue.snapshot.any(
          (op) => FirestorePaths.belongsToUser(op.documentPath, _uid),
        ),
        isFalse,
      );
      expect(
        env.queue.snapshot.any(
          (op) => FirestorePaths.belongsToUser(op.documentPath, _other),
        ),
        isTrue,
      );

      await env.sync.processQueue();
      expect(await env.remote.getDocument(userPath), isNull);
      expect((await env.remote.getDocument(otherPath))?.data['kcal'], 2);

      await env.sync.enqueueSet(FirestorePaths.user(_uid), {'name': 'geri'});
      await env.sync.processQueue();
      expect(await env.remote.getDocument(FirestorePaths.user(_uid)), isNull);

      final revivedQueue = InMemorySyncQueue();
      final revived = SyncService(
        queue: revivedQueue,
        remote: env.remote,
        clock: () => DateTime(2026, 9, 29, 9),
      );
      for (final id in AccountDeletion.readBlockedUserIds(env.storage)) {
        revived.blockUserUploads(id);
      }
      await revived.enqueueSet(FirestorePaths.user(_uid), {'name': 'yeniden'});
      await revived.enqueueSet(FirestorePaths.user(_other), {'name': 'kalır'});
      await revived.processQueue();
      expect(await env.remote.getDocument(FirestorePaths.user(_uid)), isNull);
      expect(
        (await env.remote.getDocument(
          FirestorePaths.user(_other),
        ))?.data['name'],
        'kalır',
      );
      await revivedQueue.dispose();
    },
  );

  test('yerel kişisel kayıtlar silinir, katalog kalır', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);

    final restored = PersistentDocumentDatabase.load(env.storage);
    addTearDown(restored.dispose);
    await _expectUserGone(restored, _uid);
    expect(env.storage.getString(StorageKeys.userProfile), isNull);
    expect(
      env.storage.getString(StorageKeys.dismissedCalorieTarget(_uid)),
      isNull,
    );
    expect(
      (await restored.getDocument(
        '${FirestorePaths.recipes}/seed',
      ))?.data['name'],
      'Çorba',
    );
    expect(env.storage.getString(StorageKeys.themeMode), 'dark');
    expect(env.storage.getString(StorageKeys.localeCode), 'tr');
    expect(env.storage.getString(StorageKeys.foodLookupCache), '{"a":1}');
    expect(env.storage.getBool(StorageKeys.onboardingCompleted), isTrue);
    await _expectUserPresent(restored, _other);
  });

  test('kişisel onboarding taslağı silinir', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);
    expect(env.storage.getString(StorageKeys.onboardingDraft), contains('"name"'));

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);

    expect(env.storage.getString(StorageKeys.onboardingDraft), isNull);
    expect(env.storage.getString(StorageKeys.themeMode), 'dark');
    expect(env.storage.getString(StorageKeys.localeCode), 'tr');
    expect(env.storage.getString(StorageKeys.foodLookupCache), '{"a":1}');
  });

  test('boş onboarding taslağı silmede hata üretmez', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);
    await env.storage.remove(StorageKeys.onboardingDraft);

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);
    expect(env.storage.getString(StorageKeys.onboardingDraft), isNull);
    expect(env.auth.currentUser, isNull);
  });

  test('asistanın yerel sohbeti silinir', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);
    expect(await AssistantChatStore(env.local).load(), isNotEmpty);

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);

    final restored = PersistentDocumentDatabase.load(env.storage);
    addTearDown(restored.dispose);
    expect(await AssistantChatStore(restored).load(), isEmpty);
  });

  test('bildirim ayarı, parmak izi ve planlanmış bildirim silinir', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);

    expect(
      env.storage.getString(StorageKeys.notificationSettings(_uid)),
      isNull,
    );
    expect(
      env.storage.getString(StorageKeys.notificationSchedule(_uid)),
      isNull,
    );
    expect(await env.notifications.pendingIds(), isEmpty);
    expect(
      env.storage.getString(StorageKeys.notificationSettings(_other)),
      '{"enabled":true}',
    );
  });

  test('kullanıcıya ait sağlık önbelleği silinir', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);
    expect(env.storage.getString(StorageKeys.healthActivityCache), isNotNull);

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);

    expect(env.storage.getString(StorageKeys.healthActivityCache), isNull);
    expect(env.storage.getBool(StorageKeys.healthLinked), isNull);
    expect(env.storage.getInt(StorageKeys.healthSyncApplied), isNull);
  });

  test('başka kullanıcının verisine dokunulmaz', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);

    expect((await env.repo.deleteAccount()).isSuccess, isTrue);

    await _expectUserPresent(env.remote, _other);
    await _expectUserPresent(env.local, _other);
    expect(
      (await env.remote.getDocument(
        '${FirestorePaths.recipes}/seed',
      ))?.data['name'],
      'Çorba',
    );
    expect(
      (await env.remote.getDocument(
        '${FirestorePaths.foods}/seed',
      ))?.data['name'],
      'Elma',
    );
    expect(
      FirestorePaths.belongsToUser(
        '${FirestorePaths.user(_other)}/meal_entries/item',
        _uid,
      ),
      isFalse,
    );
  });

  testWidgets('requires-recent-login başarı sayılmaz', (tester) async {
    final env = await _Env.signedIn(
      auth: _ScriptedAuth(
        uid: _uid,
        onDelete: () async {
          throw const AuthException(
            'requires_recent_login',
            code: 'requires-recent-login',
          );
        },
      ),
    );
    addTearDown(env.dispose);

    final result = await env.repo.deleteAccount();
    final failure = result.failureOrNull;

    expect(result.isSuccess, isFalse);
    expect(failure, isA<AuthFailure>());
    expect(failure?.code, 'requires-recent-login');
    expect(env.auth.currentUser?.uid, _uid);
    expect(env.auth.deleteCalls, 1);
    await _expectUserGone(env.remote, _uid);
    expect(await env.local.getDocument(FirestorePaths.user(_uid)), isNotNull);
    expect(env.sync.uploadsBlockedFor(FirestorePaths.user(_uid)), isTrue);
    await env.sync.enqueueSet(FirestorePaths.user(_uid), {'name': 'geri'});
    await env.sync.processQueue();
    expect(await env.remote.getDocument(FirestorePaths.user(_uid)), isNull);

    final message = await _message(tester, failure!);
    expect(
      message,
      lookupAppLocalizations(const Locale('tr')).authRequiresRecentLogin,
    );
    expect(message.contains('requires-recent-login'), isFalse);
    expect(message.contains('Firebase'), isFalse);
  });

  test('eşzamanlı silme istekleri tek kez çalışır', () async {
    final gate = _ScriptedAuth(uid: _uid, delay: true);
    final env = await _Env.signedIn(auth: gate);
    addTearDown(env.dispose);

    final first = env.repo.deleteAccount();
    await _until(() => gate.deleteCalls == 1);
    final second = env.repo.deleteAccount();
    await Future<void>.delayed(Duration.zero);

    expect(gate.deleteCalls, 1);
    gate.release();
    final results = await Future.wait([first, second]);
    expect(results.every((result) => result.isSuccess), isTrue);
    expect(gate.deleteCalls, 1);
    expect(env.auth.currentUser, isNull);
  });

  test('oturum yoksa silme başlamaz', () async {
    final env = await _Env.signedIn();
    addTearDown(env.dispose);
    await env.auth.signOut();

    final result = await env.repo.deleteAccount();

    expect(result.failureOrNull, isA<AuthFailure>());
    expect(result.failureOrNull?.code, 'unauthenticated');
    await _expectUserPresent(env.remote, _uid);
    await _expectUserPresent(env.remote, _other);
  });
}

Future<void> _seedUser(DocumentDatabase db, String uid) async {
  await db.setDocument(FirestorePaths.user(uid), {'name': uid});
  for (final path in FirestorePaths.userCollectionPaths(uid)) {
    await db.setDocument('$path/item', {'owner': uid});
  }
}

Future<void> _expectUserGone(DocumentDatabase db, String uid) async {
  expect(await db.getDocument(FirestorePaths.user(uid)), isNull);
  for (final path in FirestorePaths.userCollectionPaths(uid)) {
    expect(await db.getCollection(path), isEmpty, reason: path);
  }
}

Future<void> _expectUserPresent(DocumentDatabase db, String uid) async {
  expect((await db.getDocument(FirestorePaths.user(uid)))?.data['name'], uid);
  for (final path in FirestorePaths.userCollectionPaths(uid)) {
    expect(await db.getCollection(path), isNotEmpty, reason: path);
  }
}

Future<String> _message(WidgetTester tester, Failure failure) async {
  late String message;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          message = failure.localizedMessage(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return message;
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Env {
  _Env({required this.auth, InMemoryDocumentDatabase? remote})
    : remote = remote ?? InMemoryDocumentDatabase(),
      storage = InMemoryKeyValueStorage(),
      notifications = InMemoryLocalNotificationService() {
    local = PersistentDocumentDatabase.load(storage);
    queue = InMemorySyncQueue();
    sync = SyncService(
      queue: queue,
      remote: this.remote,
      clock: () => DateTime(2026, 9, 29, 8),
    );
    activeRemote = this.remote;
    deletion = AccountDeletion(
      auth: auth,
      sync: sync,
      local: () => local,
      remote: () => activeRemote,
      storage: storage,
      notifications: notifications,
    );
    repo = AuthRepositoryImpl(
      auth,
      const DebugAnalyticsService(),
      accountDeletion: deletion,
    );
  }

  static Future<_Env> signedIn({_ScriptedAuth? auth}) async {
    final remote = InMemoryDocumentDatabase();
    final env = _Env(
      auth: auth ?? _ScriptedAuth(uid: _uid, remote: remote),
      remote: remote,
    );
    await env._seed();
    return env;
  }

  final _ScriptedAuth auth;
  final InMemoryDocumentDatabase remote;
  final InMemoryKeyValueStorage storage;
  final InMemoryLocalNotificationService notifications;
  late final PersistentDocumentDatabase local;
  late final InMemorySyncQueue queue;
  late final SyncService sync;
  late final AccountDeletion deletion;
  late final AuthRepositoryImpl repo;
  late DocumentDatabase activeRemote;

  Future<void> _seed() async {
    await _seedUser(local, _uid);
    await _seedUser(local, _other);
    await _seedUser(remote, _uid);
    await _seedUser(remote, _other);
    await remote.setDocument('${FirestorePaths.recipes}/seed', {
      'name': 'Çorba',
    });
    await remote.setDocument('${FirestorePaths.foods}/seed', {'name': 'Elma'});
    await local.setDocument('${FirestorePaths.recipes}/seed', {
      'name': 'Çorba',
    });
    await storage.setString(StorageKeys.userProfile, '{"id":"$_uid"}');
    await storage.setString(
      StorageKeys.notificationSettings(_uid),
      '{"enabled":true}',
    );
    await storage.setString(
      StorageKeys.notificationSchedule(_uid),
      '{"1":true}',
    );
    await storage.setString(
      StorageKeys.notificationSettings(_other),
      '{"enabled":true}',
    );
    await storage.setString(StorageKeys.dismissedCalorieTarget(_uid), '1800');
    await storage.setString(StorageKeys.themeMode, 'dark');
    await storage.setString(StorageKeys.localeCode, 'tr');
    await storage.setString(StorageKeys.foodLookupCache, '{"a":1}');
    await storage.setBool(StorageKeys.onboardingCompleted, value: true);
    await storage.setString(
      StorageKeys.onboardingDraft,
      '{"currentStep":"summary","name":"Ayşe","age":30,"height":165,"weight":70,"targetWeight":62}',
    );
    await storage.setString(StorageKeys.healthActivityCache, '{"health":{}}');
    await storage.setBool(StorageKeys.healthLinked, value: true);
    await storage.setInt(StorageKeys.healthSyncApplied, 4);
    await AssistantChatStore(
      local,
    ).replaceAll(const [AssistantTranscript.user('merhaba')]);
    await notifications.scheduleDaily(
      id: 3,
      title: 'Su',
      body: 'İç',
      hour: 9,
      minute: 0,
    );
    await local.flush();
  }

  Future<void> dispose() async {
    await local.dispose();
    await remote.dispose();
    await queue.dispose();
    await auth.dispose();
  }
}

class _ScriptedAuth extends FakeAuthService {
  _ScriptedAuth({
    required String uid,
    this.remote,
    this.onDelete,
    this.delay = false,
  }) : super(
         initialUser: AuthUser(uid: uid, email: 'a@b.com'),
       );

  final DocumentDatabase? remote;
  final Future<void> Function()? onDelete;
  final bool delay;
  final _gate = Completer<void>();
  var deleteCalls = 0;
  var cloudPresentAtAuthDelete = false;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    final target = remote;
    if (target != null) {
      final profile = await target.getDocument(FirestorePaths.user(_uid));
      if (profile != null) cloudPresentAtAuthDelete = true;
      for (final path in FirestorePaths.userCollectionPaths(_uid)) {
        final docs = await target.getCollection(path);
        if (docs.isNotEmpty) cloudPresentAtAuthDelete = true;
      }
    }
    final hook = onDelete;
    if (hook != null) await hook();
    if (delay) await _gate.future;
    await super.deleteAccount();
  }
}
