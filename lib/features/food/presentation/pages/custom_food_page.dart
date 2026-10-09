import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../food_format.dart';
import '../providers/food_providers.dart';

/// Kullanıcının etiket değerleriyle kendi yiyeceğini oluşturması.
/// Kaydedilince doğrudan detay ekranına geçilir, böylece hemen eklenebilir.
class CustomFoodPage extends ConsumerStatefulWidget {
  const CustomFoodPage({super.key, this.meal, this.barcode, this.logDate});

  final MealType? meal;
  final String? barcode;
  final DateTime? logDate;

  @override
  ConsumerState<CustomFoodPage> createState() => _CustomFoodPageState();
}

class _CustomFoodPageState extends ConsumerState<CustomFoodPage> {
  static const _portionUnits = [
    PortionUnit.serving,
    PortionUnit.piece,
    PortionUnit.slice,
    PortionUnit.bowl,
    PortionUnit.glass,
    PortionUnit.tablespoon,
    PortionUnit.teaspoon,
  ];

  /// Makrolardan hesaplanan enerji girilen kaloriden bu oranda saparsa
  /// kullanıcı uyarılır (kaydetme engellenmez).
  static const _mismatchTolerance = 0.2;
  static const _mismatchMinKcal = 20.0;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _portionAmount = TextEditingController(text: '100');
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  final _sugar = TextEditingController();
  final _sodium = TextEditingController();
  TextEditingController? _barcodeField;

  var _basis = NutritionBasis.gram;
  var _portionUnit = PortionUnit.serving;
  var _saving = false;

  List<TextEditingController> get _nutrientFields => [
    _calories,
    _protein,
    _carbs,
    _fat,
  ];

