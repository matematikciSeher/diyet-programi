import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../../progress/domain/models/progress_report.dart';
import '../../../progress/presentation/progress_labels.dart';
import '../../../progress/presentation/providers/progress_providers.dart';
import '../../../progress/presentation/widgets/add_measurement_sheet.dart';
import '../../../progress/presentation/widgets/weight_chart.dart';
import '../../domain/services/measurement_stats.dart';

class _SelectedFieldController extends Notifier<MeasurementField?> {
  @override
  MeasurementField? build() => null;

  void select(MeasurementField field) => state = field;
}

final _selectedFieldProvider =
    NotifierProvider<_SelectedFieldController, MeasurementField?>(
      _SelectedFieldController.new,
    );

/// Bel, kalça, göğüs, boyun, kol ve uyluk ölçüleri; seçili ölçünün grafiği,
/// başlangıç/son/değişim özeti ve kayıt geçmişi.
class MeasurementsPage extends ConsumerWidget {
  const MeasurementsPage({super.key});

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    List<MeasurementSeries> series,
  ) async {
    final l10n = context.l10n;
    final measurement = await showAddMeasurementSheet(
      context,
      now: ref.read(clockProvider)(),
      previous: [for (final s in series) s.trend],
    );
    if (measurement == null || !context.mounted) return;
    final actions = ref.read(progressActionsProvider);
    final result = await actions.addMeasurement(measurement);
    if (!context.mounted) return;
    switch (result) {
      case Success(value: final saved):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.progressMeasurementSaved),
              action: SnackBarAction(
                label: l10n.actionUndo,
                onPressed: () => actions.deleteMeasurement(saved.id),
              ),
            ),
          );
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final measurements = ref.watch(measurementsProvider);
    final series = MeasurementStats.series(measurements.value ?? const []);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureMeasurements)),
      floatingActionButton: series.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(context, ref, series),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.progressAddMeasurement),
            ),
      body: AsyncValueView(
        value: measurements,
        loading: (_) => const SkeletonView(),
        onRetry: () => ref.invalidate(measurementsProvider),
        data: (list) => series.isEmpty
            ? EmptyStateView(
                icon: Icons.straighten_rounded,
                title: l10n.measureEmptyTitle,
                message: l10n.measureEmptyMessage,
                actionLabel: l10n.measureAddFirst,
                onAction: () => _add(context, ref, series),
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
                        _SummaryCard(series: series),
                        AppSpacing.gapLg,
                        _ChartCard(series: series),
                        AppSpacing.gapLg,
                        _HistoryCard(measurements: list.reversed.toList()),
                        AppSpacing.gapMd,
                        TextButton.icon(
                          onPressed: () => context.push(AppRoutes.progress),
                          icon: const Icon(Icons.insights_rounded),
                          label: Text(l10n.measureSeeProgress),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Color _changeColor(BuildContext context, double change) {
  if (change == 0) return context.colors.onSurfaceVariant;
  return change < 0
      ? context.nutritionColors.success
      : context.nutritionColors.warning;
}

String _signed(BuildContext context, MeasurementField field, double change) {
  final text = ProgressFormat.signed(context, change);
  return field == MeasurementField.bodyFat
      ? context.l10n.progressPercent(text)
      : context.l10n.progressCm(text);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.series});

  final List<MeasurementSeries> series;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = context.textStyles.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.straighten_rounded,
            title: l10n.measureSummaryTitle,
            color: context.nutritionColors.fiber,
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox.shrink()),
              Expanded(
                flex: 2,
                child: Text(l10n.measureStart, style: labelStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(l10n.measureLatest, style: labelStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  l10n.measureChange,
                  style: labelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const Divider(),
          for (final s in series)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      s.field.label(l10n),
                      style: context.textStyles.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(s.field.format(context, s.first)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      s.field.format(context, s.latest),
                      style: context.textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _signed(context, s.field, s.change),
                      textAlign: TextAlign.end,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: _changeColor(context, s.change),
                      ),
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

class _ChartCard extends ConsumerWidget {
  const _ChartCard({required this.series});

  final List<MeasurementSeries> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selectedField = ref.watch(_selectedFieldProvider);
    final selected =
        series.where((s) => s.field == selectedField).firstOrNull ??
        series.first;
    final points = selected.points;
    final field = selected.field;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.show_chart_rounded,
            title: l10n.measureChartTitle,
            color: context.colors.primary,
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in series)
                ChoiceChip(
                  label: Text(s.field.label(l10n)),
                  selected: s.field == field,
                  onSelected: (_) =>
                      ref.read(_selectedFieldProvider.notifier).select(s.field),
                ),
            ],
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
              label: l10n.measureChartSemantics(
                field.label(l10n),
                field.format(
                  context,
                  points.map((p) => p.kg).reduce(math.min),
                ),
                field.format(
                  context,
                  points.map((p) => p.kg).reduce(math.max),
                ),
              ),
              excludeSemantics: true,
              child: WeightChart(
                points: points,
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
  const _HistoryCard({required this.measurements});

  /// En yeni önce.
  final List<BodyMeasurement> measurements;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement m,
  ) async {
    final l10n = context.l10n;
    final actions = ref.read(progressActionsProvider);
    final result = await actions.deleteMeasurement(m.id);
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
            onPressed: () => actions.restoreMeasurement(m),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CardTitle(
              icon: Icons.history_rounded,
              title: l10n.measureHistoryTitle,
              color: context.colors.primary,
            ),
          ),
          AppSpacing.gapSm,
          for (final m in measurements)
            ListTile(
              key: ValueKey('measurement-${m.id}'),
              title: Text(AppFormat.date(context, m.recordedAt)),
              subtitle: Text(
                [
                  for (final field in MeasurementField.values)
                    if (field.valueOf(m) case final value?)
                      '${field.label(l10n)} ${field.format(context, value)}',
                ].join(' · '),
              ),
              trailing: IconButton(
                tooltip: l10n.actionDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _delete(context, ref, m),
              ),
            ),
        ],
      ),
    );
  }
}
