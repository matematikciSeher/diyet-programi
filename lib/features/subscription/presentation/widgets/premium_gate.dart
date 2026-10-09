import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/app_feature.dart';
import '../app_feature_labels.dart';
import '../providers/premium_providers.dart';

void openPaywall(BuildContext context, {AppFeature? feature}) =>
    context.push(AppRoutes.paywallPath(feature: feature));

/// Erişim varsa [child], yoksa [fallback] (varsayılan: tam sayfa kilit
/// ekranı) gösterir. Satın alma sonrası kendiliğinden açılır.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  final AppFeature feature;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(featureAccessProvider(feature))) return child;
    return fallback ?? PremiumLockedPage(feature: feature);
  }
}

class PremiumLockedPage extends ConsumerStatefulWidget {
  const PremiumLockedPage({super.key, required this.feature});

  final AppFeature feature;

  @override
  ConsumerState<PremiumLockedPage> createState() => _PremiumLockedPageState();
}

class _PremiumLockedPageState extends ConsumerState<PremiumLockedPage> {
  @override
  void initState() {
    super.initState();
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          AnalyticsEvents.premiumGateShown,
          parameters: {'feature': widget.feature.name},
        )
        .ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feature = widget.feature;
    return Scaffold(
      appBar: AppBar(title: Text(feature.label(l10n))),
      body: SafeArea(
        child: MessageView(
          icon: feature.icon,
          title: l10n.premiumLockedTitle(feature.label(l10n)),
          message: feature.description(l10n),
          actionLabel: l10n.premiumUnlockAction,
          onAction: () => openPaywall(context, feature: feature),
        ),
      ),
    );
  }
}

/// Sayfa içindeki bir kartın yerine geçen kilitli önizleme.
class PremiumLockedCard extends StatelessWidget {
  const PremiumLockedCard({super.key, required this.feature, this.title});

  final AppFeature feature;

  /// Kilitlenen kartın kendi başlığı; verilmezse özellik adı kullanılır.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final description = feature.description(l10n);
    return AppCard(
      onTap: () => openPaywall(context, feature: feature),
      child: Row(
        children: [
          Icon(feature.icon, color: context.colors.primary),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? feature.label(l10n),
                  style: context.textStyles.titleSmall,
                ),
                if (description != null) ...[
                  AppSpacing.gapXs,
                  Text(
                    description,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.gapMd,
          const PremiumBadge(),
        ],
      ),
    );
  }
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.compact = false});

  /// Yalnızca ikon; dar alanlar (hızlı eylemler vb.) için.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = Icon(
      Icons.workspace_premium_rounded,
      size: AppSizes.iconSm,
      color: colors.onTertiaryContainer,
    );
    return Semantics(
      label: context.l10n.featurePremium,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.tertiaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.xxs : AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: compact
              ? icon
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    AppSpacing.gapXs,
                    Text(
                      context.l10n.featurePremium,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
