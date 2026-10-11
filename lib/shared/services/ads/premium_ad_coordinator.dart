import 'ad_backend.dart';

/// Banner, geçiş ve ödüllü reklamların tek giriş noktası.
///
/// Premium açıkken yükleme ve gösterme çağrıları [AdBackend]'e ulaşmaz.
/// Widget'ı gizlemek yeterli değildir. Ödüllü reklam dönüşü bir özelliği
/// açmaz; mevcut kilit kuralları entitlement üzerinden kalır.
class PremiumAdCoordinator {
  const PremiumAdCoordinator({
    required bool Function() adsAllowed,
    required AdBackend backend,
  }) : _adsAllowed = adsAllowed,
       _backend = backend;

  final bool Function() _adsAllowed;
  final AdBackend _backend;

  Future<AdOutcome> loadBanner(AdPlacement placement) async {
    if (!_adsAllowed()) return AdOutcome.blocked;
    final filled = await _backend.loadBanner(placement);
    return filled ? AdOutcome.shown : AdOutcome.noFill;
  }

  Future<AdOutcome> showInterstitial(AdPlacement placement) async {
    if (!_adsAllowed()) return AdOutcome.blocked;
    final filled = await _backend.showInterstitial(placement);
    return filled ? AdOutcome.shown : AdOutcome.noFill;
  }

  Future<AdOutcome> showRewarded(AdPlacement placement) async {
    if (!_adsAllowed()) return AdOutcome.blocked;
    final filled = await _backend.showRewarded(placement);
    return filled ? AdOutcome.shown : AdOutcome.noFill;
  }

  Future<void> releaseBanner(AdPlacement placement) =>
      _backend.releaseBanner(placement);
}