  @override
  void initState() {
    super.initState();
    final code = widget.barcode?.trim();
    if (code != null && code.isNotEmpty) {
      _barcodeField = TextEditingController(text: code);
    }
    for (final c in _nutrientFields) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _portionAmount,
      _calories,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _sugar,
      _sodium,
      ?_barcodeField,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _read(TextEditingController c) => FoodFormat.parseQuantity(c.text);

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.errorValueRequired : null;

  String? _positive(String? v) {
    final value = FoodFormat.parseQuantity(v ?? '');
    return value == null || value <= 0
        ? context.l10n.errorPositiveNumber
        : null;
  }

  String? _nonNegative(String? v) {
    final value = FoodFormat.parseQuantity(v ?? '');
    return value == null || value < 0
        ? context.l10n.errorNonNegativeNumber
        : null;
  }

  String? _optionalNonNegative(String? v) =>
      (v == null || v.trim().isEmpty) ? null : _nonNegative(v);

  /// 4/4/9 kcal/g (Atwater) ile makrolardan hesaplanan enerji.
  double? _macroEnergyIfMismatch() {
    final kcal = _read(_calories);
    final p = _read(_protein);
    final c = _read(_carbs);
    final f = _read(_fat);
    if (kcal == null || p == null || c == null || f == null) return null;
    final fromMacros = p * 4 + c * 4 + f * 9;
    final diff = (fromMacros - kcal).abs();
    final allowed = (kcal * _mismatchTolerance).clamp(_mismatchMinKcal, 1e9);
    return diff > allowed ? fromMacros : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final calc = ref.read(foodCalculationServiceProvider);
    final fiber = _read(_fiber);
    final sugar = _read(_sugar);
    final sodium = _read(_sodium);
    final brand = _brand.text.trim();
    final food = calc.buildCustomFood(
      id: '',
      name: _name.text,
      brand: brand.isEmpty ? null : brand,
      barcode: widget.barcode,
      basis: _basis,
      portionAmount: _read(_portionAmount)!,
      portionUnit: _portionUnit,
      nutritionPerPortion: NutritionFacts(
        calories: _read(_calories)!,
        proteinG: _read(_protein)!,
        carbsG: _read(_carbs)!,
        fatG: _read(_fat)!,
        fiberG: fiber,
        sugarG: sugar,
        sodiumMg: sodium,
      ),
    );
    final result = await ref.read(foodRepositoryProvider).saveCustomFood(food);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      success: (saved) {
        context.showSnack(context.l10n.customFoodSaved(saved.name));
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
    final mismatch = _macroEnergyIfMismatch();
    final decimal = [
      FilteringTextInputFormatter.allow(RegExp(r'^\d{0,5}([.,]\d{0,2})?')),
    ];
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);
    final baseUnit = _basis.unitLabel(l10n);

    Widget numberField(
      TextEditingController c,
      String label,
      FormFieldValidator<String> validator,
    ) => AppTextField(
      controller: c,
      label: label,
      keyboardType: numberKeyboard,
      inputFormatters: decimal,
      textInputAction: TextInputAction.next,
      validator: validator,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customFoodTitle)),
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
                    label: l10n.customFoodName,
                    hint: l10n.customFoodNameHint,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  AppSpacing.gapLg,
                  AppTextField(
                    controller: _brand,
                    label: l10n.customFoodBrand,
                    textInputAction: TextInputAction.next,
                  ),
                  if (_barcodeField != null) ...[
                    AppSpacing.gapLg,
                    AppTextField(
                      controller: _barcodeField,
                      label: l10n.customFoodBarcode,
                      prefixIcon: Icons.qr_code_2_rounded,
                      enabled: false,
                    ),
                  ],
                  SectionHeader(title: l10n.customFoodPortion),
                  DropdownButtonFormField<PortionUnit>(
                    initialValue: _portionUnit,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.customFoodPortionUnit,
                    ),
                    items: [
                      for (final u in _portionUnits)
                        DropdownMenuItem(value: u, child: Text(u.label(l10n))),
                    ],
                    onChanged: (u) =>
                        setState(() => _portionUnit = u ?? _portionUnit),
                  ),
                  AppSpacing.gapLg,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _portionAmount,
                          label: l10n.customFoodPortionAmount,
                          keyboardType: numberKeyboard,
                          inputFormatters: decimal,
                          suffixText: baseUnit,
                          validator: _positive,
                        ),
                      ),
                      AppSpacing.gapMd,
                      SegmentedButton<NutritionBasis>(
                        segments: [
                          for (final b in NutritionBasis.values)
                            ButtonSegment(
                              value: b,
                              label: Text(b.unitLabel(l10n)),
                            ),
                        ],
                        selected: {_basis},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            setState(() => _basis = s.first),
                      ),
                    ],
                  ),
                  SectionHeader(title: l10n.customFoodValuesTitle),
                  Text(
                    l10n.customFoodValuesHint,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapMd,
                  numberField(_calories, l10n.customFoodCalories, _nonNegative),
                  AppSpacing.gapLg,
                  numberField(_protein, l10n.customFoodProtein, _nonNegative),
                  AppSpacing.gapLg,
                  numberField(_carbs, l10n.customFoodCarbs, _nonNegative),
                  AppSpacing.gapLg,
                  numberField(_fat, l10n.customFoodFat, _nonNegative),
                  AppSpacing.gapLg,
                  numberField(
                    _fiber,
                    l10n.customFoodFiber,
                    _optionalNonNegative,
                  ),
                  AppSpacing.gapLg,
                  numberField(
                    _sugar,
                    l10n.customFoodSugar,
                    _optionalNonNegative,
                  ),
                  AppSpacing.gapLg,
                  numberField(
                    _sodium,
                    l10n.customFoodSodium,
                    _optionalNonNegative,
                  ),
                  if (mismatch != null) ...[
                    AppSpacing.gapLg,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: AppSizes.iconSm,
                          color: context.nutritionColors.warning,
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Text(
                            l10n.customFoodEnergyMismatch(
                              AppFormat.integer(context, mismatch),
                            ),
                            style: context.textStyles.bodySmall,
                          ),
                        ),
                      ],
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
