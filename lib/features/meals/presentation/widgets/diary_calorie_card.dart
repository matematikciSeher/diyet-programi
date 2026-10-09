import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/calorie_summary_card.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../providers/diary_providers.dart';

/// Seçili günün alınan / hedef kalorisi, kalan veya aşılan miktar ve
/// makro ilerlemeleri. Hedefler profilden gelir.
class DiaryCalorieCard extends ConsumerWidget {
  const DiaryCalorieCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.nutritionColors;
    final totals =
        ref.watch(dailyNutritionTotalsProvider) ?? NutritionFacts.zero;
    final targets = ref.watch(diaryTargetsProvider);

    final eaten = totals.calories.round();
    final target = targets.calories.round();
    final remaining = target - eaten;
    final isOver = remaining < 0;
    final status = isOver
        ? l10n.diaryCaloriesOver(AppFormat.integer(context, -remaining))
        : l10n.diaryCaloriesLeft(AppFormat.integer(context, remaining));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.local_fire_department_outlined,
            title: l10n.dashboardCaloriesTitle,
            color: c.calories,
          ),
          AppSpacing.gapLg,
          LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = (constraints.maxWidth * 0.42).clamp(
                112.0,
                164.0,
              );
              return Row(
                children: [
                  ProgressRing(
                    progress: target <= 0 ? 0 : eaten / target,
                    size: ringSize,
                    strokeWidth: ringSize * 0.085,
                    color: c.calories,
                    overflowColor: c.warning,
                    semanticLabel: l10n.dashboardCaloriesTitle,
                    center: Padding(
                      padding: EdgeInsets.all(ringSize * 0.15),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormat.integer(context, eaten),
                              style: context.textStyles.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              l10n.diaryCaloriesOfTarget(
                                AppFormat.integer(context, target),
                              ),
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
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            status,
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isOver ? c.warning : null,
                            ),
                          ),
                        ),
                        AppSpacing.gapMd,
                        _Stat(
                          label: l10n.dashboardEaten,
                          value: l10n.kcalValue(
                            AppFormat.integer(context, eaten),
                          ),
                        ),
                        AppSpacing.gapSm,
                        _Stat(
                          label: l10n.dashboardTarget,
                          value: l10n.kcalValue(
                            AppFormat.integer(context, target),
                          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MacroProgress(
                  label: l10n.macroProtein,
                  value: totals.proteinG,
                  target: targets.proteinG,
                  color: c.protein,
                ),
              ),
              AppSpacing.gapLg,
              Expanded(
                child: MacroProgress(
                  label: l10n.macroCarbs,
                  value: totals.carbsG,
                  target: targets.carbsG,
                  color: c.carbs,
                ),
              ),
              AppSpacing.gapLg,
              Expanded(
                child: MacroProgress(
                  label: l10n.macroFat,
                  value: totals.fatG,
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
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: '$label  ',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: value,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
