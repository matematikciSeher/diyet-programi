import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../domain/models/progress_report.dart';

/// Kalori, protein ve su hedeflerinin tutturulduğu günlerin oranı.
class AdherenceCard extends StatelessWidget {
  const AdherenceCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.water,
  });

  final Adherence calories;
  final Adherence protein;
  final Adherence water;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.nutritionColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.task_alt_rounded,
            title: l10n.progressAdherenceTitle,
            color: colors.success,
          ),
          AppSpacing.gapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdherenceRing(
                label: l10n.progressAdherenceCalories,
                adherence: calories,
                color: colors.calories,
              ),
              _AdherenceRing(
                label: l10n.progressAdherenceProtein,
                adherence: protein,
                color: colors.protein,
              ),
              _AdherenceRing(
                label: l10n.progressAdherenceWater,
                adherence: water,
                color: colors.water,
              ),
            ],
          ),
          AppSpacing.gapLg,
          Text(
            l10n.progressAdherenceNote,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdherenceRing extends StatelessWidget {
  const _AdherenceRing({
    required this.label,
    required this.adherence,
    required this.color,
  });

  final String label;
  final Adherence adherence;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ratio = adherence.ratio;
    final percent = ratio == null
        ? l10n.progressNoValue
        : l10n.progressPercent('${(ratio * 100).round()}');
    final days = ratio == null
        ? l10n.progressAdherenceNoData
        : l10n.progressAdherenceDays(adherence.hitDays, adherence.trackedDays);

    return Expanded(
      child: Semantics(
        label: '$label: $percent, $days',
        excludeSemantics: true,
        child: Column(
          children: [
            ProgressRing(
              progress: ratio ?? 0,
              size: 72,
              strokeWidth: 7,
              color: color,
              center: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    percent,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.gapSm,
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.textStyles.labelMedium,
            ),
            Text(
              days,
              textAlign: TextAlign.center,
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
