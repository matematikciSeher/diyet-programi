import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../food/presentation/food_format.dart';
import '../../../food/presentation/widgets/meal_type_selector.dart';

typedef FoodEntryEdit = ({double factor, MealType mealType});

/// Yiyeceğin miktarını ve öğününü düzenler; besin değerleri anlık
/// güncellenir. Kaydedilirse ölçek katsayısı ve öğün döner.
Future<FoodEntryEdit?> showEditFoodEntrySheet(
  BuildContext context,
  MealEntry entry,
) => showModalBottomSheet<FoodEntryEdit>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _EditFoodEntrySheet(entry: entry),
);

class _EditFoodEntrySheet extends StatefulWidget {
  const _EditFoodEntrySheet({required this.entry});

  final MealEntry entry;

  @override
  State<_EditFoodEntrySheet> createState() => _EditFoodEntrySheetState();
}

class _EditFoodEntrySheetState extends State<_EditFoodEntrySheet> {
  late MealType _meal = widget.entry.mealType;
  late final double _baseAmount =
      widget.entry.quantity ?? widget.entry.quantityGrams;
  late double _amount = _baseAmount;
  late final _controller = TextEditingController();

  MealEntry get _entry => widget.entry;

  /// Ölçü birimi adet/dilim gibi bir birimse onu, değilse g/ml'yi düzenler.
  PortionUnit? get _unit => _entry.quantity == null ? null : _entry.unit;
  bool get _isBaseUnit => _unit == null || _unit!.isBaseUnit;
  double get _step => _isBaseUnit ? 10 : 0.5;
  double get _factor => _baseAmount <= 0 ? 1 : _amount / _baseAmount;
  bool get _canScale => _entry.isScalable && _baseAmount > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.text.isEmpty) {
      _controller.text = FoodFormat.quantityInput(context, _amount);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _change(double delta) {
    final next = math.max(_step, ((_amount + delta) / _step).round() * _step);
    setState(() => _amount = next);
    _controller.text = FoodFormat.quantityInput(context, next);
  }

  void _onTyped(String text) {
    final value = FoodFormat.parseQuantity(text);
    if (value != null) setState(() => _amount = value);
  }

  String _unitLabel() {
    final l10n = context.l10n;
    final unit = _unit;
    if (unit == null) {
      return _entry.unit == PortionUnit.milliliter
          ? l10n.unitMilliliter
          : l10n.unitGram;
    }
    return unit.label(l10n, _amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nutrition = _entry.nutrition.scale(_canScale ? _factor : 1);
    final valid = !_canScale || _amount > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.diaryEditTitle, style: context.textStyles.titleLarge),
            AppSpacing.gapXs,
            Text(
              _entry.name,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (_canScale) ...[
              AppSpacing.gapLg,
              Text(l10n.diaryEditAmount, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: l10n.diaryEditDecrease,
                    onPressed: _amount > _step ? () => _change(-_step) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,5}([.,]\d{0,2})?'),
                        ),
                      ],
                      decoration: InputDecoration(suffixText: _unitLabel()),
                      onChanged: _onTyped,
                    ),
                  ),
                  AppSpacing.gapSm,
                  IconButton.outlined(
                    tooltip: l10n.diaryEditIncrease,
                    onPressed: () => _change(_step),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (!_isBaseUnit) ...[
                AppSpacing.gapSm,
                Text(
                  FoodFormat.grams(context, _entry.quantityGrams * _factor),
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            AppSpacing.gapLg,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _NutrientChip(
                  label: l10n.dashboardCaloriesTitle,
                  value: FoodFormat.kcal(context, nutrition.calories),
                  color: context.nutritionColors.calories,
                ),
                _NutrientChip(
                  label: l10n.macroProtein,
                  value: FoodFormat.grams(context, nutrition.proteinG),
                  color: context.nutritionColors.protein,
                ),
                _NutrientChip(
                  label: l10n.macroCarbs,
                  value: FoodFormat.grams(context, nutrition.carbsG),
                  color: context.nutritionColors.carbs,
                ),
                _NutrientChip(
                  label: l10n.macroFat,
                  value: FoodFormat.grams(context, nutrition.fatG),
                  color: context.nutritionColors.fat,
                ),
              ],
            ),
            AppSpacing.gapLg,
            Text(l10n.foodMeal, style: context.textStyles.labelLarge),
            AppSpacing.gapSm,
            MealTypeSelector(
              value: _meal,
              onChanged: (m) => setState(() => _meal = m),
            ),
            AppSpacing.gapXl,
            FilledButton(
              onPressed: valid
                  ? () => Navigator.of(
                      context,
                    ).pop((factor: _canScale ? _factor : 1.0, mealType: _meal))
                  : null,
              child: Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
