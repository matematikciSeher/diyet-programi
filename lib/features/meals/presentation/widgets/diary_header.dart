import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/services/service_providers.dart';
import '../diary_format.dart';
import '../providers/diary_providers.dart';

/// Başlık, gün değiştirme okları, "Bugün" kısayolu ve yatay tarih şeridi.
class DiaryHeader extends ConsumerWidget {
  const DiaryHeader({super.key});

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
    DateTime today,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DiaryDateRange.first(today),
      lastDate: DiaryDateRange.last(today),
      currentDate: today,
    );
    if (picked != null) ref.read(selectedDateProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(selectedDateProvider);
    final controller = ref.read(selectedDateProvider.notifier);
    final today = ref.watch(clockProvider)().startOfDay;
    final isToday = selected.isSameDay(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.page,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.navDiary,
                    style: context.textStyles.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isToday
                    ? const SizedBox(height: AppSizes.minTouchTarget)
                    : TextButton.icon(
                        key: const ValueKey('today'),
                        onPressed: controller.goToToday,
                        icon: const Icon(Icons.today_rounded),
                        label: Text(l10n.diaryToday),
                      ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.diaryPreviousDay,
                onPressed: controller.canGoBack ? controller.previous : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: l10n.diaryPickDate,
                  child: InkWell(
                    borderRadius: AppRadius.mdAll,
                    onTap: () => _pickDate(context, ref, selected, today),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Column(
                          key: ValueKey(selected),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    DiaryFormat.dayMonth(context, selected),
                                    style: context.textStyles.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppSpacing.gapXs,
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: AppSizes.iconSm,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ],
                            ),
                            Text(
                              DiaryFormat.relativeDay(context, selected, today),
                              style: context.textStyles.labelMedium?.copyWith(
                                color: isToday
                                    ? context.colors.primary
                                    : context.colors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.diaryNextDay,
                onPressed: controller.canGoForward ? controller.next : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        AppSpacing.gapSm,
        DiaryDateStrip(
          selected: selected,
          today: today,
          onSelected: controller.select,
        ),
      ],
    );
  }
}

/// Yatay kaydırılabilir gün seçici; seçili gün ortada tutulur.
class DiaryDateStrip extends StatefulWidget {
  const DiaryDateStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.onSelected,
  });

  static const itemExtent = 56.0;
  static const height = 68.0;

  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  @override
  State<DiaryDateStrip> createState() => _DiaryDateStripState();
}

class _DiaryDateStripState extends State<DiaryDateStrip> {
  ScrollController? _controller;
  double _viewport = 0;

  DateTime get _first => DiaryDateRange.first(widget.today);
  int get _count =>
      DiaryDateRange.maxPastDays + DiaryDateRange.maxFutureDays + 1;

  int _indexOf(DateTime day) =>
      (day.startOfDay.difference(_first).inHours / 24).round();

  double _offsetFor(DateTime day) {
    const extent = DiaryDateStrip.itemExtent;
    final max = math.max(0.0, _count * extent - _viewport);
    final centered = _indexOf(day) * extent - (_viewport - extent) / 2;
    return centered.clamp(0.0, max);
  }

  @override
  void didUpdateWidget(DiaryDateStrip old) {
    super.didUpdateWidget(old);
    final controller = _controller;
    if (!old.selected.isSameDay(widget.selected) &&
        controller != null &&
        controller.hasClients) {
      controller.animateTo(
        _offsetFor(widget.selected),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.maxWidth;
        final controller = _controller ??= ScrollController(
          initialScrollOffset: _offsetFor(widget.selected),
        );
        return SizedBox(
          height: DiaryDateStrip.height,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemExtent: DiaryDateStrip.itemExtent,
            itemCount: _count,
            itemBuilder: (context, index) {
              final day = _first.addDays(index);
              return _DayChip(
                day: day,
                selected: day.isSameDay(widget.selected),
                isToday: day.isSameDay(widget.today),
                onTap: () => widget.onSelected(day),
              );
            },
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected
        ? colors.onPrimary
        : (isToday ? colors.primary : colors.onSurface);

    return Semantics(
      button: true,
      selected: selected,
      label: MaterialLocalizations.of(context).formatFullDate(day),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected || !isToday
                  ? Colors.transparent
                  : colors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.mdAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DiaryFormat.weekdayShort(context, day),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: selected
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        '${day.day}',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
