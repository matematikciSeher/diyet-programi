import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../shared/models/progress_photo.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/media/photo_picker_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../subscription/domain/models/app_feature.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../../domain/models/progress_report.dart';
import '../progress_labels.dart';
import '../providers/progress_providers.dart';
import '../widgets/activity_progress_card.dart';
import '../widgets/add_measurement_sheet.dart';
import '../widgets/add_weight_sheet.dart';
import '../widgets/adherence_card.dart';
import '../widgets/measurements_card.dart';
import '../widgets/progress_photos_card.dart';
import '../widgets/score_history_card.dart';
import '../widgets/weekly_average_card.dart';
import '../widgets/weight_chart_card.dart';
import '../widgets/weight_goal_card.dart';

enum _AddAction { weight, measurement, photo }

/// Kilo, ölçü, fotoğraf ve beslenme hedeflerine uyumun zaman içindeki
/// değişimi.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  static const _twoColumnWidth = 760.0;
  static const _wideMaxWidth = 1200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final report = ref.watch(progressReportProvider);
    final actions = _ProgressPageActions(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featureProgress),
        actions: [
          PopupMenuButton<_AddAction>(
            tooltip: l10n.actionAdd,
            icon: const Icon(Icons.add_rounded),
            onSelected: (action) => switch (action) {
              _AddAction.weight => actions.addWeight(report.value),
              _AddAction.measurement => actions.addMeasurement(report.value),
              _AddAction.photo => actions.addPhoto(report.value),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _AddAction.weight,
                child: ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: Text(l10n.progressAddWeight),
                ),
              ),
              PopupMenuItem(
                value: _AddAction.measurement,
                child: ListTile(
                  leading: const Icon(Icons.straighten_rounded),
                  title: Text(l10n.progressAddMeasurement),
                ),
              ),
              PopupMenuItem(
                value: _AddAction.photo,
                child: ListTile(
                  leading: const Icon(Icons.add_a_photo_outlined),
                  title: Text(l10n.progressAddPhoto),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AsyncValueView(
        value: report,
        onRetry: () => ref
          ..invalidate(weightEntriesProvider)
          ..invalidate(measurementsProvider),
        data: (data) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoColumnWidth;
            return _ProgressBody(
              report: data,
              photos: ref.watch(progressPhotosProvider).value ?? const [],
              twoColumns: wide,
              maxWidth: wide ? _wideMaxWidth : Breakpoints.maxContentWidth,
              actions: actions,
            );
          },
        ),
      ),
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({
    required this.report,
    required this.photos,
    required this.twoColumns,
    required this.maxWidth,
    required this.actions,
  });

  final ProgressReport report;
  final List<ProgressPhoto> photos;
  final bool twoColumns;
  final double maxWidth;
  final _ProgressPageActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = SegmentedButton<ProgressRange>(
      segments: [
        for (final r in ProgressRange.values)
          ButtonSegment(value: r, label: Text(r.label(l10n))),
      ],
      selected: {report.range},
      showSelectedIcon: false,
      onSelectionChanged: (s) =>
          ref.read(progressRangeProvider.notifier).select(s.first),
    );
    final goal = WeightGoalCard(
      weight: report.weight,
      onAddWeight: () => actions.addWeight(report),
    );
    final chart = WeightChartCard(
      points: report.weightPoints,
      targetKg: report.weight?.targetKg,
      onShowHistory: actions.showWeightHistory,
    );
    final weekly = PremiumGate(
      feature: AppFeature.periodicReports,
      fallback: PremiumLockedCard(
        feature: AppFeature.periodicReports,
        title: l10n.progressWeeklyTitle,
      ),
      child: WeeklyAverageCard(
        average: report.weeklyAverage,
        direction: report.weight?.direction ?? WeightDirection.lose,
      ),
    );
    final measurements = MeasurementsCard(
      measurements: report.measurements,
      onAdd: () => actions.addMeasurement(report),
    );
    final adherence = PremiumGate(
      feature: AppFeature.advancedAnalytics,
      fallback: PremiumLockedCard(
        feature: AppFeature.advancedAnalytics,
        title: l10n.progressAdherenceTitle,
      ),
      child: AdherenceCard(
        calories: report.calorieAdherence,
        protein: report.proteinAdherence,
        water: report.waterAdherence,
      ),
    );
    final scores = PremiumGate(
      feature: AppFeature.advancedReports,
      fallback: PremiumLockedCard(
        feature: AppFeature.advancedReports,
        title: l10n.progressScoreTitle,
      ),
      child: ScoreHistoryCard(
        days: report.days,
        averageScore: report.averageScore,
      ),
    );
    final activity = const ActivityProgressCard();
    final photoCard = ProgressPhotosCard(
      photos: photos,
      onAdd: () => actions.addPhoto(report),
      onOpen: actions.openPhoto,
    );

    const gap = SizedBox(height: AppSpacing.lg);
    final Widget content;
    if (twoColumns) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: range),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    goal,
                    gap,
                    chart,
                    gap,
                    activity,
                    gap,
                    scores,
                    gap,
                    photoCard,
                  ],
                ),
              ),
              AppSpacing.gapXl,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [weekly, gap, adherence, gap, measurements],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          range,
          gap,
          goal,
          gap,
          chart,
          gap,
          activity,
          gap,
          weekly,
          gap,
          measurements,
          gap,
          adherence,
          gap,
          scores,
          gap,
          photoCard,
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl,
      ),
      child: ResponsiveCenter(maxWidth: maxWidth, child: content),
    );
  }
}

