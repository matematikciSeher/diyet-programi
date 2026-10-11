import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/subscription_status.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../../shared/services/subscription/subscription_service.dart';
import '../../domain/models/app_feature.dart';
import '../app_feature_labels.dart';

/// Premium ekranı. Bu sürümde mağaza fiyatı veya satın alma yoktur.
/// Geliştirme derlemesinde test üyeliği yerel olarak açılıp kapatılır.
class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key, this.source});

  /// Paywall'u açan kilitli özellik (paket avantajıysa başlıkta vurgulanır).
  final AppFeature? source;

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
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

  bool get _canTestMembership =>
      kDebugMode &&
      ref.read(subscriptionServiceProvider) is TestMembershipControls;

  AppFeature? get _highlighted {
    final source = widget.source;
    if (source == null || !AppFeature.packageBenefits.contains(source)) {
      return null;
    }
    return source;
  }

  Future<void> _startTestMembership() async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.testPremiumConfirmTitle,
      message: l10n.testPremiumConfirmMessage,
      confirmLabel: l10n.testPremiumConfirmAction,
    );
    if (!confirmed || !mounted) return;
    final service = ref.read(subscriptionServiceProvider);
    if (service is! TestMembershipControls) return;
    final controls = service as TestMembershipControls;
    setState(() => _busy = true);
    final status = await controls.activateTestMembership();
    if (!mounted) return;
    setState(() => _busy = false);
    if (status.isTestGrant) context.showSnack(l10n.testPremiumStarted);
  }

  Future<void> _resetTestMembership() async {
    final service = ref.read(subscriptionServiceProvider);
    if (service is! TestMembershipControls) return;
    await (service as TestMembershipControls).resetTestMembership();
    if (!mounted) return;
    context.showSnack(context.l10n.testPremiumResetDone);
  }

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
    final premium = status?.hasEntitlement(Entitlements.premium) ?? false;

    final Widget body;
    if (premium && status != null && status.isTestGrant) {
      body = _TestGrantView(
        onDone: _close,
        onReset: kDebugMode ? _resetTestMembership : null,
      );
    } else if (premium && status != null) {
      body = _ActiveView(status: status, onDone: _close);
    } else {
      body = _BenefitsView(
        highlighted: _highlighted,
        testPanel: _canTestMembership
            ? _TestMembershipPanel(busy: _busy, onStart: _startTestMembership)
            : null,
        unavailableNote: _canTestMembership ? null : l10n.paywallPurchaseLater,
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

class _BenefitsView extends StatelessWidget {
  const _BenefitsView({
    required this.highlighted,
    required this.testPanel,
    required this.unavailableNote,
  });

  final AppFeature? highlighted;
  final Widget? testPanel;
  final String? unavailableNote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              highlighted == null
                  ? l10n.paywallTitle
                  : l10n.premiumLockedTitle(highlighted!.label(l10n)),
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
            for (final feature in AppFeature.packageBenefits)
              _BenefitRow(
                feature: feature,
                highlighted: feature == highlighted,
              ),
            if (unavailableNote != null) ...[
              AppSpacing.gapXl,
              Text(
                unavailableNote!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (testPanel != null) ...[
              AppSpacing.gapXl,
              const Divider(),
              AppSpacing.gapLg,
              testPanel!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TestMembershipPanel extends StatelessWidget {
  const _TestMembershipPanel({required this.busy, required this.onStart});

  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.testPremiumSectionTitle,
          style: context.textStyles.titleSmall,
        ),
        AppSpacing.gapXs,
        Text(
          l10n.testPremiumSectionMessage,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapMd,
        AppButton.secondary(
          label: l10n.testPremiumStart,
          icon: Icons.science_outlined,
          isLoading: busy,
          onPressed: busy ? null : onStart,
        ),
      ],
    );
  }
}

class _TestGrantView extends StatelessWidget {
  const _TestGrantView({required this.onDone, required this.onReset});

  final VoidCallback onDone;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: ResponsiveCenter(
              child: Column(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 56,
                    color: context.colors.primary,
                  ),
                  AppSpacing.gapLg,
                  Text(
                    l10n.testPremiumActiveTitle,
                    style: context.textStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    l10n.testPremiumActiveMessage,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapXl,
                  for (final feature in AppFeature.packageBenefits)
                    _BenefitRow(feature: feature, highlighted: false),
                  AppSpacing.gapXl,
                  AppButton(label: l10n.actionContinue, onPressed: onDone),
                ],
              ),
            ),
          ),
        ),
        if (onReset != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: AppButton.text(
              label: l10n.testPremiumReset,
              icon: Icons.bug_report_outlined,
              onPressed: onReset,
            ),
          ),
      ],
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
