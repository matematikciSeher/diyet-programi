import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../../progress/domain/models/progress_report.dart';
import '../../../progress/presentation/progress_labels.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../progress/presentation/widgets/add_weight_sheet.dart';
import '../../../progress/presentation/widgets/weight_chart.dart';
import '../../domain/services/weight_stats.dart';
import '../providers/weight_providers.dart';
import '../widgets/target_change_sheet.dart';
import '../widgets/target_suggestion_card.dart';

/// Başlangıç → güncel → hedef kilo, grafik, ilerleme metrikleri ve kayıt
/// geçmişi. Kayıtlar [UserProfile.weight]'i günceller.
class WeightPage extends ConsumerWidget {
  const WeightPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, double? current) async {
    final l10n = context.l10n;
    final input = await showAddWeightSheet(
      context,
      now: ref.read(clockProvider)(),
      initialKg: current,
      withNote: true,
    );
    if (input == null || !context.mounted) return;
    final actions = ref.read(progressActionsProvider);
    final result = await actions.addWeight(
      input.kg,
      at: input.date,
      note: input.note,
    );
    if (!context.mounted) return;
    switch (result) {
      case Success(value: final entry):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.progressWeightSaved(AppFormat.decimal(context, input.kg)),
              ),
              action: SnackBarAction(
                label: l10n.actionUndo,
                onPressed: () => actions.deleteWeight(entry.id),
              ),
            ),
          );
        final suggestion = ref.read(targetSuggestionProvider);
        if (suggestion != null && context.mounted) {
          final decision = await showTargetChangeSheet(
            context,
            suggestion: suggestion,
          );
          if (decision != null) {
            await applyTargetChangeDecision(ref, suggestion, decision);
          }
        }
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(weightStatsProvider);
    final current = stats.value?.currentKg;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureWeight)),
      floatingActionButton: stats.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context, ref, current),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.weightAdd),
            ),
      body: AsyncValueView(
        value: stats,
        loading: (_) => const SkeletonView(),
        onRetry: () => ref.invalidate(weightEntriesProvider),
        data: (data) => data == null
            ? EmptyStateView(
                icon: Icons.monitor_weight_outlined,
                title: l10n.weightEmptyTitle,
                message: l10n.weightEmptyMessage,
                actionLabel: l10n.weightAddFirst,
                onAction: () => _add(context, ref, null),
              )
            : ListView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xxxl * 2,
                ),
                children: [
                  ResponsiveCenter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _JourneyCard(stats: data),
                        AppSpacing.gapLg,
                        const TargetSuggestionCard(),
                        _MetricsCard(stats: data),
                        AppSpacing.gapLg,
                        _ChartCard(stats: data),
                        AppSpacing.gapLg,
                        _HistoryCard(stats: data),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.stats});

  final WeightStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = stats.progress;
    final fraction = progress.fraction;
    final colors = context.colors;
    String kg(double v) => ProgressFormat.kg(context, v);

    Widget column(String label, String value, {Color? color}) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textStyles.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.textStyles.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    final arrow = Icon(
      Icons.arrow_forward_rounded,
      size: AppSizes.iconSm,
      color: colors.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.flag_outlined,
            title: l10n.weightJourneyTitle,
            color: colors.primary,
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              column(l10n.progressStartWeight, kg(progress.startKg)),
              arrow,
              column(
                l10n.progressCurrentWeight,
                kg(progress.currentKg),
                color: colors.primary,
              ),
              arrow,
              column(
                l10n.progressTargetWeight,
                progress.targetKg == null ? '—' : kg(progress.targetKg!),
              ),
            ],
          ),
          if (fraction != null) ...[
            AppSpacing.gapLg,
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: LinearProgressIndicator(value: fraction, minHeight: 8),
            ),
            AppSpacing.gapSm,
            Text(
              progress.reached
                  ? l10n.progressGoalReached
                  : l10n.progressGoalPercent(
                      AppFormat.integer(context, fraction * 100),
                    ),
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ] else ...[
            AppSpacing.gapMd,
            Text(
              l10n.progressNoTarget,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.stats});

  final WeightStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = stats.progress;
    final achieved = progress.achievedKg;
    final remaining = progress.remainingKg;
    final latest = stats.latestEntry;
    final weekly = stats.weeklyChangeKg;
    final good = context.nutritionColors.success;

    return StatGrid(
      children: [
        StatTile(
          icon: progress.direction == WeightDirection.lose
              ? Icons.trending_down_rounded
              : Icons.trending_up_rounded,
          label: progress.direction == WeightDirection.lose
              ? l10n.progressLostWeight
              : l10n.progressGainedWeight,
          value: ProgressFormat.kg(context, math.max(0, achieved)),
          color: achieved > 0 ? good : null,
        ),
        StatTile(
          icon: Icons.flag_outlined,
          label: l10n.weightStatRemaining,
          value: remaining == null ? '—' : ProgressFormat.kg(context, remaining),
        ),
        StatTile(
          icon: Icons.percent_rounded,
          label: l10n.weightStatPercent,
          value: '${ProgressFormat.signed(context, stats.changePercent)}%',
        ),
        StatTile(
          icon: Icons.event_outlined,
          label: l10n.weightStatLast,
          value: ProgressFormat.kg(context, stats.currentKg),
          caption: latest == null
              ? null
              : AppFormat.date(context, latest.recordedAt),
        ),
        StatTile(
          icon: Icons.speed_rounded,
          label: l10n.weightStatWeekly,
          value: weekly == null
              ? '—'
              : l10n.weightPerWeek(ProgressFormat.signed(context, weekly)),
        ),
      ],
    );
  }
}

