import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/subscription_status.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../../shared/services/subscription/subscription_service.dart';
import '../../domain/models/app_feature.dart';

/// Özelliğe erişim kararının tek kaynağı. Durum henüz yüklenmediyse
/// premium özellikler kilitli kabul edilir.
final featureAccessProvider = Provider.family<bool, AppFeature>((ref, feature) {
  final entitlement = feature.requiredEntitlement;
  if (entitlement == null) return true;
  final status = ref.watch(subscriptionStatusProvider).value;
  return status?.hasEntitlement(entitlement) ?? false;
});

/// Reklam altyapısı eklendiğinde reklam gösterimi buna bağlanır.
final showAdsProvider = Provider<bool>(
  (ref) => !ref.watch(featureAccessProvider(AppFeature.adFree)),
);

final currentOfferingProvider = FutureProvider<SubscriptionOffering?>(
  (ref) => ref.watch(subscriptionServiceProvider).getCurrentOffering(),
);

final subscriptionActionsProvider = Provider<SubscriptionActions>(
  (ref) => SubscriptionActions(
    ref.watch(subscriptionServiceProvider),
    ref.watch(analyticsServiceProvider),
  ),
);

class SubscriptionActions {
  const SubscriptionActions(this._service, this._analytics);

  final SubscriptionService _service;
  final AnalyticsService _analytics;

  Future<Result<SubscriptionStatus>> purchase(
    SubscriptionPackage package, {
    AppFeature? source,
  }) => guard(() async {
    final status = await _service.purchase(package);
    await _analytics.logEvent(
      AnalyticsEvents.purchaseCompleted,
      parameters: {'product_id': package.productId, 'source': ?source?.name},
    );
    return status;
  });

  Future<Result<SubscriptionStatus>> restore() => guard(() async {
    final status = await _service.restorePurchases();
    await _analytics.logEvent(
      AnalyticsEvents.purchaseRestored,
      parameters: {'premium': status.hasEntitlement(Entitlements.premium)},
    );
    return status;
  });
}
