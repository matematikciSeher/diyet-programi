import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../../domain/usecases/diary_actions.dart';
import '../diary_format.dart';
import '../providers/diary_providers.dart';
import 'edit_food_entry_sheet.dart';
import 'meal_section_card.dart';

/// Yiyecek menüsündeki (⋮) ve karta dokunmadaki işlemleri yürütür.
Future<void> handleFoodEntryAction(
  BuildContext context,
  WidgetRef ref,
  MealEntry entry,
  FoodEntryAction action,
) async {
  final actions = ref.read(diaryActionsProvider);
  final l10n = context.l10n;

  switch (action) {
    case FoodEntryAction.edit:
      final edit = await showEditFoodEntrySheet(context, entry);
      if (edit == null || !context.mounted) return;
      if (edit.factor == 1 && edit.mealType == entry.mealType) return;
      final result = await actions.updateEntry(
        entry,
        factor: edit.factor,
        mealType: edit.mealType,
      );
      if (context.mounted) {
        _showResult(context, result, l10n.diaryEntryUpdated(entry.name));
      }

    case FoodEntryAction.copy:
      final today = ref.read(clockProvider)().startOfDay;
      final day = await _pickCopyTarget(context, today);
      if (day == null || !context.mounted) return;
      final result = await actions.copyEntry(entry, day);
      if (!context.mounted) return;
      _showResult(
        context,
        result,
        l10n.diaryEntryCopied(entry.name, DiaryFormat.dayMonth(context, day)),
        onUndo: () => result.valueOrNull == null
            ? null
            : actions.deleteEntry(result.valueOrNull!),
      );

    case FoodEntryAction.move:
      final to = await _pickMealType(context, entry.mealType);
      if (to == null || to == entry.mealType || !context.mounted) return;
      final result = await actions.moveEntry(entry, to);
      if (!context.mounted) return;
      _showResult(
        context,
        result,
        l10n.diaryEntryMoved(entry.name, to.label(l10n)),
        onUndo: () => actions.moveEntry(entry, entry.mealType),
      );

    case FoodEntryAction.favorite:
      final isFavorite = ref
          .read(favoriteFoodIdsProvider)
          .contains(DiaryActions.favoriteIdFor(entry));
      final result = await actions.setFavorite(entry, favorite: !isFavorite);
      if (!context.mounted) return;
      _showResult(
        context,
        result,
        isFavorite
            ? l10n.diaryFavoriteRemoved(entry.name)
            : l10n.diaryFavoriteAdded(entry.name),
      );

    case FoodEntryAction.delete:
      if (!await _confirmDelete(context) || !context.mounted) return;
      final result = await actions.deleteEntry(entry);
      if (!context.mounted) return;
      _showResult(
        context,
        result,
        l10n.diaryEntryDeleted(entry.name),
        onUndo: () => actions.restoreEntry(entry),
      );
  }
}

void _showResult(
  BuildContext context,
  Result<Object?> result,
  String successMessage, {
  Future<Object?>? Function()? onUndo,
}) {
  final message = result.when(
    success: (_) => successMessage,
    failure: (f) => f.localizedMessage(context),
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: result.isSuccess && onUndo != null
            ? SnackBarAction(label: context.l10n.actionUndo, onPressed: onUndo)
            : null,
      ),
    );
}

Future<bool> _confirmDelete(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded),
      title: Text(l10n.diaryDeleteTitle),
      content: Text(l10n.diaryDeleteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<MealType?> _pickMealType(BuildContext context, MealType current) {
  final l10n = context.l10n;
  return showModalBottomSheet<MealType>(
    context: context,
    useSafeArea: true,
    builder: (context) => _SheetList(
      title: l10n.diaryMoveTitle,
      children: [
        for (final type in MealType.values)
          ListTile(
            leading: Icon(type.icon),
            title: Text(type.label(l10n)),
            trailing: type == current
                ? Icon(Icons.check_rounded, color: context.colors.primary)
                : null,
            enabled: type != current,
            onTap: () => Navigator.of(context).pop(type),
          ),
      ],
    ),
  );
}

enum _CopyTarget { today, tomorrow, pick }

Future<DateTime?> _pickCopyTarget(BuildContext context, DateTime today) async {
  final l10n = context.l10n;
  final target = await showModalBottomSheet<_CopyTarget>(
    context: context,
    useSafeArea: true,
    builder: (context) => _SheetList(
      title: l10n.diaryCopyTitle,
      children: [
        ListTile(
          leading: const Icon(Icons.today_rounded),
          title: Text(l10n.diaryCopyToday),
          onTap: () => Navigator.of(context).pop(_CopyTarget.today),
        ),
        ListTile(
          leading: const Icon(Icons.event_rounded),
          title: Text(l10n.diaryCopyTomorrow),
          onTap: () => Navigator.of(context).pop(_CopyTarget.tomorrow),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month_rounded),
          title: Text(l10n.diaryPickDate),
          onTap: () => Navigator.of(context).pop(_CopyTarget.pick),
        ),
      ],
    ),
  );
  if (target == null || !context.mounted) return null;
  return switch (target) {
    _CopyTarget.today => today,
    _CopyTarget.tomorrow => today.addDays(1),
    _CopyTarget.pick => showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DiaryDateRange.first(today),
      lastDate: DiaryDateRange.last(today),
      currentDate: today,
    ),
  };
}

class _SheetList extends StatelessWidget {
  const _SheetList({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Text(title, style: context.textStyles.titleLarge),
          ),
          ...children,
        ],
      ),
    );
  }
}
