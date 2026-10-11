import 'dart:async';
import 'dart:convert';

import '../../../core/constants/storage_keys.dart';
import '../../models/enums.dart';
import '../../models/subscription_status.dart';
import '../local_storage/key_value_storage.dart';
import 'subscription_service.dart';

/// Geliştirme ortamı için yerel abonelik simülasyonu.
///
/// [exposeOfferings] açıksa paywall sahte mağaza paketlerini gösterir.
/// [activateTestMembership] ise ödeme taklidi yapmaz: süre, yenileme ve
/// ürün kimliği olmayan, açıkça test amaçlı bir entitlement yazar.
/// Durum kullanıcıya göre yerel depoda kalır. Gerçek ödeme almaz.
class FakeSubscriptionService
    implements SubscriptionService, TestMembershipControls {
  FakeSubscriptionService(
    this._storage, {
    DateTime Function()? clock,
    this.exposeOfferings = true,
  }) : _clock = clock ?? DateTime.now;

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

  /// `false` iken mağaza paketi dönmez; test üyeliği yine çalışır.
  final bool exposeOfferings;
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
  Future<SubscriptionOffering?> getCurrentOffering() async =>
      exposeOfferings ? offering : null;

  @override
  Future<SubscriptionStatus> activateTestMembership() async {
    await _storage.setString(_key, jsonEncode({'test': true}));
    return _emit();
  }

  @override
  Future<void> resetTestMembership() => reset();

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
    final test = json['test'] == true;
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    final lifetime = json['lifetime'] == true;
    if (!test &&
        !lifetime &&
        (expiresAt == null || !expiresAt.isAfter(_clock()))) {
      return SubscriptionStatus.free;
    }
    return SubscriptionStatus(
      tier: SubscriptionTier.premium,
      activeEntitlements: const {Entitlements.premium},
      expiresAt: test ? null : expiresAt,
      willRenew: !test && !lifetime,
      isInTrial: !test && json['trial'] == true,
      productId: test ? null : json['productId'] as String?,
      isTestGrant: test,
    );
  }
}
