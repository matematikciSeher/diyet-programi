import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/models/recipe.dart';
import '../../../progress/presentation/progress_labels.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/models/recipe_category.dart';
import '../../domain/services/recipe_text_parser.dart';
import '../recipe_labels.dart';

/// Kullanıcının kendi tarifini (adımlar, malzemeler, porsiyon başı besin
/// değerleri) oluşturduğu form. Tarif `users/{uid}/recipes` altına yazılır.
class RecipeCreatePage extends ConsumerStatefulWidget {
  const RecipeCreatePage({super.key});

  @override
  ConsumerState<RecipeCreatePage> createState() => _RecipeCreatePageState();
}

class _RecipeCreatePageState extends ConsumerState<RecipeCreatePage> {
  static const _maxServings = 20;

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _prep = TextEditingController();
  final _cook = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _categories = <RecipeCategory>{};
  var _servings = 1;
  var _saving = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _prep,
      _cook,
      _kcal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _ingredients,
      _steps,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.errorValueRequired : null;

  String? _number(String? v, {bool required = false, double max = 5000}) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) {
      return required ? context.l10n.errorValueRequired : null;
    }
    final value = ProgressFormat.parse(text);
    if (value == null || value < 0 || value > max) {
      return context.l10n.errorOutOfRange('0', '${max.round()}');
    }
    return null;
  }

  double _read(TextEditingController c) => ProgressFormat.parse(c.text) ?? 0;

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_categories.isEmpty) {
      context.showSnack(l10n.recipeNeedsCategory);
      return;
    }
    setState(() => _saving = true);
    final fiber = ProgressFormat.parse(_fiber.text);
    final prep = ProgressFormat.parse(_prep.text)?.round();
    final cook = ProgressFormat.parse(_cook.text)?.round();
    final description = _description.text.trim();
    final recipe = Recipe(
      id: '',
      title: _title.text.trim(),
      description: description.isEmpty ? null : description,
      servings: _servings,
      prepMinutes: prep,
      cookMinutes: cook,
      nutritionPerServing: NutritionFacts(
        calories: _read(_kcal),
        proteinG: _read(_protein),
        carbsG: _read(_carbs),
        fatG: _read(_fat),
        fiberG: fiber,
      ),
      ingredients: RecipeTextParser.ingredients(_ingredients.text),
      steps: RecipeTextParser.steps(_steps.text),
      tags: [
        for (final c in RecipeCategory.assignable)
          if (_categories.contains(c)) c.name,
      ],
    );
    final result = await ref.read(recipeRepositoryProvider).saveRecipe(recipe);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success(value: final saved):
        context.showSnack(l10n.recipeSaved(saved.title));
        context.pushReplacement(AppRoutes.recipeDetailPath(saved.id));
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool required = false,
    double max = 5000,
  }) => AppTextField(
    controller: controller,
    label: label,
    suffixText: suffix,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}([.,]\d?)?')),
    ],
    textInputAction: TextInputAction.next,
    validator: (v) => _number(v, required: required, max: max),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        AppSpacing.gapMd,
        Expanded(child: b),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipeCreate)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.gapMd,
                  AppTextField(
                    controller: _title,
                    label: l10n.recipeName,
                    hint: l10n.recipeNameHint,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  AppSpacing.gapMd,
                  AppTextField(
                    controller: _description,
                    label: l10n.recipeDescription,
                    maxLines: 2,
                  ),
                  SectionHeader(title: l10n.recipeCategories),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final c in RecipeCategory.assignable)
                        FilterChip(
                          avatar: Icon(c.icon, size: AppSizes.iconSm),
                          label: Text(c.label(l10n)),
                          selected: _categories.contains(c),
                          onSelected: (on) => setState(
                            () => on ? _categories.add(c) : _categories.remove(c),
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  Text(
                    l10n.recipeComputedCategoriesNote,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
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
                        tooltip: l10n.recipeLessServings,
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
                        tooltip: l10n.recipeMoreServings,
                        onPressed: _servings < _maxServings
                            ? () => setState(() => _servings++)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  pair(
                    _numberField(
                      _prep,
                      l10n.recipePrepMinutes,
                      suffix: l10n.unitMinutes,
                      max: 600,
                    ),
                    _numberField(
                      _cook,
                      l10n.recipeCookMinutes,
                      suffix: l10n.unitMinutes,
                      max: 600,
                    ),
                  ),
                  SectionHeader(title: l10n.recipeNutritionPerServing),
                  _numberField(
                    _kcal,
                    l10n.nutrientCalories,
                    suffix: 'kcal',
                    required: true,
                  ),
                  AppSpacing.gapMd,
                  pair(
                    _numberField(
                      _protein,
                      l10n.macroProtein,
                      suffix: l10n.unitGram,
                      required: true,
                      max: 500,
                    ),
                    _numberField(
                      _carbs,
                      l10n.macroCarbs,
                      suffix: l10n.unitGram,
                      required: true,
                      max: 500,
                    ),
                  ),
                  AppSpacing.gapMd,
                  pair(
                    _numberField(
                      _fat,
                      l10n.macroFat,
                      suffix: l10n.unitGram,
                      required: true,
                      max: 500,
                    ),
                    _numberField(_fiber, l10n.nutrientFiber, suffix: l10n.unitGram, max: 200),
                  ),
                  SectionHeader(title: l10n.recipeIngredients),
                  AppTextField(
                    controller: _ingredients,
                    hint: l10n.recipeIngredientsHint,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                  ),
                  SectionHeader(title: l10n.recipeSteps),
                  AppTextField(
                    controller: _steps,
                    hint: l10n.recipeStepsHint,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                  ),
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
