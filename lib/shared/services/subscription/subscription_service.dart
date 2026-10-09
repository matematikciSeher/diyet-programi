import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import '../../models/subscription_status.dart';

/// RevenueCat `PackageType` karşılığı.
enum SubscriptionPeriod { weekly, monthly, annual, lifetime }

/// Mağazada satılan bir paket (aylık / yıllık vb.).
///
/// RevenueCat `Package` → [id] (`identifier`), `storeProduct.identifier` →
/// [productId], `storeProduct.priceString` → [priceString] olarak eşlenir.
class SubscriptionPackage extends Equatable {
  const SubscriptionPackage({
    required this.id,
    required this.productId,
    required this.period,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.trialDays,
  });

  final String id;
  final String productId;
  final SubscriptionPeriod period;

  /// İndirim hesabı için sayısal fiyat; kullanıcıya [priceString] gösterilir.
  final double price;
  final String priceString;
  final String currencyCode;

  /// Ücretsiz deneme süresi (mağazada tanımlı intro offer).
  final int? trialDays;

  /// Aylık fiyat karşılığı; yıllık paketteki tasarrufu göstermek için.
  double? get monthlyPrice => switch (period) {
    SubscriptionPeriod.weekly => price * 52 / 12,
    SubscriptionPeriod.monthly => price,
    SubscriptionPeriod.annual => price / 12,
    SubscriptionPeriod.lifetime => null,
  };

  @override
  List<Object?> get props => [
    id,
    productId,
    period,
    price,
    priceString,
    currencyCode,
    trialDays,
  ];
}

/// RevenueCat `Offering`: panelden yönetilen, paywall'da gösterilecek paket
/// grubu. Fiyat/paket değişikliği uygulama güncellemesi gerektirmez.
class SubscriptionOffering extends Equatable {
  const SubscriptionOffering({required this.id, required this.packages});

  final String id;
  final List<SubscriptionPackage> packages;

  SubscriptionPackage? byPeriod(SubscriptionPeriod period) =>
      packages.where((p) => p.period == period).firstOrNull;

  @override
  List<Object?> get props => [id, packages];
}

/// Premium üyelik soyutlaması. Hedef: `RevenueCatSubscriptionService`
/// (purchases_flutter). Public SDK anahtarı `AppConfig`'ten okunur.
///
/// Uygulama kullanıcısı (Firebase uid) RevenueCat `appUserID` olarak
/// kullanılır; böylece abonelik cihazlar arasında taşınır.
abstract interface class SubscriptionService {
  Future<void> initialize({String? appUserId});
  Stream<SubscriptionStatus> watchStatus();
  Future<SubscriptionStatus> getStatus();

  /// Paneldeki "current" offering; mağaza kullanılamıyorsa `null`.
  Future<SubscriptionOffering?> getCurrentOffering();

  /// Kullanıcı vazgeçerse `PurchaseException(userCancelled: true)` fırlatır.
  Future<SubscriptionStatus> purchase(SubscriptionPackage package);

  /// Mağaza politikaları gereği "Satın alımları geri yükle" zorunludur.
  Future<SubscriptionStatus> restorePurchases();

  Future<void> logIn(String appUserId);

  /// Anonim kullanıcıda no-op olmalıdır (RevenueCat bu durumda hata verir).
  Future<void> logOut();
}

/// RevenueCat panelindeki entitlement kimlikleri.
abstract final class Entitlements {
  static const premium = 'premium';
}

/// Ödeme sistemi eklenene kadar herkes ücretsiz katmandadır.
class FreeTierSubscriptionService implements SubscriptionService {
  const FreeTierSubscriptionService();

  @override
  Future<void> initialize({String? appUserId}) async {}

  @override
  Stream<SubscriptionStatus> watchStatus() =>
      Stream.value(SubscriptionStatus.free);

  @override
  Future<SubscriptionStatus> getStatus() async => SubscriptionStatus.free;

  @override
  Future<SubscriptionOffering?> getCurrentOffering() async => null;

  @override
  Future<SubscriptionStatus> purchase(SubscriptionPackage package) =>
      throw const ServiceUnavailableException('purchases_not_configured');

  @override
  Future<SubscriptionStatus> restorePurchases() async =>
      SubscriptionStatus.free;

  @override
  Future<void> logIn(String appUserId) async {}

  @override
  Future<void> logOut() async {}
}
