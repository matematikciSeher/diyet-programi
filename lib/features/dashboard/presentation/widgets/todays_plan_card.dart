import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';

class TodaysPlanCard extends StatelessWidget {
  const TodaysPlanCard({
    super.key,
    required this.plan,
    required this.loggedMealTypes,
    required this.onOpenPlan,
  });

  final List<PlannedMeal> plan;

  /// Kaydı yapılmış öğünler "eklendi" olarak işaretlenir.
  final Set<MealType> loggedMealTypes;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (plan.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.planEmpty, style: context.textStyles.bodyMedium),
            AppSpacing.gapSm,
            TextButton(onPressed: onOpenPlan, child: Text(l10n.planCreate)),
          ],
        ),
      );
    }

    final nextIndex = plan.indexWhere(
      (m) => !loggedMealTypes.contains(m.mealType),
    );
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      onTap: onOpenPlan,
      child: Column(
        children: [
          for (final (index, meal) in plan.indexed) ...[
            if (index > 0) const Divider(indent: AppSpacing.lg),
            _PlanRow(
              meal: meal,
              logged: loggedMealTypes.contains(meal.mealType),
              isNext: index == nextIndex,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.meal,
    required this.logged,
    required this.isNext,
  });

  final PlannedMeal meal;
  final bool logged;
  final bool isNext;

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
    final success = context.nutritionColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time ?? '',
              style: context.textStyles.labelLarge?.copyWith(
                color: isNext
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
                fontWeight: isNext ? FontWeight.w700 : null,
              ),
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${meal.mealType.label(l10n)} · '
                  '${l10n.kcalValue(AppFormat.integer(context, meal.nutrition.calories))}',
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  meal.title,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: isNext ? FontWeight.w600 : null,
                    decoration: logged ? TextDecoration.lineThrough : null,
                    color: logged ? context.colors.onSurfaceVariant : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Icon(
            logged
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: logged ? success : context.colors.outlineVariant,
            semanticLabel: logged ? l10n.planLogged : null,
          ),
        ],
      ),
    );
  }
}
