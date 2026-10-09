import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/models/food.dart';
import '../../domain/models/portion_selection.dart';
import '../food_format.dart';

/// Miktar alanı, ölçü seçimi ve hızlı miktar çipleri. Her değişiklikte
/// [onChanged] çağrılır; geçersiz miktarda miktar 0 olarak bildirilir.
class PortionEditor extends StatefulWidget {
  const PortionEditor({
    super.key,
    required this.food,
    required this.portions,
    required this.initial,
    required this.onChanged,
    this.autofocus = false,
  });

  final Food food;
  final List<FoodPortion> portions;
  final PortionSelection initial;
  final ValueChanged<PortionSelection> onChanged;
  final bool autofocus;

  @override
  State<PortionEditor> createState() => _PortionEditorState();
}

class _PortionEditorState extends State<PortionEditor> {
  static const _namedPresets = [0.5, 1.0, 1.5, 2.0, 3.0];
  static const _basePresets = [50.0, 100.0, 150.0, 200.0, 250.0];

  late final TextEditingController _controller;
  late PortionSelection _selection = widget.initial;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _controller.text = FoodFormat.quantityInput(context, _selection.quantity);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(PortionSelection selection) {
    setState(() => _selection = selection);
    widget.onChanged(selection);
  }

  void _setQuantity(double quantity) {
    _controller.text = FoodFormat.quantityInput(context, quantity);
    _emit(_selection.copyWith(quantity: quantity));
  }

  void _onTextChanged(String text) {
    _emit(_selection.copyWith(quantity: FoodFormat.parseQuantity(text) ?? 0));
  }

  /// Temel ölçüye geçerken toplam miktar korunur; porsiyon birimine
  /// geçerken 1 porsiyon seçilir.
  void _onPortionChanged(FoodPortion? portion) {
    if (portion == null || portion == _selection.portion) return;
    final quantity = portion.unit.isBaseUnit
        ? (_selection.isValid
              ? (_selection.baseAmount / portion.baseAmount).roundToDouble()
              : 100.0)
        : 1.0;
    _controller.text = FoodFormat.quantityInput(context, quantity);
    _emit(PortionSelection(portion: portion, quantity: quantity));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final presets = _selection.portion.unit.isBaseUnit
        ? _basePresets
        : _namedPresets;
    final invalid = !_selection.isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: TextField(
                controller: _controller,
                autofocus: widget.autofocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,5}([.,]\d{0,2})?'),
                  ),
                ],
                textAlign: TextAlign.center,
                style: context.textStyles.titleMedium,
                decoration: InputDecoration(
                  labelText: l10n.foodAmount,
                  errorText: invalid ? l10n.foodInvalidAmount : null,
                  errorMaxLines: 2,
                ),
                onChanged: _onTextChanged,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: DropdownButtonFormField<FoodPortion>(
                initialValue: widget.portions.contains(_selection.portion)
                    ? _selection.portion
                    : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.foodUnit),
                items: [
                  for (final p in widget.portions)
                    DropdownMenuItem(
                      value: p,
                      child: Text(
                        FoodFormat.portionOption(context, widget.food, p),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _onPortionChanged,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in presets)
              ChoiceChip(
                label: Text(FoodFormat.quantityInput(context, preset)),
                selected: _selection.quantity == preset,
                showCheckmark: false,
                onSelected: (_) => _setQuantity(preset),
              ),
          ],
        ),
      ],
    );
  }
}
