import 'package:diyet_programi/features/subscription/presentation/providers/premium_providers.dart';
import 'package:diyet_programi/features/subscription/presentation/widgets/ad_banner_slot.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/services/ads/ad_backend.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:diyet_programi/shared/services/subscription/fake_subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium banner, geçiş ve ödüllü çağrıları durdurur', () async {
    final backend = _RecordingAdBackend();
    final storage = InMemoryKeyValueStorage();
    final service = FakeSubscriptionService(storage, exposeOfferings: false);
    final container = ProviderContainer(
      overrides: [
        keyValueStorageProvider.overrideWithValue(storage),
        subscriptionServiceProvider.overrideWith((ref) {
          ref.onDispose(service.dispose);
          return service;
        }),
        adBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(subscriptionStatusProvider.future);

    final ads = container.read(premiumAdCoordinatorProvider);
    expect(await ads.loadBanner(AdPlacement.shell), AdOutcome.shown);
    expect(
      await ads.showInterstitial(AdPlacement.navigation),
      AdOutcome.shown,
    );
    expect(await ads.showRewarded(AdPlacement.rewarded), AdOutcome.shown);
    expect(backend.banners, [AdPlacement.shell]);
    expect(backend.interstitials, [AdPlacement.navigation]);
    expect(backend.rewarded, [AdPlacement.rewarded]);

    await service.activateTestMembership();
    await pumpEventQueue();
    expect(container.read(showAdsProvider), isFalse);
    expect(await ads.loadBanner(AdPlacement.shell), AdOutcome.blocked);
    expect(
      await ads.showInterstitial(AdPlacement.navigation),
      AdOutcome.blocked,
    );
    expect(await ads.showRewarded(AdPlacement.rewarded), AdOutcome.blocked);
    expect(backend.banners, [AdPlacement.shell]);
    expect(backend.interstitials, [AdPlacement.navigation]);
    expect(backend.rewarded, [AdPlacement.rewarded]);

    await service.resetTestMembership();
    await pumpEventQueue();
    expect(container.read(showAdsProvider), isTrue);
    expect(
      await ads.showInterstitial(AdPlacement.navigation),
      AdOutcome.shown,
    );
    expect(await ads.showRewarded(AdPlacement.rewarded), AdOutcome.shown);
    expect(backend.interstitials, [
      AdPlacement.navigation,
      AdPlacement.navigation,
    ]);
    expect(backend.rewarded, [AdPlacement.rewarded, AdPlacement.rewarded]);
  });

  testWidgets('premium olunca banner kalkar, sıfırlayınca yeniden yüklenebilir', (
    tester,
  ) async {
    final backend = _RecordingAdBackend();
    final storage = InMemoryKeyValueStorage();
    final service = FakeSubscriptionService(storage, exposeOfferings: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStorageProvider.overrideWithValue(storage),
          subscriptionServiceProvider.overrideWith((ref) {
            ref.onDispose(service.dispose);
            return service;
          }),
          adBackendProvider.overrideWithValue(backend),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AdBannerSlot()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(AdBannerSlot.bannerKey), findsOneWidget);
    expect(backend.banners, [AdPlacement.shell]);

    await service.activateTestMembership();
    await tester.pumpAndSettle();
    expect(find.byKey(AdBannerSlot.bannerKey), findsNothing);
    expect(backend.banners, [AdPlacement.shell]);
    expect(backend.released, [AdPlacement.shell]);

    await service.resetTestMembership();
    await tester.pumpAndSettle();
    expect(find.byKey(AdBannerSlot.bannerKey), findsOneWidget);
    expect(backend.banners, [AdPlacement.shell, AdPlacement.shell]);
  });
}

class _RecordingAdBackend implements AdBackend {
  final banners = <AdPlacement>[];
  final interstitials = <AdPlacement>[];
  final rewarded = <AdPlacement>[];
  final released = <AdPlacement>[];

  @override
  Future<bool> loadBanner(AdPlacement placement) async {
    banners.add(placement);
    return true;
  }

  @override
  Future<bool> showInterstitial(AdPlacement placement) async {
    interstitials.add(placement);
    return true;
  }

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    rewarded.add(placement);
    return true;
  }

  @override
  Future<void> releaseBanner(AdPlacement placement) async {
    released.add(placement);
  }
}
