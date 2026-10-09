import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/datasources/food_api_config.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/portion_selection.dart';
import '../../domain/usecases/log_food.dart';
import '../food_format.dart';
import '../food_log_feedback.dart';
import '../providers/food_providers.dart';
import '../widgets/meal_type_selector.dart';
import '../widgets/nutrition_facts_panel.dart';
import '../widgets/open_food_facts_attribution.dart';
import '../widgets/portion_editor.dart';
import '../widgets/sample_data_notice.dart';

/// Yiyecek detayı: porsiyon seçimi, anlık besin değerleri, öğün seçimi ve
/// favori.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({
    super.key,
    required this.foodId,
    this.initialFood,
    this.initialMeal,
    this.logDate,
  });

  final String foodId;

  /// Listeden gelindiğinde yiyecek tekrar yüklenmez.
  final Food? initialFood;
  final MealType? initialMeal;

  /// Verilirse yemek bu güne eklenir (Günlük'te seçili gün).
  final DateTime? logDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = initialFood;
    if (food != null) {
      return _FoodDetailView(food: food, meal: initialMeal, logDate: logDate);
    }

    final value = ref.watch(foodByIdProvider(foodId));
    return AsyncValueView(
      value: value,
      loading: (_) => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(foodByIdProvider(foodId)),
        ),
      ),
      data: (loaded) => loaded == null
          ? Scaffold(
              appBar: AppBar(),
              body: MessageView(
                icon: Icons.search_off_rounded,
                title: context.l10n.foodNotFound,
              ),
            )
          : _FoodDetailView(food: loaded, meal: initialMeal, logDate: logDate),
    );
  }
}

class _FoodDetailView extends ConsumerStatefulWidget {
  const _FoodDetailView({required this.food, this.meal, this.logDate});

  final Food food;
  final MealType? meal;
  final DateTime? logDate;

  @override
  ConsumerState<_FoodDetailView> createState() => _FoodDetailViewState();
}

class _FoodDetailViewState extends ConsumerState<_FoodDetailView> {
  late MealType _meal =
      widget.meal ?? LogFood.suggestedMeal(ref.read(clockProvider)());
  late PortionSelection _selection = _initialSelection();
  var _saving = false;

  Food get _food => widget.food;

  /// Daha önce eklendiyse son kullanılan porsiyonla açılır.
  PortionSelection _initialSelection() {
    final recents = ref.read(recentFoodsProvider).value ?? const [];
    for (final recent in recents) {
      if (recent.food.id == _food.id) return recent.lastSelection;
    }
    return ref.read(foodCalculationServiceProvider).defaultSelection(_food);
  }

  Future<void> _add() async {
    setState(() => _saving = true);
    final ok = await logFoodWithFeedback(
      context,
      ref,
      food: _food,
      selection: _selection,
      meal: _meal,
      day: widget.logDate,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) context.pop();
  }

  Future<void> _toggleFavorite({required bool isFavorite}) async {
    final result = await ref
        .read(foodRepositoryProvider)
        .setFavorite(_food, favorite: !isFavorite);
    if (!mounted) return;
    result.when(
      success: (_) {},
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.foodDeleted(_food.name);
    final result = await ref
        .read(foodRepositoryProvider)
        .deleteCustomFood(_food.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        context.pop();
        messenger.showSnackBar(SnackBar(content: Text(message)));
      },
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calc = ref.watch(foodCalculationServiceProvider);
    final isFavorite = ref.watch(favoriteFoodIdsProvider).contains(_food.id);
    final nutrition = calc.nutritionFor(_food, _selection);
    final reference = _food.dataReference;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isFavorite
                ? l10n.foodFavoriteRemove
                : l10n.foodFavoriteAdd,
            isSelected: isFavorite,
            onPressed: () => _toggleFavorite(isFavorite: isFavorite),
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(
              Icons.favorite_rounded,
              color: context.colors.error,
            ),
          ),
          if (_food.isUserCreated)
            IconButton(
              tooltip: l10n.foodDelete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(food: _food),
                AppSpacing.gapLg,
                AppCard(
                  child: PortionEditor(
                    food: _food,
                    portions: calc.portionsFor(_food),
                    initial: _selection,
                    onChanged: (s) => setState(() => _selection = s),
                  ),
                ),
                AppSpacing.gapSm,
                AppCard(child: NutritionFactsPanel(nutrition: nutrition)),
                if (_food.ingredients.isNotEmpty) ...[
                  SectionHeader(title: l10n.foodIngredients),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final i in _food.ingredients)
                          ListTile(
                            dense: true,
                            title: Text(i.name),
                            subtitle: Text(FoodFormat.grams(context, i.grams)),
                            trailing: Text(
                              FoodFormat.kcal(context, i.nutrition.calories),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                SectionHeader(title: l10n.foodMeal),
                MealTypeSelector(
                  value: _meal,
                  onChanged: (m) => setState(() => _meal = m),
                ),
                AppSpacing.gapXl,
                if (_food.isSample && reference != null)
                  SampleDataNotice(source: reference)
                else if (reference == FoodApiConfig.dataReference)
                  const OpenFoodFactsAttribution(compact: true)
                else if (reference != null)
                  Text(
                    l10n.foodSource(reference),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: AppButton(
            label: l10n.foodAddToMeal(_meal.label(l10n)),
            icon: Icons.add_rounded,
            isLoading: _saving,
            onPressed: _selection.isValid ? _add : null,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.food});

  final Food food;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badge = switch (food) {
      Food(isRecipe: true) => l10n.foodRecipeBadge,
      Food(source: FoodSource.custom) => l10n.foodCustomBadge,
      Food(isSample: true) => l10n.foodSampleBadge,
      _ => null,
    };
    final brand = food.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (food.imageUrl != null && food.imageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: AppRadius.lgAll,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                food.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          AppSpacing.gapLg,
        ],
        Text(
          food.name,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (brand != null) ...[
          AppSpacing.gapXs,
          Text(
            brand,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (badge != null)
              Chip(
                avatar: Icon(food.source.icon, size: AppSizes.iconSm),
                label: Text(badge),
                visualDensity: VisualDensity.compact,
              ),
            Text(
              l10n.foodPer100(
                food.basis.unitLabel(l10n),
                AppFormat.integer(context, food.nutritionPer100.calories),
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
