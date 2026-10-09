import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/portion_selection.dart';
import '../food_format.dart';
import '../providers/food_providers.dart';
import '../widgets/food_picker_sheet.dart';
import '../widgets/nutrition_facts_panel.dart';

/// Birden fazla yiyecekten tarif oluşturma; toplam ve porsiyon başı besin
/// değerleri malzemeler değiştikçe hesaplanır.
class RecipeBuilderPage extends ConsumerStatefulWidget {
  const RecipeBuilderPage({super.key, this.meal, this.logDate});

  final MealType? meal;
  final DateTime? logDate;

  @override
  ConsumerState<RecipeBuilderPage> createState() => _RecipeBuilderPageState();
}

class _IngredientDraft {
  const _IngredientDraft(this.food, this.selection, this.ingredient);

  final Food food;
  final PortionSelection selection;
  final FoodIngredient ingredient;
}

class _RecipeBuilderPageState extends ConsumerState<RecipeBuilderPage> {
  static const _maxServings = 50;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ingredients = <_IngredientDraft>[];
  var _servings = 1;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  _IngredientDraft _draft(Food food, PortionSelection selection) =>
      _IngredientDraft(
        food,
        selection,
        ref
            .read(foodCalculationServiceProvider)
            .ingredientFrom(food, selection),
      );

  Future<void> _addIngredient() async {
    final picked = await pickIngredient(context);
    if (picked == null || !mounted) return;
    final (food, selection) = picked;
    setState(() => _ingredients.add(_draft(food, selection)));
  }

  Future<void> _editIngredient(int index) async {
    final current = _ingredients[index];
    final selection = await showPortionSheet(
      context,
      current.food,
      initial: current.selection,
    );
    if (selection == null || !mounted) return;
    setState(() => _ingredients[index] = _draft(current.food, selection));
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_ingredients.isEmpty) {
      context.showSnack(context.l10n.recipeNeedsIngredient);
      return;
    }
    if (!valid) return;
    setState(() => _saving = true);

    final recipe = ref
        .read(foodCalculationServiceProvider)
        .buildRecipe(
          id: '',
          name: _name.text,
          servings: _servings,
          ingredients: [for (final d in _ingredients) d.ingredient],
        );
    final result = await ref
        .read(foodRepositoryProvider)
        .saveCustomFood(recipe);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (saved) {
        context.showSnack(context.l10n.recipeSaved(saved.name));
        context.pushReplacement(
          AppRoutes.foodDetailPath(
            saved.id,
            meal: widget.meal,
            date: widget.logDate,
          ),
          extra: saved,
        );
      },
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calc = ref.watch(foodCalculationServiceProvider);
    final ingredients = [for (final d in _ingredients) d.ingredient];
    final total = calc.recipeTotal(ingredients);
    final weight = calc.recipeWeight(ingredients);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipeBuilderTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.gapMd,
                  AppTextField(
                    controller: _name,
                    label: l10n.recipeName,
                    hint: l10n.recipeNameHint,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.errorValueRequired
                        : null,
                  ),
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.recipeServings,
                          style: context.textStyles.labelLarge,
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _servings > 1
                            ? () => setState(() => _servings--)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_servings',
                          textAlign: TextAlign.center,
                          style: context.textStyles.titleMedium,
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _servings < _maxServings
                            ? () => setState(() => _servings++)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  SectionHeader(title: l10n.foodIngredients),
                  if (_ingredients.isEmpty)
                    Text(
                      l10n.recipeNoIngredients,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, d) in _ingredients.indexed)
                            ListTile(
                              onTap: () => _editIngredient(i),
                              title: Text(d.food.name),
                              subtitle: Text(
                                '${FoodFormat.selection(context, d.food, d.selection)}'
                                ' · ${FoodFormat.kcal(context, d.ingredient.nutrition.calories)}',
                              ),
                              trailing: IconButton(
                                tooltip: l10n.actionRemove,
                                onPressed: () =>
                                    setState(() => _ingredients.removeAt(i)),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                        ],
                      ),
                    ),
                  AppSpacing.gapMd,
                  AppButton.secondary(
                    label: l10n.recipeAddIngredient,
                    icon: Icons.add_rounded,
                    onPressed: _addIngredient,
                  ),
                  if (_ingredients.isNotEmpty) ...[
                    SectionHeader(title: l10n.recipePerServing),
                    AppCard(
                      child: NutritionFactsPanel(
                        nutrition: total.scale(1 / _servings),
                      ),
                    ),
                    SectionHeader(title: l10n.recipeTotal),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NutritionFactsPanel(
                            nutrition: total,
                            showDetails: false,
                          ),
                          AppSpacing.gapMd,
                          Text(
                            l10n.recipeTotalWeight(
                              AppFormat.integer(context, weight),
                            ),
                            style: context.textStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      l10n.recipeWeightNote,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
            label: l10n.actionSave,
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
