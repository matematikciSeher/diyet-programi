import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Selamlama, günün motivasyon cümlesi ve profil kısayolu.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.now,
    required this.onProfileTap,
    this.name,
  });

  final DateTime now;
  final String? name;
  final VoidCallback onProfileTap;

  static const _motivationCount = 7;

  /// `dashboardGreeting` select anahtarı.
  static String periodOf(DateTime time) => switch (time.hour) {
    >= 5 && < 12 => 'morning',
    >= 12 && < 18 => 'afternoon',
    _ => 'evening',
  };

  static int motivationIndexOf(DateTime time) =>
      DateTime(
        time.year,
        time.month,
        time.day,
      ).difference(DateTime(time.year)).inDays %
      _motivationCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final period = periodOf(now);
    final trimmed = name?.trim();
    final hasName = trimmed != null && trimmed.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  hasName
                      ? l10n.dashboardGreetingNamed(period, trimmed)
                      : l10n.dashboardGreeting(period),
                  style: context.textStyles.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.gapXs,
              Text(
                l10n.dashboardMotivation('${motivationIndexOf(now)}'),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        Tooltip(
          message: l10n.navProfile,
          child: Semantics(
            button: true,
            label: l10n.navProfile,
            excludeSemantics: true,
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: AppSizes.minTouchTarget / 2,
                backgroundColor: context.colors.primaryContainer,
                foregroundColor: context.colors.onPrimaryContainer,
                child: hasName
                    ? Text(
                        trimmed.characters.first.toUpperCase(),
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.colors.onPrimaryContainer,
                        ),
                      )
                    : const Icon(Icons.person_outline_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
