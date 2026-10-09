import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../../dashboard/presentation/widgets/nutrition_score_card.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';

/// Günlük beslenme skorlarının çubuk grafiği. Bir çubuğa dokunup
/// sürükleyerek günün ayrıntısı görülür.
class ScoreHistoryCard extends StatefulWidget {
  const ScoreHistoryCard({super.key, required this.days, this.averageScore});

  /// Eskiden yeniye; son eleman bugündür.
  final List<DailyProgress> days;
  final double? averageScore;

  @override
  State<ScoreHistoryCard> createState() => _ScoreHistoryCardState();
}

class _ScoreHistoryCardState extends State<ScoreHistoryCard> {
  int? _selected;

  static const _chartHeight = 120.0;

  @override
  void didUpdateWidget(ScoreHistoryCard old) {
    super.didUpdateWidget(old);
    if (old.days.length != widget.days.length) _selected = null;
  }

  void _selectAt(double dx, double width) {
    if (widget.days.isEmpty || width <= 0) return;
    final index = (dx / width * widget.days.length).floor().clamp(
      0,
      widget.days.length - 1,
    );
    if (index != _selected) setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = widget.days;
    final hasScores = days.any((d) => d.score != null);
    final selectedIndex = _selected ?? days.length - 1;
    final average = widget.averageScore;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.bar_chart_rounded,
            title: l10n.progressScoreTitle,
            color: context.nutritionColors.calories,
            trailing: average == null
                ? null
                : Text(
                    l10n.progressScoreAverage('${average.round()}'),
                    style: context.textStyles.labelLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
          ),
          AppSpacing.gapMd,
          if (!hasScores)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                l10n.progressScoreEmpty,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _selectAt(d.localPosition.dx, width),
                  onHorizontalDragUpdate: (d) =>
                      _selectAt(d.localPosition.dx, width),
                  child: SizedBox(
                    height: _chartHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (i, day) in days.indexed)
                          Expanded(
                            child: _Bar(
                              day: day,
                              selected: i == selectedIndex,
                              gap: width / days.length > 10 ? 3 : 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            AppSpacing.gapXs,
            Row(
              children: [
                Text(
                  ProgressFormat.shortDate(context, days.first.day),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.progressToday,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            _DayDetail(
              day: days[selectedIndex],
              isToday: selectedIndex == days.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.selected, required this.gap});

  final DailyProgress day;
  final bool selected;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final score = day.score;
    final color = score == null
        ? context.colors.outlineVariant
        : score.band.color(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap / 2),
      child: FractionallySizedBox(
        heightFactor: score == null ? 0.04 : (score.value / 100).clamp(0.04, 1),
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            border: selected
                ? Border.all(color: context.colors.onSurface, width: 1.5)
                : null,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.day, required this.isToday});

  final DailyProgress day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final score = day.score;
    final date = isToday
        ? l10n.progressToday
        : AppFormat.date(context, day.day);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: AppRadius.mdAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(
                score == null ? '–' : '${score.value}',
                style: context.textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: score?.band.color(context),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: context.textStyles.labelLarge),
                    Text(
                      score == null
                          ? l10n.progressNotLogged
                          : '${score.band.label(l10n)} · '
                                '${l10n.progressDaySummary(AppFormat.integer(context, day.calories), AppFormat.integer(context, day.proteinG), AppFormat.liters(context, day.waterMl))}',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
