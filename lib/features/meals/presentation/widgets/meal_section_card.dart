import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../food/presentation/food_format.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/usecases/diary_actions.dart';
import '../diary_format.dart';
import '../providers/diary_providers.dart';

enum FoodEntryAction { edit, copy, move, favorite, delete }

/// Bir öğün kartı: başlık, toplam kalori, yiyecekler ve "Yemek ekle".
/// Yalnızca kendi öğünü değiştiğinde yeniden çizilir.
class MealSectionCard extends ConsumerWidget {
  const MealSectionCard({
    super.key,
    required this.type,
    required this.onAddFood,
    required this.onEntryAction,
    this.lockExpanded = false,
  });

  final MealType type;
  final VoidCallback onAddFood;
  final void Function(MealEntry entry, FoodEntryAction action) onEntryAction;

  /// Tek öğün görünümünde kart daraltılamaz; yiyecekler hemen görünür.
  final bool lockExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final meal = ref.watch(mealLogProvider(type)) ?? MealLog(type: type);
    final collapsed =
        !lockExpanded &&
        ref.watch(collapsedMealsProvider.select((s) => s.contains(type)));
    final favorites = ref.watch(favoriteFoodIdsProvider);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MealHeader(
            meal: meal,
            collapsed: collapsed,
            onToggle: lockExpanded
                ? null
                : () => ref.read(collapsedMealsProvider.notifier).toggle(type),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: collapsed
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (meal.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xs,
                          ),
                          child: Text(
                            l10n.diaryMealEmptyHint(type.name),
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        for (final entry in meal.entries) ...[
                          const Divider(indent: AppSpacing.lg),
                          FoodEntryTile(
                            key: ValueKey(entry.id),
                            entry: entry,
                            isFavorite: favorites.contains(
                              DiaryActions.favoriteIdFor(entry),
                            ),
                            onAction: (action) => onEntryAction(entry, action),
                          ),
                        ],
                      if (!meal.isEmpty) const Divider(indent: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: onAddFood,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.quickAddFood),
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

class _MealHeader extends StatelessWidget {
  const _MealHeader({
    required this.meal,
    required this.collapsed,
    required this.onToggle,
  });

  static const _leadingSize = 40.0;

  final MealLog meal;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = meal.total;
    final isEmpty = meal.isEmpty;
    final label = meal.type.label(l10n);

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: _leadingSize,
              height: _leadingSize,
              decoration: BoxDecoration(
                color: isEmpty
                    ? context.colors.surfaceContainerHighest
                    : context.colors.secondaryContainer,
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(
                meal.type.icon,
                size: AppSizes.iconSm + 2,
                color: isEmpty
                    ? context.colors.onSurfaceVariant
                    : context.colors.onSecondaryContainer,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      label,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    isEmpty
                        ? l10n.mealEmpty
                        : FoodFormat.macros(
                            context,
                            total.proteinG,
                            total.carbsG,
                            total.fatG,
                          ),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                l10n.kcalValue(AppFormat.integer(context, total.calories)),
                key: ValueKey(total.calories.round()),
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isEmpty ? context.colors.onSurfaceVariant : null,
                ),
              ),
            ),
            if (onToggle != null)
              IconButton(
                tooltip: collapsed ? l10n.diaryExpand : l10n.diaryCollapse,
                onPressed: onToggle,
                icon: AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Günlükteki tek bir yiyecek: ad, porsiyon, makrolar, kalori ve menü.
class FoodEntryTile extends StatelessWidget {
  const FoodEntryTile({
    super.key,
    required this.entry,
    required this.onAction,
    this.isFavorite = false,
  });

  final MealEntry entry;
  final bool isFavorite;
  final ValueChanged<FoodEntryAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final n = entry.nutrition;

    return InkWell(
      onTap: () => onAction(FoodEntryAction.edit),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapXs,
                  Text(
                    DiaryFormat.portion(context, entry),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    FoodFormat.macros(context, n.proteinG, n.carbsG, n.fatG),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            Text(
              l10n.kcalValue(AppFormat.integer(context, n.calories)),
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            PopupMenuButton<FoodEntryAction>(
              tooltip: l10n.diaryEntryMenu,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: onAction,
              itemBuilder: (context) => [
                _item(
                  FoodEntryAction.edit,
                  Icons.edit_outlined,
                  l10n.diaryEntryEdit,
                ),
                _item(
                  FoodEntryAction.copy,
                  Icons.content_copy_rounded,
                  l10n.diaryEntryCopy,
                ),
                _item(
                  FoodEntryAction.move,
                  Icons.drive_file_move_outline,
                  l10n.diaryEntryMove,
                ),
                _item(
                  FoodEntryAction.favorite,
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  isFavorite ? l10n.foodFavoriteRemove : l10n.foodFavoriteAdd,
                ),
                const PopupMenuDivider(),
                _item(
                  FoodEntryAction.delete,
                  Icons.delete_outline_rounded,
                  l10n.actionDelete,
                  color: context.colors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<FoodEntryAction> _item(
    FoodEntryAction value,
    IconData icon,
    String label, {
    Color? color,
  }) => PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm + 2, color: color),
        AppSpacing.gapMd,
        Flexible(
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    ),
  );
}
