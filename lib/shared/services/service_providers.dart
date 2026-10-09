import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_api_client.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../models/subscription_status.dart';
import 'ai/ai_nutrition_service.dart';
import 'ai/proxy_ai_nutrition_service.dart';
import 'analytics/analytics_service.dart';
import 'auth/auth_service.dart';
import 'auth/fake_auth_service.dart';
import 'barcode/barcode_lookup_service.dart';
import 'crash_reporting/crash_reporting_service.dart';
import 'database/document_database.dart';
import 'database/in_memory_document_database.dart';
import 'food_database/food_database_service.dart';
import 'health/health_data_service.dart';
import 'health/health_platform_support.dart';
import 'health/health_service_factory.dart';
import 'local_storage/key_value_storage.dart';
import 'media/photo_picker_service.dart';
import 'messaging/push_notification_service.dart';
import 'media/media_permission_gateway.dart';
import 'speech/speech_recognition_service.dart';
import 'speech/speech_to_text_recognition_service.dart';
import 'storage/file_storage_service.dart';
import 'subscription/subscription_service.dart';
import 'sync/sync_queue.dart';
import 'sync/sync_service.dart';

// Uygulamanın dış dünyaya açılan tüm servisleri burada tanımlanır.
// Varsayılanlar ağ/SDK gerektirmeyen güvenli implementasyonlardır.
// Gerçek implementasyonlar (Firebase, RevenueCat, Health...) eklendiğinde
// `bootstrap.dart` içindeki `ProviderScope.overrides` ile değiştirilir;
// uygulamanın geri kalanı değişmez.

/// `bootstrap` içinde `SharedPreferencesStorage` ile override edilmelidir.
final keyValueStorageProvider = Provider<KeyValueStorage>(
  (ref) =>
      throw UnimplementedError('keyValueStorageProvider override edilmeli'),
);

final authServiceProvider = Provider<AuthService>((ref) {
  final service = FakeAuthService();
  ref.onDispose(service.dispose);
  return service;
});

final documentDatabaseProvider = Provider<DocumentDatabase>((ref) {
  final db = InMemoryDocumentDatabase();
  ref.onDispose(db.dispose);
  return db;
});

/// Firestore uzak kaynağı. Firebase yoksa `null`; senkron kuyruk bekler.
final remoteDocumentDatabaseProvider = Provider<DocumentDatabase?>(
  (ref) => null,
);

/// Testlerde sabit zaman verebilmek için saat kaynağı.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final syncQueueProvider = Provider<SyncQueue>((ref) {
  final queue = InMemorySyncQueue();
  ref.onDispose(queue.dispose);
  return queue;
});

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    queue: ref.watch(syncQueueProvider),
    remote: ref.watch(remoteDocumentDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final fileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => InMemoryFileStorageService(),
);

final photoPickerServiceProvider = Provider<PhotoPickerService>(
  (ref) => ImagePickerPhotoService(),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const DebugAnalyticsService(),
);

final crashReportingServiceProvider = Provider<CrashReportingService>(
  (ref) => const LoggingCrashReportingService(),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => const NoopPushNotificationService(),
);

/// Platform eklentisi bağlanana kadar planlanan bildirimler bellekte tutulur.
final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => InMemoryLocalNotificationService(),
);

final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => const FreeTierSubscriptionService(),
);

final healthDataServiceProvider = Provider<HealthDataService>((ref) {
  final config = ref.watch(appConfigProvider);
  return createHealthDataService(
    useFakeServices: config.useFakeServices,
    isRelease: kReleaseMode,
    platformSupported: healthPlatformSupported,
  );
});

final aiNutritionServiceProvider = Provider<AiNutritionService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.isAiProxyConfigured) {
    return const UnavailableAiNutritionService();
  }
  final timeoutSeconds = config.aiTimeoutSeconds < 5 || config.aiTimeoutSeconds > 60
      ? 20
      : config.aiTimeoutSeconds;
  final maxTokens = config.aiMaxOutputTokens < 64 || config.aiMaxOutputTokens > 1024
      ? 512
      : config.aiMaxOutputTokens;
  return ProxyAiNutritionService(
    client: DioApiClient.create(
      baseUrl: config.aiProxyBaseUrl.trim(),
      timeout: Duration(seconds: timeoutSeconds),
      tokenProvider: () => ref.read(authServiceProvider).getIdToken(),
    ),
    model: config.aiModel,
    maxOutputTokens: maxTokens,
  );
});

/// Firebase senkron kuyruğuna yazmayan cihaz bellek/disk veritabanı.
/// Sohbet geçmişi bunu kullanır; [documentDatabaseProvider] kullanılmaz.
final localDocumentDatabaseProvider = Provider<DocumentDatabase>(
  (ref) => throw UnimplementedError(
    'localDocumentDatabaseProvider bootstrap içinde override edilmeli',
  ),
);

final mediaPermissionGatewayProvider = Provider<MediaPermissionGateway>(
  (ref) => const PermissionHandlerGateway(),
);

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>(
  (ref) => SpeechToTextRecognitionService(
    maxDuration: Duration(
      seconds: ref.watch(appConfigProvider).effectiveVoiceMaxDurationSeconds,
    ),
  ),
);

final foodDatabaseServiceProvider = Provider<FoodDatabaseService>(
  (ref) => const EmptyFoodDatabaseService(),
);

final barcodeLookupServiceProvider = Provider<BarcodeLookupService>(
  (ref) => const EmptyBarcodeLookupService(),
);

// --- Uygulama geneli türetilmiş durumlar ---

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Oturum açmış kullanıcının uid'i; oturum yoksa `null`.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// Auth durumunu loading / authenticated / unauthenticated / error olarak sunar.
final authSessionProvider = Provider<AuthSession>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading && !auth.hasValue) {
    return const AuthSession.loading();
  }
  if (auth.hasError) {
    return AuthSession.error(auth.error.runtimeType.toString());
  }
  final user = auth.value;
  if (user == null) return const AuthSession.unauthenticated();
  return AuthSession.authenticated(user);
});

final _subscriptionInitProvider = FutureProvider<void>(
  (ref) => ref.watch(subscriptionServiceProvider).initialize(),
);

/// Abonelik, oturumdaki kullanıcıya bağlanır (RevenueCat `appUserID` = uid);
/// kullanıcı değişince durum yeniden okunur.
final subscriptionStatusProvider = StreamProvider<SubscriptionStatus>((
  ref,
) async* {
  final service = ref.watch(subscriptionServiceProvider);
  await ref.watch(_subscriptionInitProvider.future);
  final uid = ref.watch(currentUserIdProvider);
  if (uid != null) {
    await service.logIn(uid);
  } else {
    await service.logOut();
  }
  yield* service.watchStatus();
});

final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionStatusProvider).value?.isPremium ?? false,
);