/// Sayfadaki kayıt akışları (form aç → kaydet → geri bildirim).
class _ProgressPageActions {
  _ProgressPageActions(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  ProgressActions get _actions => ref.read(progressActionsProvider);
  DateTime get _now => ref.read(clockProvider)();

  void _showFailure(Result<Object?> result) {
    if (result case Err(:final failure) when context.mounted) {
      context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> addWeight(ProgressReport? report) async {
    final l10n = context.l10n;
    final input = await showAddWeightSheet(
      context,
      now: _now,
      initialKg: report?.weight?.currentKg,
    );
    if (input == null || !context.mounted) return;
    final result = await _actions.addWeight(input.kg, at: input.date);
    if (!context.mounted) return;
    if (result case Success(value: final entry)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.progressWeightSaved(AppFormat.decimal(context, input.kg)),
            ),
            action: SnackBarAction(
              label: l10n.actionUndo,
              onPressed: () => _actions.deleteWeight(entry.id),
            ),
          ),
        );
    }
    _showFailure(result);
  }

  Future<void> addMeasurement(ProgressReport? report) async {
    final measurement = await showAddMeasurementSheet(
      context,
      now: _now,
      previous: report?.measurements ?? const [],
    );
    if (measurement == null || !context.mounted) return;
    final result = await _actions.addMeasurement(measurement);
    if (!context.mounted) return;
    if (result.isSuccess) {
      context.showSnack(context.l10n.progressMeasurementSaved);
    }
    _showFailure(result);
  }

  Future<void> addPhoto(ProgressReport? report) async {
    final actions = _actions;
    final sources = PhotoSource.values.where(actions.supportsPhotoSource);
    final source = sources.length <= 1
        ? sources.firstOrNull ?? PhotoSource.gallery
        : await _chooseSource();
    if (source == null || !context.mounted) return;
    final result = await actions.addPhoto(
      source,
      currentWeightKg: report?.weight?.currentKg,
    );
    if (!context.mounted) return;
    if (result case Success(value: _?)) {
      context.showSnack(context.l10n.progressPhotoAdded);
    }
    _showFailure(result);
  }

  Future<PhotoSource?> _chooseSource() {
    final l10n = context.l10n;
    return showModalBottomSheet<PhotoSource>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.progressPhotoCamera),
            onTap: () => Navigator.of(sheet).pop(PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.progressPhotoGallery),
            onTap: () => Navigator.of(sheet).pop(PhotoSource.gallery),
          ),
          AppSpacing.gapSm,
        ],
      ),
    );
  }

  Future<void> openPhoto(ProgressPhoto photo) async {
    final l10n = context.l10n;
    final delete = await showDialog<bool>(
      context: context,
      builder: (dialog) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ProgressPhotoImage(photo: photo, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        AppFormat.date(dialog, photo.takenAt),
                        if (photo.weightKg case final kg?)
                          ProgressFormat.kg(dialog, kg),
                      ].join(' · '),
                      style: dialog.textStyles.labelLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.progressPhotoDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => Navigator.of(dialog).pop(true),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialog).pop(false),
                    child: Text(
                      MaterialLocalizations.of(dialog).closeButtonLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (delete != true || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.progressPhotoDelete),
        content: Text(l10n.progressPhotoDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await _actions.deletePhoto(photo);
    if (!context.mounted) return;
    if (result.isSuccess) context.showSnack(l10n.progressPhotoDeleted);
    _showFailure(result);
  }

  Future<void> showWeightHistory() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _WeightHistorySheet(),
  );
}

class _WeightHistorySheet extends ConsumerWidget {
  const _WeightHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = ref.watch(weightEntriesProvider).value ?? const [];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.progressWeightHistory,
              style: context.textStyles.titleLarge,
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(l10n.progressNoWeightTitle))
                : ListView.builder(
                    controller: scroll,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      return ListTile(
                        title: Text(ProgressFormat.kg(context, entry.weightKg)),
                        subtitle: Text(
                          AppFormat.date(context, entry.recordedAt),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.actionDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            final result = await ref
                                .read(progressActionsProvider)
                                .deleteWeight(entry.id);
                            if (!context.mounted) return;
                            context.showSnack(
                              result.isSuccess
                                  ? l10n.progressEntryDeleted
                                  : result.failureOrNull!.localizedMessage(
                                      context,
                                    ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
