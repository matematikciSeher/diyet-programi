import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';

/// Bel ölçüsü öne çıkarılır; diğer ölçüler altında listelenir.
class MeasurementsCard extends StatelessWidget {
  const MeasurementsCard({
    super.key,
    required this.measurements,
    required this.onAdd,
  });

  final List<MeasurementTrend> measurements;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waist = measurements
        .where((m) => m.field == MeasurementField.waist)
        .firstOrNull;
    final others = measurements
        .where((m) => m.field != MeasurementField.waist)
        .toList();
    final latestAt = measurements.isEmpty
        ? null
        : measurements
              .map((m) => m.latestAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.straighten_rounded,
            title: l10n.progressMeasurementsTitle,
            color: context.nutritionColors.fiber,
            trailing: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.progressAddMeasurement),
            ),
          ),
          AppSpacing.gapMd,
          if (measurements.isEmpty)
            Text(
              l10n.progressNoMeasurements,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else ...[
            if (waist != null) _WaistHighlight(trend: waist),
            if (waist != null && others.isNotEmpty) AppSpacing.gapMd,
            for (final m in others) _MeasurementRow(trend: m),
            if (latestAt != null) ...[
              AppSpacing.gapSm,
              Text(
                l10n.progressLastMeasured(AppFormat.date(context, latestAt)),
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Color _changeColor(BuildContext context, double change) {
  if (change == 0) return context.colors.onSurfaceVariant;
  return change < 0
      ? context.nutritionColors.success
      : context.nutritionColors.warning;
}

String _signedChange(BuildContext context, MeasurementTrend t) {
  final text = ProgressFormat.signed(context, t.change);
  return t.field == MeasurementField.bodyFat
      ? context.l10n.progressPercent(text)
      : context.l10n.progressCm(text);
}

class _WaistHighlight extends StatelessWidget {
  const _WaistHighlight({required this.trend});

  final MeasurementTrend trend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.nutritionColors.fiber;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.progressWaistTitle,
                    style: context.textStyles.labelLarge,
                  ),
                  Text(
                    trend.field.format(context, trend.latest),
                    style: context.textStyles.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                l10n.progressSinceStart(_signedChange(context, trend)),
                textAlign: TextAlign.end,
                style: context.textStyles.labelLarge?.copyWith(
                  color: _changeColor(context, trend.change),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.trend});

  final MeasurementTrend trend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              trend.field.label(l10n),
              style: context.textStyles.bodyMedium,
            ),
          ),
          Text(
            trend.field.format(context, trend.latest),
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              _signedChange(context, trend),
              textAlign: TextAlign.end,
              style: context.textStyles.labelMedium?.copyWith(
                color: _changeColor(context, trend.change),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
