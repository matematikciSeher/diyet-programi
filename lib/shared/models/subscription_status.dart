import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Ödeme sağlayıcısından (RevenueCat) bağımsız abonelik durumu.
///
/// RevenueCat `CustomerInfo.entitlements.active` → [activeEntitlements],
/// `EntitlementInfo.expirationDate` → [expiresAt],
/// `EntitlementInfo.periodType == trial` → [isInTrial] olarak eşlenir.
class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.tier,
    this.activeEntitlements = const {},
    this.expiresAt,
    this.willRenew = false,
    this.isInTrial = false,
    this.productId,
    this.managementUrl,
  });

  static const free = SubscriptionStatus(tier: SubscriptionTier.free);

  final SubscriptionTier tier;
  final Set<String> activeEntitlements;
  final DateTime? expiresAt;
  final bool willRenew;
  final bool isInTrial;
  final String? productId;

  /// Mağazanın abonelik yönetim sayfası (iptal / plan değişikliği).
  final String? managementUrl;

  bool get isPremium => tier == SubscriptionTier.premium;

  bool hasEntitlement(String id) => activeEntitlements.contains(id);

  @override
  List<Object?> get props => [
    tier,
    activeEntitlements,
    expiresAt,
    willRenew,
    isInTrial,
    productId,
    managementUrl,
  ];
}
