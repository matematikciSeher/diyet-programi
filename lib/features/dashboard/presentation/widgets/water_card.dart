import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/daily_dashboard.dart';
import 'card_title.dart';

class WaterCard extends StatelessWidget {
  const WaterCard({
    super.key,
    required this.glasses,
    required this.goalGlasses,
    required this.waterMl,
    required this.goalMl,
    required this.onAddGlass,
    this.onTap,
  });

  final int glasses;
  final int goalGlasses;
  final int waterMl;
  final int goalMl;
  final VoidCallback? onAddGlass;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.nutritionColors.water;
    final reached = waterMl >= goalMl;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.water_drop_rounded,
            title: l10n.dashboardWaterTitle,
            color: color,
            trailing: Text(
              l10n.litersOfTarget(
                AppFormat.liters(context, waterMl),
                AppFormat.liters(context, goalMl),
              ),
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          AppSpacing.gapMd,
          Text(
            l10n.waterGlassesProgress(glasses, goalGlasses),
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapSm,
          ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (var i = 0; i < goalGlasses; i++)
                  Icon(
                    i < glasses
                        ? Icons.local_drink_rounded
                        : Icons.local_drink_outlined,
                    size: 24,
                    color: i < glasses ? color : context.colors.outlineVariant,
                  ),
              ],
            ),
          ),
          if (reached) ...[
            AppSpacing.gapSm,
            Text(
              l10n.waterGoalReached,
              style: context.textStyles.labelLarge?.copyWith(
                color: context.nutritionColors.success,
              ),
            ),
          ],
          AppSpacing.gapLg,
          FilledButton.tonalIcon(
            onPressed: onAddGlass,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.waterAddAmount(DailyDashboard.glassMl)),
          ),
        ],
      ),
    );
  }
}
