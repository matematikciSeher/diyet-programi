/// Reklamın istendiği yer. Ödüllü reklam bir özellik kilidini açmaz.
enum AdPlacement { shell, navigation, rewarded }

enum AdOutcome { shown, blocked, noFill }

/// Ağ reklamı yükleyen uyarlanabilir uç. Premium kararı burada verilmez.
abstract interface class AdBackend {
  Future<bool> loadBanner(AdPlacement placement);
  Future<bool> showInterstitial(AdPlacement placement);
  Future<bool> showRewarded(AdPlacement placement);
  Future<void> releaseBanner(AdPlacement placement);
}

/// Reklam ağı bağlı değilken dolum döndürmez. Çağrı yine de yapılır;
/// böylece ücretsiz kullanıcının mevcut (görünmeyen) davranışı değişmez.
class NoFillAdBackend implements AdBackend {
  const NoFillAdBackend();

  @override
  Future<bool> loadBanner(AdPlacement placement) async => false;

  @override
  Future<bool> showInterstitial(AdPlacement placement) async => false;

  @override
  Future<bool> showRewarded(AdPlacement placement) async => false;

  @override
  Future<void> releaseBanner(AdPlacement placement) async {}
}
