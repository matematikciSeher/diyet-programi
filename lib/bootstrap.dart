import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/routing/notification_navigation.dart';
import 'core/utils/app_logger.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/notifications/data/repositories/syncing_notification_repository.dart';
import 'features/notifications/presentation/providers/notification_coordinator.dart';
import 'shared/repositories/local_user_profile_repository.dart';
import 'shared/repositories/syncing_user_profile_repository.dart';
import 'shared/repositories/user_profile_repository.dart';
import 'shared/services/account/account_deletion.dart';
import 'shared/services/analytics/analytics_service.dart';
import 'shared/services/analytics/firebase_analytics_service.dart';
import 'shared/services/auth/firebase_auth_service.dart';
import 'shared/services/crash_reporting/firebase_crash_reporting_service.dart';
import 'shared/services/database/firestore_document_database.dart';
import 'shared/services/database/local_first_document_database.dart';
import 'shared/services/database/persistent_document_database.dart';
import 'shared/services/local_storage/shared_preferences_storage.dart';
import 'shared/services/messaging/flutter_local_notification_service.dart';
import 'shared/services/service_providers.dart';
import 'shared/services/subscription/fake_subscription_service.dart';
import 'shared/services/sync/sync_queue.dart';
import 'shared/services/sync/sync_service.dart';
import 'shared/services/sync/user_data_hydrator.dart';

/// Uygulamanın kompozisyon kökü: yapılandırma, servis implementasyonları
/// ve global hata yakalama burada bağlanır.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final storage = await SharedPreferencesStorage.create();
  final firebase = await FirebaseBootstrap.initialize(config);
  final useRemote = firebase.isAvailable && !config.useFakeServices;
  if (kReleaseMode && !firebase.isAvailable) {
    AppLogger.warning(
      'Release: Firebase başlatılamadı; Auth/Firestore yerel kalacak. '
      'google-services.json / GoogleService-Info.plist veya FIREBASE_* '
      'dart-define gerekli. Credential üretilmez.',
    );
  }

  final localDb = PersistentDocumentDatabase.load(storage);
  final syncQueue = PersistentSyncQueue.load(storage);
  final remoteDb = useRemote ? FirestoreDocumentDatabase() : null;
  final syncService = SyncService(queue: syncQueue, remote: remoteDb);
  for (final uid in AccountDeletion.readBlockedUserIds(storage)) {
    syncService.blockUserUploads(uid);
  }

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      keyValueStorageProvider.overrideWithValue(storage),
      localDocumentDatabaseProvider.overrideWithValue(localDb),
      remoteDocumentDatabaseProvider.overrideWithValue(remoteDb),
      syncQueueProvider.overrideWithValue(syncQueue),
      syncServiceProvider.overrideWithValue(syncService),
      documentDatabaseProvider.overrideWith((ref) {
        final db = LocalFirstDocumentDatabase(
          local: localDb,
          sync: syncService,
          clock: ref.watch(clockProvider),
        );
        ref.onDispose(db.dispose);
        return db;
      }),
      userProfileRepositoryProvider.overrideWith((ref) {
        final local = LocalUserProfileRepository(storage);
        ref.onDispose(local.dispose);
        return SyncingUserProfileRepository(
          local: local,
          sync: syncService,
          uid: ref.watch(currentUserIdProvider),
          remote: remoteDb,
        );
      }),
      notificationRepositoryProvider.overrideWith((ref) {
        final local = LocalNotificationRepository(
          storage,
          ref.watch(currentUserIdProvider),
        );
        final repo = SyncingNotificationRepository(
          local: local,
          sync: syncService,
          uid: ref.watch(currentUserIdProvider),
          remote: remoteDb,
        );
        ref.onDispose(repo.dispose);
        return repo;
      }),
      localNotificationServiceProvider.overrideWith((ref) {
        final service = FlutterLocalNotificationService();
        ref.onDispose(service.dispose);
        return service;
      }),
      if (useRemote)
        authServiceProvider.overrideWithValue(
          FirebaseAuthService(
            googleServerClientId: const String.fromEnvironment(
              'GOOGLE_SERVER_CLIENT_ID',
            ),
          ),
        ),
      if (useRemote && config.enableAnalytics)
        analyticsServiceProvider.overrideWithValue(FirebaseAnalyticsService()),
      if (useRemote && config.enableCrashReporting)
        crashReportingServiceProvider.overrideWithValue(
          FirebaseCrashReportingService(),
        ),
      if (config.useFakeServices)
        subscriptionServiceProvider.overrideWith((ref) {
          final service = FakeSubscriptionService(
            storage,
            clock: ref.watch(clockProvider),
          );
          ref.onDispose(service.dispose);
          return service;
        }),
    ],
  );

  final crashReporting = container.read(crashReportingServiceProvider);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporting
        .recordError(
          details.exception,
          details.stack,
          reason: details.context?.toDescription(),
        )
        .ignore();
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashReporting.recordError(error, stackTrace, fatal: true).ignore();
    return true;
  };

  if (useRemote && config.enableCrashReporting) {
    await crashReporting.setCollectionEnabled(enabled: true);
  }
  if (useRemote && config.enableAnalytics) {
    final analytics = container.read(analyticsServiceProvider);
    await analytics.setCollectionEnabled(enabled: true);
    unawaited(analytics.logEvent(AnalyticsEvents.appOpen));
  }

  await container.read(localNotificationServiceProvider).initialize();
  attachNotificationNavigation(container);
  container.read(notificationCoordinatorProvider);

  container.listen(authStateProvider, (previous, next) {
    final user = next.value;
    final analytics = container.read(analyticsServiceProvider);
    final crash = container.read(crashReportingServiceProvider);
    unawaited(analytics.setUserId(user?.uid));
    unawaited(crash.setUserId(user?.uid));
    if (user == null || !useRemote) return;
    final profiles = container.read(userProfileRepositoryProvider);
    final notifications = container.read(notificationRepositoryProvider);
    unawaited(
      UserDataHydrator(
        sync: syncService,
        local: localDb,
        profiles: profiles is SyncingUserProfileRepository ? profiles : null,
      ).hydrate(user.uid),
    );
    if (notifications is SyncingNotificationRepository) {
      unawaited(notifications.hydrateFromRemote());
    }
  }, fireImmediately: true);

  unawaited(syncService.processQueue());

  AppLogger.info(
    'Starting ${config.appName} [${config.environment.name}]'
    '${kReleaseMode ? '' : ' (debug)'}'
    '${firebase.isAvailable ? ' firebase=on' : ' firebase=offline'}',
  );

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
