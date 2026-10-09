import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';

class WeeklyAverageCard extends StatelessWidget {
  const WeeklyAverageCard({
    super.key,
    required this.average,
    this.direction = WeightDirection.lose,
  });

  final WeeklyAverage average;

  /// Değişimin olumlu mu olumsuz mu renklendirileceğini belirler.
  final WeightDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final none = l10n.progressNoValue;
    final change = average.weightChangeKg;
    final favorable =
        change != null &&
        (direction == WeightDirection.lose ? change <= 0 : change >= 0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.date_range_rounded,
            title: l10n.progressWeeklyTitle,
            color: context.nutritionColors.calories,
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _Metric(
                label: l10n.progressWeeklyWeight,
                value: average.weightKg == null
                    ? none
                    : ProgressFormat.kg(context, average.weightKg!),
                detail: change == null
                    ? null
                    : l10n.progressWeeklyVsLast(
                        ProgressFormat.signed(context, change),
                      ),
                detailColor: favorable
                    ? context.nutritionColors.success
                    : context.nutritionColors.warning,
              ),
              _Metric(
                label: l10n.progressWeeklyCalories,
                value: average.calories == null
                    ? none
                    : l10n.progressWeeklyKcal(
                        AppFormat.integer(context, average.calories!),
                      ),
              ),
              _Metric(
                label: l10n.progressWeeklyScore,
                value: average.score == null
                    ? none
                    : '${average.score!.round()} ${l10n.scoreOutOf}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.detail,
    this.detailColor,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? detailColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Semantics(
        label: [label, value, ?detail].join(', '),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail != null)
              Text(
                detail!,
                style: context.textStyles.labelSmall?.copyWith(
                  color: detailColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
