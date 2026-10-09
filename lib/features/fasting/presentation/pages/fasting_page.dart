import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../domain/models/fasting_schedule.dart';
import '../providers/fasting_providers.dart';

String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(h)}:${two(m)}:${two(s)}';
}

String _hoursMinutes(BuildContext context, Duration d) =>
    context.l10n.fastingHoursMinutes(d.inHours, d.inMinutes % 60);

/// Protokol seçimi, dairesel zamanlayıcı, geçmiş ve yeme penceresindeki
/// plan öğünleri. Tıbbi tavsiye vermez.
class FastingPage extends ConsumerWidget {
  const FastingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(fastingScheduleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureFasting)),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xxxl,
        ),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProtocolPicker(selected: schedule?.protocol),
                AppSpacing.gapLg,
                if (schedule == null)
                  EmptyStateView(
                    icon: Icons.timer_outlined,
                    title: l10n.fastingEmptyTitle,
                    message: l10n.fastingEmptyMessage,
                  )
                else ...[
                  _WindowCard(schedule: schedule),
                  AppSpacing.gapLg,
                  _TimerCard(schedule: schedule),
                  AppSpacing.gapLg,
                  const _EatingWindowMeals(),
                  const _HistoryCard(),
                ],
                AppSpacing.gapLg,
                const _Disclaimer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolPicker extends ConsumerWidget {
  const _ProtocolPicker({required this.selected});

  final FastingPreference? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final active = ref.watch(activeFastProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.fastingProtocolTitle, style: context.textStyles.titleMedium),
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final p in FastingPreference.protocols)
              ChoiceChip(
                key: ValueKey('fasting-protocol-${p.name}'),
                label: Text('${p.fastingHours}:${p.eatingHours}'),
                selected: selected == p,
                onSelected: active != null
                    ? null
                    : (_) async {
                        if (selected == p) return;
                        final confirmed = await showAppConfirmDialog(
                          context,
                          title: context.l10n.confirmFastingTitle,
                          message: context.l10n.confirmFastingMessage,
                        );
                        if (!confirmed || !context.mounted) return;
                        final result = await ref
                            .read(fastingControllerProvider)
                            .selectProtocol(p);
                        if (!context.mounted) return;
                        if (result case Err(:final failure)) {
                          context.showSnack(failure.localizedMessage(context));
                        }
                      },
              ),
          ],
        ),
        if (active != null) ...[
          AppSpacing.gapXs,
          Text(
            l10n.fastingProtocolLocked,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _WindowCard extends ConsumerWidget {
  const _WindowCard({required this.schedule});

  final FastingSchedule schedule;

  Future<void> _pickStart(BuildContext context, WidgetRef ref) async {
    final start = schedule.eatingStartMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start ~/ 60, minute: start % 60),
      helpText: context.l10n.fastingEatingStartPicker,
    );
    if (picked == null || !context.mounted) return;
    await ref
        .read(fastingControllerProvider)
        .setEatingWindowStart(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    String t(int m) => AppFormat.minutesOfDay(context, m);
    final colors = context.colors;

    Widget window(String label, String range, Color color, IconData icon) =>
        Expanded(
          child: Row(
            children: [
              Icon(icon, color: color),
              AppSpacing.gapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(range, style: context.textStyles.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              window(
                l10n.fastingPhaseFasting,
                '${t(schedule.fastingStartMinutes)}–${t(schedule.fastingEndMinutes)}',
                colors.primary,
                Icons.nightlight_outlined,
              ),
              window(
                l10n.fastingPhaseEating,
                '${t(schedule.eatingStartMinutes)}–${t(schedule.eatingEndMinutes)}',
                context.nutritionColors.success,
                Icons.restaurant_rounded,
              ),
            ],
          ),
          AppSpacing.gapSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _pickStart(context, ref),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(l10n.fastingChangeWindow),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends ConsumerWidget {
  const _TimerCard({required this.schedule});

  final FastingSchedule schedule;

  Future<void> _run(
    BuildContext context,
    Future<Result<FastingSession>> Function() action, {
    String Function(FastingSession)? message,
  }) async {
    final result = await action();
    if (!context.mounted) return;
    switch (result) {
      case Success(:final value):
        if (message != null) context.showSnack(message(value));
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final timer = ref.watch(fastingTimerProvider);
    if (timer == null) return const SizedBox.shrink();
    final controller = ref.read(fastingControllerProvider);
    final session = timer.session;
    final fasting = timer.isFasting;
    final color = fasting
        ? context.colors.primary
        : context.nutritionColors.success;
    final ends = timer.phaseEndsAt;

    final String subtitle;
    if (fasting) {
      subtitle = timer.targetReached
          ? l10n.fastingTargetReached
          : l10n.fastingRemaining(formatClock(timer.remaining));
    } else {
      subtitle = l10n.fastingEatingRemaining(formatClock(timer.remaining));
    }

    return AppCard(
      child: Column(
        children: [
          ProgressRing(
            progress: timer.progress,
            size: 240,
            strokeWidth: 16,
            color: color,
            semanticLabel: l10n.fastingTimerSemantics(
              fasting ? l10n.fastingPhaseFasting : l10n.fastingPhaseEating,
              formatClock(fasting ? timer.elapsed : timer.remaining),
            ),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (fasting ? l10n.fastingPhaseFasting : l10n.fastingPhaseEating)
                      .toUpperCase(),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: color,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  formatClock(fasting ? timer.elapsed : timer.remaining),
                  key: const ValueKey('fasting-clock'),
                  style: context.textStyles.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (timer.isPaused)
                  Text(
                    l10n.fastingPaused,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.nutritionColors.warning,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium,
          ),
          if (ends != null) ...[
            AppSpacing.gapXs,
            Text(
              fasting
                  ? l10n.fastingEndsAt(
                      AppFormat.minutesOfDay(
                        context,
                        ends.hour * 60 + ends.minute,
                      ),
                    )
                  : l10n.fastingEatingEndsAt(
                      AppFormat.minutesOfDay(
                        context,
                        ends.hour * 60 + ends.minute,
                      ),
                    ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          AppSpacing.gapLg,
          if (session == null)
            FilledButton.icon(
              key: const ValueKey('fasting-start'),
              onPressed: () => _run(
                context,
                () => controller.start(schedule),
                message: (_) => l10n.fastingStarted,
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.fastingStart),
            )
          else
            Row(
              children: [
                Expanded(
                  child: session.isPaused
                      ? OutlinedButton.icon(
                          key: const ValueKey('fasting-resume'),
                          onPressed: () =>
                              _run(context, () => controller.resume(session)),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l10n.fastingResume),
                        )
                      : OutlinedButton.icon(
                          key: const ValueKey('fasting-pause'),
                          onPressed: () =>
                              _run(context, () => controller.pause(session)),
                          icon: const Icon(Icons.pause_rounded),
                          label: Text(l10n.fastingPause),
                        ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('fasting-finish'),
                    onPressed: () => _run(
                      context,
                      () => controller.finish(session),
                      message: (s) => s.completed
                          ? l10n.fastingFinishedCompleted(
                              _hoursMinutes(context, s.elapsed(s.endedAt!)),
                            )
                          : l10n.fastingFinishedEarly(
                              _hoursMinutes(context, s.elapsed(s.endedAt!)),
                            ),
                    ),
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(l10n.fastingFinish),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EatingWindowMeals extends ConsumerWidget {
  const _EatingWindowMeals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final meals = ref.watch(eatingWindowMealsProvider);
    if (meals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        onTap: () => context.push(AppRoutes.nutritionPlan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardTitle(
              icon: Icons.restaurant_menu_rounded,
              title: l10n.fastingWindowMealsTitle,
              color: context.nutritionColors.success,
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            AppSpacing.gapSm,
            for (final m in meals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        AppFormat.minutesOfDay(context, m.timeMinutes!),
                        style: context.textStyles.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${m.mealType.label(l10n)} · ${m.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(fastingHistoryProvider).value;
    if (history == null) return const SizedBox.shrink();

    Widget group(String title, List<FastingSession> sessions) {
      if (sessions.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              title,
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          for (final s in sessions) _SessionTile(session: s),
        ],
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: CardTitle(
              icon: Icons.history_rounded,
              title: l10n.fastingHistoryTitle,
              color: context.colors.primary,
            ),
          ),
          AppSpacing.gapMd,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: StatGrid(
              children: [
                StatTile(
                  icon: Icons.check_circle_outline_rounded,
                  label: l10n.fastingStatCompleted,
                  value: '${history.completedCount}/${history.sessionCount}',
                  caption: l10n.fastingLast7Days,
                  color: context.nutritionColors.success,
                ),
                StatTile(
                  icon: Icons.av_timer_rounded,
                  label: l10n.fastingStatAverage,
                  value: history.averageDuration == null
                      ? '—'
                      : _hoursMinutes(context, history.averageDuration!),
                  caption: l10n.fastingLast7Days,
                ),
              ],
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.fastingHistoryEmpty,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            group(l10n.diaryToday, history.today),
            group(l10n.diaryYesterday, history.yesterday),
            group(l10n.fastingLast7Days, history.earlier),
          ],
        ],
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final FastingSession session;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = ref.read(fastingControllerProvider);
    final result = await controller.delete(session);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.fastingSessionDeleted),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () => controller.restore(session),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final end = session.endedAt!;
    final duration = session.elapsed(end);
    String time(DateTime d) =>
        AppFormat.minutesOfDay(context, d.hour * 60 + d.minute);
    final protocol = session.protocol;

    return ListTile(
      key: ValueKey('fasting-session-${session.id}'),
      leading: Icon(
        session.completed
            ? Icons.check_circle_rounded
            : Icons.timelapse_rounded,
        color: session.completed
            ? context.nutritionColors.success
            : context.colors.onSurfaceVariant,
      ),
      title: Text(_hoursMinutes(context, duration)),
      subtitle: Text(
        [
          '${time(session.startedAt)}–${time(end)}',
          if (protocol != null && protocol != FastingPreference.none)
            '${protocol.fastingHours}:${protocol.eatingHours}',
          session.completed ? l10n.fastingCompleted : l10n.fastingEndedEarly,
        ].join(' · '),
      ),
      trailing: IconButton(
        tooltip: l10n.actionDelete,
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () => _delete(context, ref),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.colors.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.colors.onSurfaceVariant,
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Text(
              context.l10n.fastingDisclaimer,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}