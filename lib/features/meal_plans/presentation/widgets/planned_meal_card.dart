import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/models/plan_item.dart';
import '../../domain/models/planned_meal.dart';

/// Plan sayfasında bir öğün: yiyecek listesi, kalori ve eylemler.
class PlannedMealCard extends StatelessWidget {
  const PlannedMealCard({
    super.key,
    required this.meal,
    required this.logged,
    required this.highlighted,
    required this.onSwap,
    required this.onLog,
  });

  final PlannedMeal meal;
  final bool logged;

  /// Son değişiklikte yenilendiyse vurgulanır.
  final bool highlighted;
  final VoidCallback? onSwap;
  final VoidCallback? onLog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final minutes = meal.timeMinutes;
    final time = minutes == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    final n = meal.nutrition;
    final variant = context.colors.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: highlighted ? context.colors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(meal.mealType.icon, color: context.colors.primary),
                AppSpacing.gapSm,
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      meal.mealType.label(l10n),
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                ),
                if (time != null)
                  Text(
                    time,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: variant,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapXs,
            Text(
              meal.title,
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapXs,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.kcalValue(AppFormat.integer(context, n.calories))} · '
                  '${l10n.macroSummaryShort(AppFormat.integer(context, n.proteinG), AppFormat.integer(context, n.carbsG), AppFormat.integer(context, n.fatG))}',
                  style: context.textStyles.labelMedium?.copyWith(
                    color: variant,
                  ),
                ),
                if (meal.portionFactor != 1)
                  _Badge(
                    l10n.planPortion(
                      AppFormat.decimal(context, meal.portionFactor, digits: 2),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapMd,
            for (final item in meal.items) _ItemRow(item: item),
            AppSpacing.gapSm,
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.end,
              overflowSpacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  onPressed: logged ? null : onSwap,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text(l10n.planSwapMeal),
                ),
                if (logged)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: context.nutritionColors.success,
                        size: AppSizes.iconSm,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        l10n.planLogged,
                        style: context.textStyles.labelLarge?.copyWith(
                          color: context.nutritionColors.success,
                        ),
                      ),
                    ],
                  )
                else
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.minTouchTarget),
                    ),
                    onPressed: onLog,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.planLogMeal),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final PlanItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: ExcludeSemantics(
              child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          Expanded(
            child: Text(item.name, style: context.textStyles.bodyMedium),
          ),
          AppSpacing.gapSm,
          Text(
            item.amount,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          text,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
