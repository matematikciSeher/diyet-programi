import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Etiketli doğrusal ilerleme çubuğu (ör. "Protein 82 / 120 g").
class MetricProgressBar extends StatelessWidget {
  const MetricProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    this.color,
  });

  final String label;
  final double value;
  final double target;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    final valueText = '${value.round()} / ${target.round()} $unit';

    return Semantics(
      label: '$label $valueText',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
              Text(
                valueText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
