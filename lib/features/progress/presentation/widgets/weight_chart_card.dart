import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';
import 'weight_chart.dart';

class WeightChartCard extends StatelessWidget {
  const WeightChartCard({
    super.key,
    required this.points,
    required this.onShowHistory,
    this.targetKg,
  });

  final List<WeightPoint> points;
  final double? targetKg;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String kg(double v) => ProgressFormat.kg(context, v);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.show_chart_rounded,
            title: l10n.progressChartTitle,
            color: context.colors.primary,
            trailing: TextButton(
              onPressed: onShowHistory,
              child: Text(l10n.progressWeightHistory),
            ),
          ),
          AppSpacing.gapMd,
          if (points.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                l10n.progressChartNeedsMore,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else
            Semantics(
              label: l10n.progressChartSemantics(
                AppFormat.date(context, points.first.date),
                AppFormat.date(context, points.last.date),
                points.length,
                kg(points.map((p) => p.kg).reduce(math.min)),
                kg(points.map((p) => p.kg).reduce(math.max)),
              ),
              excludeSemantics: true,
              child: WeightChart(
                points: points,
                targetKg: targetKg,
                targetLabel: targetKg == null
                    ? null
                    : l10n.progressChartTarget(kg(targetKg!)),
                formatWeight: (v) => AppFormat.decimal(context, v),
                formatDate: (d) => ProgressFormat.shortDate(context, d),
              ),
            ),
        ],
      ),
    );
  }
}
