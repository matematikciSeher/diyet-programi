import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/datasources/food_api_config.dart';
import '../../domain/models/portion_selection.dart';
import '../../domain/usecases/log_food.dart';
import '../food_log_feedback.dart';
import '../providers/food_providers.dart';
import '../widgets/food_list_tile.dart';
import '../widgets/food_search_results.dart';
import '../widgets/meal_type_selector.dart';

/// Yemek ekleme giriş noktası: arama, barkod/fotoğraf/ses kısayolları,
/// son kullanılanlar, favoriler ve kullanıcının kendi yiyecekleri.
class FoodSearchPage extends ConsumerStatefulWidget {
  const FoodSearchPage({super.key, this.initialMeal, this.logDate});

  final MealType? initialMeal;

  /// Verilirse yemekler bu güne eklenir (Günlük'te seçili gün).
  final DateTime? logDate;

  @override
  ConsumerState<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends ConsumerState<FoodSearchPage> {
  final _debounce = Debouncer(duration: FoodApiConfig.searchDebounce);
  final _controller = TextEditingController();
  var _query = '';
  late MealType _meal =
      widget.initialMeal ?? LogFood.suggestedMeal(ref.read(clockProvider)());

  @override
  void dispose() {
    _debounce.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    _debounce.run(() {
      if (mounted) setState(() => _query = text.trim());
    });
    setState(() {});
  }

  void _clear() {
    _debounce.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  void _applyQuery(String text) {
    _debounce.cancel();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _query = text.trim());
  }

  void _openDetail(Food food) {
    unawaited(
      ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.foodSelected),
    );
    context.push(
      AppRoutes.foodDetailPath(food.id, meal: _meal, date: widget.logDate),
      extra: food,
    );
  }

