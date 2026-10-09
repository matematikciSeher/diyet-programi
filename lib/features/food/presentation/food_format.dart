import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/food.dart';
import '../../../shared/presentation/enum_labels.dart';
import '../domain/models/portion_selection.dart';

extension PortionUnitL10n on PortionUnit {
  String label(AppLocalizations l10n, [num count = 1]) => switch (this) {
    PortionUnit.gram => l10n.unitGram,
    PortionUnit.milliliter => l10n.unitMilliliter,
    PortionUnit.piece => l10n.unitPiece(count),
    PortionUnit.slice => l10n.unitSlice(count),
    PortionUnit.serving => l10n.unitServing(count),
    PortionUnit.bowl => l10n.unitBowl(count),
    PortionUnit.glass => l10n.unitGlass(count),
    PortionUnit.tablespoon => l10n.unitTablespoon(count),
    PortionUnit.teaspoon => l10n.unitTeaspoon(count),
  };
}

extension NutritionBasisL10n on NutritionBasis {
  String unitLabel(AppLocalizations l10n) => switch (this) {
    NutritionBasis.gram => l10n.unitGram,
    NutritionBasis.milliliter => l10n.unitMilliliter,
  };
}

extension FoodSourceIcon on FoodSource {
  IconData get icon => switch (this) {
    FoodSource.recipe => Icons.soup_kitchen_outlined,
    FoodSource.custom => Icons.edit_note_rounded,
    FoodSource.barcode => Icons.qr_code_rounded,
    FoodSource.aiPhoto => Icons.photo_camera_outlined,
    FoodSource.voice => Icons.mic_none_rounded,
    FoodSource.database => Icons.restaurant_rounded,
    FoodSource.mealPlan => Icons.calendar_month_outlined,
  };
}

/// Yiyecek ekranlarında ortak metin biçimleri.
abstract final class FoodFormat {
  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// Metin alanına yazılacak miktar: gruplama yok, en fazla 2 ondalık.
  static String quantityInput(BuildContext context, double value) {
    final format = NumberFormat.decimalPattern(_locale(context))
      ..turnOffGrouping()
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 2;
    return format.format(value);
  }

  /// "1,5" ve "1.5" kabul edilir.
  static double? parseQuantity(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  static String _amount(BuildContext context, double value) =>
      NumberFormat.decimalPattern(
        _locale(context),
      ).copyWithDigits(value < 10 ? 1 : 0).format(value);

  /// "150 g", "2 dilim (50 g)".
  static String selection(
    BuildContext context,
    Food food,
    PortionSelection selection,
  ) {
    final l10n = context.l10n;
    final unit = selection.portion.unit;
    final portion = l10n.portionQuantity(
      quantityInput(context, selection.quantity),
      unit.label(l10n, selection.quantity),
    );
    if (unit.isBaseUnit) return portion;
    return l10n.portionWithBase(
      portion,
      l10n.portionQuantity(
        _amount(context, selection.baseAmount),
        food.basis.unitLabel(l10n),
      ),
    );
  }

  /// Ölçü seçiminde gösterilen etiket: "adet · büyük boy (50 g)".
  static String portionOption(
    BuildContext context,
    Food food,
    FoodPortion portion,
  ) {
    final l10n = context.l10n;
    final unit = portion.unit.label(l10n);
    if (portion.unit.isBaseUnit) return unit;
    final description = portion.description;
    final name = description == null ? unit : '$unit · $description';
    return l10n.portionWithBase(
      name,
      l10n.portionQuantity(
        _amount(context, portion.baseAmount),
        food.basis.unitLabel(l10n),
      ),
    );
  }

  static String grams(BuildContext context, double value) =>
      context.l10n.gramsValue(
        NumberFormat.decimalPattern(
          _locale(context),
        ).copyWithDigits(value < 10 ? 1 : 0).format(value),
      );

  static String kcal(BuildContext context, double value) =>
      context.l10n.kcalValue(
        NumberFormat.decimalPattern(_locale(context)).format(value.round()),
      );

  static String macros(BuildContext context, double p, double c, double f) {
    String v(double x) => NumberFormat.decimalPattern(
      _locale(context),
    ).copyWithDigits(x < 10 ? 1 : 0).format(x);
    return context.l10n.macroSummaryShort(v(p), v(c), v(f));
  }

  static String mealLabel(BuildContext context, MealType meal) =>
      meal.label(context.l10n);
}

extension on NumberFormat {
  NumberFormat copyWithDigits(int digits) => this
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = digits;
}
