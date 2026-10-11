import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/services/ads/ad_backend.dart';
import '../providers/premium_providers.dart';

/// Alt gezinmenin üstündeki banner.
///
/// Yükleme kare sonrasına bırakılır; böylece geçiş sırasında reklam
/// sağlayıcısı derleme aşamasında arayüzü yenilemez. Premium açıkken
/// banner ağaçtan çıkar ve yükleme çağrısı yapılmaz.
class AdBannerSlot extends ConsumerStatefulWidget {
  const AdBannerSlot({super.key});

  static const bannerKey = ValueKey('ad-banner');

  @override
  ConsumerState<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends ConsumerState<AdBannerSlot> {
  var _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final coordinator = ref.read(premiumAdCoordinatorProvider);
    if (!ref.read(showAdsProvider)) {
      await coordinator.releaseBanner(AdPlacement.shell);
      if (mounted) setState(() => _shown = false);
      return;
    }
    final outcome = await coordinator.loadBanner(AdPlacement.shell);
    if (!mounted) return;
    setState(() => _shown = outcome == AdOutcome.shown);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(showAdsProvider, (previous, next) {
      if (previous == next) return;
      _refresh();
    });
    if (!_shown) return const SizedBox.shrink();
    final colors = context.colors;
    return Material(
      key: AdBannerSlot.bannerKey,
      color: colors.surfaceContainerHighest,
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: Center(
          child: Text(
            context.l10n.adBannerLabel,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
