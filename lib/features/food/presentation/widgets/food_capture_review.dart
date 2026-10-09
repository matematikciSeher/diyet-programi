import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/models/food_log_draft.dart';
import '../../domain/models/portion_selection.dart';
import '../../domain/services/food_calculation_service.dart';
import '../../domain/services/food_match_service.dart';
import '../../domain/services/portion_resolver.dart';
import '../food_format.dart';
import 'portion_editor.dart';

/// Fotoğraf veya ses adaylarının onay ekranı. Kaydetmez.
class FoodCaptureReview extends StatelessWidget {
  const FoodCaptureReview({
    super.key,
    required this.drafts,
    required this.meal,
    required this.saving,
    required this.calculator,
    required this.onMeal,
    required this.onChanged,
    required this.onSelectFood,
    required this.onRemove,
    required this.onRematch,
    required this.onPickReplacement,
    required this.onAddFood,
    required this.onCreateCustom,
    required this.onSave,
  });

  final List<FoodLogDraft> drafts;
  final MealType? meal;
  final bool saving;
  final FoodCalculationService calculator;
  final ValueChanged<MealType> onMeal;
  final ValueChanged<FoodLogDraft> onChanged;
  final void Function(FoodLogDraft draft, Food food) onSelectFood;
  final ValueChanged<FoodLogDraft> onRemove;
  final Future<void> Function(FoodLogDraft draft, String query) onRematch;
  final Future<void> Function(FoodLogDraft draft) onPickReplacement;
  final VoidCallback onAddFood;
  final VoidCallback onCreateCustom;
  final VoidCallback onSave;

  bool get _ready =>
      meal != null && drafts.isNotEmpty && drafts.every((draft) => draft.canSave);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.photoLogResults, style: context.textStyles.titleMedium),
        AppSpacing.gapSm,
        Text(
          l10n.photoLogDisclaimer,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapMd,
        Text(l10n.photoLogMeal, style: context.textStyles.titleSmall),
        AppSpacing.gapSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in MealType.values)
              ChoiceChip(
                label: Text(type.label(l10n)),
                selected: meal == type,
                onSelected: (_) => onMeal(type),
              ),
          ],
        ),
        if (meal == null) ...[
          AppSpacing.gapSm,
          Text(l10n.photoLogSelectMeal, style: context.textStyles.bodyMedium),
        ],
        AppSpacing.gapLg,
        for (final draft in drafts) ...[
          _DraftTile(
            key: ValueKey(draft.localId),
            draft: draft,
            calculator: calculator,
            onChanged: onChanged,
            onSelectFood: onSelectFood,
            onRemove: onRemove,
            onRematch: onRematch,
            onPickReplacement: onPickReplacement,
            onCreateCustom: onCreateCustom,
          ),
          AppSpacing.gapMd,
        ],
        OutlinedButton.icon(
          onPressed: onAddFood,
          icon: const Icon(Icons.add),
          label: Text(l10n.photoLogAddFood),
          style: _target,
        ),
        AppSpacing.gapLg,
        FilledButton(
          key: const ValueKey('capture-save'),
          onPressed: saving || !_ready ? null : onSave,
          style: _target,
          child: Text(l10n.photoLogAddToDiary),
        ),
      ],
    );
  }
}

const _target = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(48, AppSizes.minTouchTarget)),
);

class _DraftTile extends StatelessWidget {
  const _DraftTile({
    super.key,
    required this.draft,
    required this.calculator,
    required this.onChanged,
    required this.onSelectFood,
    required this.onRemove,
    required this.onRematch,
    required this.onPickReplacement,
    required this.onCreateCustom,
  });

