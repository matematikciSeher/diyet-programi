import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/presentation/widgets/nutrition_score_card.dart';
import '../../domain/models/daily_nutrition_score.dart';
import '../diary_format.dart';
import '../providers/diary_providers.dart';

/// Günün beslenme skoru ve skoru oluşturan faktörlerin durumu.
/// Skor burada hesaplanmaz; `DailyNutritionScoreService`'ten gelir.
class DiaryScoreCard extends ConsumerWidget {
  const DiaryScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final score = ref.watch(nutritionScoreProvider);
    final kind = DiaryDayKind.of(
      ref.watch(selectedDateProvider),
      ref.watch(clockProvider)(),
    );
    if (score == null) return const SizedBox.shrink();
    final color = score.band.color(context);

    return AppCard(
      onTap: () => showNutritionScoreDetails(context, score.breakdown),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.diaryScoreTitle(kind.name),
                    style: context.textStyles.titleSmall,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              ProgressRing(
                progress: score.value / 100,
                size: 64,
                strokeWidth: 7,
                color: color,
                semanticLabel: l10n.dashboardScoreTitle,
              ),
              AppSpacing.gapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Text(
                          l10n.scoreOutOf,
                          style: context.textStyles.titleMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      score.band.label(l10n),
                      style: context.textStyles.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 300;
              final width = twoColumns
                  ? (constraints.maxWidth - AppSpacing.md) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final check in score.checks)
                    SizedBox(
                      width: width,
                      child: _FactorCheck(check: check),
                    ),
                ],
              );
            },
          ),
          AppSpacing.gapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  l10n.diaryScoreDisclaimer,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactorCheck extends StatelessWidget {
  const _FactorCheck({required this.check});

  final ScoreFactorCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.nutritionColors;
    final (icon, color) = switch (check.status) {
      ScoreFactorStatus.met => (Icons.check_circle_rounded, c.success),
      ScoreFactorStatus.partial => (Icons.change_history_rounded, c.warning),
      ScoreFactorStatus.missed => (
        Icons.radio_button_unchecked_rounded,
        context.colors.outline,
      ),
    };
    final label = check.factor.label(l10n);

    return Semantics(
      label: '$label, ${l10n.diaryScoreStatus(check.status.name)}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
