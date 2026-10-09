import 'dart:async';
import 'dart:convert';

import '../../../core/constants/storage_keys.dart';
import '../../models/enums.dart';
import '../../models/subscription_status.dart';
import '../local_storage/key_value_storage.dart';
import 'subscription_service.dart';

/// Geliştirme ortamı için mağaza simülasyonu (`USE_FAKE_SERVICES=true`).
///
/// RevenueCat ile aynı davranır: satın alma entitlement'ı aktifleştirir,
/// durum kullanıcıya göre saklanır ve geri yüklenebilir. Gerçek ödeme almaz.
class FakeSubscriptionService implements SubscriptionService {
  FakeSubscriptionService(this._storage, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _anonymousUserId = r'$anonymous';

  static const offering = SubscriptionOffering(
    id: 'default',
    packages: [
      SubscriptionPackage(
        id: r'$rc_monthly',
        productId: 'premium_monthly',
        period: SubscriptionPeriod.monthly,
        price: 9.99,
        priceString: '₺9,99',
        currencyCode: 'TRY',
      ),
      SubscriptionPackage(
        id: r'$rc_annual',
        productId: 'premium_annual',
        period: SubscriptionPeriod.annual,
        price: 99.99,
        priceString: '₺99,99',
        currencyCode: 'TRY',
        trialDays: 7,
      ),
    ],
  );

  final KeyValueStorage _storage;
  final DateTime Function() _clock;
  final _changes = StreamController<SubscriptionStatus>.broadcast();
  String _appUserId = _anonymousUserId;

  String get _key => StorageKeys.fakeSubscription(_appUserId);

  @override
  Future<void> initialize({String? appUserId}) async {
    _appUserId = appUserId ?? _anonymousUserId;
    _emit();
  }

  @override
  Stream<SubscriptionStatus> watchStatus() async* {
    yield _read();
    yield* _changes.stream;
  }

  @override
  Future<SubscriptionStatus> getStatus() async => _read();

  @override
  Future<SubscriptionOffering?> getCurrentOffering() async => offering;

  @override
  Future<SubscriptionStatus> purchase(SubscriptionPackage package) async {
    final now = _clock();
    final trial = package.trialDays;
    final expiresAt = trial != null
        ? now.add(Duration(days: trial))
        : switch (package.period) {
            SubscriptionPeriod.weekly => now.add(const Duration(days: 7)),
            SubscriptionPeriod.monthly => now.add(const Duration(days: 30)),
            SubscriptionPeriod.annual => now.add(const Duration(days: 365)),
            SubscriptionPeriod.lifetime => null,
          };
    await _storage.setString(
      _key,
      jsonEncode({
        'productId': package.productId,
        'expiresAt': expiresAt?.toIso8601String(),
        'trial': trial != null,
        'lifetime': package.period == SubscriptionPeriod.lifetime,
      }),
    );
    return _emit();
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async => _emit();

  @override
  Future<void> logIn(String appUserId) async {
    if (appUserId == _appUserId) return;
    _appUserId = appUserId;
    _emit();
  }

  @override
  Future<void> logOut() async {
    _appUserId = _anonymousUserId;
    _emit();
  }

  /// Geliştirmede ücretsiz katmanı yeniden denemek için.
  Future<void> reset() async {
    await _storage.remove(_key);
    _emit();
  }

  Future<void> dispose() => _changes.close();

  SubscriptionStatus _emit() {
    final status = _read();
    if (!_changes.isClosed) _changes.add(status);
    return status;
  }

  SubscriptionStatus _read() {
    final raw = _storage.getString(_key);
    if (raw == null) return SubscriptionStatus.free;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    final lifetime = json['lifetime'] == true;
    if (!lifetime && (expiresAt == null || !expiresAt.isAfter(_clock()))) {
      return SubscriptionStatus.free;
    }
    return SubscriptionStatus(
      tier: SubscriptionTier.premium,
      activeEntitlements: const {Entitlements.premium},
      expiresAt: expiresAt,
      willRenew: !lifetime,
      isInTrial: json['trial'] == true,
      productId: json['productId'] as String?,
    );
  }
}
