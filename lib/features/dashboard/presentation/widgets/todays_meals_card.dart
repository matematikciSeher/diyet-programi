import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/daily_dashboard.dart';

/// Kahvaltı, öğle, akşam ve atıştırmalık bölümleri tek kartta.
class TodaysMealsCard extends StatelessWidget {
  const TodaysMealsCard({
    super.key,
    required this.dashboard,
    required this.onAddFood,
    this.onOpenMeal,
  });

  final DailyDashboard dashboard;
  final ValueChanged<MealType> onAddFood;
  final ValueChanged<MealType>? onOpenMeal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, type) in MealType.values.indexed) ...[
            if (index > 0) const Divider(indent: AppSpacing.lg),
            _MealSection(
              type: type,
              entries: dashboard.mealsOf(type),
              total: dashboard.totalOf(type),
              onAdd: () => onAddFood(type),
              onTap: onOpenMeal == null ? null : () => onOpenMeal!(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.type,
    required this.entries,
    required this.total,
    required this.onAdd,
    this.onTap,
  });

  static const _maxVisibleItems = 3;
  static const _leadingSize = 40.0;

  final MealType type;
  final List<MealEntry> entries;
  final NutritionFacts total;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmpty = entries.isEmpty;
    final hidden = entries.length - _maxVisibleItems;
    final label = type.label(l10n);
    String grams(double v) => AppFormat.integer(context, v);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: _leadingSize,
                  height: _leadingSize,
                  decoration: BoxDecoration(
                    color: isEmpty
                        ? context.colors.surfaceContainerHighest
                        : context.colors.secondaryContainer,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(
                    type.icon,
                    size: AppSizes.iconSm + 2,
                    color: isEmpty
                        ? context.colors.onSurfaceVariant
                        : context.colors.onSecondaryContainer,
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isEmpty
                            ? l10n.mealEmpty
                            : l10n.macroSummaryShort(
                                grams(total.proteinG),
                                grams(total.carbsG),
                                grams(total.fatG),
                              ),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isEmpty) ...[
                  AppSpacing.gapSm,
                  Text(
                    l10n.kcalValue(AppFormat.integer(context, total.calories)),
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                IconButton.filledTonal(
                  onPressed: onAdd,
                  tooltip: l10n.mealAddFoodTo(label),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            if (!isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: _leadingSize + AppSpacing.md,
                  end: AppSpacing.sm,
                  top: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final entry in entries.take(_maxVisibleItems))
                      _FoodLine(entry: entry),
                    if (hidden > 0)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            l10n.mealMoreItems(hidden),
                            style: context.textStyles.labelMedium?.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodLine extends StatelessWidget {
  const _FoodLine({required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    final serving = entry.servingLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: entry.name,
                children: [
                  if (serving != null)
                    TextSpan(
                      text: ' · $serving',
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                ],
              ),
              style: context.textStyles.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            AppFormat.integer(context, entry.nutrition.calories),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
