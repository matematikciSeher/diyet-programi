import 'package:diyet_programi/features/subscription/domain/models/app_feature.dart';
import 'package:diyet_programi/features/subscription/presentation/providers/premium_providers.dart';
import 'package:diyet_programi/shared/models/subscription_status.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:diyet_programi/shared/services/subscription/fake_subscription_service.dart';
import 'package:diyet_programi/shared/services/subscription/subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/subscription_overrides.dart';

void main() {
  var now = DateTime(2026, 9, 28);
  late InMemoryKeyValueStorage storage;
  late FakeSubscriptionService service;

  final annual = FakeSubscriptionService.offering.byPeriod(
    SubscriptionPeriod.annual,
  )!;
  final monthly = FakeSubscriptionService.offering.byPeriod(
    SubscriptionPeriod.monthly,
  )!;

  setUp(() async {
    now = DateTime(2026, 9, 28);
    storage = InMemoryKeyValueStorage();
    service = FakeSubscriptionService(storage, clock: () => now);
    await service.initialize(appUserId: 'user-1');
  });

  tearDown(() => service.dispose());

  group('FakeSubscriptionService', () {
    test('satın alma premium entitlement açar ve kalıcıdır', () async {
      expect(await service.getStatus(), SubscriptionStatus.free);

      final status = await service.purchase(monthly);
      expect(status.hasEntitlement(Entitlements.premium), isTrue);
      expect(status.expiresAt, now.add(const Duration(days: 30)));
      expect(status.willRenew, isTrue);

      final reopened = FakeSubscriptionService(storage, clock: () => now);
      await reopened.initialize(appUserId: 'user-1');
      expect((await reopened.restorePurchases()).isPremium, isTrue);
      await reopened.dispose();
    });

    test('deneme süreli paket deneme olarak başlar', () async {
      final status = await service.purchase(annual);
      expect(status.isInTrial, isTrue);
      expect(status.expiresAt, now.add(Duration(days: annual.trialDays!)));
    });

    test('abonelik kullanıcıya bağlıdır', () async {
      await service.purchase(monthly);
      await service.logIn('user-2');
      expect((await service.getStatus()).isPremium, isFalse);
      await service.logIn('user-1');
      expect((await service.getStatus()).isPremium, isTrue);
    });

    test('süresi dolan abonelik ücretsiz katmana düşer', () async {
      await service.purchase(monthly);
      now = now.add(const Duration(days: 31));
      expect(await service.getStatus(), SubscriptionStatus.free);
    });

    test('durum değişiklikleri yayınlanır', () async {
      final statuses = <bool>[];
      final sub = service.watchStatus().listen(
        (s) => statuses.add(s.isPremium),
      );
      await pumpEventQueue();
      await service.purchase(monthly);
      await service.reset();
      await pumpEventQueue();
      expect(statuses, [false, true, false]);
      await sub.cancel();
    });
  });

  group('featureAccessProvider', () {
    test('ücretsiz kullanıcı yalnızca ücretsiz özellikleri açar', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(subscriptionStatusProvider, (_, _) {});
      await container.read(subscriptionStatusProvider.future);

      for (final feature in AppFeature.values) {
        expect(
          container.read(featureAccessProvider(feature)),
          !feature.isPremium,
          reason: feature.name,
        );
      }
      expect(container.read(showAdsProvider), isTrue);
    });

    test('premium kullanıcı tüm özellikleri açar', () async {
      final container = ProviderContainer(overrides: [premiumOverride]);
      addTearDown(container.dispose);
      container.listen(subscriptionStatusProvider, (_, _) {});
      await container.read(subscriptionStatusProvider.future);

      for (final feature in AppFeature.values) {
        expect(container.read(featureAccessProvider(feature)), isTrue);
      }
      expect(container.read(showAdsProvider), isFalse);
    });

    test('katalog istenen ücretsiz / premium ayrımına uyar', () {
      expect(AppFeature.values.where((f) => !f.isPremium), [
        AppFeature.calorieTracking,
        AppFeature.weightTracking,
        AppFeature.waterTracking,
        AppFeature.foodLogging,
        AppFeature.basicProgress,
      ]);
      expect(AppFeature.premiumFeatures, hasLength(11));
    });
  });
}
