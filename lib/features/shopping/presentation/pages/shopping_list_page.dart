import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../data/repositories/shopping_list_repository_impl.dart';
import '../../domain/models/shopping_list_item.dart';
import '../providers/shopping_list_providers.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(shoppingListItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingMyList),
        actions: [
          IconButton(
            tooltip: l10n.shoppingClearCompleted,
            onPressed: () =>
                ref.read(shoppingListRepositoryProvider).clearCompleted(),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addManual(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.shoppingAddItem),
      ),
      body: AsyncValueView(
        value: items,
        loading: (_) => const SkeletonView(),
        onRetry: () => ref.invalidate(shoppingListItemsProvider),
        data: (list) => ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxxl * 2,
          ),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    key: const ValueKey('shopping-generate-week'),
                    onPressed: () => _generateWeek(context, ref),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(l10n.shoppingGenerateWeek),
                  ),
                  AppSpacing.gapLg,
                  if (list.isEmpty)
                    EmptyStateView(
                      icon: Icons.shopping_basket_outlined,
                      title: l10n.shoppingEmptyTitle,
                      message: l10n.shoppingEmptyMessage,
                    )
                  else
                    for (final category in ShoppingCategory.values)
                      _CategorySection(
                        category: category,
                        items: [
                          for (final item in list)
                            if (item.category == category) item,
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateWeek(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(shoppingListActionsProvider).generateWeek();
    if (!context.mounted) return;
    context.showSnack(context.l10n.shoppingGenerated(count));
  }

  Future<void> _addManual(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<(String, double, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddItemSheet(),
    );
    if (created == null || !context.mounted) return;
    final result = await ref
        .read(shoppingListActionsProvider)
        .addManual(name: created.$1, quantity: created.$2, unit: created.$3);
    if (!context.mounted) return;
    if (result case Err(:final failure)) {
      context.showSnack(failure.localizedMessage(context));
    }
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category, required this.items});

  final ShoppingCategory category;
  final List<ShoppingListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            category.label(l10n),
            style: context.textStyles.titleSmall,
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const Divider(height: 1),
                CheckboxListTile(
                  key: ValueKey('shop-${item.id}'),
                  value: item.isCompleted,
                  onChanged: (_) =>
                      ref.read(shoppingListActionsProvider).toggle(item),
                  title: Text(
                    item.name,
                    style: item.isCompleted
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: Text(
                    '${AppFormat.decimal(context, item.quantity)} ${item.unit}'
                    '${item.sourceRecipeId != null
                        ? ' · ${l10n.shoppingFromRecipe}'
                        : item.sourceMealPlanId != null
                        ? ' · ${l10n.shoppingFromPlan}'
                        : ''}',
                  ),
                  secondary: IconButton(
                    tooltip: l10n.actionDelete,
                    onPressed: () =>
                        ref.read(shoppingListActionsProvider).delete(item.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
        AppSpacing.gapLg,
      ],
    );
  }
}

extension ShoppingCategoryL10n on ShoppingCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ShoppingCategory.produce => '🥬 ${l10n.shoppingCategoryProduce}',
    ShoppingCategory.meat => '🥩 ${l10n.shoppingCategoryMeat}',
    ShoppingCategory.dairy => '🥛 ${l10n.shoppingCategoryDairy}',
    ShoppingCategory.grains => '🌾 ${l10n.shoppingCategoryGrains}',
    ShoppingCategory.breakfast => '🥚 ${l10n.shoppingCategoryBreakfast}',
    ShoppingCategory.other => '🥫 ${l10n.shoppingCategoryOther}',
  };
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _unit = TextEditingController(text: 'adet');

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.shoppingAddItem, style: context.textStyles.titleLarge),
          AppSpacing.gapMd,
          AppTextField(controller: _name, label: l10n.shoppingItemName),
          AppSpacing.gapMd,
          AppTextField(
            controller: _qty,
            label: l10n.shoppingQuantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          AppSpacing.gapMd,
          AppTextField(controller: _unit, label: l10n.shoppingUnit),
          AppSpacing.gapLg,
          FilledButton(
            onPressed: () {
              final qty = double.tryParse(_qty.text.replaceAll(',', '.')) ?? 1;
              final name = _name.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop((name, qty, _unit.text.trim()));
            },
            child: Text(l10n.shoppingAddItem),
          ),
        ],
      ),
    );
  }
}