  final FoodLogDraft draft;
  final FoodCalculationService calculator;
  final ValueChanged<FoodLogDraft> onChanged;
  final void Function(FoodLogDraft draft, Food food) onSelectFood;
  final ValueChanged<FoodLogDraft> onRemove;
  final Future<void> Function(FoodLogDraft draft, String query) onRematch;
  final Future<void> Function(FoodLogDraft draft) onPickReplacement;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final food = draft.food;
    final selection = food == null
        ? null
        : selectionForDraft(
            food: food,
            quantity: draft.quantity,
            unit: draft.unit,
            baseAmount: draft.baseAmount,
            needsAmount: draft.needsAmount,
          );
    final nutrition = food == null || selection == null
        ? null
        : calculator.nutritionFor(food, selection);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  food?.name ?? draft.queryName,
                  style: context.textStyles.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.photoLogRemove,
                onPressed: () => onRemove(draft),
                icon: const Icon(Icons.delete_outline),
                style: IconButton.styleFrom(
                  minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
                ),
              ),
            ],
          ),
          if (draft.confidence != null && draft.confidence! > 0)
            Text(
              l10n.photoLogConfidence('${(draft.confidence! * 100).round()}'),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          if (draft.matchStatus == FoodMatchStatus.notFound) ...[
            AppSpacing.gapSm,
            Text(l10n.photoLogNoMatch),
            AppSpacing.gapSm,
            _SearchRow(onSubmit: (query) => onRematch(draft, query)),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: () => onPickReplacement(draft),
                  child: Text(l10n.photoLogManualSearch),
                ),
                OutlinedButton(
                  onPressed: onCreateCustom,
                  child: Text(l10n.photoLogCreateCustom),
                ),
              ],
            ),
          ],
          if (draft.options.isNotEmpty && food == null) ...[
            AppSpacing.gapSm,
            Text(l10n.photoLogChooseMatch),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final option in draft.options)
                  ChoiceChip(
                    label: Text(option.name),
                    selected: false,
                    onSelected: (_) => onSelectFood(draft, option),
                  ),
              ],
            ),
          ],
          if (food != null && draft.needsAmount) ...[
            AppSpacing.gapSm,
            Text(l10n.photoLogAmbiguousQuantity),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final grams in const [30.0, 50.0, 75.0, 100.0])
                  ChoiceChip(
                    label: Text('${grams.round()} g'),
                    selected: draft.baseAmount == grams,
                    onSelected: (_) => onChanged(
                      draft.copyWith(
                        quantity: grams,
                        unit: PortionUnit.gram,
                        baseAmount: grams,
                        needsAmount: false,
                        assumption: false,
                      ),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapSm,
            _GramField(
              label: l10n.photoLogManualGrams,
              onGrams: (grams) => onChanged(
                draft.copyWith(
                  quantity: grams,
                  unit: PortionUnit.gram,
                  baseAmount: grams,
                  needsAmount: false,
                  assumption: false,
                ),
              ),
            ),
          ],
          if (food != null && selection != null && !draft.needsAmount) ...[
            if (draft.assumption) ...[
              AppSpacing.gapSm,
              Text(
                l10n.photoLogAssumption(
                  _qty(draft.quantity),
                  _unitLabel(context, draft),
                  _qty(draft.baseAmount ?? selection.baseAmount),
                ),
              ),
            ],
            AppSpacing.gapSm,
            PortionEditor(
              key: ValueKey('${draft.localId}-${food.id}-${draft.unit.name}'),
              food: food,
              portions: calculator.portionsFor(food),
              initial: selection,
              onChanged: (next) => onChanged(_fromSelection(draft, food, next)),
            ),
            AppSpacing.gapSm,
            Text(
              '${l10n.photoLogCalculated}: ${FoodFormat.kcal(context, nutrition!.calories)}',
              style: context.textStyles.labelLarge,
            ),
          ],
          if (draft.hasRestriction) ...[
            AppSpacing.gapSm,
            Text(
              [
                if (draft.allergyConflict) l10n.photoLogAllergyWarning,
                if (draft.dislikeConflict) l10n.photoLogDislikeWarning,
                if (draft.dietConflict) l10n.photoLogDietWarning,
              ].join(' '),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: draft.restrictionAcknowledged,
              onChanged: (value) => onChanged(
                draft.copyWith(restrictionAcknowledged: value ?? false),
              ),
              title: Text(l10n.photoLogAcknowledge),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          if (food != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onPickReplacement(draft),
                child: Text(l10n.photoLogChangeFood),
              ),
            ),
        ],
      ),
    );
  }

  FoodLogDraft _fromSelection(
    FoodLogDraft draft,
    Food food,
    PortionSelection selection,
  ) {
    final grams = calculator.gramsFor(food, selection) ?? selection.baseAmount;
    return draft.copyWith(
      quantity: selection.quantity,
      unit: selection.portion.unit,
      baseAmount: grams,
      needsAmount: !selection.isValid,
      assumption: !selection.portion.unit.isBaseUnit,
      clearSpokenUnit: true,
    );
  }

  String _unitLabel(BuildContext context, FoodLogDraft draft) {
    final l10n = context.l10n;
    return switch (draft.spokenUnitKey) {
      'tea' => l10n.voiceUnitTea,
      'spoon' => l10n.voiceUnitSpoon,
      'plate' => l10n.voiceUnitPlate,
      'dessert' => l10n.voiceUnitDessert,
      _ => draft.unit.label(l10n, draft.quantity),
    };
  }

  String _qty(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);
}

class _SearchRow extends StatefulWidget {
  const _SearchRow({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<_SearchRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: _controller,
            label: l10n.photoLogSearchAgain,
            onSubmitted: widget.onSubmit,
          ),
        ),
        AppSpacing.gapSm,
        IconButton(
          tooltip: l10n.photoLogSearchAgain,
          onPressed: () => widget.onSubmit(_controller.text),
          icon: const Icon(Icons.search),
        ),
      ],
    );
  }
}

class _GramField extends StatefulWidget {
  const _GramField({required this.label, required this.onGrams});

  final String label;
  final ValueChanged<double> onGrams;

  @override
  State<_GramField> createState() => _GramFieldState();
}

class _GramFieldState extends State<_GramField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.label,
      suffixText: 'g',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSubmitted: (value) {
        final grams = double.tryParse(value.replaceAll(',', '.'));
        if (grams != null && grams > 0) widget.onGrams(grams);
      },
    );
  }
}
