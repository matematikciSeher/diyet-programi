import '../../../../shared/models/food.dart';
import '../models/portion_selection.dart';

/// Konuşulan veya tahmin edilen miktarı mevcut [FoodPortion] ile çözer.
///
/// Yiyeceğin porsiyonu yoksa gram uydurulmaz. Kullanıcı onay ekranında
/// miktarı değiştirene kadar [PortionResolution.needsAmount] true kalır.
class PortionResolution {
  const PortionResolution({
    required this.quantity,
    required this.unit,
    required this.baseAmount,
    required this.assumption,
    required this.needsAmount,
  });

  final double quantity;
  final PortionUnit unit;
  final double? baseAmount;
  final bool assumption;
  final bool needsAmount;
}

PortionResolution resolvePortion({
  required Food? food,
  required double? quantity,
  required PortionUnit? unit,
  required bool quantityAmbiguous,
  bool estimated = false,
}) {
  if (quantityAmbiguous || quantity == null || quantity <= 0) {
    return PortionResolution(
      quantity: quantity ?? 0,
      unit: unit ?? PortionUnit.gram,
      baseAmount: null,
      assumption: false,
      needsAmount: true,
    );
  }
  final resolvedUnit = unit ?? PortionUnit.piece;
  if (resolvedUnit == PortionUnit.gram) {
    return PortionResolution(
      quantity: quantity,
      unit: PortionUnit.gram,
      baseAmount: quantity,
      assumption: estimated,
      needsAmount: false,
    );
  }
  if (resolvedUnit == PortionUnit.milliliter) {
    if (food == null) {
      return PortionResolution(
        quantity: quantity,
        unit: PortionUnit.milliliter,
        baseAmount: null,
        assumption: false,
        needsAmount: true,
      );
    }
    if (food.basis == NutritionBasis.milliliter) {
      return PortionResolution(
        quantity: quantity,
        unit: PortionUnit.milliliter,
        baseAmount: quantity,
        assumption: false,
        needsAmount: false,
      );
    }
    final density = food.gramsPerMl;
    if (density != null && density > 0) {
      return PortionResolution(
        quantity: quantity,
        unit: PortionUnit.milliliter,
        baseAmount: density * quantity,
        assumption: true,
        needsAmount: false,
      );
    }
    return PortionResolution(
      quantity: quantity,
      unit: PortionUnit.milliliter,
      baseAmount: null,
      assumption: false,
      needsAmount: true,
    );
  }
  final defined = food?.portions
      .where((portion) => portion.unit == resolvedUnit && portion.baseAmount > 0)
      .firstOrNull;
  if (defined != null) {
    return PortionResolution(
      quantity: quantity,
      unit: resolvedUnit,
      baseAmount: defined.baseAmount * quantity,
      assumption: true,
      needsAmount: false,
    );
  }
  return PortionResolution(
    quantity: quantity,
    unit: resolvedUnit,
    baseAmount: null,
    assumption: false,
    needsAmount: true,
  );
}

/// Onaylı taslaktan hesaplama seçimi. AI kalorisi kullanılmaz.
PortionSelection? selectionForDraft({
  required Food food,
  required double quantity,
  required PortionUnit unit,
  required double? baseAmount,
  required bool needsAmount,
}) {
  if (needsAmount || baseAmount == null || baseAmount <= 0 || quantity <= 0) {
    return null;
  }
  if (unit == PortionUnit.milliliter && food.basis == NutritionBasis.milliliter) {
    return PortionSelection(
      portion: const FoodPortion(unit: PortionUnit.milliliter, baseAmount: 1),
      quantity: quantity,
    );
  }
  if (unit == PortionUnit.milliliter &&
      food.gramsPerMl != null &&
      food.gramsPerMl! > 0) {
    return PortionSelection(
      portion: FoodPortion(
        unit: PortionUnit.milliliter,
        baseAmount: food.gramsPerMl!,
      ),
      quantity: quantity,
    );
  }
  if (!unit.isBaseUnit) {
    final defined = food.portions
        .where((portion) => portion.unit == unit && portion.baseAmount > 0)
        .firstOrNull;
    if (defined != null &&
        (baseAmount - defined.baseAmount * quantity).abs() < 0.05) {
      return PortionSelection(portion: defined, quantity: quantity);
    }
  }
  final baseUnit = food.basis == NutritionBasis.milliliter &&
          unit == PortionUnit.milliliter
      ? PortionUnit.milliliter
      : PortionUnit.gram;
  return PortionSelection(
    portion: FoodPortion(unit: baseUnit, baseAmount: 1),
    quantity: baseAmount,
  );
}
