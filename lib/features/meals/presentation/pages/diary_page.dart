import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/presentation/widgets/activity_card.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';
import '../../../food/domain/usecases/log_food.dart';
import '../../../progress/presentation/widgets/add_weight_sheet.dart';
import '../diary_format.dart';
import '../providers/diary_providers.dart';
import '../widgets/diary_calorie_card.dart';
import '../widgets/diary_header.dart';
import '../widgets/diary_score_card.dart';
import '../widgets/diary_water_card.dart';
import '../widgets/food_entry_actions.dart';
import '../widgets/meal_section_card.dart';
import '../widgets/quick_add_sheet.dart';

/// Günlük beslenme kaydının yönetildiği ekran: gün seçimi, kalori ve makro
/// özeti, öğünler, su, aktivite, kilo ve beslenme skoru.
class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  /// Bu genişliğin üzerinde içerik iki sütuna bölünür.
  static const _twoColumnWidth = 900.0;
  static const _wideMaxWidth = 1200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(diaryStatusProvider);
    final handler = _DiaryHandler(context, ref);

    final Widget body;
    if (status.error != null) {
      body = ErrorView(
        error: status.error,
        onRetry: () => ref.invalidate(dailyLogProvider),
      );
    } else if (!status.hasValue) {
      body = const LoadingView();
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) => _DiaryContent(
          handler: handler,
          isEmpty: status.isEmpty,
          twoColumns: constraints.maxWidth >= _twoColumnWidth,
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: context.l10n.dashboardQuickActions,
        onPressed: handler.openQuickAdd,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapSm,
            const ResponsiveCenter(
              padding: EdgeInsets.zero,
              maxWidth: _wideMaxWidth,
              child: DiaryHeader(),
            ),
            const Divider(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _DiaryContent extends ConsumerWidget {
  const _DiaryContent({
    required this.handler,
    required this.isEmpty,
    required this.twoColumns,
  });

  final _DiaryHandler handler;
  final bool isEmpty;
  final bool twoColumns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gap = SizedBox(height: AppSpacing.lg);
    final meals = [
      for (final type in MealType.values)
        MealSectionCard(
          key: ValueKey(type),
          type: type,
          onAddFood: () => handler.addFood(type),
          onEntryAction: handler.onEntryAction,
        ),
    ];
    final primary = <Widget>[
      const _DayNote(),
      const DiaryCalorieCard(),
      if (isEmpty) _EmptyDayCard(onAddFood: () => handler.addFood(null)),
      ...meals,
    ];
    final secondary = <Widget>[
      DiaryWaterCard(
        key: const ValueKey('diary-water'),
        onAdd: handler.addWater,
        onRemove: handler.removeWater,
      ),
      const _DiaryActivityCard(),
      _DiaryWeightCard(onAdd: handler.addWeight),
      const DiaryScoreCard(),
    ];

    ref.listen(diaryFocusProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = next.section == AppRoutes.waterSection
            ? const ValueKey('diary-water')
            : ValueKey(next.meal);
        final found = _findByKey(context, key);
        if (found != null) {
          Scrollable.ensureVisible(
            found,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1,
          );
        }
        ref.read(diaryFocusProvider.notifier).clear();
      });
    });
    const padding = EdgeInsets.only(
      top: AppSpacing.lg,
      // FAB içeriğin son kartını kapatmasın.
      bottom: AppSpacing.xxxl + AppSpacing.xxxl,
    );

    if (twoColumns) {
      Widget column(List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) gap, child],
        ],
      );
      return SingleChildScrollView(
        padding: padding,
        child: ResponsiveCenter(
          maxWidth: DiaryPage._wideMaxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: column(primary)),
              AppSpacing.gapXl,
              Expanded(flex: 2, child: column(secondary)),
            ],
          ),
        ),
      );
    }

    final sections = [...primary, ...secondary];
    return ListView.separated(
      padding: padding,
      itemCount: sections.length,
      separatorBuilder: (_, _) => gap,
      itemBuilder: (context, index) => ResponsiveCenter(
        maxWidth: Breakpoints.maxContentWidth,
        child: sections[index],
      ),
    );
  }
}

BuildContext? _findByKey(BuildContext context, Key key) {
  BuildContext? found;
  void visit(Element element) {
    if (found != null) return;
    if (element.widget.key == key) {
      found = element;
      return;
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return found;
}

/// Geçmiş veya gelecek bir gün seçiliyken kısa bir bilgi satırı.
class _DayNote extends ConsumerWidget {
  const _DayNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = DiaryDayKind.of(
      ref.watch(selectedDateProvider),
      ref.watch(clockProvider)(),
    );
    if (kind == DiaryDayKind.today) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          kind == DiaryDayKind.past
              ? Icons.history_rounded
              : Icons.event_note_rounded,
          size: AppSizes.iconSm,
          color: context.colors.onSurfaceVariant,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Text(
            kind == DiaryDayKind.past
                ? context.l10n.diaryPastDayNote
                : context.l10n.diaryFutureDayNote,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDayCard extends ConsumerWidget {
  const _EmptyDayCard({required this.onAddFood});

  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = DiaryDayKind.of(
      ref.watch(selectedDateProvider),
      ref.watch(clockProvider)(),
    );
    return AppCard(
      color: context.colors.secondaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: AppSizes.iconLg,
            color: context.colors.primary,
          ),
          AppSpacing.gapMd,
          Text(
            l10n.diaryEmptyDayTitle(kind.name),
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapXs,
          Text(
            l10n.diaryEmptyDayMessage,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapLg,
          FilledButton.icon(
            onPressed: onAddFood,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.quickAddFood),
          ),
        ],
      ),
    );
  }
}

class _DiaryActivityCard extends ConsumerWidget {
  const _DiaryActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(diaryActivityProvider);
    if (activity == null) return const SizedBox.shrink();
    final isToday = ref
        .watch(selectedDateProvider)
        .isSameDay(ref.watch(clockProvider)());
    return ActivityCard(
      activity: activity,
      stepGoal: ref.watch(diaryTargetsProvider.select((t) => t.steps)),
      title: isToday ? context.l10n.diaryActivityTitleToday : null,
      onTap: () => context.push(AppRoutes.activity),
    );
  }
}

