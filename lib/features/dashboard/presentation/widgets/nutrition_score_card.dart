import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/nutrition_score.dart';

extension ScoreFactorL10n on ScoreFactor {
  String label(AppLocalizations l10n) => switch (this) {
    ScoreFactor.calories => l10n.scoreFactorCalories,
    ScoreFactor.protein => l10n.scoreFactorProtein,
    ScoreFactor.fiber => l10n.scoreFactorFiber,
    ScoreFactor.water => l10n.scoreFactorWater,
    ScoreFactor.produce => l10n.scoreFactorProduce,
    ScoreFactor.processed => l10n.scoreFactorProcessed,
    ScoreFactor.macroBalance => l10n.scoreFactorMacroBalance,
    ScoreFactor.mealRhythm => l10n.scoreFactorMealRhythm,
  };

  String tip(AppLocalizations l10n) => switch (this) {
    ScoreFactor.calories => l10n.scoreTipCalories,
    ScoreFactor.protein => l10n.scoreTipProtein,
    ScoreFactor.fiber => l10n.scoreTipFiber,
    ScoreFactor.water => l10n.scoreTipWater,
    ScoreFactor.produce => l10n.scoreTipProduce,
    ScoreFactor.processed => l10n.scoreTipProcessed,
    ScoreFactor.macroBalance => l10n.scoreTipMacroBalance,
    ScoreFactor.mealRhythm => l10n.scoreTipMealRhythm,
  };
}

/// Skoru oluşturan tüm faktörleri ve tıbbi uyarıyı gösteren alt sayfa.
Future<void> showNutritionScoreDetails(
  BuildContext context,
  NutritionScore score,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ScoreDetailsSheet(score: score),
);

extension ScoreBandUi on ScoreBand {
  String label(AppLocalizations l10n) => switch (this) {
    ScoreBand.starting => l10n.scoreBandStarting,
    ScoreBand.fair => l10n.scoreBandFair,
    ScoreBand.good => l10n.scoreBandGood,
    ScoreBand.great => l10n.scoreBandGreat,
  };

  Color color(BuildContext context) => switch (this) {
    ScoreBand.great => context.nutritionColors.success,
    ScoreBand.good => context.nutritionColors.calories,
    ScoreBand.fair => context.nutritionColors.warning,
    ScoreBand.starting => context.colors.outline,
  };
}

class NutritionScoreCard extends StatelessWidget {
  const NutritionScoreCard({super.key, required this.score});

  final NutritionScore score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final band = score.band;
    final color = band.color(context);
    final weakest = score.weakest;

    return AppCard(
      onTap: () => showNutritionScoreDetails(context, score),
      child: Row(
        children: [
          ProgressRing(
            progress: score.value / 100,
            size: 84,
            strokeWidth: 8,
            color: color,
            semanticLabel: l10n.dashboardScoreTitle,
            center: Text(
              '${score.value}',
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardScoreTitle,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  band.label(l10n),
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (weakest != null && weakest.progress < 1) ...[
                  AppSpacing.gapXs,
                  Text(
                    weakest.factor.tip(l10n),
                    style: context.textStyles.bodySmall,
                  ),
                ],
                AppSpacing.gapSm,
                Text(
                  l10n.scoreDisclaimerShort,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ScoreDetailsSheet extends StatelessWidget {
  const _ScoreDetailsSheet({required this.score});

  final NutritionScore score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = score.band.color(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.scoreDetails, style: context.textStyles.titleLarge),
          AppSpacing.gapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${score.value}',
                style: context.textStyles.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              AppSpacing.gapXs,
              Text(l10n.scoreOutOf, style: context.textStyles.titleMedium),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  score.band.label(l10n),
                  style: context.textStyles.titleMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          for (final component in score.components) ...[
            _FactorRow(component: component),
            AppSpacing.gapMd,
          ],
          AppSpacing.gapSm,
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: AppRadius.mdAll,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: AppSizes.iconSm,
                    color: context.colors.onSurfaceVariant,
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Text(
                      l10n.scoreDisclaimerLong,
                      style: context.textStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.component});

  final ScoreComponent component;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final factor = component.factor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                factor.label(l10n),
                style: context.textStyles.labelLarge,
              ),
            ),
            Text(
              l10n.scorePoints(
                AppFormat.integer(context, component.points),
                factor.maxPoints,
              ),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.gapXs,
        ClipRRect(
          borderRadius: AppRadius.smAll,
          child: LinearProgressIndicator(
            value: component.progress,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
