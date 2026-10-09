import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/nutrition/nutrition_calculator.dart';
import '../providers/onboarding_flow_controller.dart';

/// Hesaplanan hedeflerin gösterildiği sonuç ekranı.
class SummaryStep extends ConsumerWidget {
  const SummaryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(onboardingPlanProvider);
    final draft = ref.watch(onboardingFlowProvider.select((s) => s.draft));
    if (plan == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final name = draft.name?.trim();
    final waterMl = draft.waterGoal ?? plan.waterMl;
    final goal = draft.goal ?? GoalType.maintainWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            name == null || name.isEmpty
                ? l10n.summaryTitle
                : l10n.summaryTitleNamed(name),
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AppSpacing.gapSm,
        Text(
          l10n.summarySubtitle,
          style: context.textStyles.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapXl,
        _CalorieHero(plan: plan),
        AppSpacing.gapMd,
        _MacroRow(plan: plan),
        AppSpacing.gapMd,
        _InfoTile(
          icon: Icons.water_drop_rounded,
          color: context.nutritionColors.water,
          title: l10n.summaryWater,
          value: l10n.waterLiters(AppFormat.liters(context, waterMl)),
        ),
        AppSpacing.gapMd,
        _DurationTile(plan: plan, goal: goal),
        AppSpacing.gapLg,
        Text(
          l10n.summaryMetrics(
            AppFormat.integer(context, plan.bmr),
            AppFormat.decimal(context, plan.bmi),
          ),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          l10n.summaryFormulaNote,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        if (plan.notices.isNotEmpty) ...[
          AppSpacing.gapXl,
          _NoticesCard(notices: plan.notices),
        ],
        AppSpacing.gapLg,
        const _DisclaimerCard(),
      ],
    );
  }
}

class _CalorieHero extends StatelessWidget {
  const _CalorieHero({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final delta = plan.calorieDelta;
    final deltaText = delta == 0
        ? l10n.summaryBalanced
        : delta < 0
        ? l10n.summaryDeficit(AppFormat.integer(context, delta.abs()))
        : l10n.summarySurplus(AppFormat.integer(context, delta));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.tertiary, 0.55)!,
          ],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summaryDailyTarget,
              style: context.textStyles.titleSmall?.copyWith(
                color: colors.onPrimary.withValues(alpha: 0.85),
              ),
            ),
            AppSpacing.gapSm,
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      AppFormat.integer(context, plan.targetCalories),
                      style: context.textStyles.displayMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  l10n.summaryKcalPerDay,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            AppSpacing.gapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.summaryMaintenance(
                    AppFormat.integer(context, plan.maintenanceCalories),
                  ),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: 0.16),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    deltaText,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.nutritionColors;
    final totalKcal = plan.proteinG * 4 + plan.carbsG * 4 + plan.fatG * 9;
    int pct(int kcal) => totalKcal == 0 ? 0 : (kcal * 100 / totalKcal).round();
    final items = [
      (l10n.macroProtein, plan.proteinG, pct(plan.proteinG * 4), c.protein),
      (l10n.macroCarbs, plan.carbsG, pct(plan.carbsG * 4), c.carbs),
      (l10n.macroFat, plan.fatG, pct(plan.fatG * 9), c.fat),
    ];
    return Row(
      children: [
        for (final (label, grams, percent, color) in items) ...[
          Expanded(
            child: _MacroCard(
              label: label,
              grams: grams,
              percent: percent,
              color: color,
            ),
          ),
          if (label != items.last.$1) AppSpacing.gapSm,
        ],
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
  });

  final String label;
  final int grams;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              AppSpacing.gapXs,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.l10n.gramsValue(AppFormat.integer(context, grams)),
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.gapSm,
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.pill),
            ),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 4,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          AppSpacing.gapXs,
          Text('%$percent', style: context.textStyles.labelSmall),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(icon, color: color),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    caption!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({required this.plan, required this.goal});

  final NutritionPlan plan;
  final GoalType goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final weeks = plan.estimatedWeeks;
    final date = plan.estimatedGoalDate;
    final String value;
    final String? caption;
    if (weeks != null && date != null) {
      value = l10n.summaryWeeks(weeks);
      caption =
          '${l10n.summaryGoalDate(AppFormat.date(context, date))} · '
          '${l10n.summaryWeeklyRate(AppFormat.decimal(context, plan.weeklyChangeKg.abs(), digits: 2))}';
    } else if (goal.changesWeight) {
      value = '—';
      caption = l10n.summaryNoDurationSlow;
    } else {
      value = '—';
      caption = l10n.summaryNoDurationMaintain;
    }
    return _InfoTile(
      icon: Icons.flag_outlined,
      color: context.nutritionColors.calories,
      title: l10n.summaryGoalDuration,
      value: value,
      caption: caption,
    );
  }
}

class _NoticesCard extends StatelessWidget {
  const _NoticesCard({required this.notices});

  final Set<HealthNotice> notices;

  static String _text(AppLocalizations l10n, HealthNotice notice) =>
      switch (notice) {
        HealthNotice.minor => l10n.noticeMinor,
        HealthNotice.senior => l10n.noticeSenior,
        HealthNotice.underweight => l10n.noticeUnderweight,
        HealthNotice.severeObesity => l10n.noticeSevereObesity,
        HealthNotice.paceAdjusted => l10n.noticePaceAdjusted,
        HealthNotice.calorieFloorApplied => l10n.noticeCalorieFloor,
        HealthNotice.fastingCaution => l10n.noticeFasting,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final warning = context.nutritionColors.warning;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.10),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: warning),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  l10n.noticeTitle,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          for (final notice in HealthNotice.values.where(notices.contains)) ...[
            AppSpacing.gapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    _text(l10n, notice),
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.medical_information_outlined,
            color: context.colors.onSurfaceVariant,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.disclaimerTitle,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  l10n.disclaimerBody,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
