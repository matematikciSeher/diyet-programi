import '../../../shared/models/subscription_status.dart';
import 'models/app_feature.dart';

/// Özelliğin açılıp açılmayacağı. Durum yoksa premium özellikler kapalıdır.
bool canAccessFeature(SubscriptionStatus? status, AppFeature feature) {
  final entitlement = feature.requiredEntitlement;
  if (entitlement == null) return true;
  return status?.hasEntitlement(entitlement) ?? false;
}