class _DiaryWeightCard extends ConsumerWidget {
  const _DiaryWeightCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kg = ref.watch(diaryWeightProvider);
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(
                  icon: Icons.monitor_weight_outlined,
                  title: l10n.diaryWeightTitle,
                  color: context.colors.primary,
                ),
                AppSpacing.gapSm,
                Text(
                  kg == null
                      ? l10n.diaryWeightEmpty
                      : l10n.diaryWeightValue(AppFormat.decimal(context, kg)),
                  style: kg == null
                      ? context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        )
                      : context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.actionAdd),
          ),
        ],
      ),
    );
  }
}

/// Sayfadaki kullanıcı etkileşimlerini [DiaryActions]'a bağlar ve sonuç
/// bildirimlerini gösterir.
class _DiaryHandler {
  const _DiaryHandler(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  DateTime get _day => ref.read(selectedDateProvider);
  DateTime get _now => ref.read(clockProvider)();
  bool get _isToday => _day.isSameDay(_now);

  void _snack(String message, {VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: onUndo == null
              ? null
              : SnackBarAction(
                  label: context.l10n.actionUndo,
                  onPressed: onUndo,
                ),
        ),
      );
  }

  /// [type] verilmezse bugün için saate göre öğün önerilir.
  void addFood(MealType? type) {
    final meal = type ?? (_isToday ? LogFood.suggestedMeal(_now) : null);
    _push(
      AppRoutes.withMeal(
        AppRoutes.foodSearch,
        meal,
        date: _isToday ? null : _day,
      ),
    );
  }

  void onEntryAction(MealEntry entry, FoodEntryAction action) =>
      handleFoodEntryAction(context, ref, entry, action);

  Future<void> addWater(int ml) async {
    final actions = ref.read(diaryActionsProvider);
    final l10n = context.l10n;
    unawaited(HapticFeedback.lightImpact());
    final result = await actions.addWater(ml, _day);
    if (!context.mounted) return;
    result.when(
      success: (log) => _snack(
        l10n.waterAdded(log.amountMl),
        onUndo: () => actions.removeWater(log.amountMl, [log]),
      ),
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }

  Future<void> removeWater(int ml) async {
    final actions = ref.read(diaryActionsProvider);
    final logs = ref.read(waterProgressProvider)?.logs ?? const [];
    final l10n = context.l10n;
    final result = await actions.removeWater(ml, logs);
    if (!context.mounted) return;
    result.when(
      success: (_) => _snack(l10n.diaryWaterRemoved(ml)),
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }

  Future<void> addWeight() async {
    final actions = ref.read(diaryActionsProvider);
    final l10n = context.l10n;
    final current =
        ref.read(diaryWeightProvider) ??
        ref.read(userProfileProvider).value?.weight;
    final input = await showAddWeightSheet(
      context,
      now: _now,
      initialKg: current,
      // Gelecek bir güne kilo girilemez; o durumda bugün seçili gelir.
      initialDate: _day.isAfter(_now) ? null : actions.timestampFor(_day),
    );
    if (input == null || !context.mounted) return;
    final result = await actions.addWeight(input.kg, input.date);
    if (!context.mounted) return;
    result.when(
      success: (entry) => _snack(
        l10n.progressWeightSaved(AppFormat.decimal(context, entry.weightKg)),
      ),
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }

  Future<void> openQuickAdd() async {
    final action = await showQuickAddSheet(context);
    if (action == null || !context.mounted) return;
    final meal = _isToday ? LogFood.suggestedMeal(_now) : null;
    final date = _isToday ? null : _day;
    switch (action) {
      case DiaryQuickAction.food:
        addFood(null);
      case DiaryQuickAction.photo:
        _push(AppRoutes.withMeal(AppRoutes.photoLog, meal, date: date));
      case DiaryQuickAction.barcode:
        _push(AppRoutes.withMeal(AppRoutes.barcodeScanner, meal, date: date));
      case DiaryQuickAction.voice:
        _push(AppRoutes.withMeal(AppRoutes.voiceLog, meal, date: date));
      case DiaryQuickAction.water:
        final ml = await _pickWaterAmount();
        if (ml != null) await addWater(ml);
      case DiaryQuickAction.weight:
        await addWeight();
      case DiaryQuickAction.activity:
        _push(AppRoutes.activity);
    }
  }

  void _push(String location) => unawaited(context.push<void>(location));

  Future<int?> _pickWaterAmount() {
    final l10n = context.l10n;
    return showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.diaryAddWater, style: context.textStyles.titleLarge),
            AppSpacing.gapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final ml in const [100, 200, 250, 330, 500, 750])
                  ActionChip(
                    avatar: Icon(
                      Icons.water_drop_outlined,
                      size: AppSizes.iconSm,
                      color: context.nutritionColors.water,
                    ),
                    label: Text(l10n.diaryMlValue(ml)),
                    onPressed: () => Navigator.of(context).pop(ml),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
