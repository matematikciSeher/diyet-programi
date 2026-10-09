import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';

/// Başlangıç, güncel, hedef, verilen ve kalan kilo özeti.
class WeightGoalCard extends StatelessWidget {
  const WeightGoalCard({
    super.key,
    required this.weight,
    required this.onAddWeight,
  });

  final WeightProgress? weight;
  final VoidCallback onAddWeight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weight = this.weight;
    final color = context.colors.primary;

    if (weight == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardTitle(
              icon: Icons.flag_outlined,
              title: l10n.progressGoalTitle,
              color: color,
            ),
            AppSpacing.gapMd,
            Text(
              l10n.progressNoWeightTitle,
              style: context.textStyles.titleMedium,
            ),
            AppSpacing.gapXs,
            Text(
              l10n.progressNoWeightMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapLg,
            FilledButton.tonalIcon(
              onPressed: onAddWeight,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.progressAddWeight),
            ),
          ],
        ),
      );
    }

    final fraction = weight.fraction;
    final achievedLabel = weight.direction == WeightDirection.lose
        ? l10n.progressLostWeight
        : l10n.progressGainedWeight;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.flag_outlined,
            title: l10n.progressGoalTitle,
            color: color,
            trailing: TextButton.icon(
              onPressed: onAddWeight,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.progressAddWeight),
            ),
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              _Stat(
                label: l10n.progressStartWeight,
                value: ProgressFormat.kg(context, weight.startKg),
              ),
              _Stat(
                label: l10n.progressCurrentWeight,
                value: ProgressFormat.kg(context, weight.currentKg),
                emphasized: true,
              ),
              _Stat(
                label: l10n.progressTargetWeight,
                value: weight.targetKg == null
                    ? l10n.progressNoValue
                    : ProgressFormat.kg(context, weight.targetKg!),
              ),
            ],
          ),
          AppSpacing.gapLg,
          if (fraction != null) ...[
            Semantics(
              label: l10n.progressGoalPercent('${(fraction * 100).round()}'),
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: AppRadius.smAll,
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 10,
                  color: weight.reached
                      ? context.nutritionColors.success
                      : color,
                ),
              ),
            ),
            AppSpacing.gapSm,
            Text(
              weight.reached
                  ? l10n.progressGoalReached
                  : l10n.progressGoalPercent('${(fraction * 100).round()}'),
              style: context.textStyles.labelLarge?.copyWith(
                color: weight.reached
                    ? context.nutritionColors.success
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ] else
            Text(
              l10n.progressNoTarget,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: _Highlight(
                  icon: weight.direction == WeightDirection.lose
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  label: achievedLabel,
                  value: ProgressFormat.kg(context, weight.achievedKg),
                  color: weight.achievedKg >= 0
                      ? context.nutritionColors.success
                      : context.nutritionColors.warning,
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: _Highlight(
                  icon: Icons.outlined_flag_rounded,
                  label: l10n.progressRemainingWeight,
                  value: weight.remainingKg == null
                      ? l10n.progressNoValue
                      : ProgressFormat.kg(context, weight.remainingKg!),
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$label $value',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              label,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXs,
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style:
                    (emphasized
                            ? context.textStyles.titleLarge
                            : context.textStyles.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: AppRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: color, size: AppSizes.iconMd),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.textStyles.labelMedium),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