class _ChartCard extends ConsumerWidget {
  const _ChartCard({required this.stats});

  final WeightStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(weightRangeProvider);
    final points = stats.points;
    final target = stats.targetKg;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.show_chart_rounded,
            title: l10n.progressChartTitle,
            color: context.colors.primary,
          ),
          AppSpacing.gapMd,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<WeightRange>(
              segments: [
                for (final r in WeightRange.values)
                  ButtonSegment(value: r, label: Text(l10n.weightRange(r.name))),
              ],
              selected: {range},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(weightRangeProvider.notifier).select(s.first),
            ),
          ),
          AppSpacing.gapLg,
          if (points.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                l10n.progressChartNeedsMore,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else
            Semantics(
              label: l10n.progressChartSemantics(
                AppFormat.date(context, points.first.date),
                AppFormat.date(context, points.last.date),
                points.length,
                ProgressFormat.kg(
                  context,
                  points.map((p) => p.kg).reduce(math.min),
                ),
                ProgressFormat.kg(
                  context,
                  points.map((p) => p.kg).reduce(math.max),
                ),
              ),
              excludeSemantics: true,
              child: WeightChart(
                points: points,
                targetKg: target,
                targetLabel: target == null
                    ? null
                    : l10n.progressChartTarget(ProgressFormat.kg(context, target)),
                formatWeight: (v) => AppFormat.decimal(context, v),
                formatDate: (d) => ProgressFormat.shortDate(context, d),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.stats});

  final WeightStats stats;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WeightEntry entry,
  ) async {
    final l10n = context.l10n;
    final actions = ref.read(progressActionsProvider);
    final result = await actions.deleteWeight(entry.id);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.progressEntryDeleted),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => actions.restoreWeight(entry),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = stats.entries;
    final variant = context.colors.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CardTitle(
              icon: Icons.history_rounded,
              title: l10n.weightHistoryTitle,
              color: context.colors.primary,
            ),
          ),
          AppSpacing.gapSm,
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.weightHistoryEmpty,
                style: context.textStyles.bodyMedium?.copyWith(color: variant),
              ),
            )
          else
            for (final entry in entries)
              ListTile(
                key: ValueKey('weight-${entry.id}'),
                title: Text(ProgressFormat.kg(context, entry.weightKg)),
                subtitle: Text(
                  [
                    AppFormat.date(context, entry.recordedAt),
                    if (stats.changeFromPrevious(entry) case final change?)
                      l10n.weightDeltaPrevious(
                        ProgressFormat.signed(context, change),
                      ),
                    ?entry.note,
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: l10n.actionDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _delete(context, ref, entry),
                ),
              ),
        ],
      ),
    );
  }
}
