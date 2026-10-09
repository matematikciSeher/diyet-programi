import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/nutrition_targets.dart';
import '../../../../shared/presentation/enum_labels.dart';
import 'card_title.dart';

/// Günün ana kartı: alınan / hedef / kalan kalori ve makro ilerlemesi.
class CalorieSummaryCard extends StatelessWidget {
  const CalorieSummaryCard({
    super.key,
    required this.consumed,
    required this.targets,
  });

  final NutritionFacts consumed;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.nutritionColors;
    final eaten = consumed.calories;
    final target = targets.calories;
    final remaining = target - eaten;
    final isOver = remaining < 0;
    final progress = target <= 0 ? 0.0 : eaten / target;
    final eatenText = AppFormat.integer(context, eaten);
    final targetText = AppFormat.integer(context, target);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.local_fire_department_outlined,
            title: l10n.dashboardCaloriesTitle,
            color: c.calories,
            trailing: Text(
              l10n.dashboardKcalOfTarget(eatenText, targetText),
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          AppSpacing.gapXl,
          LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = (constraints.maxWidth * 0.46).clamp(
                120.0,
                176.0,
              );
              return Row(
                children: [
                  ProgressRing(
                    progress: progress,
                    size: ringSize,
                    strokeWidth: ringSize * 0.09,
                    color: c.calories,
                    overflowColor: c.warning,
                    semanticLabel: l10n.dashboardCaloriesTitle,
                    center: Padding(
                      padding: EdgeInsets.all(ringSize * 0.14),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormat.integer(context, remaining.abs()),
                              style: context.textStyles.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isOver ? c.warning : null,
                                  ),
                            ),
                            Text(
                              isOver
                                  ? l10n.dashboardKcalOver
                                  : l10n.dashboardKcalLeft,
                              style: context.textStyles.labelMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Stat(
                          label: l10n.dashboardEaten,
                          value: l10n.kcalValue(eatenText),
                          color: c.calories,
                        ),
                        AppSpacing.gapLg,
                        _Stat(
                          label: l10n.dashboardTarget,
                          value: l10n.kcalValue(targetText),
                          color: context.colors.outline,
                        ),
                        AppSpacing.gapLg,
                        _Stat(
                          label: isOver
                              ? l10n.dashboardKcalOver
                              : l10n.dashboardRemaining,
                          value: l10n.kcalValue(
                            AppFormat.integer(context, remaining.abs()),
                          ),
                          color: isOver
                              ? c.warning
                              : context.colors.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          AppSpacing.gapXl,
          Row(
            children: [
              Expanded(
                child: MacroProgress(
                  label: l10n.macroProtein,
                  value: consumed.proteinG,
                  target: targets.proteinG,
                  color: c.protein,
                ),
              ),
              AppSpacing.gapLg,
              Expanded(
                child: MacroProgress(
                  label: l10n.macroCarbs,
                  value: consumed.carbsG,
                  target: targets.carbsG,
                  color: c.carbs,
                ),
              ),
              AppSpacing.gapLg,
              Expanded(
                child: MacroProgress(
                  label: l10n.macroFat,
                  value: consumed.fatG,
                  target: targets.fatG,
                  color: c.fat,
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
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.smAll,
          ),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Etiket, ilerleme çubuğu ve "72 / 120 g" metninden oluşan makro göstergesi.
class MacroProgress extends StatelessWidget {
  const MacroProgress({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    final reached = target > 0 && value >= target;
    final valueText = context.l10n.gramsOfTarget(
      AppFormat.integer(context, value),
      AppFormat.integer(context, target),
    );
    return Semantics(
      label: '$label $valueText',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (reached) ...[
                AppSpacing.gapXs,
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: context.nutritionColors.success,
                ),
              ],
            ],
          ),
          AppSpacing.gapSm,
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
            ),
          ),
          AppSpacing.gapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              valueText,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
