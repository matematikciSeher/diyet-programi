import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/subscription_status.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../../shared/services/subscription/subscription_service.dart';
import '../../domain/models/app_feature.dart';
import '../app_feature_labels.dart';
import '../providers/premium_providers.dart';

/// Premium satış ekranı. Paketler RevenueCat "current" offering'inden gelir;
/// fiyatlar mağazanın yerelleştirdiği metinle gösterilir.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key, this.source});

  /// Paywall'u açan kilitli özellik (varsa başlıkta vurgulanır).
  final AppFeature? source;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  SubscriptionPackage? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          AnalyticsEvents.paywallViewed,
          parameters: {'source': widget.source?.name ?? 'direct'},
        )
        .ignore();
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          AnalyticsEvents.subscriptionScreenOpened,
          parameters: {'source': widget.source?.name ?? 'direct'},
        )
        .ignore();
  }

  Future<void> _run(
    Future<Result<SubscriptionStatus>> Function(SubscriptionActions) action, {
    required bool isRestore,
  }) async {
    setState(() => _busy = true);
    final result = await action(ref.read(subscriptionActionsProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = context.l10n;
    switch (result) {
      case Success(:final value)
          when value.hasEntitlement(Entitlements.premium):
        context.showSnack(
          isRestore ? l10n.paywallRestored : l10n.paywallPurchaseSuccess,
        );
      case Success():
        context.showSnack(l10n.paywallNothingToRestore);
      case Err(failure: PurchaseCancelledFailure()):
        break;
      case Err(failure: NotImplementedFailure()):
        context.showSnack(l10n.errorPurchaseUnavailable);
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  void _purchase(SubscriptionPackage package) => _run(
    (actions) => actions.purchase(package, source: widget.source),
    isRestore: false,
  );

  void _restore() => _run((actions) => actions.restore(), isRestore: true);

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(subscriptionStatusProvider).value;
    final offering = ref.watch(currentOfferingProvider);

    final Widget body;
    if (status != null && status.hasEntitlement(Entitlements.premium)) {
      body = _ActiveView(status: status, onDone: _close);
    } else {
      body = AsyncValueView(
        value: offering,
        onRetry: () => ref.invalidate(currentOfferingProvider),
        data: (offering) {
          final packages = offering?.packages ?? const [];
          if (packages.isEmpty) {
            return MessageView(
              icon: Icons.storefront_outlined,
              title: l10n.errorPurchaseUnavailable,
              actionLabel: l10n.paywallRestore,
              onAction: _busy ? null : _restore,
            );
          }
          final selected = packages.contains(_selected)
              ? _selected!
              : offering!.byPeriod(SubscriptionPeriod.annual) ?? packages.first;
          return _OfferView(
            source: widget.source,
            packages: packages,
            selected: selected,
            busy: _busy,
            onSelect: (p) => setState(() => _selected = p),
            onPurchase: () => _purchase(selected),
            onRestore: _restore,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(onPressed: _close),
        title: Text(l10n.featurePremium),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _OfferView extends StatelessWidget {
  const _OfferView({
    required this.source,
    required this.packages,
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
  });

  final AppFeature? source;
  final List<SubscriptionPackage> packages;
  final SubscriptionPackage selected;
  final bool busy;
  final ValueChanged<SubscriptionPackage> onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthly = packages
        .where((p) => p.period == SubscriptionPeriod.monthly)
        .firstOrNull;
    final features = [
      ?source,
      ...AppFeature.premiumFeatures.where((f) => f != source),
    ];
    final trialDays = selected.trialDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 56,
              color: context.colors.primary,
            ),
            AppSpacing.gapLg,
            Text(
              source == null
                  ? l10n.paywallTitle
                  : l10n.premiumLockedTitle(source!.label(l10n)),
              style: context.textStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapSm,
            Text(
              l10n.paywallSubtitle,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            for (final feature in features)
              _BenefitRow(feature: feature, highlighted: feature == source),
            AppSpacing.gapXl,
            for (final package in packages) ...[
              _PackageTile(
                package: package,
                monthlyReference: monthly,
                selected: package == selected,
                onTap: busy ? null : () => onSelect(package),
              ),
              AppSpacing.gapMd,
            ],
            AppSpacing.gapSm,
            AppButton(
              label: trialDays != null
                  ? l10n.paywallStartTrial(trialDays)
                  : l10n.paywallSubscribe,
              isLoading: busy,
              onPressed: onPurchase,
            ),
            AppSpacing.gapSm,
            Center(
              child: AppButton.text(
                label: l10n.paywallRestore,
                onPressed: busy ? null : onRestore,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              trialDays != null
                  ? l10n.paywallTrialLegal(trialDays, selected.priceString)
                  : l10n.paywallLegal,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.feature, required this.highlighted});

  final AppFeature feature;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final description = feature.description(l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            feature.icon,
            color: highlighted ? context.colors.primary : null,
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label(l10n),
                  style: context.textStyles.titleSmall?.copyWith(
                    color: highlighted ? context.colors.primary : null,
                  ),
                ),
                if (description != null)
                  Text(
                    description,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.monthlyReference,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPackage package;

  /// Tasarruf yüzdesi bu pakete göre hesaplanır.
  final SubscriptionPackage? monthlyReference;
  final bool selected;
  final VoidCallback? onTap;

  int? get _savingsPercent {
    final reference = monthlyReference?.price;
    final perMonth = package.monthlyPrice;
    if (reference == null || perMonth == null || reference <= 0) return null;
    if (package.period == SubscriptionPeriod.monthly) return null;
    final percent = ((1 - perMonth / reference) * 100).round();
    return percent > 0 ? percent : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final savings = _savingsPercent;
    final perMonth = package.monthlyPrice;
    final showPerMonth =
        perMonth != null && package.period != SubscriptionPeriod.monthly;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            package.period.label(l10n),
                            style: context.textStyles.titleMedium,
                          ),
                          if (savings != null)
                            _Tag(label: l10n.paywallSavings(savings)),
                        ],
                      ),
                      if (showPerMonth)
                        Text(
                          l10n.paywallPerMonth(
                            _currency(context, perMonth, package.currencyCode),
                          ),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  package.priceString,
                  style: context.textStyles.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _currency(BuildContext context, double value, String code) =>
      NumberFormat.simpleCurrency(
        locale: Localizations.localeOf(context).toLanguageTag(),
        name: code,
      ).format(value);
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.tertiary,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onTertiary,
          ),
        ),
      ),
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.status, required this.onDone});

  final SubscriptionStatus status;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expiresAt = status.expiresAt;
    final String? message;
    if (expiresAt == null) {
      message = null;
    } else if (status.isInTrial) {
      message = l10n.paywallTrialUntil(AppFormat.date(context, expiresAt));
    } else if (status.willRenew) {
      message = l10n.paywallRenewsOn(AppFormat.date(context, expiresAt));
    } else {
      message = l10n.paywallActiveUntil(AppFormat.date(context, expiresAt));
    }
    return MessageView(
      icon: Icons.workspace_premium_rounded,
      title: l10n.paywallActiveTitle,
      message: message,
      actionLabel: l10n.actionContinue,
      onAction: onDone,
    );
  }
}
