import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/health_link_providers.dart';

bool healthUiSupported(TargetPlatform platform) =>
    platform == TargetPlatform.android || platform == TargetPlatform.iOS;

class HealthDataSection extends ConsumerStatefulWidget {
  const HealthDataSection({super.key});

  @override
  ConsumerState<HealthDataSection> createState() => _HealthDataSectionState();
}

class _HealthDataSectionState extends ConsumerState<HealthDataSection> {
  var _busy = false;

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final outcome = await ref.read(healthLinkControllerProvider).connect();
      if (!mounted) return;
      final l10n = context.l10n;
      context.showSnack(switch (outcome) {
        HealthLinkOutcome.linked => l10n.activityConnectGranted,
        HealthLinkOutcome.denied => l10n.healthPermissionDenied,
        HealthLinkOutcome.unavailable => l10n.healthUnavailableBody,
      });
      ref
        ..invalidate(todayActivityProvider)
        ..invalidate(weeklyActivityProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final platform = Theme.of(context).platform;
    final supported = healthUiSupported(platform);
    final linked = supported && ref.watch(healthLinkedProvider);
    final status = linked ? l10n.healthStatusLinked : l10n.healthStatusNotLinked;
    final platformName = switch (platform) {
      TargetPlatform.iOS => l10n.healthAppleName,
      TargetPlatform.android => l10n.healthConnectName,
      _ => null,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_outline_rounded, color: context.colors.primary),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  l10n.healthDataTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          if (!supported)
            Text(
              l10n.healthUnavailableBody,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(platformName!),
              trailing: Text(
                status,
                style: context.textStyles.labelLarge?.copyWith(
                  color: linked
                      ? context.colors.primary
                      : context.colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              l10n.healthPrivacyNote,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLg,
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _connect,
              icon: const Icon(Icons.link_rounded),
              label: Text(l10n.healthConnectAction),
            ),
          ],
        ],
      ),
    );
  }
}
