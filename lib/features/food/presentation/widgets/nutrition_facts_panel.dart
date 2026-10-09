import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../food_format.dart';

/// Kalori + makrolar ve varsa lif, şeker, doymuş yağ, sodyum.
class NutritionFactsPanel extends StatelessWidget {
  const NutritionFactsPanel({
    super.key,
    required this.nutrition,
    this.showDetails = true,
  });

  final NutritionFacts nutrition;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.nutritionColors;
    final n = nutrition;
    String g(double v) => FoodFormat.grams(context, v);

    final details = [
      if (n.fiberG != null) (l10n.nutrientFiber, g(n.fiberG!)),
      if (n.sugarG != null) (l10n.nutrientSugar, g(n.sugarG!)),
      if (n.saturatedFatG != null)
        (l10n.nutrientSaturatedFat, g(n.saturatedFatG!)),
      if (n.sodiumMg != null)
        (
          l10n.nutrientSodium,
          l10n.mgValue(AppFormat.integer(context, n.sodiumMg!)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                AppFormat.integer(context, n.calories),
                style: context.textStyles.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.calories,
                ),
              ),
              AppSpacing.gapSm,
              Text('kcal', style: context.textStyles.titleMedium),
            ],
          ),
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            _Macro(l10n.macroProtein, g(n.proteinG), colors.protein),
            _Macro(l10n.macroCarbs, g(n.carbsG), colors.carbs),
            _Macro(l10n.macroFat, g(n.fatG), colors.fat),
          ],
        ),
        if (showDetails && details.isNotEmpty) ...[
          AppSpacing.gapMd,
          const Divider(height: 1),
          for (final (label, value) in details)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: context.textStyles.bodyMedium),
                  ),
                  Text(value, style: context.textStyles.bodyMedium),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.smAll,
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
