import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/subscription_status.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:diyet_programi/shared/services/subscription/subscription_service.dart';

const premiumStatus = SubscriptionStatus(
  tier: SubscriptionTier.premium,
  activeEntitlements: {Entitlements.premium},
);

/// Premium özellikleri test eden senaryolar için aktif abonelik.
final premiumOverride = subscriptionStatusProvider.overrideWith(
  (ref) => Stream.value(premiumStatus),
);
