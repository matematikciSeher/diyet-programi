import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../data/datasources/food_api_config.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/portion_selection.dart';
import '../providers/food_providers.dart';
import 'food_list_tile.dart';
import 'open_food_facts_attribution.dart';
import 'sample_data_notice.dart';

class FoodSearchResultsList extends ConsumerStatefulWidget {
  const FoodSearchResultsList({
    super.key,
    required this.query,
    required this.meal,
    required this.onOpen,
    required this.onQuickAdd,
    this.date,
  });

  final String query;
  final MealType meal;
  final DateTime? date;
  final ValueChanged<Food> onOpen;
  final Future<void> Function(Food, PortionSelection) onQuickAdd;

  @override
  ConsumerState<FoodSearchResultsList> createState() =>
      _FoodSearchResultsListState();
}

class _FoodSearchResultsListState extends ConsumerState<FoodSearchResultsList> {
  final _extra = <Food>[];
  var _page = 1;
  var _loadingMore = false;
  var _hasMore = true;

  @override
  void didUpdateWidget(covariant FoodSearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _extra.clear();
      _page = 1;
      _hasMore = true;
      _loadingMore = false;
    }
  }

  Future<void> _loadMore(int firstPageLength) async {
    if (_loadingMore || !_hasMore) return;
    if (firstPageLength < FoodApiConfig.searchPageSize && _page == 1) {
      _hasMore = false;
      return;
    }
    setState(() => _loadingMore = true);
    final next = _page + 1;
    final result = await ref
        .read(foodRepositoryProvider)
        .search(widget.query, page: next);
    if (!mounted) return;
    result.when(
      success: (foods) {
        final seen = {for (final food in _extra) food.id};
        setState(() {
          _page = next;
          _extra.addAll(foods.where((f) => seen.add(f.id)));
          _hasMore = foods.length >= FoodApiConfig.searchPageSize;
          _loadingMore = false;
        });
      },
      failure: (_) => setState(() {
        _loadingMore = false;
        _hasMore = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final results = ref.watch(foodSearchResultsProvider(widget.query));
    final calc = ref.watch(foodCalculationServiceProvider);

    return results.when(
      loading: () => const Align(
        alignment: Alignment.topCenter,
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => MessageView(
        icon: Icons.cloud_off_rounded,
        title: l10n.foodDatabaseUnavailable,
        message: l10n.foodDatabaseUnavailableHint,
        actionLabel: l10n.foodCreateCustom,
        onAction: () => context.push(
          AppRoutes.customFoodPath(meal: widget.meal, date: widget.date),
        ),
      ),
      data: (firstPage) {
        if (firstPage.isEmpty && _extra.isEmpty) {
          return MessageView(
            icon: Icons.search_off_rounded,
            title: l10n.foodNoResults(widget.query),
            message: l10n.foodNoResultsHint,
            actionLabel: l10n.foodCreateCustom,
            onAction: () => context.push(
              AppRoutes.customFoodPath(meal: widget.meal, date: widget.date),
            ),
          );
        }
        final foods = [...firstPage, ..._extra];
        final seen = <String>{};
        final unique = [for (final f in foods) if (seen.add(f.id)) f];
        final sampleSource = unique
            .where((f) => f.isSample)
            .map((f) => f.dataReference)
            .nonNulls
            .firstOrNull;
        final showOff = unique.any(
          (f) => f.dataReference == FoodApiConfig.dataReference,
        );
        final footer = sampleSource != null || showOff || _loadingMore;
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 480) {
              unawaited(_loadMore(firstPage.length));
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            itemCount: unique.length + (footer ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= unique.length) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      if (_loadingMore) const LinearProgressIndicator(),
                      if (sampleSource != null)
                        SampleDataNotice(source: sampleSource)
                      else if (showOff)
                        const OpenFoodFactsAttribution(),
                    ],
                  ),
                );
              }
              final food = unique[index];
              final selection = calc.defaultSelection(food);
              return FoodListTile(
                key: ValueKey(food.id),
                food: food,
                selection: selection,
                nutrition: calc.nutritionFor(food, selection),
                onTap: () => widget.onOpen(food),
                onQuickAdd: () => widget.onQuickAdd(food, selection),
              );
            },
          ),
        );
      },
    );
  }
}

class FoodCategoryChips extends StatelessWidget {
  const FoodCategoryChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = [
      l10n.foodCategoryFruit,
      l10n.foodCategoryVegetable,
      l10n.foodCategoryProtein,
      l10n.foodCategoryDairy,
      l10n.foodCategoryGrain,
      l10n.foodCategoryBeverage,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.page,
      child: Row(
        children: [
          for (final (i, label) in categories.indexed) ...[
            if (i > 0) AppSpacing.gapSm,
            ActionChip(label: Text(label), onPressed: () => onSelected(label)),
          ],
        ],
      ),
    );
  }
}