  Future<void> _quickAdd(Food food, PortionSelection selection) =>
      logFoodWithFeedback(
        context,
        ref,
        food: food,
        selection: selection,
        meal: _meal,
        day: widget.logDate,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logDate = widget.logDate;
    final showDate =
        logDate != null && !logDate.isSameDay(ref.watch(clockProvider)());
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.foodAddTitle),
            if (showDate)
              Text(
                AppFormat.date(context, logDate),
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.page,
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.foodSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.foodClearSearch,
                            onPressed: _clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: _onQueryChanged,
                  onSubmitted: (text) {
                    _debounce.cancel();
                    setState(() => _query = text.trim());
                  },
                ),
              ),
              AppSpacing.gapMd,
              MealTypeSelector(
                value: _meal,
                scrollable: true,
                onChanged: (meal) => setState(() => _meal = meal),
              ),
              AppSpacing.gapSm,
              _InputShortcuts(meal: _meal, date: logDate),
              if (_query.isEmpty) ...[
                AppSpacing.gapSm,
                FoodCategoryChips(onSelected: _applyQuery),
              ],
              AppSpacing.gapSm,
              Expanded(
                child: _query.isEmpty
                    ? _BrowseTabs(
                        meal: _meal,
                        date: logDate,
                        onOpen: _openDetail,
                        onQuickAdd: _quickAdd,
                      )
                    : FoodSearchResultsList(
                        query: _query,
                        meal: _meal,
                        date: logDate,
                        onOpen: _openDetail,
                        onQuickAdd: _quickAdd,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yazmak dışındaki ekleme yolları.
class _InputShortcuts extends StatelessWidget {
  const _InputShortcuts({required this.meal, this.date});

  final MealType meal;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shortcuts = [
      (
        Icons.qr_code_scanner_rounded,
        l10n.quickAddBarcode,
        AppRoutes.barcodeScanner,
      ),
      (Icons.photo_camera_outlined, l10n.quickAddPhoto, AppRoutes.photoLog),
      (Icons.mic_none_rounded, l10n.quickAddVoice, AppRoutes.voiceLog),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.page,
      child: Row(
        children: [
          for (final (i, (icon, label, route)) in shortcuts.indexed) ...[
            if (i > 0) AppSpacing.gapSm,
            ActionChip(
              avatar: Icon(icon, size: AppSizes.iconSm),
              label: Text(label),
              onPressed: () =>
                  context.push(AppRoutes.withMeal(route, meal, date: date)),
            ),
          ],
        ],
      ),
    );
  }
}

typedef _QuickAdd = Future<void> Function(Food, PortionSelection);

class _BrowseTabs extends StatelessWidget {
  const _BrowseTabs({
    required this.meal,
    required this.onOpen,
    required this.onQuickAdd,
    this.date,
  });

  final MealType meal;
  final DateTime? date;
  final ValueChanged<Food> onOpen;
  final _QuickAdd onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.foodTabRecent),
              Tab(text: l10n.foodTabFavorites),
              Tab(text: l10n.foodTabMine),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RecentTab(onOpen: onOpen, onQuickAdd: onQuickAdd),
                _FavoritesTab(onOpen: onOpen, onQuickAdd: onQuickAdd),
                _MyFoodsTab(
                  meal: meal,
                  date: date,
                  onOpen: onOpen,
                  onQuickAdd: onQuickAdd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTab extends ConsumerWidget {
  const _RecentTab({required this.onOpen, required this.onQuickAdd});

  final ValueChanged<Food> onOpen;
  final _QuickAdd onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentFoodsProvider);
    final calc = ref.watch(foodCalculationServiceProvider);
    return _AsyncList(
      value: recents,
      emptyIcon: Icons.history_rounded,
      emptyMessage: context.l10n.foodRecentEmpty,
      itemBuilder: (recent) => FoodListTile(
        food: recent.food,
        selection: recent.lastSelection,
        nutrition: calc.nutritionFor(recent.food, recent.lastSelection),
        onTap: () => onOpen(recent.food),
        onQuickAdd: () => onQuickAdd(recent.food, recent.lastSelection),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({required this.onOpen, required this.onQuickAdd});

  final ValueChanged<Food> onOpen;
  final _QuickAdd onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteFoodsProvider);
    final calc = ref.watch(foodCalculationServiceProvider);
    return _AsyncList(
      value: favorites,
      emptyIcon: Icons.favorite_border_rounded,
      emptyMessage: context.l10n.foodFavoritesEmpty,
      itemBuilder: (food) {
        final selection = calc.defaultSelection(food);
        return FoodListTile(
          food: food,
          selection: selection,
          nutrition: calc.nutritionFor(food, selection),
          onTap: () => onOpen(food),
          onQuickAdd: () => onQuickAdd(food, selection),
        );
      },
    );
  }
}

class _MyFoodsTab extends ConsumerWidget {
  const _MyFoodsTab({
    required this.meal,
    required this.onOpen,
    required this.onQuickAdd,
    this.date,
  });

  final MealType meal;
  final DateTime? date;
  final ValueChanged<Food> onOpen;
  final _QuickAdd onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final foods = ref.watch(customFoodsProvider);
    final calc = ref.watch(foodCalculationServiceProvider);

    final actions = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              label: l10n.foodCreateCustom,
              icon: Icons.add_rounded,
              onPressed: () => context.push(
                AppRoutes.customFoodPath(meal: meal, date: date),
              ),
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: AppButton.secondary(
              label: l10n.foodCreateRecipe,
              icon: Icons.soup_kitchen_outlined,
              onPressed: () => context.push(
                AppRoutes.withMeal(AppRoutes.recipeBuilder, meal, date: date),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        actions,
        Expanded(
          child: _AsyncList(
            value: foods,
            emptyIcon: Icons.edit_note_rounded,
            emptyMessage: l10n.foodMineEmpty,
            itemBuilder: (food) {
              final selection = calc.defaultSelection(food);
              return FoodListTile(
                food: food,
                selection: selection,
                nutrition: calc.nutritionFor(food, selection),
                onTap: () => onOpen(food),
                onQuickAdd: () => onQuickAdd(food, selection),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({
    required this.value,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.itemBuilder,
  });

  final AsyncValue<List<T>> value;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (items) => items.isEmpty
          ? EmptyStateView(icon: emptyIcon, message: emptyMessage)
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: items.length,
              itemBuilder: (context, i) => itemBuilder(items[i]),
            ),
    );
  }
}
