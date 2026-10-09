import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../shared/models/food.dart';
import '../../data/datasources/food_api_config.dart';
import '../../domain/models/portion_selection.dart';
import '../providers/food_providers.dart';
import 'food_list_tile.dart';
import 'nutrition_facts_panel.dart';
import 'portion_editor.dart';

/// Tarif malzemesi seçimi: önce yiyecek, ardından miktar.
Future<Food?> pickFood(BuildContext context) {
  return showModalBottomSheet<Food>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.9,
      child: _FoodPickerSheet(),
    ),
  );
}

Future<(Food, PortionSelection)?> pickIngredient(BuildContext context) async {
  final food = await pickFood(context);
  if (food == null || !context.mounted) return null;
  final selection = await showPortionSheet(context, food);
  return selection == null ? null : (food, selection);
}

/// Bir yiyecek için miktar/ölçü seçtirir.
Future<PortionSelection?> showPortionSheet(
  BuildContext context,
  Food food, {
  PortionSelection? initial,
}) {
  return showModalBottomSheet<PortionSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PortionSheet(food: food, initial: initial),
  );
}

class _FoodPickerSheet extends ConsumerStatefulWidget {
  const _FoodPickerSheet();

  @override
  ConsumerState<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<_FoodPickerSheet> {
  final _debounce = Debouncer(duration: FoodApiConfig.searchDebounce);
  var _query = '';

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce.run(() {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calc = ref.watch(foodCalculationServiceProvider);

    final List<Food> foods;
    var loading = false;
    if (_query.isEmpty) {
      final recents = ref.watch(recentFoodsProvider).value ?? const [];
      final custom = ref.watch(customFoodsProvider).value ?? const [];
      final seen = <String>{};
      foods = [
        for (final f in [...recents.map((r) => r.food), ...custom])
          if (seen.add(f.id)) f,
      ];
    } else {
      final results = ref.watch(foodSearchResultsProvider(_query));
      loading = results.isLoading;
      foods = results.value ?? const [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.page,
          child: Text(
            l10n.foodPickerTitle,
            style: context.textStyles.titleLarge,
          ),
        ),
        AppSpacing.gapMd,
        Padding(
          padding: AppSpacing.page,
          child: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.foodSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: _onChanged,
          ),
        ),
        if (loading) const LinearProgressIndicator() else AppSpacing.gapXs,
        Expanded(
          child: foods.isEmpty && _query.isNotEmpty && !loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      l10n.foodNoResults(_query),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, i) {
                    final food = foods[i];
                    final selection = calc.defaultSelection(food);
                    return FoodListTile(
                      food: food,
                      selection: selection,
                      nutrition: calc.nutritionFor(food, selection),
                      onTap: () => Navigator.of(context).pop(food),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PortionSheet extends ConsumerStatefulWidget {
  const _PortionSheet({required this.food, this.initial});

  final Food food;
  final PortionSelection? initial;

  @override
  ConsumerState<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends ConsumerState<_PortionSheet> {
  late PortionSelection _selection =
      widget.initial ??
      ref.read(foodCalculationServiceProvider).defaultSelection(widget.food);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calc = ref.watch(foodCalculationServiceProvider);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.food.name, style: context.textStyles.titleLarge),
          AppSpacing.gapLg,
          PortionEditor(
            food: widget.food,
            portions: calc.portionsFor(widget.food),
            initial: _selection,
            onChanged: (s) => setState(() => _selection = s),
          ),
          AppSpacing.gapLg,
          NutritionFactsPanel(
            nutrition: calc.nutritionFor(widget.food, _selection),
            showDetails: false,
          ),
          AppSpacing.gapXl,
          AppButton(
            label: l10n.actionAdd,
            icon: Icons.add_rounded,
            onPressed: _selection.isValid
                ? () => Navigator.of(context).pop(_selection)
                : null,
          ),
        ],
      ),
    );
  }
}
